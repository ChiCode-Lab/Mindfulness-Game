import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../main.dart'; // To access GameScreen and design colors

import '../services/progress_service.dart';
import '../services/notification_service.dart';
import '../services/economy_service.dart';
import '../widgets/out_of_opals_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  final ProgressService progressService;
  
  const SettingsScreen({super.key, required this.progressService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedColumns = 4;
  int _selectedRows = 4;
  int _selectedDurationMinutes = 5;
  Soundscape _selectedSoundscape = Soundscape.campfire;
  TimeOfDay? _selectedZenTime;
  late EconomyService _economyService;
  late TextEditingController _usernameController;
  bool _isPublic = false;
  bool _isSavingUsername = false;

  @override
  void initState() {
    super.initState();
    _economyService = EconomyService();
    _economyService.init(); // Boot economy locally
    _usernameController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      try {
        final res = await client.from('user_profiles').select('username, is_public').eq('id', user.id).maybeSingle();
        if (res != null && mounted) {
          setState(() {
            _usernameController.text = res['username'] ?? '';
            _isPublic = res['is_public'] ?? false;
          });
        }
      } catch (e) {
        debugPrint('Failed to load profile: $e');
      }
    }
  }

  Future<void> _updateUsername(String username) async {
    if (username.isEmpty) return;
    setState(() => _isSavingUsername = true);
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      try {
        await client.from('user_profiles').update({
          'username': username.toLowerCase().trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully 🌿')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username already taken or invalid.')),
          );
        }
      }
    }
    if (mounted) setState(() => _isSavingUsername = false);
  }

  Future<void> _togglePublic(bool value) async {
    setState(() => _isPublic = value);
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      try {
        await client.from('user_profiles').update({'is_public': value}).eq('id', user.id);
      } catch (e) {
        debugPrint('Toggle public failed: $e');
      }
    }
  }

  int get _currentCost {
    final settings = GameSettings(
      gridColumns: _selectedColumns,
      gridRows: _selectedRows,
      sessionDuration: Duration(minutes: _selectedDurationMinutes),
      soundscape: _selectedSoundscape,
    );
    return settings.calculateOpalCost(
      isPremiumAudio: true // All audio is now premium/high-quality
    );
  }

  void _onBegin() async {
    final settings = GameSettings(
      gridColumns: _selectedColumns,
      gridRows: _selectedRows,
      sessionDuration: Duration(minutes: _selectedDurationMinutes),
      soundscape: _selectedSoundscape,
    );
    final cost = _currentCost;

    if (!_economyService.canAfford(cost)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => OutOfOpalsDialog(
          economyService: _economyService,
          onAdWatched: () async {
            await _economyService.addOpals(25);
            if (mounted) setState(() {}); // Refresh OPAL UI if needed
          },
          onPremiumStarted: () async {
            await _economyService.startPremiumTrial();
            if (mounted) setState(() {});
          }
        ),
      );
      return; 
    }

    // Deduct upon start
    await _economyService.deductOpals(cost);

    if (_selectedZenTime != null && mounted) {
      final notifService = NotificationService();
      await notifService.init();
      await notifService.requestPermissions();
      await notifService.scheduleDailyZen(_selectedZenTime!);
    }
    
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          settings: settings,
          progressService: widget.progressService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF2D1B4E), // Deep Lavender Ambient
              Color(0xFF1A233A), // Deep Twilight Blue
            ],
            stops: [0.1, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Set your Intention',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: Color(0xFFF8F9FA),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select your environment to breathe and focus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB0BEC4),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Grid Size Selector
                  _buildSectionHeader('COMPLEXITY'),
                  const SizedBox(height: 16),
                  _buildGridSizeSelector(),
                  const SizedBox(height: 32),

                  // Session Duration Selector
                  _buildSectionHeader('SESSION DURATION'),
                  const SizedBox(height: 16),
                  _buildDurationSelector(),
                  const SizedBox(height: 40),

                  // Soundscape Selector
                  _buildSectionHeader('SOUNDSCAPE'),
                  const SizedBox(height: 16),
                  _buildSoundscapeSelector(),

                  const SizedBox(height: 48),

                  // Viral Identity
                  _buildSectionHeader('VIRAL IDENTITY'),
                  const SizedBox(height: 16),
                  _buildUsernameField(),
                  const SizedBox(height: 16),
                  _buildPublicToggle(),

                  const SizedBox(height: 48),
                  
                  // Zen Time Selector
                  _buildSectionHeader('DAILY HABIT'),
                  const SizedBox(height: 16),
                  _buildTimePicker(),

                  const SizedBox(height: 48),

                  // Begin Action
                  Center(
                    child: Text(
                      _economyService.state.isPremium ? 'Premium Active - No Opal Cost' : 'Current Balance: ${_economyService.state.opals} Opals',
                      style: const TextStyle(color: Color(0xFFB0BEC4), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onBegin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A66), // Soft Coral
                      foregroundColor: const Color(0xFF1A233A),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                      shadowColor: const Color(0xFFFF8A66).withOpacity(0.4),
                    ),
                    child: Text(
                      _economyService.state.isPremium ? 'BEGIN SESSION' : 'BEGIN SESSION ($_currentCost OPALS)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFB0BEC4),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildGridSizeSelector() {
    // (columns, rows, label)
    const options = [
      (2, 2, '2×2'),
      (3, 3, '3×3'),
      (4, 3, '4×3'),
      (4, 4, '4×4'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((opt) {
        final isSelected = _selectedColumns == opt.$1 && _selectedRows == opt.$2;
        return _buildGridChip(opt.$3, opt.$1, opt.$2, isSelected);
      }).toList(),
    );
  }

  Widget _buildGridChip(String label, int cols, int rows, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedColumns = cols;
        _selectedRows = rows;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF8A66).withOpacity(0.2)
              : const Color(0xFF222E4A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF8A66) : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF8A66) : const Color(0xFFF8F9FA),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    const durations = [3, 5, 10, 15, 20];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: durations
          .map((min) => _buildChoiceChip(
                '${min}m',
                min,
                _selectedDurationMinutes,
                (val) => setState(() => _selectedDurationMinutes = val),
              ))
          .toList(),
    );
  }

  Widget _buildChoiceChip(String label, int value, int groupValue, ValueChanged<int> onSelect) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFF8A66).withOpacity(0.2) 
              : const Color(0xFF222E4A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFF8A66) 
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF8A66) : const Color(0xFFF8F9FA),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSoundscapeSelector() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSoundCard(Soundscape.campfire, Icons.local_fire_department, 'Campfire', 'Deep crackle'),
        _buildSoundCard(Soundscape.rainfall, Icons.thunderstorm, 'Rainfall', 'Steady flow'),
        _buildSoundCard(Soundscape.campfireMusic, Icons.music_note, 'Campfire +', 'Ambient layers'),
        _buildSoundCard(Soundscape.rainfallMusic, Icons.music_note, 'Rainfall +', 'Ethereal drift'),
      ],
    );
  }

  Widget _buildSoundCard(Soundscape value, IconData icon, String label, String subtitle) {
    final isSelected = _selectedSoundscape == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSoundscape = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // UI-UX PRO MAX: Premium glassmorphism with subtle borders and shadows
          color: isSelected 
              ? const Color(0xFFFF8A66).withOpacity(0.25) 
              : const Color(0xFF222E4A).withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFF8A66) 
                : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFFF8A66).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ] : [],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFFFF8A66) : const Color(0xFFB0BEC4),
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFF8A66) : const Color(0xFFF8F9FA),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: (isSelected ? const Color(0xFFFF8A66) : const Color(0xFFB0BEC4)).withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF8A66),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Color(0xFF1A233A)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          setState(() {
            _selectedZenTime = time;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF222E4A).withAlpha(100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Zen Time',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedZenTime == null 
                      ? 'Not Set' 
                      : '${_selectedZenTime!.format(context)}',
                  style: const TextStyle(
                    color: Color(0xFFB0BEC4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Icon(Icons.notifications_active, color: Color(0xFFFF8A66)),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF222E4A).withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.alternate_email, color: Color(0xFFFF8A66), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _usernameController,
              onSubmitted: _updateUsername,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'set_username',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_isSavingUsername)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8A66)))
          else
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFFFF8A66)),
              onPressed: () => _updateUsername(_usernameController.text),
            ),
        ],
      ),
    );
  }

  Widget _buildPublicToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Public Forest Profile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Allow others to see your mindful growth',
              style: TextStyle(color: Color(0xFFB0BEC4), fontSize: 11),
            ),
          ],
        ),
        Switch(
          value: _isPublic,
          onChanged: _togglePublic,
          activeColor: const Color(0xFFFF8A66),
          activeTrackColor: const Color(0xFFFF8A66).withOpacity(0.3),
        ),
      ],
    );
  }
}

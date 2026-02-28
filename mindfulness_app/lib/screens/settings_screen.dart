import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../main.dart'; // To access GameScreen and design colors

import '../services/progress_service.dart';
import '../services/notification_service.dart';
import '../services/economy_service.dart';
import '../widgets/out_of_opals_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final ProgressService progressService;
  
  const SettingsScreen({super.key, required this.progressService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedGridSize = 4;
  Soundscape _selectedSoundscape = Soundscape.oceanWaves;
  TimeOfDay? _selectedZenTime;
  late EconomyService _economyService;

  @override
  void initState() {
    super.initState();
    _economyService = EconomyService();
    _economyService.init(); // Boot economy locally
  }

  int get _currentCost {
    final settings = GameSettings(
      gridSize: _selectedGridSize,
      soundscape: _selectedSoundscape,
    );
    return settings.calculateOpalCost(
      isPremiumAudio: _selectedSoundscape != Soundscape.none
    );
  }

  void _onBegin() async {
    final settings = GameSettings(
      gridSize: _selectedGridSize,
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
            await _economyService.addOpals(50);
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
                  const SizedBox(height: 40),

                  // Soundscape Selector
                  _buildSectionHeader('SOUNDSCAPE'),
                  const SizedBox(height: 16),
                  _buildSoundscapeSelector(),

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildChoiceChip('2x2', 2, _selectedGridSize, (val) => setState(() => _selectedGridSize = val)),
        _buildChoiceChip('3x3', 3, _selectedGridSize, (val) => setState(() => _selectedGridSize = val)),
        _buildChoiceChip('4x4', 4, _selectedGridSize, (val) => setState(() => _selectedGridSize = val)),
      ],
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSoundCard(Soundscape.none, Icons.volume_off, 'Silent'),
            _buildSoundCard(Soundscape.rainThunder, Icons.thunderstorm, 'Rain'),
            _buildSoundCard(Soundscape.oceanWaves, Icons.water, 'Ocean'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSoundCard(Soundscape.campfire, Icons.local_fire_department, 'Campfire'),
            _buildSoundCard(Soundscape.forestUnderwater, Icons.park, 'Forest'),
            const SizedBox(width: 80), // spacer for balance
          ],
        ),
      ],
    );
  }

  Widget _buildSoundCard(Soundscape value, IconData icon, String label) {
    final isSelected = _selectedSoundscape == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSoundscape = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFF8A66).withOpacity(0.2) 
              : const Color(0xFF222E4A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFF8A66) 
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF8A66) : const Color(0xFFB0BEC4),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF8A66) : const Color(0xFFB0BEC4),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
}

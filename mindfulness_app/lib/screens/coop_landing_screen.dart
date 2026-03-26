import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/multiplayer_service.dart';
import '../services/progress_service.dart';
import '../services/economy_service.dart';
import '../services/deep_link_service.dart';
import 'coop_game_screen.dart';

class CoOpLandingScreen extends StatefulWidget {
  final String roomId;
  final String? referrerId;
  final ProgressService progressService;

  const CoOpLandingScreen({
    super.key,
    required this.roomId,
    this.referrerId,
    required this.progressService,
  });

  @override
  State<CoOpLandingScreen> createState() => _CoOpLandingScreenState();
}

class _CoOpLandingScreenState extends State<CoOpLandingScreen> {
  final MultiplayerService _multiplayerService = MultiplayerService();
  bool _isLoading = false;
  bool _showTutorial = false;
  int _tutorialStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D1B4E), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _showTutorial ? _buildTutorialContent() : _buildLandingContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandingContent() {
    return Column(
      key: const ValueKey('landing'),
      children: [
        _buildProgressBar(0),
        const Spacer(),
        _buildHeroImage(),
        const SizedBox(height: 40),
        _buildInviteDetails(),
        const Spacer(),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildTutorialContent() {
    final steps = [
      ('Which one grew?', 'SIZE', 'One crystal is subtly larger. Tap it.'),
      ('Which shifted hue?', 'COLOR', 'A glow of a different color. Notice it.'),
      ('Which one faded?', 'OPACITY', 'One grows dimmer. Presence is quiet.'),
    ];

    final current = steps[_tutorialStep];

    return Column(
      key: const ValueKey('tutorial'),
      children: [
        _buildProgressBar(_tutorialStep + 1),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A66).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF8A66).withOpacity(0.3)),
          ),
          child: Text(
            current.$2,
            style: const TextStyle(color: Color(0xFFFF8A66), fontWeight: FontWeight.bold, letterSpacing: 3),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          current.$1,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          current.$3,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (_tutorialStep < 2) {
                _tutorialStep++;
              } else {
                _launchGame();
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8A66),
            foregroundColor: const Color(0xFF1A233A),
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(_tutorialStep < 2 ? 'NEXT' : 'I AM READY'),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int activeIndex) {
    return Row(
      children: List.generate(4, (i) {
        final isActive = i <= activeIndex;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFF8A66) : Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A66).withOpacity(0.2),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
      child: const Flutter3DViewer(
        src: 'assets/3D/opal.glb',
        progressBarColor: Colors.transparent,
      ),
    );
  }

  Widget _buildInviteDetails() {
    return Column(
      children: [
        const Text(
          'A Friend has Invited You',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Join their session and grow a Zen Tree together.\nNo strings attached, first time is on us.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A66).withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFF8A66).withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFFF8A66), size: 18),
              SizedBox(width: 10),
              Text(
                'GIFT: 3-MIN FREE SESSION',
                style: TextStyle(
                  color: Color(0xFFFF8A66),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _onOneTapAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8A66),
            foregroundColor: const Color(0xFF1A233A),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A233A)),
                )
              : const Text(
                  '1-TAP CONNECT',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text(
            'Maybe Later',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white30, fontWeight: FontWeight.normal),
          ),
        ),
      ],
    );
  }

  void _onOneTapAuth() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final pendingRef = await DeepLinkService().getPendingReferrer();
      
      if (user != null) {
        // Sync attribution if we have a referrer
        if (pendingRef != null || widget.referrerId != null) {
          final refId = widget.referrerId ?? pendingRef;
          await Supabase.instance.client.from('user_profiles').upsert({
            'id': user.id,
            'referred_by': refId,
          });
          debugPrint('Co-op Attribution: Linked user ${user.id} to referrer $refId');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final hasCompletedLocal = prefs.getBool('has_completed_onboarding') ?? false;

      // Also check Supabase for onboarding status to be thorough
      bool hasCompletedCloud = false;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('user_profiles')
            .select('has_completed_onboarding')
            .eq('id', user.id)
            .maybeSingle();
        hasCompletedCloud = profile?['has_completed_onboarding'] ?? false;
      }

      if (!hasCompletedLocal && !hasCompletedCloud) {
        setState(() => _showTutorial = true);
      } else {
        _launchGame();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _launchGame() async {
    setState(() => _isLoading = true);
    try {
      final success = await _multiplayerService.joinFreeRoom(widget.roomId);
      if (!mounted) return;

      if (success) {
        await _multiplayerService.markFreeCoopUsed();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CoopGameScreen(
              multiplayerService: _multiplayerService,
              roomId: widget.roomId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room reached its limit or session ended.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not enter session: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

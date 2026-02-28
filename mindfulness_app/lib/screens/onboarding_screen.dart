import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/progress_service.dart';
import '../main.dart'; // To reuse ShapeBaseAttributes/MutationType if needed, or we redefine locally if complex. Wait, MindfulnessApp relies on main.dart.
import 'dashboard_screen.dart';

// Since main.dart has some classes, we should abstract them or just redefine the basics here for simplicity.
// To avoid circular dependencies, let's just use the viewer directly for the onboarding.

class OnboardingScreen extends StatefulWidget {
  final ProgressService progressService;

  const OnboardingScreen({super.key, required this.progressService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  
  // Step 0: Welcome text
  // Step 1: Size tutorial
  // Step 2: Color tutorial
  // Step 3: Done

  late final AnimationController _ambientController;
  
  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    // Auto-advance step 0 after a short delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentStep == 0) {
        setState(() {
          _currentStep = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Try to update Supabase. If fails, it's fine, we have local prefs.
        await Supabase.instance.client
            .from('user_profiles')
            .upsert({
              'id': user.id,
              'has_completed_onboarding': true,
            });
      }
    } catch (e) {
      debugPrint('Supabase sync failed: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(progressService: widget.progressService),
      ),
    );
  }

  void _onShapeTapped(bool isAnomaly) {
    if (!isAnomaly) return; // Ignore wrong taps during onboarding
    
    setState(() {
      if (_currentStep == 1) {
        _currentStep = 2;
      } else if (_currentStep == 2) {
        _currentStep = 3;
        Future.delayed(const Duration(seconds: 2), _completeOnboarding);
      }
    });
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
      return const Center(
        child: Text(
          'Breathe in.\nWelcome to your sanctuary.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
            height: 1.8,
            color: Color(0xFFF8F9FA),
          ),
        ),
      );
    }

    if (_currentStep == 3) {
      return const Center(
        child: Text(
          'You are ready.',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            letterSpacing: 3.0,
            color: Color(0xFFFF8A66), // Soft Coral
          ),
        ),
      );
    }
    
    String instruction = _currentStep == 1 ? "Find the anomaly." : "Look closer.\nNotice the subtle shift.";
    bool isSizeMutation = _currentStep == 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          instruction,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
            height: 1.5,
            color: Color(0xFFB0BEC4), // Muted Lavender
          ),
        ),
        const SizedBox(height: 64),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOnboardingCrystal(isAnomaly: false, isSizeMutation: isSizeMutation),
            const SizedBox(width: 32),
            _buildOnboardingCrystal(isAnomaly: true, isSizeMutation: isSizeMutation),
          ],
        ),
      ],
    );
  }

  Widget _buildOnboardingCrystal({required bool isAnomaly, required bool isSizeMutation}) {
    return GestureDetector(
      onTap: () => _onShapeTapped(isAnomaly),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, child) {
            double scale = 1.0;
            double hue = 0.0;
            
            // Apply breathing
            scale *= (1.0 + _ambientController.value * 0.05);

            if (isAnomaly) {
              if (isSizeMutation) {
                scale *= 1.3;
              } else {
                hue = 60.0; // Noticeable color shift
              }
            }

            Widget viewer = const IgnorePointer(
              child: Flutter3DViewer(
                src: 'assets/3D/Meshy_AI_Crimson_Ember_Lamp_0226174821_texture.glb',
                progressBarColor: Colors.transparent,
                enableTouch: false,
              ),
            );

            if (hue > 0) {
              viewer = Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: HSVColor.fromAHSV(0.8, hue, 1.0, 1.0).toColor(),
                      blurRadius: 40,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: viewer,
              );
            }

            return Transform.scale(
              scale: scale,
              child: viewer,
            );
          },
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
              Color(0xFF0D1B2A), // Very Dark Blue
            ],
            stops: [0.1, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 1500),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: KeyedSubtree(
              key: ValueKey<int>(_currentStep),
              child: Center(child: _buildStepContent()),
            ),
          ),
        ),
      ),
    );
  }
}

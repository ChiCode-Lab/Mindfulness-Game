import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/progress_service.dart';
import 'dashboard_screen.dart';

/// One tutorial slide definition.
class _TutorialStep {
  final String instruction;
  final String mutationName;
  final String description;
  final double anomalyScale;
  final double anomalyHue;
  final double anomalyOpacity;
  final double anomalyLength;
  final double anomalyBreadth;
  final double anomalyRotation;
  final Offset anomalyOffset;
  final bool anomalyBlooming;

  const _TutorialStep({
    required this.instruction,
    required this.mutationName,
    required this.description,
    this.anomalyScale = 1.0,
    this.anomalyHue = 0.0,
    this.anomalyOpacity = 1.0,
    this.anomalyLength = 1.0,
    this.anomalyBreadth = 1.0,
    this.anomalyRotation = 0.0,
    this.anomalyOffset = Offset.zero,
    this.anomalyBlooming = false,
  });
}

const List<_TutorialStep> _tutorialSteps = [
  _TutorialStep(
    instruction: 'Which one grew?',
    mutationName: 'SIZE',
    description: 'One crystal is subtly larger.\nFeel the difference in presence.',
    anomalyScale: 1.4,
  ),
  _TutorialStep(
    instruction: 'Which shifted hue?',
    mutationName: 'COLOR',
    description: 'A glow of a different colour.\nLook at the light, not the shape.',
    anomalyHue: 120.0,
  ),
  _TutorialStep(
    instruction: 'Which one faded?',
    mutationName: 'OPACITY',
    description: 'One grows dimmer.\nPresence is not always loud.',
    anomalyOpacity: 0.3,
  ),
  _TutorialStep(
    instruction: 'Which one stretched?',
    mutationName: 'LENGTH',
    description: 'Elongated. Like a deep inhale.\nNotice the vertical shift.',
    anomalyLength: 1.5,
  ),
  _TutorialStep(
    instruction: 'Which one widened?',
    mutationName: 'BREADTH',
    description: 'Broader. Expanded.\nFeel the horizontal spread.',
    anomalyBreadth: 1.5,
  ),
  _TutorialStep(
    instruction: 'Which one tilted?',
    mutationName: 'ORIENTATION',
    description: 'Slightly rotated.\nNotice the lean.',
    anomalyRotation: 0.5,
  ),
  _TutorialStep(
    instruction: 'Which one drifted?',
    mutationName: 'POSITION',
    description: 'It moved. Subtle, but there.\nGround yourself and look again.',
    anomalyOffset: Offset(28, 0),
  ),
  _TutorialStep(
    instruction: 'Which one is blooming?',
    mutationName: 'BLOOM',
    description: 'Alive. Pulsing with energy.\nFeel it breathe.',
    anomalyBlooming: true,
  ),
];

class OnboardingScreen extends StatefulWidget {
  final ProgressService progressService;

  const OnboardingScreen({super.key, required this.progressService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  // -1 = welcome, 0-7 = tutorial steps, 8 = done
  int _stepIndex = -1;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Auto-advance past the welcome card
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _stepIndex == -1) {
        setState(() => _stepIndex = 0);
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
        await Supabase.instance.client.from('user_profiles').upsert({
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
        builder: (context) =>
            DashboardScreen(progressService: widget.progressService),
      ),
    );
  }

  void _onAnomalyTapped() {
    setState(() {
      if (_stepIndex < 7) {
        _stepIndex++;
      } else {
        // Last step tapped — show done, then navigate
        _stepIndex = 8;
        Future.delayed(const Duration(seconds: 2), _completeOnboarding);
      }
    });
  }

  Widget _buildWelcome() {
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

  Widget _buildDone() {
    return const Center(
      child: Text(
        'You are ready.',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 3.0,
          color: Color(0xFFFF8A66),
        ),
      ),
    );
  }

  Widget _buildTutorialStep(_TutorialStep step) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Attribute label badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A66).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF8A66).withValues(alpha: 0.4)),
          ),
          child: Text(
            step.mutationName,
            style: const TextStyle(
              color: Color(0xFFFF8A66),
              fontWeight: FontWeight.bold,
              letterSpacing: 3.0,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          step.instruction,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
            height: 1.5,
            color: Color(0xFFF8F9FA),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFB0BEC4),
            height: 1.6,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCrystalCell(isAnomaly: false, step: step),
            const SizedBox(width: 32),
            _buildCrystalCell(isAnomaly: true, step: step),
          ],
        ),
        const SizedBox(height: 48),
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(8, (i) {
            final isCurrent = i == _stepIndex;
            final isPast = i < _stepIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFFFF8A66)
                    : isPast
                        ? const Color(0xFFFF8A66).withValues(alpha: 0.4)
                        : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          '${_stepIndex + 1} of 8',
          style: const TextStyle(
            color: Color(0xFFB0BEC4),
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCrystalCell({required bool isAnomaly, required _TutorialStep step}) {
    return GestureDetector(
      key: isAnomaly ? const Key('anomaly_crystal') : null,
      onTap: isAnomaly ? _onAnomalyTapped : null,
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
          builder: (context, _) {
            final t = _ambientController.value;

            double scale = isAnomaly ? step.anomalyScale : 1.0;
            double hue = isAnomaly ? step.anomalyHue : 0.0;
            double opacity = isAnomaly ? step.anomalyOpacity : 1.0;
            double length = isAnomaly ? step.anomalyLength : 1.0;
            double breadth = isAnomaly ? step.anomalyBreadth : 1.0;
            double rotation = isAnomaly ? step.anomalyRotation : 0.0;
            Offset offset = isAnomaly ? step.anomalyOffset : Offset.zero;
            bool blooming = isAnomaly && step.anomalyBlooming;

            // Ambient breathing
            scale *= (1.0 + t * 0.04);
            if (blooming) scale *= (1.0 + t * 0.12);

            // NOTE: NOT const — unique widget instances needed so Flutter web
            // creates separate HtmlElementView states for normal vs anomaly cells.
            Widget viewer = Flutter3DViewer(
              key: ValueKey('onboarding_${isAnomaly ? 'anomaly' : 'normal'}'),
              src: 'assets/3D/opal.glb',
              progressBarColor: Colors.transparent,
              enableTouch: false,
              onError: (err) => debugPrint('🔴 Onboarding viewer error: $err'),
              onLoad: (addr) => debugPrint('✅ Onboarding viewer loaded: $addr'),
            );

            // Color mutation via glow
            if (hue > 0) {
              viewer = Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: HSVColor.fromAHSV(0.8, hue % 360, 1.0, 1.0).toColor(),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: viewer,
              );
            }

            viewer = Opacity(opacity: opacity.clamp(0.0, 1.0), child: viewer);

            viewer = Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(offset.dx, offset.dy, 0)
                ..rotateZ(rotation)
                ..scale(breadth * scale * 0.7, length * scale * 0.7, scale * 0.7),
              child: viewer,
            );

            return viewer;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_stepIndex == -1) {
      content = _buildWelcome();
    } else if (_stepIndex == 8) {
      content = _buildDone();
    } else {
      content = _buildTutorialStep(_tutorialSteps[_stepIndex]);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF2D1B4E),
              Color(0xFF0D1B2A),
            ],
            stops: [0.1, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: KeyedSubtree(
                key: ValueKey<int>(_stepIndex),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

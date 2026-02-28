import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'models/game_settings.dart';
import 'models/game_metrics.dart';
import 'services/soundscape_engine.dart';
import 'services/progress_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/background_task_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await BackgroundTaskService().init();
  BackgroundTaskService().registerDynamicNudge();

  await Supabase.initialize(
    url: 'https://bnpoaydhzytfpkyghwky.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJucG9heWRoenl0ZnBreWdod2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMzgwMzgsImV4cCI6MjA4NzcxNDAzOH0.5MOWBZzKaZY9x69XBi1e219KnaTefL1YZC-MNh6T0fk',
  );

  final progressService = ProgressService();
  await progressService.init();
  
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

  runApp(MindfulnessApp(
    progressService: progressService,
    hasCompletedOnboarding: hasCompletedOnboarding,
  ));
}

class MindfulnessApp extends StatelessWidget {
  final ProgressService progressService;
  final bool hasCompletedOnboarding;
  
  const MindfulnessApp({
    super.key, 
    required this.progressService,
    required this.hasCompletedOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindfulness App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: const Color(0xFFF8F9FA),
          displayColor: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: Colors.transparent, // Handled by gradient
      ),
      home: hasCompletedOnboarding 
          ? DashboardScreen(progressService: progressService)
          : OnboardingScreen(progressService: progressService),
    );
  }
}

class GameScreen extends StatefulWidget {
  final GameSettings settings;
  final ProgressService progressService;
  
  const GameScreen({
    super.key, 
    required this.settings,
    required this.progressService,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum MutationType { color, opacity, length, breadth, size, orientation, position, bloom }

class ShapeBaseAttributes {
  final double scale;
  final double rotation;
  final Offset offset;
  final double opacityMultiplier;
  final double colorShift;
  final double lengthMultiplier;
  final double breadthMultiplier;
  final bool isBlooming;
  
  // Tracking for bounds constraints
  final bool isFadingIn;
  final Offset positionDirection;
  final double scaleDirection;

  ShapeBaseAttributes({
    required this.scale,
    required this.rotation,
    required this.offset,
    required this.opacityMultiplier,
    required this.colorShift,
    this.lengthMultiplier = 1.0,
    this.breadthMultiplier = 1.0,
    this.isBlooming = false,
    this.isFadingIn = false,
    this.positionDirection = const Offset(1, -1),
    this.scaleDirection = 1.0,
  });

  ShapeBaseAttributes copyWith({
    double? scale,
    double? rotation,
    Offset? offset,
    double? opacityMultiplier,
    double? colorShift,
    double? lengthMultiplier,
    double? breadthMultiplier,
    bool? isBlooming,
    bool? isFadingIn,
    Offset? positionDirection,
    double? scaleDirection,
  }) {
    return ShapeBaseAttributes(
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      offset: offset ?? this.offset,
      opacityMultiplier: opacityMultiplier ?? this.opacityMultiplier,
      colorShift: colorShift ?? this.colorShift,
      lengthMultiplier: lengthMultiplier ?? this.lengthMultiplier,
      breadthMultiplier: breadthMultiplier ?? this.breadthMultiplier,
      isBlooming: isBlooming ?? this.isBlooming,
      isFadingIn: isFadingIn ?? this.isFadingIn,
      positionDirection: positionDirection ?? this.positionDirection,
      scaleDirection: scaleDirection ?? this.scaleDirection,
    );
  }

  factory ShapeBaseAttributes.random(Random random) {
    return ShapeBaseAttributes(
      scale: 0.8 + random.nextDouble() * 0.2, // 0.8 to 1.0 size variance
      rotation: (random.nextDouble() - 0.5) * 0.2, // slight tilt
      offset: Offset((random.nextDouble() - 0.5) * 6, (random.nextDouble() - 0.5) * 6),
      opacityMultiplier: 0.7 + random.nextDouble() * 0.3,
      colorShift: (random.nextDouble() - 0.5) * 40.0, // +/- 20 degree hue shift
      lengthMultiplier: 0.8 + random.nextDouble() * 0.4, // 0.8 to 1.2
      breadthMultiplier: 0.8 + random.nextDouble() * 0.4, // 0.8 to 1.2
      // isBlooming is false initially to allow it to be a distinct mutation
      isFadingIn: random.nextBool(),
      positionDirection: Offset((random.nextBool() ? 1.0 : -1.0), (random.nextBool() ? 1.0 : -1.0)),
      scaleDirection: random.nextBool() ? 1.0 : -1.0,
    );
  }

  ShapeBaseAttributes applyMutation(MutationType mutation) {
    switch (mutation) {
      case MutationType.position:
        double newDx = offset.dx + (positionDirection.dx * 10);
        double newDy = offset.dy + (positionDirection.dy * 10);
        double newDirX = positionDirection.dx;
        double newDirY = positionDirection.dy;
        
        // Reverse vector if bounds hit
        if (newDx > 40.0) {
          newDx = 40.0;
          newDirX = -1.0;
        } else if (newDx < -40.0) {
          newDx = -40.0;
          newDirX = 1.0;
        }
        
        if (newDy > 40.0) {
          newDy = 40.0;
          newDirY = -1.0;
        } else if (newDy < -40.0) {
          newDy = -40.0;
          newDirY = 1.0;
        }
        
        return copyWith(offset: Offset(newDx, newDy), positionDirection: Offset(newDirX, newDirY));
        
      case MutationType.orientation:
        return copyWith(rotation: rotation + 0.2);
        
      case MutationType.size:
        double newScale = scale + (scaleDirection * 0.15);
        double newScaDir = scaleDirection;
        
        if (newScale > 1.2) {
          newScale = 1.2;
          newScaDir = -1.0;
        } else if (newScale < 0.5) {
          newScale = 0.5;
          newScaDir = 1.0;
        }
        return copyWith(scale: newScale, scaleDirection: newScaDir);
        
      case MutationType.length:
        double newLen = lengthMultiplier + (scaleDirection * 0.2);
        double newLenDir = scaleDirection;
        if (newLen > 1.2) {
          newLen = 1.2;
          newLenDir = -1.0;
        } else if (newLen < 0.5) {
          newLen = 0.5;
          newLenDir = 1.0;
        }
        return copyWith(lengthMultiplier: newLen, scaleDirection: newLenDir);
        
      case MutationType.breadth:
        double newBreadth = breadthMultiplier + (scaleDirection * 0.2);
        double newBreadthDir = scaleDirection;
        if (newBreadth > 1.2) {
          newBreadth = 1.2;
          newBreadthDir = -1.0;
        } else if (newBreadth < 0.5) {
          newBreadth = 0.5;
          newBreadthDir = 1.0;
        }
        return copyWith(breadthMultiplier: newBreadth, scaleDirection: newBreadthDir);
        
      case MutationType.opacity:
        double newOp = isFadingIn ? opacityMultiplier + 0.3 : opacityMultiplier - 0.3;
        bool fadingIn = isFadingIn;
        if (newOp <= 0.3) {
          newOp = 0.3;
          fadingIn = true;
        } else if (newOp >= 1.0) {
          newOp = 1.0;
          fadingIn = false;
        }
        return copyWith(opacityMultiplier: newOp, isFadingIn: fadingIn);
        
      case MutationType.color:
        return copyWith(colorShift: colorShift + 120.0);
        
      case MutationType.bloom:
        return copyWith(isBlooming: true);
    }
  }
}

class ActiveTarget {
  final MutationType mutation;
  final DateTime spawnTime;

  ActiveTarget({required this.mutation, required this.spawnTime});
}

class _GameScreenState extends State<GameScreen> {
  late GameSettings settings;
  late GameMetrics metrics;
  late SoundscapeEngine audioEngine;
  late DateTime _sessionStartTime;

  final Random _random = Random();
  
  Map<int, ActiveTarget> activeTargets = {};
  Map<int, Timer> targetTimers = {};
  
  late List<ShapeBaseAttributes> baseAttributes;
  late List<String> cellShapes;
  
  Timer? _masterSpawnTimer;
  Map<int, bool> successPulses = {}; // Track which cells are currently pulsing

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    settings = widget.settings;
    metrics = GameMetrics();
    audioEngine = SoundscapeEngine();
    
    _initializeGridData();
    
    _scheduleNextSpawn();
    audioEngine.play(settings.soundscape);
  }

  void _scheduleNextSpawn() {
    // Average 7 seconds between spawns. 3 to 11 seconds roughly.
    final nextDelay = 3 + _random.nextInt(9);
    _masterSpawnTimer = Timer(Duration(seconds: nextDelay), () {
      if (!mounted) return;
      _spawnTarget();
      _scheduleNextSpawn();
    });
  }

  void _initializeGridData() {
    final List<String> shapeTypes = ['pebble', 'leaf', 'tree'];
    baseAttributes = List.generate(settings.totalCells, (_) => ShapeBaseAttributes.random(_random));
    cellShapes = List.generate(settings.totalCells, (_) => shapeTypes[_random.nextInt(shapeTypes.length)]);
  }

  ShapeBaseAttributes _applyMutation(ShapeBaseAttributes base, MutationType mutation) {
    return base.applyMutation(mutation);
  }

  void _spawnTarget() {
    // Find available grid indices
    final availableIndices = List.generate(settings.totalCells, (i) => i)
        ..removeWhere((i) => activeTargets.containsKey(i));
        
    if (availableIndices.isEmpty) return;

    final newTargetIndex = availableIndices[_random.nextInt(availableIndices.length)];
    final mutation = MutationType.values[_random.nextInt(MutationType.values.length)];

    setState(() {
      activeTargets[newTargetIndex] = ActiveTarget(
        mutation: mutation,
        spawnTime: DateTime.now(),
      );
    });

    targetTimers[newTargetIndex] = Timer(const Duration(seconds: 5), () => _onTimerExpired(newTargetIndex));
  }

  void _onTimerExpired(int index) {
    if (!mounted) return;
    targetTimers[index]?.cancel();
    targetTimers.remove(index);
    
    final target = activeTargets[index];
    if (target != null) {
      baseAttributes[index] = _applyMutation(baseAttributes[index], target.mutation);
    }
    
    setState(() {
      activeTargets.remove(index);
      metrics.recordTap(
        isCorrect: false,
        reactionTime: const Duration(seconds: 5),
      );
    });
    // Silent fail: No harsh notifications. We just record it and wait for next spawn.
  }

  void _triggerSuccessPulse(int index) {
    setState(() {
      successPulses[index] = true;
    });
    // Remove pulse after animation duration
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          successPulses[index] = false;
        });
      }
    });
  }

  void _onShapeTapped(int index) {
    if (activeTargets.containsKey(index)) {
      // Correct tap!
      final target = activeTargets[index]!;
      targetTimers[index]?.cancel();
      targetTimers.remove(index);
      
      final reactionTime = DateTime.now().difference(target.spawnTime);

      audioEngine.playInteractionSound(); // Soft tap sound
      _triggerSuccessPulse(index);

      // Persist the state
      baseAttributes[index] = _applyMutation(baseAttributes[index], target.mutation);

      widget.progressService.incrementLeaf(); // Award a leaf to the Zen Tree

      setState(() {
        activeTargets.remove(index);
        metrics.recordTap(isCorrect: true, reactionTime: reactionTime);
      });
    } else {
      // Incorrect tap
      setState(() {
        metrics.recordTap(isCorrect: false, reactionTime: Duration.zero);
      });
      // Soft silence. No harsh UI alerts.
    }
  }

  @override
  void dispose() {
    final durationMinutes = DateTime.now().difference(_sessionStartTime).inMinutes;
    final int recordedMinutes = durationMinutes > 0 ? durationMinutes : 1; // Minimum 1 minute recorded for the session
    widget.progressService.completeSession(recordedMinutes);

    _masterSpawnTimer?.cancel();
    targetTimers.values.forEach((timer) => timer.cancel());
    audioEngine.stop();
    audioEngine.dispose();
    super.dispose();
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildGrid(),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.self_improvement,
                            color: Color(0xFFFF8A66),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              'STREAK: ${metrics.currentStreak}',
                              key: ValueKey<int>(metrics.currentStreak),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'PRESENCE LEVEL: ${(metrics.accuracy * 100).toStringAsFixed(1)}%\nDEEP FOCUS: ${(metrics.averageReactionTime.inMilliseconds / 1000).toStringAsFixed(2)}s\nZEN TREE LEAVES: ${metrics.treeGrowthLevel}',
                    key: ValueKey<String>('${metrics.accuracy}_${metrics.treeGrowthLevel}'),
                    style: const TextStyle(
                      color: Color(0xFFB0BEC4),
                      fontSize: 10,
                      letterSpacing: 1.1,
                      height: 1.5,
                    ),
                  ),
                )
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'SOLO MODE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                    color: Color(0xFFB0BEC4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: settings.gridSize,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: settings.totalCells,
        itemBuilder: (context, index) {
          final targetInfo = activeTargets[index];
          final mutation = targetInfo?.mutation;
          final spawnTime = targetInfo?.spawnTime;
          final isPulsing = successPulses[index] ?? false;
          
          return GestureDetector(
            onTap: () => _onShapeTapped(index),
            behavior: HitTestBehavior.opaque,
            child: ShapeCell(
              shapeType: cellShapes[index],
              baseAttributes: baseAttributes[index],
              mutationSpawnTime: spawnTime,
              mutation: mutation,
              isSuccessPulse: isPulsing,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0, left: 24, right: 24),
      child: Column(
        children: [
          const Text(
            'Find the glowing shape. Take a deep breath.',
            style: TextStyle(
              color: Color(0xFFB0BEC4),
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Soft UI reset for edge cases
              _initializeGridData();
              targetTimers.values.forEach((timer) => timer.cancel());
              targetTimers.clear();
              activeTargets.clear();
              _spawnTarget();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A66), // Soft Coral
              foregroundColor: const Color(0xFF1A233A),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'REFRESH GRID',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class ShapeCell extends StatelessWidget {
  final String shapeType;
  final ShapeBaseAttributes baseAttributes;
  final DateTime? mutationSpawnTime;
  final MutationType? mutation;
  final bool isSuccessPulse;

  const ShapeCell({
    super.key,
    required this.shapeType,
    required this.baseAttributes,
    this.mutationSpawnTime,
    this.mutation,
    this.isSuccessPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ModelShapeRenderer(
                baseAttributes: baseAttributes,
                mutationSpawnTime: mutationSpawnTime,
                mutation: mutation,
                isSuccessPulse: isSuccessPulse,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModelShapeRenderer extends StatefulWidget {
  final ShapeBaseAttributes baseAttributes;
  final DateTime? mutationSpawnTime;
  final MutationType? mutation;
  final bool isSuccessPulse;

  const ModelShapeRenderer({
    super.key,
    required this.baseAttributes,
    this.mutationSpawnTime,
    this.mutation,
    this.isSuccessPulse = false,
  });

  @override
  State<ModelShapeRenderer> createState() => _ModelShapeRendererState();
}

class _ModelShapeRendererState extends State<ModelShapeRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;
  ShapeBaseAttributes? _previousAttributes;

  @override
  void initState() {
    super.initState();
    _previousAttributes = widget.baseAttributes;
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModelShapeRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baseAttributes != widget.baseAttributes) {
      _previousAttributes = oldWidget.baseAttributes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final time = _ambientController.value;
        double progress = 0.0;
        if (widget.mutationSpawnTime != null) {
          progress = (DateTime.now().difference(widget.mutationSpawnTime!).inMilliseconds / 5000.0).clamp(0.0, 1.0);
          progress = Curves.easeInOutCubic.transform(progress);
        }

        double finalScale = widget.baseAttributes.scale * 0.7; // Base scale down
        double finalLength = widget.baseAttributes.lengthMultiplier;
        double finalBreadth = widget.baseAttributes.breadthMultiplier;
        double finalRotation = widget.baseAttributes.rotation;
        Offset finalOffset = widget.baseAttributes.offset;
        double finalOpacity = widget.baseAttributes.opacityMultiplier;
        double finalHue = widget.baseAttributes.colorShift;
        bool isBlooming = widget.baseAttributes.isBlooming;

        if (widget.mutationSpawnTime != null && _previousAttributes != null && progress < 1.0) {
           finalScale = lerpDouble(_previousAttributes!.scale * 0.7, widget.baseAttributes.scale * 0.7, progress) ?? finalScale;
           finalLength = lerpDouble(_previousAttributes!.lengthMultiplier, widget.baseAttributes.lengthMultiplier, progress) ?? finalLength;
           finalBreadth = lerpDouble(_previousAttributes!.breadthMultiplier, widget.baseAttributes.breadthMultiplier, progress) ?? finalBreadth;
           finalRotation = lerpDouble(_previousAttributes!.rotation, widget.baseAttributes.rotation, progress) ?? finalRotation;
           finalOffset = Offset.lerp(_previousAttributes!.offset, widget.baseAttributes.offset, progress) ?? finalOffset;
           finalOpacity = lerpDouble(_previousAttributes!.opacityMultiplier, widget.baseAttributes.opacityMultiplier, progress) ?? finalOpacity;
           finalHue = lerpDouble(_previousAttributes!.colorShift, widget.baseAttributes.colorShift, progress) ?? finalHue;
        }

        if (isBlooming) {
          finalScale *= (1.0 + time * 0.1); // Constant ambient breathing
        }

        Widget viewer = const IgnorePointer(
          child: Flutter3DViewer(
            src: 'assets/3D/Meshy_AI_Crimson_Ember_Lamp_0226174821_texture.glb',
            progressBarColor: Colors.transparent,
            enableTouch: false, // Ensures tap events bubble up to the GestureDetector
          ),
        );

        // Apply Color Mutation via Ambient Behind Glow
        if (finalHue.abs() > 5.0) {
          viewer = Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: HSVColor.fromAHSV(0.8, (finalHue % 360).abs(), 1.0, 1.0).toColor(),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
            child: viewer,
          );
        }

        // Apply Opacity Mutation
        viewer = Opacity(
          opacity: finalOpacity.clamp(0.0, 1.0),
          child: viewer,
        );

        // Apply Scale, Length, Breadth, Orientation, Position Mutations
        viewer = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(finalOffset.dx, finalOffset.dy)
            ..rotateZ(finalRotation)
            ..scale(finalBreadth * finalScale, finalLength * finalScale, finalScale),
          child: viewer,
        );

        // Apply Success Pulse Glow
        if (widget.isSuccessPulse) {
          viewer = Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: viewer,
          );
        }

        return viewer;
      },
    );
  }
}

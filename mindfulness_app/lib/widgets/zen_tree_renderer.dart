import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import '../models/zen_tree.dart';

class ZenTreeRenderer extends StatefulWidget {
  final ZenTreeData treeData;

  const ZenTreeRenderer({
    super.key,
    required this.treeData,
  });

  @override
  State<ZenTreeRenderer> createState() => _ZenTreeRendererState();
}

class _ZenTreeRendererState extends State<ZenTreeRenderer>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _infusionController;
  late Animation<double> _infusionAnimation;

  int _previousLeafCount = 0;

  @override
  void initState() {
    super.initState();

    _previousLeafCount = widget.treeData.leafCount;

    // Continuous subtle breathing animation (Y-axis stretch).
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // One-shot "Leaf Infusion" pulse: briefly overshoots scale then settles.
    _infusionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _infusionAnimation = TweenSequence<double>([
      // Quick overshoot to 1.15x
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      // Settle back to 1.0x
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_infusionController);
  }

  @override
  void didUpdateWidget(covariant ZenTreeRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect leaf count increase → trigger Leaf Infusion pulse.
    if (widget.treeData.leafCount > _previousLeafCount) {
      _infusionController.forward(from: 0.0);
    }
    _previousLeafCount = widget.treeData.leafCount;
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _infusionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseScale = widget.treeData.scaleFactor;

    return AnimatedScale(
      scale: baseScale,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathingController, _infusionController]),
        builder: (context, child) {
          // Subtle vertical breathing effect.
          final breathingScale = 1.0 + (_breathingController.value * 0.05);

          // Leaf Infusion pulse multiplier (1.0 when idle).
          final infusionScale = _infusionController.isAnimating
              ? _infusionAnimation.value
              : 1.0;

          return Transform.scale(
            scale: infusionScale,
            child: Transform.scale(
              scaleY: breathingScale,
              child: child,
            ),
          );
        },
        child: const Flutter3DViewer(
          src: 'assets/3D/tree_gn.glb',
          progressBarColor: Colors.transparent,
          enableTouch: true,
        ),
      ),
    );
  }
}

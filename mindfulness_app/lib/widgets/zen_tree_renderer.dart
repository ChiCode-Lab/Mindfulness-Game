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

class _ZenTreeRendererState extends State<ZenTreeRenderer> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        // Subtle vertical breathing effect
        final breathingScale = 1.0 + (_breathingController.value * 0.05);
        final baseScale = widget.treeData.scaleFactor;
        
        return Transform.scale(
          scale: baseScale,
          child: Transform.scale(
            scaleY: breathingScale, // Only stretch Y axis for a "breathing" growth effect
            child: const Flutter3DViewer(
              src: 'assets/3D/maple_tree.glb',
              progressBarColor: Colors.transparent,
              enableTouch: true, // Allow user to spin the tree in dashboard
            ),
          ),
        );
      },
    );
  }
}

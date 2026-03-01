import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/zen_tree.dart';
import '../services/progress_service.dart';
import '../services/economy_service.dart';

/// Bento-grid screen showing past (legacy) Zen Trees.
///
/// Free users see at most the first 5 trees; trees at index 5–11 are hidden
/// behind a blurred premium lock. Premium users see everything.
class ForestScreen extends StatefulWidget {
  final ProgressService progressService;

  const ForestScreen({super.key, required this.progressService});

  @override
  State<ForestScreen> createState() => _ForestScreenState();
}

class _ForestScreenState extends State<ForestScreen> {
  late EconomyService _economyService;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _economyService = EconomyService();
    _economyService.init().then((_) {
      if (mounted) {
        setState(() {
          _isPremium = _economyService.state.isPremium;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final legacyTrees = widget.progressService.getLegacyForest();
    // Most recent first.
    final trees = legacyTrees.reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A233A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222E4A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFFF8F9FA),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Legacy Forest',
                      style: TextStyle(
                        color: Color(0xFFF8F9FA),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Tree count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222E4A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFF8A65).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.park_rounded,
                          color: Color(0xFFFF8A65),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${trees.length}',
                          style: const TextStyle(
                            color: Color(0xFFFF8A65),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Grid ────────────────────────────────────────────
            Expanded(
              child: trees.isEmpty
                  ? _buildEmptyState()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: trees.length,
                        itemBuilder: (context, index) {
                          final tree = trees[index];
                          // Free users: lock indices 5–11 (days 6–12).
                          final isLocked = !_isPremium && index >= 5;
                          return _ForestCard(
                            tree: tree,
                            dayIndex: index,
                            isLocked: isLocked,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forest_rounded,
            color: Colors.white.withOpacity(0.15),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Your forest is empty',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a meditation session\nto grow your first tree.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Glassmorphic tree card
// ─────────────────────────────────────────────────────────────────────────────

class _ForestCard extends StatelessWidget {
  final ZenTreeData tree;
  final int dayIndex;
  final bool isLocked;

  const _ForestCard({
    required this.tree,
    required this.dayIndex,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isLocked ? _buildLockedContent() : _buildUnlockedContent(),
        ),
      ),
    );
  }

  Widget _buildUnlockedContent() {
    final dateLabel = _formatDate(tree.date);
    // Visual "health" indicator based on leaf count.
    final healthColor = _healthColor(tree.leafCount);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day label
          Text(
            'Day ${dayIndex + 1}',
            style: const TextStyle(
              color: Color(0xFFB0BEC5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 10,
            ),
          ),
          const Spacer(),
          // Tree icon placeholder (visual representation)
          Center(
            child: Icon(
              Icons.park_rounded,
              color: healthColor.withOpacity(0.85),
              size: 48,
            ),
          ),
          const Spacer(),
          // Leaf count
          Row(
            children: [
              Icon(
                Icons.eco_rounded,
                color: healthColor,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${tree.leafCount} leaves',
                style: const TextStyle(
                  color: Color(0xFFF8F9FA),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Scale bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: tree.scaleFactor / 1.5, // 0–1.5 mapped to 0–1
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedContent() {
    return Stack(
      children: [
        // Blurred placeholder
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: const Color(0xFF222E4A).withOpacity(0.6),
              ),
            ),
          ),
        ),
        // Lock overlay
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                color: Colors.white.withOpacity(0.25),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Premium',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Returns a color reflecting how many leaves the tree has.
  Color _healthColor(int leafCount) {
    if (leafCount >= 30) return const Color(0xFF66BB6A); // Lush green
    if (leafCount >= 15) return const Color(0xFFFFA726); // Warm amber
    if (leafCount >= 5) return const Color(0xFFFF8A65);  // Soft coral
    return const Color(0xFF78909C);                       // Muted steel
  }
}

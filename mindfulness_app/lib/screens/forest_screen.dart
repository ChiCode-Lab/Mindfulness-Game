import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/zen_tree.dart';
import '../services/progress_service.dart';
import '../services/economy_service.dart';
import 'paywall_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
  String? _username;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _economyService = EconomyService();
    _economyService.init().then((_) {
      if (mounted) {
        setState(() {
          _isPremium = _economyService.state.isPremium;
        });
        _loadUsername();
      }
    });
  }

  Future<void> _loadUsername() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final res = await Supabase.instance.client
          .from('user_profiles')
          .select('username, is_public')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() {
          _username = res['username'] ?? 'user_${user.id.toString().substring(0, 8)}';
          _isPublic = res['is_public'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading username for forest share: $e');
    }
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
                  const SizedBox(width: 8),
                  // Share Button
                  _buildShareButton(context),
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
                            economyService: _economyService,
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

  Widget _buildShareButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showShareModal(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: const Icon(Icons.share_rounded, color: Color(0xFF4CAF50), size: 18),
      ),
    );
  }

  void _showShareModal(BuildContext context) {
    final username = _username ?? 'zen_seeker';
    final shareUrl = 'https://mindaware.app/forest/$username';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Color(0xFF1A233A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SHARE YOUR FOREST',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Make Forest Public', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('mindaware.app/forest/$username', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  value: _isPublic,
                  onChanged: (val) async {
                    setState(() => _isPublic = val);
                    setModalState(() => _isPublic = val);
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      await Supabase.instance.client
                          .from('user_profiles')
                          .update({'is_public': val})
                          .eq('id', user.id);
                    }
                  },
                  activeColor: const Color(0xFFFF8A66),
                ),
                const SizedBox(height: 16),
                if (_isPublic) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: shareUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Others can visit your forest at:',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shareUrl,
                    style: const TextStyle(color: Color(0xFFFF8A66), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Share.share('Check out my mindfulness forest on MindAware! 🌿 $shareUrl');
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('SEND TO FRIENDS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A66),
                      foregroundColor: const Color(0xFF1A233A),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 48),
                  const Icon(Icons.lock_rounded, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Your forest is currently private.\nToggle the switch above to share it with the world.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 48),
                ],
              ],
            ),
          );
        }
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
  final EconomyService economyService;

  const _ForestCard({
    required this.tree,
    required this.dayIndex,
    required this.isLocked,
    required this.economyService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaywallScreen(
                    economyService: economyService,
                    isMandatory: false,
                  ),
                ),
              )
          : () => _showTreeDetails(context),
      child: ClipRRect(
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
      ),
    );
  }

  void _showTreeDetails(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tree Details',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return _TreeDetailOverlay(tree: tree, dayIndex: dayIndex);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
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
          // Tree icon visual representation scaled by leaf count (up to 2000)
          Center(
            child: Transform.scale(
              scale: tree.scaleFactor,
              child: Icon(
                Icons.park_rounded,
                color: healthColor.withOpacity(0.85),
                size: 48,
              ),
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
                size: 28,
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
              const SizedBox(height: 6),
              // Tap hint — subtle but discoverable
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A66).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF8A66).withOpacity(0.25),
                  ),
                ),
                child: const Text(
                  'Unlock ✨',
                  style: TextStyle(
                    color: Color(0xFFFF8A66),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tree Detail Overlay (Animated & Glassmorphic)
// ─────────────────────────────────────────────────────────────────────────────

class _TreeDetailOverlay extends StatelessWidget {
  final ZenTreeData tree;
  final int dayIndex;

  const _TreeDetailOverlay({required this.tree, required this.dayIndex});

  @override
  Widget build(BuildContext context) {
    final healthColor = _healthColor(tree.leafCount);
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withAlpha(40),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAY ${dayIndex + 1}',
                              style: const TextStyle(
                                color: Color(0xFFB0BEC5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatFullDate(tree.date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // Stats Grid
                    _buildMetricRow(
                      'Daily Progress',
                      '${tree.leafCount * 2} min', 
                      'Goal: 30 min',
                      Icons.timer_outlined,
                      const Color(0xFFB0BEC5),
                    ),
                    const SizedBox(height: 24),
                    _buildMetricRow(
                      'Focus Score',
                      '${tree.focusScore}%',
                      'Presence Level',
                      Icons.psychology_outlined,
                      const Color(0xFF64B5F6),
                    ),
                    const SizedBox(height: 24),
                    _buildMetricRow(
                      'Average Deep Focus',
                      '${(tree.scaleFactor * 85).toInt()}ms',
                      'Stability Metric',
                      Icons.bolt_rounded,
                      const Color(0xFFFFD54F),
                    ),
                    const SizedBox(height: 32),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: healthColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: healthColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, color: healthColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(tree.leafCount),
                            style: TextStyle(
                              color: healthColor,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String title, String value, String sub, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sub,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getStatusText(int leafCount) {
    if (leafCount >= 30) return 'Zen Master';
    if (leafCount >= 15) return 'Focused';
    if (leafCount >= 5) return 'Mindful';
    return 'Learning';
  }

  Color _healthColor(int leafCount) {
    if (leafCount >= 30) return const Color(0xFF66BB6A);
    if (leafCount >= 15) return const Color(0xFFFFA726);
    if (leafCount >= 5) return const Color(0xFFFF8A65);
    return const Color(0xFF78909C);
  }
}

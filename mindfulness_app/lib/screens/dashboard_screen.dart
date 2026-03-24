import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../services/multiplayer_service.dart';
import '../services/economy_service.dart';
import 'settings_screen.dart'; // To access SettingsScreen
import 'multiplayer_lobby_screen.dart'; // To access Coop route
import 'forest_screen.dart'; // To access Legacy Forest
import 'paywall_screen.dart';
import '../widgets/trial_nudge_banner.dart';

class DashboardScreen extends StatefulWidget {
  final ProgressService progressService;

  const DashboardScreen({super.key, required this.progressService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late MultiplayerService _multiplayerService;
  late EconomyService _economyService;

  @override
  void initState() {
    super.initState();
    _multiplayerService = MultiplayerService();
    _economyService = EconomyService();
    _economyService.init().then((_) {
      if (mounted) {
        setState(() {});
        // Check if trial has expired and user is not a paid subscriber.
        // If so, push the mandatory PaywallScreen on first Dashboard load.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _checkForPaywallTrigger();
        });
      }
    });
  }

  void _checkForPaywallTrigger() {
    final state = _economyService.state;
    // Mandatory paywall if trial is over and no paid sub found
    if (!state.isPremium &&
        state.premiumTrialEnd != null &&
        DateTime.now().isAfter(state.premiumTrialEnd!)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaywallScreen(
            economyService: _economyService,
            isMandatory: true,
          ),
        ),
      );
    }
  }
  
  void _navigateToSoloMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(progressService: widget.progressService),
      ),
    ).then((_) {
      // Refresh UI when coming back to update the tree growth visually
      _economyService.init().then((_) {
          if (mounted) setState(() {});
      });
    });
  }

  void _navigateToCoopMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerLobbyScreen(multiplayerService: _multiplayerService),
      ),
    ).then((_) {
      _economyService.init().then((_) {
          if (mounted) setState(() {});
      });
    });
  }

  void _navigateToLegacyForest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForestScreen(progressService: widget.progressService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A233A), // Deep Twilight Blue matching stats.html
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Journey',
                      style: TextStyle(
                        color: Color(0xFFF8F9FA), // Off-white
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222E4A).withAlpha(200),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.diamond, color: Color(0xFFFF8A65), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _economyService.state.isPremium ? '∞' : '${_economyService.state.opals}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              TrialNudgeBanner(economyService: _economyService),
              const SizedBox(height: 16),
              
              // Graph Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MINDFULNESS MINUTES',
                      style: TextStyle(
                        color: Color(0xFFB0BEC5), // Muted Lavender
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.progressService.totalMindfulMinutes}',
                          style: const TextStyle(
                            color: Color(0xFFF8F9FA),
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, color: Color(0xFFFF8A65), size: 16),
                              SizedBox(width: 4),
                              Text(
                                '+12%',
                                style: TextStyle(
                                  color: Color(0xFFFF8A65), // Soft Coral
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Last 7 days average',
                      style: TextStyle(
                        color: Color(0xFF778DA9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // The actual graph
              SizedBox(
                height: 120,
                width: double.infinity,
                child: CustomPaint(
                  painter: _MindfulnessChartPainter(),
                ),
              ),
              
              // Days label for graph
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                      .map((day) => Text(
                            day,
                            style: const TextStyle(
                              color: Color(0xFFB0BEC5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ))
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),
              
              // STATS PILLS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildStatPill('Current Streak', '${widget.progressService.currentStreak} Days', Icons.local_fire_department, const Color(0xFFFF8A65)),
                    const SizedBox(height: 16),
                    _buildStatPill('Longest Session', '${widget.progressService.longestStreak * 5} min', Icons.timer, const Color(0xFFB0BEC5)), 
                    const SizedBox(height: 16),
                    _buildStatPill('Total Mindful Time', '${widget.progressService.totalMindfulMinutes} min', Icons.all_inclusive, const Color(0xFF4CAF50)),
                  ],
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _navigateToSoloMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65), // Soft Coral
                        foregroundColor: const Color(0xFF1A233A),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        shadowColor: const Color(0xFFFF8A65).withOpacity(0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.self_improvement),
                          SizedBox(width: 8),
                          Text(
                            'START SOLO MEDITATION',
                            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _navigateToCoopMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF222E4A), // Soft Midnight
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: Colors.white.withAlpha(20)),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group),
                          SizedBox(width: 8),
                          Text(
                            'COOPERATIVE ZEN',
                            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _navigateToLegacyForest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: Colors.white.withAlpha(40)),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.park_rounded, color: Color(0xFF66BB6A)),
                          SizedBox(width: 8),
                          Text(
                            'MY ZEN FOREST',
                            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF222E4A), // Soft Midnight
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFB0BEC5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MindfulnessChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // A simplified smooth bezier curve representing exactly the shape from stats.html
    final path = Path();
    
    // Starting point
    path.moveTo(0, size.height * 0.7);
    
    // Control points scaled roughly to the canvas width and height
    path.cubicTo(
      size.width * 0.1, size.height * 0.7, 
      size.width * 0.15, size.height * 0.2, 
      size.width * 0.3, size.height * 0.2,
    );
    path.cubicTo(
      size.width * 0.45, size.height * 0.2, 
      size.width * 0.45, size.height * 0.8, 
      size.width * 0.6, size.height * 0.8,
    );
    path.cubicTo(
      size.width * 0.75, size.height * 0.8, 
      size.width * 0.8, size.height * 0.1, 
      size.width, size.height * 0.1,
    );

    // Fill paint
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF8A65).withOpacity(0.3),
          const Color(0xFFFF8A65).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);

    // Line paint
    final linePaint = Paint()
      ..color = const Color(0xFFFF8A65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2); // Soft glow

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

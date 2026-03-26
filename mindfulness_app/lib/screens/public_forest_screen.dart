import 'package:flutter/material.dart';
import '../models/zen_tree.dart';
import '../services/progress_service.dart';

class PublicForestScreen extends StatefulWidget {
  final String username;
  final ProgressService progressService;

  const PublicForestScreen({
    super.key,
    required this.username,
    required this.progressService,
  });

  @override
  State<PublicForestScreen> createState() => _PublicForestScreenState();
}

class _PublicForestScreenState extends State<PublicForestScreen> {
  late Future<List<ZenTreeData>> _forestFuture;

  @override
  void initState() {
    super.initState();
    _forestFuture = widget.progressService.fetchPublicForest(widget.username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A233A),
      body: Stack(
        children: [
          // Background Forest (Abstract gradient for now)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0xFF2D1B4E), Color(0xFF1A233A)],
                stops: [0.1, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: FutureBuilder<List<ZenTreeData>>(
              future: _forestFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A66)));
                }

                final trees = snapshot.data ?? [];
                
                return Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildHeader(trees.length),
                    const SizedBox(height: 24),
                    Expanded(
                      child: trees.isEmpty 
                        ? _buildEmptyState() 
                        : _buildForestGrid(trees),
                    ),
                    _buildCTA(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFFF8A66).withOpacity(0.2),
            child: Text(
              widget.username[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFFFF8A66), fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "${widget.username.toUpperCase()}'S FOREST",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count Trees Grown • Mindful Journey',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildForestGrid(List<ZenTreeData> trees) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: trees.length,
      itemBuilder: (context, index) {
        final tree = trees[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.park_rounded,
                color: _healthColor(tree.leafCount),
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                'Day ${trees.length - index}',
                style: const TextStyle(color: Colors.white30, fontSize: 8),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Empty Path... for now.',
        style: TextStyle(color: Colors.white.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildCTA() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, const Color(0xFF1A233A)],
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          // Deep link to app or landing
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A66),
          foregroundColor: const Color(0xFF1A233A),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text('PLANT YOUR FIRST TREE →', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }

  Color _healthColor(int leafCount) {
    if (leafCount >= 30) return const Color(0xFF66BB6A);
    if (leafCount >= 15) return const Color(0xFFFFA726);
    return const Color(0xFFFF8A65);
  }
}

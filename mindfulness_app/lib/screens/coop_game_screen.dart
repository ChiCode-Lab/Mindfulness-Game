import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../services/multiplayer_service.dart';
import '../models/game_metrics.dart';
import '../services/viral_share_service.dart';
import '../../main.dart'; 

class CoopGameScreen extends StatefulWidget {
  final MultiplayerService multiplayerService;
  final String roomId;

  const CoopGameScreen({
    super.key,
    required this.multiplayerService,
    required this.roomId,
  });

  @override
  State<CoopGameScreen> createState() => _CoopGameScreenState();
}

class _CoopGameScreenState extends State<CoopGameScreen> {
  final Random _random = Random();
  late List<String> _cellShapes;
  late List<ShapeBaseAttributes> _baseAttributes;
  late Map<int, bool> _successPulses;
  bool _showingEndDialog = false;

  
  RoomState? _currentState;
  bool _isInit = false;
  int _totalCells = 9; // default assumes 3x3

  @override
  void initState() {
    super.initState();
    _listenToRoomState();
  }

  void _listenToRoomState() {
    widget.multiplayerService.streamSessionState(widget.roomId).listen((data) {
      if (data.isNotEmpty) {
        final state = RoomState.fromJson(data.first);
        
        // Setup initial grid state if not done
        if (!_isInit) {
          _totalCells = state.gridSize * state.gridSize;
          _cellShapes = List.generate(_totalCells, (_) => 'round_rect');
          _baseAttributes = List.generate(_totalCells, (_) => ShapeBaseAttributes.random(_random));
          _successPulses = {};
          _isInit = true;
        }

        // Detect if target index changed (somebody caught it!)
        if (_currentState != null && _currentState!.activeTargetIndex != state.activeTargetIndex) {
            // Visualize the "catch" pulse for the previous target 
            _triggerSuccessPulse(_currentState!.activeTargetIndex);

            // Commit the old mutation to the base attributes visually
            final pt = _currentState!;
            _baseAttributes[pt.activeTargetIndex] = _applyMutationLocally(
               _baseAttributes[pt.activeTargetIndex], 
               _parseMutationString(pt.mutationType), 
               pt.spawnTimestamp
            );
        }

        if (mounted) {
          setState(() {
            _currentState = state;
          });

          if (state.status == 'completed' && !_showingEndDialog) {
             _showSessionSummary();
          }
        }
      }
    });
  }

  void _showSessionSummary() {
    setState(() => _showingEndDialog = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: ViralShareService.boundaryKey,
              child: ViralShareService.buildShareCard(
                leafCount: _currentState?.sharedLeafCount ?? 0,
                mode: 'CO-OP ZEN',
                date: '${DateTime.now().day}/${DateTime.now().month}',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('BACK HOME', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => ViralShareService.shareSession(
                    leafCount: _currentState?.sharedLeafCount ?? 0,
                    mode: 'CO-OP ZEN',
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('GIFT CALM'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A66),
                    foregroundColor: const Color(0xFF1A233A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ShapeBaseAttributes _applyMutationLocally(ShapeBaseAttributes base, MutationType type, DateTime spawn) {
    // Replicates the final progress state to visually bake it in
    double finalScale = base.scale;
    double finalRotation = base.rotation;
    Offset finalOffset = base.offset;
    double finalOpacity = base.opacityMultiplier;
    double finalHue = base.colorShift;
    bool isBlooming = base.isBlooming;

    final double dir = (spawn.millisecondsSinceEpoch % 2 == 0) ? 1.0 : -1.0;
    
    switch (type) {
      case MutationType.position: finalOffset += Offset(10 * dir, -10 * dir); break;
      case MutationType.orientation: finalRotation += 0.3 * dir; break;
      case MutationType.size: finalScale += 0.2 * dir; break;
      case MutationType.length: break;
      case MutationType.breadth: break;
      case MutationType.bloom: finalScale *= (1.0 + 0.15 * dir); isBlooming = true; break;
      case MutationType.opacity: finalOpacity = (finalOpacity + (0.6 * dir)).clamp(0.1, 1.0); break;
      case MutationType.color: finalHue += 180.0 * dir; break;
    }

    return base.copyWith(
      scale: finalScale,
      rotation: finalRotation,
      offset: finalOffset,
      opacityMultiplier: finalOpacity,
      colorShift: finalHue,
      isBlooming: isBlooming,
    );
  }

  MutationType _parseMutationString(String str) {
     return MutationType.values.firstWhere((e) => e.toString() == str, orElse: () => MutationType.color);
  }

  String _getRandomMutationType() {
    final types = MutationType.values;
    return types[_random.nextInt(types.length)].toString();
  }

  void _triggerSuccessPulse(int index) {
    setState(() => _successPulses[index] = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _successPulses[index] = false);
    });
  }

  void _onShapeTapped(int index) {
    if (_currentState == null) return;
    
    // Check if what they tapped is the currently active broadcast target
    if (index == _currentState!.activeTargetIndex) {
       // Correct click! Broadcast the success to the backend.
       // The backend subscription will handle firing the particle effect for BOTH players locally.
       final newTarget = _random.nextInt(_totalCells);
       final newMutation = _getRandomMutationType();
       
       widget.multiplayerService.broadcastCatch(widget.roomId, newTarget, newMutation);
    }
  }

  @override
  void dispose() {
    widget.multiplayerService.leaveRoom(widget.roomId); // Tell other player we left
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _currentState == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF8A66))),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter, radius: 1.5,
            colors: [Color(0xFF2D1B4E), Color(0xFF1A233A)], stops: [0.1, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
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
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFB0BEC4)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Column(
            children: [
               Text(
                 _currentState!.status == 'completed' ? 'Partner Left' : 'Shared Zen',
                 style: TextStyle(
                   color: _currentState!.status == 'completed' ? Colors.red[300] : const Color(0xFFE0E1DD),
                   fontSize: 20, 
                   fontWeight: FontWeight.w600,
                 ),
               ),
               Text(
                 'ROOM: ${widget.roomId}',
                 style: const TextStyle(color: Color(0xFF778DA9), fontSize: 12, letterSpacing: 2.0),
               )
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF222E4A).withAlpha(100),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Row(
              children: [
                 const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 16),
                 const SizedBox(width: 8),
                 Text(
                   '${_currentState!.sharedLeafCount}',
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                 ),
              ],
            )
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
          crossAxisCount: _currentState!.gridSize,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _totalCells,
        itemBuilder: (context, index) {
          final isTarget = _currentState!.activeTargetIndex == index;
          final isPulsing = _successPulses[index] ?? false;
          
          return GestureDetector(
            onTap: () => _onShapeTapped(index),
            behavior: HitTestBehavior.opaque,
            child: ShapeCell(
              cellIndex: index,
              shapeType: _cellShapes[index],
              baseAttributes: _baseAttributes[index],
              mutationSpawnTime: isTarget ? _currentState!.spawnTimestamp : null,
              mutation: isTarget ? _parseMutationString(_currentState!.mutationType) : null,
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
             child: Text(
               _currentState!.status == 'completed' ? 'Your partner disconnected.' : 'Breathe together.',
               style: const TextStyle(color: Color(0xFFB0BEC4), fontSize: 14, letterSpacing: 0.5),
             ),
           );
  }
}

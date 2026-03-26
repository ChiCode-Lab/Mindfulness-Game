import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/multiplayer_service.dart';
import '../services/economy_service.dart';
import '../models/game_settings.dart';
import 'coop_game_screen.dart';
import '../services/deep_link_service.dart';


class MultiplayerLobbyScreen extends StatefulWidget {
  final MultiplayerService multiplayerService;

  const MultiplayerLobbyScreen({super.key, required this.multiplayerService});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  bool _isHosting = false;
  bool _isMatchmaking = false;
  String? _currentRoomId;
  String _joinCodeInput = '';

  int _selectedGridSize = 3;
  int _selectedSessionLength = 5;
  
  late EconomyService _economyService;

  @override
  void initState() {
    super.initState();
    _economyService = EconomyService();
    _economyService.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  int get _currentCost {
    final settings = GameSettings(
      gridColumns: _selectedGridSize,
      gridRows: _selectedGridSize,
      sessionDuration: Duration(minutes: _selectedSessionLength),
      isMultiplayer: true,
    );
    return settings.calculateOpalCost();
  }

  @override
  void dispose() {
    if (_isMatchmaking) {
      widget.multiplayerService.cancelMatchmaking();
    }
    super.dispose();
  }

  void _hostPrivateRoom() async {
    setState(() => _isHosting = true);
    final roomId = await widget.multiplayerService.createPrivateRoom(_selectedGridSize, _selectedSessionLength, 50);
    setState(() {
      _currentRoomId = roomId;
    });

    _listenForOpponent(roomId);
  }

  void _joinPrivateRoom() async {
    if (_joinCodeInput.length != 6) return;
    
    try {
      final success = await widget.multiplayerService.joinPrivateRoom(_joinCodeInput, _economyService);
      if (success) {
        _startCoopGame(_joinCodeInput);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or Full Room Code')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _startAutomatedMatchmaking() async {
    setState(() {
      _isMatchmaking = true;
      _currentRoomId = null;
    });

    try {
      final roomId = await widget.multiplayerService.startMatchmaking(_selectedGridSize, _selectedSessionLength, _economyService);
      if (roomId != null) {
        // Matched instantly!
        _startCoopGame(roomId);
      } else {
        // Queued. Start listening
        widget.multiplayerService.streamRoomsForUser().listen((data) {
          if (data.isNotEmpty) {
            final matchedRoomId = data.first['room_id'] as String;
            if (_isMatchmaking) { // ensuring we haven't cancelled
              _startCoopGame(matchedRoomId);
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _isMatchmaking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _cancelMatchmaking() {
    setState(() {
      _isMatchmaking = false;
      _currentRoomId = null;
    });
    widget.multiplayerService.cancelMatchmaking();
    if (_isHosting && _currentRoomId != null) {
      widget.multiplayerService.leaveRoom(_currentRoomId!); // Clean up hosted room
      _isHosting = false;
    }
  }

  void _listenForOpponent(String roomId) {
    widget.multiplayerService.streamSessionState(roomId).listen((data) {
      if (data.isNotEmpty) {
        final state = RoomState.fromJson(data.first);
        if (state.isReady && _isHosting) { // Second player joined!
            _isHosting = false;
            _startCoopGame(roomId);
        }
      }
    });
  }

  void _startCoopGame(String roomId) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CoopGameScreen(
          multiplayerService: widget.multiplayerService,
          roomId: roomId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('Cooperative Zen', style: TextStyle(color: Color(0xFFE0E1DD))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE0E1DD)),
        leading: BackButton(onPressed: () {
            _cancelMatchmaking();
            Navigator.of(context).pop();
        }),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isMatchmaking || _currentRoomId != null 
              ? _buildWaitingState() 
              : _buildSetupState(),
        ),
      ),
    );
  }

  Widget _buildSetupState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Share the Journey',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF8F9FA)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Grow a single Zen Tree together with a partner. No rushing, no pressure.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF778DA9)),
        ),
        const SizedBox(height: 48),

        // Settings (Only applied if hosting or matchmaking)
        const Text('Preferences', style: TextStyle(color: Color(0xFFB0BEC4), fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
             _buildChoiceChip('3x3 Grid', 3, _selectedGridSize, (v) => setState(() => _selectedGridSize = v)),
             _buildChoiceChip('4x4 Grid', 4, _selectedGridSize, (v) => setState(() => _selectedGridSize = v)),
          ],
        ),
        const SizedBox(height: 32),

        const SizedBox(height: 16),
        Center(
          child: Text(
            _economyService.state.isPremium 
              ? 'Premium Active - No Social Surcharge' 
              : 'Current Balance: ${_economyService.state.opals} Opals\nRequired: $_currentCost Opals',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB0BEC4), fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _startAutomatedMatchmaking,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50), // Green for matching
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            _economyService.state.isPremium ? 'FIND PARTNER NOW' : 'FIND PARTNER ($_currentCost OPALS)', 
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)
          ),
        ),

        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _hostPrivateRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF222E4A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            _economyService.state.isPremium ? 'HOST PRIVATE ROOM' : 'HOST PRIVATE ROOM ($_currentCost OPALS)'
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Joining a room? You must match the Host\'s settings cost.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB0BEC4), fontSize: 12),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _joinCodeInput = val),
                 style: const TextStyle(color: Colors.white, letterSpacing: 4.0, fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'ENTER 6-DIGIT CODE',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(100), letterSpacing: 1.0, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFF222E4A).withAlpha(100),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
               height: 56,
              child: ElevatedButton(
                onPressed: _joinCodeInput.length == 6 ? _joinPrivateRoom : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Icon(Icons.arrow_forward),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildWaitingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        const CircularProgressIndicator(color: Color(0xFFFF8A66)),
        const SizedBox(height: 48),
        Text(
          _currentRoomId != null ? 'Waiting for friend...' : 'Searching the forest...',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, color: Color(0xFFF8F9FA)),
        ),
        if (_currentRoomId != null) ...[
          const SizedBox(height: 24),
          const Text('Share this code with your partner:', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF778DA9))),
          const SizedBox(height: 12),
          Text(
            _currentRoomId!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8.0, color: Color(0xFFE0E1DD)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => showInviteSheet(
              context,
              roomId: _currentRoomId!,
              referrerId: widget.multiplayerService.localUserId,
            ),
            icon: const Icon(Icons.share_rounded, size: 20),
            label: const Text('INVITE A FRIEND', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We\'ll both earn shared leaves and grow faster.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF778DA9), fontSize: 13),
          ),
        ],
        const Spacer(),

        OutlinedButton(
          onPressed: _cancelMatchmaking,
          style: OutlinedButton.styleFrom(
             padding: const EdgeInsets.symmetric(vertical: 16),
             foregroundColor: Colors.red[300],
             side: BorderSide(color: Colors.red[300]!.withAlpha(100)),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('CANCEL WAITING'),
        )
      ],
    );
  }

  Widget _buildChoiceChip(String label, int value, int groupValue, ValueChanged<int> onSelect) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8A66).withOpacity(0.2) : const Color(0xFF222E4A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFFFF8A66) : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? const Color(0xFFFF8A66) : const Color(0xFFF8F9FA), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}

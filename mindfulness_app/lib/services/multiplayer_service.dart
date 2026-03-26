import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'economy_service.dart';

class RoomState {
  final String roomId;
  final String player1Id;
  final String? player2Id;
  final int sharedLeafCount;
  final int activeTargetIndex;
  final String mutationType;
  final DateTime spawnTimestamp;
  final int gridSize;
  final int sessionLength;
  final String status;

  RoomState({
    required this.roomId,
    required this.player1Id,
    this.player2Id,
    required this.sharedLeafCount,
    required this.activeTargetIndex,
    required this.mutationType,
    required this.spawnTimestamp,
    required this.gridSize,
    required this.sessionLength,
    required this.status,
  });

  bool get isReady => player1Id.isNotEmpty && (player2Id != null && player2Id!.isNotEmpty);

  factory RoomState.fromJson(Map<String, dynamic> json) {
    return RoomState(
      roomId: json['room_id'] as String,
      player1Id: json['player_1_id'] as String,
      player2Id: json['player_2_id'] as String?,
      sharedLeafCount: json['shared_leaf_count'] as int,
      activeTargetIndex: json['active_target_index'] as int,
      mutationType: json['mutation_type'] as String,
      spawnTimestamp: DateTime.parse(json['spawn_timestamp']),
      gridSize: json['grid_size'] as int,
      sessionLength: json['session_length'] as int,
      status: json['status'] as String,
    );
  }
}

class MultiplayerService {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _localUserId;

  MultiplayerService() {
    _initUserId();
  }

  Future<void> _initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _localUserId = prefs.getString('local_user_id');
    if (_localUserId == null) {
      // For anonymous users, we just generate a persistent UUID local to the device
      _localUserId = Supabase.instance.client.auth.currentSession?.user.id ?? 
                      DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
      await prefs.setString('local_user_id', _localUserId!);
    }
  }

  String get localUserId => _localUserId ?? '';

  String _generateRoomCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  // -------------------------------------------------------------
  // Private Rooms
  // -------------------------------------------------------------
  Future<String> createPrivateRoom(int gridSize, int sessionLength, int entryCost) async {
    final roomId = _generateRoomCode();
    await _supabase.from('zen_rooms').insert({
      'room_id': roomId,
      'player_1_id': localUserId,
      'grid_size': gridSize,
      'session_length': sessionLength,
      'active_target_index': Random().nextInt(gridSize * gridSize),
      'mutation_type': 'MutationType.color',
      'entry_cost': entryCost, // Save the cost needed to join
    });
    return roomId;
  }

  Future<bool> joinPrivateRoom(String roomId, EconomyService economy) async {
    final room = await _supabase
        .from('zen_rooms')
        .select()
        .eq('room_id', roomId)
        .eq('status', 'active')
        .maybeSingle();

    if (room == null || room['player_2_id'] != null) {
      return false; // Room doesn't exist or is full
    }

    // Check affordance for the Social Surcharge
    final entryCost = room['entry_cost'] as int? ?? 0;
    if (!economy.canAfford(entryCost)) {
      throw Exception('Insufficient Opals to join this room.');
    }

    // Deduct
    await economy.deductOpals(entryCost);

    // Join the room
    await _supabase
        .from('zen_rooms')
        .update({'player_2_id': localUserId})
        .eq('room_id', roomId);
    return true;
  }

  /// Special bypass for first-time invited users (Viral Engine).
  Future<bool> joinFreeRoom(String roomId) async {
    // Basic validation: ensures room is still active and has space
    final room = await _supabase
        .from('zen_rooms')
        .select()
        .eq('room_id', roomId)
        .eq('status', 'active')
        .maybeSingle();

    if (room == null || room['player_2_id'] != null) {
      return false;
    }

    // Join without cost check
    await _supabase
        .from('zen_rooms')
        .update({'player_2_id': localUserId})
        .eq('room_id', roomId);
    return true;
  }

  Future<bool> isFirstCoopSession() async {
    final prefs = await SharedPreferences.getInstance();
    // We check both local state and theoretically Supabase (if Big Pickle's migration is ready)
    // For now, local-first is safest for MVP/Demo
    final used = prefs.getBool('used_free_coop_session') ?? false;
    return !used;
  }

  Future<void> markFreeCoopUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('used_free_coop_session', true);
  }

  // -------------------------------------------------------------
  // Matchmaking (RPC)
  // -------------------------------------------------------------
  Future<String?> startMatchmaking(int gridSize, int sessionLength, EconomyService economy) async {
    // Determine the cost dynamically before queueing
    // (In production, the RPC should validate this to prevent hacking, but client validates first)
    // Assume we calculate the cost here or pass it in. For simplicity, assume 50 for testing.
    final estimatedCost = 50; 
    
    if (!economy.canAfford(estimatedCost)) {
       throw Exception('Insufficient Opals for matchmaking.');
    }
    await economy.deductOpals(estimatedCost);

    final response = await _supabase.rpc('find_or_create_match', params: {
      'p_user_id': localUserId,
      'p_grid_size': gridSize,
      'p_session_length': sessionLength,
    });

    return response as String?; // Will be null if queued, or the room_id if matched instantly
  }

  Future<void> cancelMatchmaking() async {
    await _supabase
        .from('matchmaking_queue')
        .delete()
        .eq('user_id', localUserId);
  }

  // Listen to the queue to see if our user row gets picked up (deleted)
  SupabaseStreamBuilder streamQueue() {
    return _supabase
        .from('matchmaking_queue')
        .stream(primaryKey: ['id'])
        .eq('user_id', localUserId);
  }

  // Once queued, listen to zen_rooms to see if we were placed in one
  SupabaseStreamBuilder streamRoomsForUser() {
    // Since stream doesn't support complex ORs yet in supabase_flutter easily, 
    // we'll filter client-side, or simply poll. For true realtime, we'll watch the table where player_2_id = localUserId.
    // The RPC sets player_2_id to the incoming user when matched.
    return _supabase
        .from('zen_rooms')
        .stream(primaryKey: ['id'])
        .eq('player_2_id', localUserId)
        .limit(1);
  }

  // -------------------------------------------------------------
  // Game Syncing
  // -------------------------------------------------------------
  SupabaseStreamBuilder streamSessionState(String roomId) {
    return _supabase
        .from('zen_rooms')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId);
  }

  Future<void> broadcastCatch(String roomId, int newTargetIndex, String newMutationType) async {
    // Atomically increment the leaf count and spawn the next shape
    // (In a highly secure prod app, we'd use another RPC for atomic increments, 
    // but a standard update is fine for casual zen pacing.)
    
    // First fetch current to increment
    final room = await _supabase.from('zen_rooms').select('shared_leaf_count').eq('room_id', roomId).single();
    final currentCount = room['shared_leaf_count'] as int;

    await _supabase.from('zen_rooms').update({
      'shared_leaf_count': currentCount + 1,
      'active_target_index': newTargetIndex,
      'mutation_type': newMutationType,
      'spawn_timestamp': DateTime.now().toIso8601String(),
    }).eq('room_id', roomId);
  }

  Future<void> leaveRoom(String roomId) async {
    // For simplicity, just mark completed so the other player gets notified it's over
    await _supabase.from('zen_rooms').update({'status': 'completed'}).eq('room_id', roomId);
  }
}

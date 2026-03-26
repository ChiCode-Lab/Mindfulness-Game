import 'package:audioplayers/audioplayers.dart';
import '../models/game_settings.dart';
import 'dart:async';

class SoundscapeEngine {
  final AudioPlayer _primaryPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _interactionPlayer = AudioPlayer();
  
  StreamSubscription? _playerCompleteSubscription;
  Soundscape? _currentSoundscape;
  int _currentVariationIndex = 0;
  
  final Map<Soundscape, List<String>> _variations = {
    Soundscape.campfire: [
      'audio/campfire_1.wav',
      'audio/campfire_2.wav',
      'audio/campfire_3.wav',
      'audio/campfire_4.wav',
    ],
    Soundscape.rainfall: [
      'audio/rain_1.wav',
      'audio/rain_2.wav',
      'audio/rain_3.wav',
    ],
  };

  SoundscapeEngine() {
    _primaryPlayer.setReleaseMode(ReleaseMode.stop); // We handle loop via playlist
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _interactionPlayer.setReleaseMode(ReleaseMode.stop);
    
    // Listen for completion to rotate files for a non-interrupted loop feel
    _playerCompleteSubscription = _primaryPlayer.onPlayerComplete.listen((_) {
       _playNextVariation();
    });
  }

  Future<void> _playNextVariation() async {
    if (_currentSoundscape == null) return;
    
    final baseSound = (_currentSoundscape == Soundscape.campfireMusic) 
      ? Soundscape.campfire 
      : (_currentSoundscape == Soundscape.rainfallMusic) 
          ? Soundscape.rainfall 
          : _currentSoundscape!;
          
    final playlist = _variations[baseSound];
    if (playlist == null || playlist.isEmpty) return;
    
    _currentVariationIndex = (_currentVariationIndex + 1) % playlist.length;
    final nextAsset = playlist[_currentVariationIndex];
    
    try {
      await _primaryPlayer.play(AssetSource(nextAsset));
    } catch (e) {
      // Ignored
    }
  }

  Future<void> playInteractionSound() async {
    try {
      // Use the crystalline/water-droplet-like sound for interactions
      await _interactionPlayer.play(AssetSource('audio/tap_water.wav'), mode: PlayerMode.lowLatency);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> playSpawnSound() async {
    try {
      await _interactionPlayer.play(AssetSource('audio/spawn_crystalline.wav'), mode: PlayerMode.lowLatency);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> playStartSound() async {
    try {
      await _interactionPlayer.play(AssetSource('audio/start_sequence.wav'), mode: PlayerMode.lowLatency);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> play(Soundscape soundscape) async {
    await stop();
    _currentSoundscape = soundscape;
    _currentVariationIndex = 0;

    final isMusicEnabled = soundscape == Soundscape.campfireMusic || soundscape == Soundscape.rainfallMusic;
    final baseSound = (soundscape == Soundscape.campfireMusic) 
      ? Soundscape.campfire 
      : (soundscape == Soundscape.rainfallMusic) 
          ? Soundscape.rainfall 
          : soundscape;

    final playlist = _variations[baseSound];
    if (playlist == null || playlist.isEmpty) return;

    try {
      if (isMusicEnabled) {
        // Placeholder music: 'shimmer_ambient.wav'
        await _musicPlayer.play(AssetSource('audio/shimmer_ambient.wav'));
      }
      await _primaryPlayer.play(AssetSource(playlist[0]));
    } catch (e) {
      // Error logging or fallback
    }
  }

  Future<void> setVolume(double volume) async {
    await _primaryPlayer.setVolume(volume);
    await _musicPlayer.setVolume(volume * 0.7); // Music should be slightly softer
  }

  Future<void> stop() async {
    await _primaryPlayer.stop();
    await _musicPlayer.stop();
  }

  void dispose() {
    _playerCompleteSubscription?.cancel();
    _primaryPlayer.dispose();
    _musicPlayer.dispose();
    _interactionPlayer.dispose();
  }
}

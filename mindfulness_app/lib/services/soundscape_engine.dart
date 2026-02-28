import 'package:audioplayers/audioplayers.dart';
import '../models/game_settings.dart';

class SoundscapeEngine {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _interactionPlayer = AudioPlayer();

  SoundscapeEngine() {
    _player.setReleaseMode(ReleaseMode.loop);
    _interactionPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playInteractionSound() async {
    try {
      await _interactionPlayer.play(AssetSource('audio/placeholder_tap.wav'), mode: PlayerMode.lowLatency);
    } catch (e) {
      // Ignored if missing
    }
  }

  Future<void> play(Soundscape soundscape) async {
    await _player.stop();
    if (soundscape == Soundscape.none) return;

    String assetPath = '';
    switch (soundscape) {
      case Soundscape.rainThunder:
         assetPath = 'audio/placeholder_rain.wav';
         break;
      case Soundscape.oceanWaves:
         assetPath = 'audio/placeholder_ocean.wav';
         break;
      case Soundscape.campfire:
         assetPath = 'audio/placeholder_campfire.wav';
         break;
      case Soundscape.forestUnderwater:
         assetPath = 'audio/placeholder_forest.wav';
         break;
      default:
         return;
    }
    
    try {
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      // It is expected to fail if the user hasn't provided the placeholder files yet.
      // print('Audio asset not found yet: $assetPath');
    }
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}

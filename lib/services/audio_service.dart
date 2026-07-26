import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> init() async {
    await _player.setSource(AssetSource('sounds/beep.mp3'));
    _player.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playBeep() async {
    if (_isPlaying) return;
    try {
      await _player.resume();
      _isPlaying = true;
    } catch (_) {
      await _player.play(AssetSource('sounds/beep.mp3'));
      _isPlaying = true;
    }
  }

  Future<void> stopBeep() async {
    if (!_isPlaying) return;
    await _player.pause();
    _isPlaying = false;
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    _player.dispose();
  }
}
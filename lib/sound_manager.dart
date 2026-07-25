// lib/sound_manager.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  AudioSource? _slideSource;
  AudioSource? _captureSource;
  AudioSource? _tapSource;
  AudioSource? _winSource;
  AudioSource? _loseSource;
  bool _initialized = false;

  bool soundEnabled = true;
  bool hapticsEnabled = true;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await SoLoud.instance.init();
      _slideSource = await SoLoud.instance.loadAsset('assets/sounds/piece_slide.mp3');
      _captureSource = await SoLoud.instance.loadAsset('assets/sounds/piece_captured.mp3');
      _tapSource = await SoLoud.instance.loadAsset('assets/sounds/tap.mp3');
      _winSource = await SoLoud.instance.loadAsset('assets/sounds/win.mp3');
      _loseSource = await SoLoud.instance.loadAsset('assets/sounds/lose.wav');
      _initialized = true;
      debugPrint('SoundManager: initialized');
    } catch (e) {
      debugPrint('SoundManager: init failed — $e');
    }
  }

  void playSlide() {
    if (!soundEnabled || !_initialized || _slideSource == null) return;
    try {
      SoLoud.instance.play(_slideSource!);
    } catch (e) {
      debugPrint('SoundManager: playSlide failed — $e');
    }
  }

  void playCapture() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 50), () {
        HapticFeedback.vibrate();
      });
    }
    if (!soundEnabled || !_initialized || _captureSource == null) return;
    try {
      SoLoud.instance.play(_captureSource!);
    } catch (e) {
      debugPrint('SoundManager: playCapture failed — $e');
    }
  }

  void playTap() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
      HapticFeedback.vibrate();
    }
    if (!soundEnabled || !_initialized || _tapSource == null) return;
    try {
      SoLoud.instance.play(_tapSource!);
    } catch (e) {
      debugPrint('SoundManager: playTap failed — $e');
    }
  }

  void playWin() {
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
    if (!soundEnabled || !_initialized || _winSource == null) return;
    try {
      SoLoud.instance.play(_winSource!);
    } catch (e) {
      debugPrint('SoundManager: playWin failed — $e');
    }
  }

  void playLose() {
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
    if (!soundEnabled || !_initialized || _loseSource == null) return;
    try {
      SoLoud.instance.play(_loseSource!);
    } catch (e) {
      debugPrint('SoundManager: playLose failed — $e');
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    SoLoud.instance.deinit();
    _initialized = false;
    _slideSource = null;
    _captureSource = null;
    _tapSource = null;
    _winSource = null;
    _loseSource = null;
  }
}
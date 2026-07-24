// lib/sound_manager.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  AudioSource? _slideSource;
  AudioSource? _captureSource;
  AudioSource? _tapSource;   // <-- ADD
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await SoLoud.instance.init();
      _slideSource = await SoLoud.instance.loadAsset('assets/sounds/piece_slide.mp3');
      _captureSource = await SoLoud.instance.loadAsset('assets/sounds/piece_captured.mp3');
      _tapSource = await SoLoud.instance.loadAsset('assets/sounds/tap.mp3');   // <-- ADD
      _initialized = true;
      debugPrint('SoundManager: initialized');
    } catch (e) {
      debugPrint('SoundManager: init failed — $e');
    }
  }

  void playSlide() {
    if (!_initialized || _slideSource == null) return;
    try {
      SoLoud.instance.play(_slideSource!);
    } catch (e) {
      debugPrint('SoundManager: playSlide failed — $e');
    }
  }

  void playCapture() {
    if (!_initialized || _captureSource == null) return;
    try {
      SoLoud.instance.play(_captureSource!);
    } catch (e) {
      debugPrint('SoundManager: playCapture failed — $e');
    }
  }

  void playTap() {   // <-- ADD THIS METHOD
    if (!_initialized || _tapSource == null) return;
    try {
      SoLoud.instance.play(_tapSource!);
    } catch (e) {
      debugPrint('SoundManager: playTap failed — $e');
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    SoLoud.instance.deinit();
    _initialized = false;
    _slideSource = null;
    _captureSource = null;
    _tapSource = null;   // <-- ADD
  }
}
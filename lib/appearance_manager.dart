import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app chrome appearance is independent from the visual board skin.
enum AppAppearance { dark, light }

class AppearanceManager {
  AppearanceManager._();
  static const _storageKey = 'app_appearance';
  static final ValueNotifier<AppAppearance> selected = ValueNotifier(
    AppAppearance.dark,
  );
  static SharedPreferences? _preferences;

  static AppAppearance get current => selected.value;
  static bool get isLight => current == AppAppearance.light;

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final saved = _preferences!.getString(_storageKey);
    selected.value = AppAppearance.values.firstWhere(
      (appearance) => appearance.name == saved,
      orElse: () => AppAppearance.dark,
    );
  }

  static void select(AppAppearance appearance) {
    if (selected.value == appearance) return;
    selected.value = appearance;
    _preferences?.setString(_storageKey, appearance.name);
  }
}

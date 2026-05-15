import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(
      ThemeModeController.new,
    );

class ThemeModeController extends Notifier<ThemeMode> {
  bool _loaded = false;

  @override
  ThemeMode build() {
    if (!_loaded) {
      _loaded = true;
      _load();
    }
    return ThemeMode.system;
  }

  void setSystem() {
    state = ThemeMode.system;
    _write('system');
  }

  void setLight() {
    state = ThemeMode.light;
    _write('light');
  }

  void setDark() {
    state = ThemeMode.dark;
    _write('dark');
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('dockge_theme_mode') ?? 'system';
      state = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  Future<void> _write(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dockge_theme_mode', value);
    } catch (_) {
      // Some test environments do not install shared_preferences.
    }
  }
}
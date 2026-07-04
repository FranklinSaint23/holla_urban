import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'holla_theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.light;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved == 'dark') state = ThemeMode.dark;
    if (saved == 'light') state = ThemeMode.light;
    if (saved == 'system') state = ThemeMode.system;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _save();
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _save();
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final val = state == ThemeMode.dark
        ? 'dark'
        : state == ThemeMode.light
            ? 'light'
            : 'system';
    await prefs.setString(_kThemeKey, val);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

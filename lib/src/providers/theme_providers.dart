import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/theme_service.dart';

final themeServiceProvider = Provider<ThemeService>((ref) {
  return ThemeService();
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final service = ref.watch(themeServiceProvider);
  return ThemeModeNotifier(service)..load();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _service;

  ThemeModeNotifier(this._service) : super(ThemeMode.system);

  Future<void> load() async {
    state = await _service.loadThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _service.saveThemeMode(mode);
  }
}

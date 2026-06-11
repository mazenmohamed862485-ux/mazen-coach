import 'package:flutter/material.dart';
import '../../data/local/preferences_helper.dart';
import 'package:mavix_coach/core/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.light;
  final PreferencesHelper _prefs;

  ThemeProvider(this._prefs);

  AppThemeMode get mode => _mode;
  bool get isDark => _mode == AppThemeMode.dark;

  ThemeData get theme {
    switch (_mode) {
      case AppThemeMode.dark:
        return AppTheme.darkTheme();
      case AppThemeMode.light:
      default:
        return AppTheme.lightTheme();
    }
  }

  ThemeMode get themeMode {
    return _mode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> initialize() async {
    final saved = await _prefs.getTheme();
    _setModeFromString(saved);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _mode = mode;
    await _prefs.saveTheme(mode.name);
    notifyListeners();
  }

  Future<void> toggleDark() async {
    final next = _mode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setTheme(next);
  }

  void _setModeFromString(String s) {
    switch (s) {
      case 'dark': _mode = AppThemeMode.dark; break;
      case 'luxury': _mode = AppThemeMode.luxury; break;
      case 'sports': _mode = AppThemeMode.sports; break;
      case 'future': _mode = AppThemeMode.future; break;
      default: _mode = AppThemeMode.light;
    }
  }
}

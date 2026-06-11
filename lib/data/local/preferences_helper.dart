import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class PreferencesHelper {
  static final PreferencesHelper instance = PreferencesHelper._init();
  PreferencesHelper._init();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── User Session ─────────────────────────────────────────────────
  Future<void> saveUserId(String uid) async {
    final p = await prefs;
    await p.setString(AppConstants.keyUserId, uid);
  }

  Future<String?> getUserId() async {
    final p = await prefs;
    return p.getString(AppConstants.keyUserId);
  }

  Future<void> saveUserJson(String json) async {
    final p = await prefs;
    await p.setString(AppConstants.keyUserJson, json);
  }

  Future<String?> getUserJson() async {
    final p = await prefs;
    return p.getString(AppConstants.keyUserJson);
  }

  Future<void> clearSession() async {
    final p = await prefs;
    await p.remove(AppConstants.keyUserId);
    await p.remove(AppConstants.keyUserJson);
  }

  // ── GAS URL ──────────────────────────────────────────────────────
  Future<void> saveGasUrl(String url) async {
    final p = await prefs;
    await p.setString(AppConstants.keyGasUrl, url);
  }

  Future<String?> getGasUrl() async {
    final p = await prefs;
    return p.getString(AppConstants.keyGasUrl);
  }

  // ── Theme ─────────────────────────────────────────────────────────
  Future<void> saveTheme(String theme) async {
    final p = await prefs;
    await p.setString(AppConstants.keyTheme, theme);
  }

  Future<String> getTheme() async {
    final p = await prefs;
    return p.getString(AppConstants.keyTheme) ?? 'light';
  }

  // ── Language ─────────────────────────────────────────────────────
  Future<void> saveLanguage(String lang) async {
    final p = await prefs;
    await p.setString(AppConstants.keyLanguage, lang);
  }

  Future<String> getLanguage() async {
    final p = await prefs;
    return p.getString(AppConstants.keyLanguage) ?? 'ar';
  }

  // ── Last Sync ────────────────────────────────────────────────────
  Future<void> saveLastSync(int ts) async {
    final p = await prefs;
    await p.setInt(AppConstants.keyLastSync, ts);
  }

  Future<int> getLastSync() async {
    final p = await prefs;
    return p.getInt(AppConstants.keyLastSync) ?? 0;
  }

  // ── Session ID ───────────────────────────────────────────────────
  Future<void> saveSessionId(String sessionId) async {
    final p = await prefs;
    await p.setString(AppConstants.keySessionId, sessionId);
  }

  Future<String?> getSessionId() async {
    final p = await prefs;
    return p.getString(AppConstants.keySessionId);
  }

  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}

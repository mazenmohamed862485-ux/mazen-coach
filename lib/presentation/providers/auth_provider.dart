import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/local/database_helper.dart';
import '../../data/local/preferences_helper.dart';
import '../../data/models/user_model.dart';
import '../../data/remote/gas_api_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, subscriptionRequired }

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  AuthState _state = AuthState.initial;
  String? _error;
  final GasApiService _api;
  final DatabaseHelper _db;
  final PreferencesHelper _prefs;

  AuthProvider({
    required GasApiService api,
    required DatabaseHelper db,
    required PreferencesHelper prefs,
  })  : _api = api,
        _db = db,
        _prefs = prefs;

  UserModel? get user => _user;
  AuthState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;
  bool get isAdminLike => _user?.isAdminLike ?? false;

  Future<void> initialize() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      // Load GAS URL
      final gasUrl = await _prefs.getGasUrl();
      if (gasUrl != null && gasUrl.isNotEmpty) {
        _api.configure(gasUrl);
      }

      // Try to restore session
      final uid = await _prefs.getUserId();
      if (uid == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      final userJson = await _prefs.getUserJson();
      if (userJson != null) {
        _user = UserModel.fromJson(jsonDecode(userJson));
        _state = AuthState.authenticated;
        notifyListeners();

        // Background refresh
        _refreshUserInBackground(_user!.uid);
      } else {
        final dbUser = await _db.getUser(uid);
        if (dbUser != null) {
          _user = dbUser;
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.unauthenticated;
        }
        notifyListeners();
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _refreshUserInBackground(String uid) async {
    if (!_api.isConfigured) return;
    try {
      final res = await _api.refreshUser(uid);
      if (res.ok && res.data != null) {
        final refreshed = UserModel.fromJson(Map<String, dynamic>.from(res.data));
        await _db.saveUser(refreshed);
        await _prefs.saveUserJson(refreshed.toJsonString());
        _user = refreshed;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<String?> login(String email, String password) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    if (!_api.isConfigured) {
      _state = AuthState.unauthenticated;
      _error = 'يرجى إعداد رابط الخادم أولاً';
      notifyListeners();
      return _error;
    }

    try {
      final res = await _api.login(email, password);
      if (!res.ok) {
        _state = AuthState.unauthenticated;
        _error = res.error ?? 'فشل تسجيل الدخول';
        notifyListeners();
        return _error;
      }

      final userData = Map<String, dynamic>.from(res.data['user'] ?? res.data);
      final user = UserModel.fromJson(userData);
      await _setLoggedIn(user, sessionToken: res.data['sessionToken']?.toString());
      return null;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _error = 'خطأ في الاتصال بالخادم';
      notifyListeners();
      return _error;
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String program,
    required int days,
    required String subscriptionType,
    required int subscriptionMonths,
  }) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    if (!_api.isConfigured) {
      _state = AuthState.unauthenticated;
      _error = 'يرجى إعداد رابط الخادم أولاً';
      notifyListeners();
      return _error;
    }

    try {
      final res = await _api.register(
        name: name, email: email, password: password, phone: phone,
        program: program, days: days, subscriptionType: subscriptionType,
        subscriptionMonths: subscriptionMonths,
      );
      if (!res.ok) {
        _state = AuthState.unauthenticated;
        _error = res.error ?? 'فشل إنشاء الحساب';
        notifyListeners();
        return _error;
      }
      final userData = Map<String, dynamic>.from(res.data['user'] ?? res.data);
      final user = UserModel.fromJson(userData);
      await _setLoggedIn(user, sessionToken: res.data['sessionToken']?.toString());
      return null;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _error = 'خطأ في الاتصال بالخادم';
      notifyListeners();
      return _error;
    }
  }

  Future<String?> guestLogin(String code) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.guestLogin(code);
      if (!res.ok) {
        _state = AuthState.unauthenticated;
        _error = res.error ?? 'رمز الضيف غير صحيح';
        notifyListeners();
        return _error;
      }
      final user = UserModel.fromJson(Map<String, dynamic>.from(res.data['user'] ?? res.data));
      await _setLoggedIn(user);
      return null;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _error = 'خطأ في الاتصال';
      notifyListeners();
      return _error;
    }
  }

  Future<void> _setLoggedIn(UserModel user, {String? sessionToken}) async {
    _user = user;
    await _db.saveUser(user);
    await _prefs.saveUserId(user.uid);
    await _prefs.saveUserJson(user.toJsonString());
    if (sessionToken != null) {
      await _prefs.saveSessionId(sessionToken);
      _api.setSessionToken(sessionToken);
    }
    _state = AuthState.authenticated;
    _error = null;
    notifyListeners();
  }

  Future<void> updateUser(UserModel updated) async {
    _user = updated;
    await _db.saveUser(updated);
    await _prefs.saveUserJson(updated.toJsonString());
    notifyListeners();
  }

  Future<void> logout() async {
    try { await _api.logout(); } catch (_) {}
    _user = null;
    _state = AuthState.unauthenticated;
    await _prefs.clearSession();
    _api.setSessionToken(null);
    notifyListeners();
  }

  Future<void> setGasUrl(String url) async {
    await _prefs.saveGasUrl(url);
    _api.configure(url);
    notifyListeners();
  }

  String? get gasUrl => _api.isConfigured ? null : null;
}

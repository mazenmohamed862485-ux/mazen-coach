import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class GasApiResponse {
  final bool ok;
  final dynamic data;
  final String? error;

  const GasApiResponse({required this.ok, this.data, this.error});

  factory GasApiResponse.error(String msg) =>
      GasApiResponse(ok: false, error: msg);
}

class GasApiService {
  String? _gasUrl;
  String? _sessionToken;
  static const Duration _timeout = Duration(seconds: 15);

  void configure(String gasUrl) {
    _gasUrl = gasUrl;
  }

  void setSessionToken(String? token) {
    _sessionToken = token;
  }

  bool get isConfigured => _gasUrl != null && _gasUrl!.isNotEmpty;

  Future<GasApiResponse> _post(Map<String, dynamic> body, {bool isPublic = false}) async {
    if (!isConfigured) return GasApiResponse.error('GAS URL غير مضبوط');
    try {
      final payload = Map<String, dynamic>.from(body);
      if (!isPublic && _sessionToken != null) {
        payload['sessionToken'] = _sessionToken;
      }
      final encoded = Uri.encodeFull(jsonEncode(payload));
      final response = await http.post(
        Uri.parse(_gasUrl!),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(jsonEncode(payload))}',
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        return GasApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
      final json = jsonDecode(response.body);
      if (json['ok'] == true) {
        return GasApiResponse(ok: true, data: json['data'] ?? json);
      } else {
        return GasApiResponse.error(json['error']?.toString() ?? 'خطأ غير معروف');
      }
    } on Exception catch (e) {
      return GasApiResponse.error('خطأ في الاتصال: $e');
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────
  Future<GasApiResponse> login(String email, String password) async {
    return _post({'action': 'LOGIN', 'email': email, 'password': password}, isPublic: true);
  }

  Future<GasApiResponse> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String program,
    required int days,
    required String subscriptionType,
    required int subscriptionMonths,
  }) async {
    return _post({
      'action': 'REGISTER',
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'program': program,
      'days': days,
      'subscriptionType': subscriptionType,
      'subscriptionMonths': subscriptionMonths,
    }, isPublic: true);
  }

  Future<GasApiResponse> guestLogin(String code) async {
    return _post({'action': 'GUEST_LOGIN', 'code': code}, isPublic: true);
  }

  Future<GasApiResponse> logout() async {
    return _post({'action': 'LOGOUT'});
  }

  Future<GasApiResponse> refreshUser(String uid) async {
    return _post({'action': 'GET_USER', 'uid': uid});
  }

  // ── Sync ─────────────────────────────────────────────────────────
  Future<GasApiResponse> syncWorkoutLog(Map<String, dynamic> log) async {
    return _post({'action': 'SYNC_WORKOUT', 'log': jsonEncode(log)});
  }

  Future<GasApiResponse> syncMeal(Map<String, dynamic> meal) async {
    return _post({'action': 'SYNC_MEAL', 'meal': jsonEncode(meal)});
  }

  Future<GasApiResponse> syncAttendance(Map<String, dynamic> att) async {
    return _post({'action': 'SYNC_ATTENDANCE', 'attendance': jsonEncode(att)});
  }

  Future<GasApiResponse> syncMeasurement(Map<String, dynamic> m) async {
    return _post({'action': 'SYNC_MEASUREMENT', 'measurement': jsonEncode(m)});
  }

  Future<GasApiResponse> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    return _post({'action': 'UPDATE_PROFILE', 'uid': uid, 'updates': jsonEncode(updates)});
  }

  // ── Admin ─────────────────────────────────────────────────────────
  Future<GasApiResponse> getAllUsers() async {
    return _post({'action': 'ADMIN_GET_USERS'});
  }

  Future<GasApiResponse> updateUserSubscription({
    required String uid,
    required String status,
    required String type,
    required int durationMonths,
  }) async {
    return _post({
      'action': 'ADMIN_UPDATE_SUBSCRIPTION',
      'uid': uid,
      'status': status,
      'subscriptionType': type,
      'durationMonths': durationMonths,
    });
  }

  Future<GasApiResponse> updateSubscriptionConfig(Map<String, dynamic> config) async {
    return _post({'action': 'ADMIN_UPDATE_SUB_CONFIG', 'config': jsonEncode(config)});
  }

  Future<GasApiResponse> getSubscriptionConfig() async {
    return _post({'action': 'GET_SUB_CONFIG'}, isPublic: true);
  }

  // ── Chat ─────────────────────────────────────────────────────────
  Future<GasApiResponse> getChatRooms(String uid) async {
    return _post({'action': 'GET_CHAT_ROOMS', 'uid': uid});
  }

  Future<GasApiResponse> getChatMessages(String roomId, {int limit = 50}) async {
    return _post({'action': 'GET_MESSAGES', 'roomId': roomId, 'limit': limit});
  }

  Future<GasApiResponse> sendChatMessage(Map<String, dynamic> msg) async {
    return _post({'action': 'SEND_MESSAGE', 'message': jsonEncode(msg)});
  }

  // ── Payment ──────────────────────────────────────────────────────
  Future<GasApiResponse> submitPayment({
    required String uid,
    required String imageUrl,
    required String plan,
    required int months,
  }) async {
    return _post({
      'action': 'SUBMIT_PAYMENT',
      'uid': uid,
      'imageUrl': imageUrl,
      'plan': plan,
      'months': months,
    });
  }
}

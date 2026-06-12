import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';

class GasApiResponse {
  final bool ok;
  final dynamic data;
  final String? error;

  const GasApiResponse({required this.ok, this.data, this.error});

  factory GasApiResponse.error(String msg) =>
      GasApiResponse(ok: false, error: msg);
}

/// Google Apps Script (GAS) API Service
///
/// GAS always redirects POST requests with HTTP 302 before returning the
/// actual response. The standard `http` package does NOT follow redirects
/// on POST (correct per HTTP spec), so every call was returning
/// "خطأ في الاتصال: 302".
///
/// Fix: use [HttpClient] directly with [followRedirects = false] disabled
/// so we can detect the 302, extract the Location header, and follow it
/// manually with a GET request to retrieve the real JSON response.
class GasApiService {
  String? _gasUrl;
  String? _sessionToken;

  static const Duration _timeout = Duration(seconds: 20);
  static const int _maxRedirects = 5;

  void configure(String gasUrl) {
    _gasUrl = gasUrl.trim();
  }

  void setSessionToken(String? token) {
    _sessionToken = token;
  }

  bool get isConfigured => _gasUrl != null && _gasUrl!.isNotEmpty;

  /// Core POST method that correctly handles Google Apps Script's 302 redirects.
  ///
  /// Flow:
  ///   1. POST the payload to the GAS exec URL (form-encoded).
  ///   2. GAS responds with 302 + a Location header pointing to the real result.
  ///   3. We follow that Location with a GET request.
  ///   4. The GET returns 200 with the actual JSON body.
  Future<GasApiResponse> _post(
    Map<String, dynamic> body, {
    bool isPublic = false,
  }) async {
    if (!isConfigured) return GasApiResponse.error('GAS URL غير مضبوط');

    final payload = Map<String, dynamic>.from(body);
    if (!isPublic && _sessionToken != null) {
      payload['sessionToken'] = _sessionToken;
    }

    final formBody = 'data=${Uri.encodeComponent(jsonEncode(payload))}';

    final client = HttpClient()
      ..connectionTimeout = _timeout
      ..idleTimeout = _timeout;

    try {
      // ── Step 1: POST to GAS ──────────────────────────────────────
      String currentUrl = _gasUrl!;
      HttpClientResponse? response;

      for (int redirectCount = 0; redirectCount < _maxRedirects; redirectCount++) {
        final uri = Uri.parse(currentUrl);
        late HttpClientRequest request;

        if (redirectCount == 0) {
          // First request is always POST
          request = await client
              .postUrl(uri)
              .timeout(_timeout);

          request.headers.set(
            HttpHeaders.contentTypeHeader,
            'application/x-www-form-urlencoded',
          );
          request.headers.set(
            HttpHeaders.contentLengthHeader,
            formBody.length.toString(),
          );
          request.write(formBody);
        } else {
          // After a redirect, GAS expects a GET
          request = await client
              .getUrl(uri)
              .timeout(_timeout);
        }

        request.headers.set(HttpHeaders.acceptHeader, 'application/json, */*');

        response = await request.close().timeout(_timeout);

        if (response.statusCode == HttpStatus.movedTemporarily ||
            response.statusCode == HttpStatus.found ||
            response.statusCode == HttpStatus.seeOther ||
            response.statusCode == HttpStatus.temporaryRedirect ||
            response.statusCode == HttpStatus.permanentRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null || location.isEmpty) {
            // Drain and close
            await response.drain<void>();
            return GasApiResponse.error(
                'خطأ في الاتصال: redirect بدون Location header');
          }
          // Drain current response body before following redirect
          await response.drain<void>();
          // Resolve relative URLs if needed
          currentUrl = Uri.parse(currentUrl).resolve(location).toString();
          continue;
        }

        // Non-redirect response — break and process
        break;
      }

      if (response == null) {
        return GasApiResponse.error('خطأ في الاتصال: لا توجد استجابة من الخادم');
      }

      // ── Step 2: Read response body ───────────────────────────────
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return GasApiResponse.error(
            'خطأ في الاتصال: ${response.statusCode}');
      }

      final rawBody = await response
          .transform(const Utf8Decoder(allowMalformed: true))
          .join()
          .timeout(_timeout);

      // ── Step 3: Parse JSON ───────────────────────────────────────
      dynamic json;
      try {
        json = jsonDecode(rawBody);
      } catch (_) {
        return GasApiResponse.error('خطأ في تحليل الاستجابة: الخادم لم يُعد JSON صحيحاً');
      }

      if (json is! Map) {
        return GasApiResponse.error('خطأ في الاستجابة: تنسيق غير متوقع');
      }

      if (json['ok'] == true) {
        return GasApiResponse(ok: true, data: json['data'] ?? json);
      } else {
        return GasApiResponse.error(
            json['error']?.toString() ?? 'خطأ غير معروف من الخادم');
      }
    } on TimeoutException {
      return GasApiResponse.error('انتهت مهلة الاتصال — تحقق من الاتصال بالإنترنت');
    } on SocketException catch (e) {
      return GasApiResponse.error('تعذّر الاتصال بالخادم: ${e.message}');
    } on HandshakeException {
      return GasApiResponse.error('خطأ في شهادة الأمان SSL');
    } catch (e) {
      return GasApiResponse.error('خطأ غير متوقع: $e');
    } finally {
      client.close(force: false);
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────

  Future<GasApiResponse> login(String email, String password) async {
    return _post(
      {'action': 'LOGIN', 'email': email, 'password': password},
      isPublic: true,
    );
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

  Future<GasApiResponse> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    return _post({
      'action': 'UPDATE_PROFILE',
      'uid': uid,
      'updates': jsonEncode(updates),
    });
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

  Future<GasApiResponse> updateSubscriptionConfig(
    Map<String, dynamic> config,
  ) async {
    return _post({
      'action': 'ADMIN_UPDATE_SUB_CONFIG',
      'config': jsonEncode(config),
    });
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

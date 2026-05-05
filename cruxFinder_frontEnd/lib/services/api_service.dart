import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const _tokenKey = 'auth_token';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _dio.options.headers.remove('Authorization');
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // ── Auth ──────────────────────────────────────────────

  /// 이메일 인증 코드 발송. 개발 모드면 응답에 devCode 포함.
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    final response = await _dio.post('/auth/send-code', data: {'email': email});
    return response.data;
  }

  /// 인증 코드 검증. 성공 시 {verified: true} 반환.
  Future<void> verifyEmailCode(String email, String code) async {
    await _dio.post('/auth/verify-code', data: {'email': email, 'code': code});
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String nickname,
    required String password,
  }) async {
    final response = await _dio.post('/users', data: {
      'email': email,
      'nickname': nickname,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['token'] as String;
    await saveToken(token);
    return response.data;
  }

  // ── Users ─────────────────────────────────────────────

  /// 닉네임 중복 확인. true = 사용 가능.
  Future<bool> checkNicknameAvailable(String nickname) async {
    final response = await _dio.get('/users/check-nickname', queryParameters: {'nickname': nickname});
    return response.data['available'] as bool;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/users/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateMe({String? nickname, String? newPassword}) async {
    final response = await _dio.patch('/users/me', data: {
      if (nickname != null) 'nickname': nickname,
      if (newPassword != null) 'newPassword': newPassword,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateBodyInfo({
    double? height,
    double? weight,
    double? armReach,
  }) async {
    final response = await _dio.patch('/users/me/body', data: {
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (armReach != null) 'armReach': armReach,
    });
    return response.data;
  }

  Future<bool> verifyPassword(String password) async {
    final response = await _dio.post('/users/verify-password', data: {'password': password});
    return response.data['verified'] as bool;
  }

  // ── Feeds ─────────────────────────────────────────────

  Future<List<dynamic>> getFeeds() async {
    final response = await _dio.get('/feeds');
    return response.data;
  }

  Future<Map<String, dynamic>> createFeed({
    required String memo,
    required DateTime climbedAt,
    required String vGrade,
    required String myDifficulty,
  }) async {
    final response = await _dio.post('/feeds', data: {
      'memo': memo,
      'climbedAt': climbedAt.toIso8601String(),
      'vGrade': vGrade,
      'myDifficulty': myDifficulty,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateFeed({
    required int feedId,
    required String memo,
    required DateTime climbedAt,
    required String vGrade,
    required String myDifficulty,
  }) async {
    final response = await _dio.patch('/feeds/$feedId', data: {
      'memo': memo,
      'climbedAt': climbedAt.toIso8601String(),
      'vGrade': vGrade,
      'myDifficulty': myDifficulty,
    });
    return response.data;
  }

  Future<void> deleteFeed(int feedId) async {
    await _dio.delete('/feeds/$feedId');
  }
}

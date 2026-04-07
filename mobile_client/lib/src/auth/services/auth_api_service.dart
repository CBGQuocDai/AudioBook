import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/auth/models/api_response.dart';
import 'package:mobile_client/src/auth/models/login_request.dart';
import 'package:mobile_client/src/auth/models/otp_request.dart';
import 'package:mobile_client/src/auth/models/reset_password_request.dart';
import 'package:mobile_client/src/auth/models/token_response.dart';
import 'package:mobile_client/src/auth/models/user_info.dart';
import 'package:mobile_client/src/auth/models/verify_otp_request.dart';
import 'package:mobile_client/src/core/config/app_config.dart';

class AuthApiService {
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  AuthApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<ApiResponse<TokenResponse>> login(LoginRequest request) async {
    final response = await _guardedRequest(
      'POST $baseUrl/auth/login',
      () => _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    final tokenResponse = TokenResponse.fromJson(data);

    return ApiResponse<TokenResponse>(
      code: _extractCode(body),
      data: tokenResponse,
      message: _extractMessage(body),
    );
  }

  Future<ApiResponse<void>> logout(String token) async {
    final response = await _guardedRequest(
      'DELETE $baseUrl/auth/logout',
      () => _client.delete(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    return ApiResponse<void>(
      code: _extractCode(body),
      message: _extractMessage(body),
    );
  }

  Future<ApiResponse<TokenResponse>> verifyOtp(VerifyOtpRequest request) async {
    final response = await _guardedRequest(
      'POST $baseUrl/auth/otp/verify',
      () => _client.post(
        Uri.parse('$baseUrl/auth/otp/verify'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    final tokenResponse = TokenResponse.fromJson(data);

    return ApiResponse<TokenResponse>(
      code: _extractCode(body),
      data: tokenResponse,
      message: _extractMessage(body),
    );
  }

  Future<ApiResponse<TokenResponse>> activeAccount(String token) async {
    final response = await _guardedRequest(
      'POST $baseUrl/auth/active',
      () => _client.post(
        Uri.parse('$baseUrl/auth/active'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    final tokenResponse = TokenResponse.fromJson(data);

    return ApiResponse<TokenResponse>(
      code: _extractCode(body),
      data: tokenResponse,
      message: _extractMessage(body),
    );
  }

  Future<ApiResponse<void>> requestOtp(OtpRequest request) async {
    final response = await _guardedRequest(
      'POST $baseUrl/auth/otp/request',
      () => _client.post(
        Uri.parse('$baseUrl/auth/otp/request'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    return ApiResponse<void>(
      code: _extractCode(body),
      message: _extractMessage(body),
    );
  }

  Future<ApiResponse<void>> forgotPassword(OtpRequest request) async {
    final response = await _guardedRequest(
      'POST $baseUrl/auth/forgot-password',
      () => _client.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    return ApiResponse<void>(
      code: _extractCode(body),
      message: _extractMessage(body),
    );
  }

  Future<ApiResponse<void>> resetPassword({
    required String token,
    required ResetPasswordRequest request,
  }) async {
    final response = await _guardedRequest(
      'POST $baseUrl/auth/reset-password',
      () => _client.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    return ApiResponse<void>(
      code: _extractCode(body),
      message: _extractMessage(body),
    );
  }

  Future<ApiResponse<UserInfo>> getCurrentUser(String token) async {
    final response = await _guardedRequest(
      'GET $baseUrl/client/me',
      () => _client.get(
        Uri.parse('$baseUrl/client/me'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    final userInfo = UserInfo.fromJson(data);

    return ApiResponse<UserInfo>(
      code: _extractCode(body),
      message: _extractMessage(body),
      data: userInfo,
    );
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final dynamic decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const AuthApiException('Response format không hợp lệ.');
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> body) {
    final dynamic data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  void _ensureSuccess(int statusCode, Map<String, dynamic> body) {
    if (statusCode < 200 || statusCode >= 300) {
      throw AuthApiException(_extractErrorMessage(body, statusCode));
    }

    final code = _extractCode(body);
    if (code != 1000) {
      throw AuthApiException(_extractErrorMessage(body, statusCode));
    }
  }

  int _extractCode(Map<String, dynamic> body) {
    final dynamic value = body['code'];
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 1000;
    }
    return 1000;
  }

  String _extractMessage(Map<String, dynamic> body) {
    return body['message']?.toString() ?? 'success';
  }

  String _extractErrorMessage(Map<String, dynamic> body, int statusCode) {
    return body['message']?.toString() ??
        body['error']?.toString() ??
        'Request thất bại ($statusCode).';
  }

  Future<http.Response> _guardedRequest(
    String endpoint,
    Future<http.Response> Function() request,
  ) async {
    try {
      log('[API][REQ] $endpoint');
      final response = await request();
      log('[API][RES] $endpoint => ${response.statusCode}');
      return response;
    } on SocketException {
      throw const AuthApiException(
        'Không thể kết nối máy chủ. Kiểm tra API đang chạy và base URL.',
      );
    } on http.ClientException catch (error) {
      throw AuthApiException('Lỗi kết nối: ${error.message}');
    }
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

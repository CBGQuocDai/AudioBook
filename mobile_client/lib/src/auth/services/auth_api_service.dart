import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/auth/models/api_response.dart';
import 'package:mobile_client/src/auth/models/avatar_file.dart';
import 'package:mobile_client/src/auth/models/change_password_request.dart';
import 'package:mobile_client/src/auth/models/login_request.dart';
import 'package:mobile_client/src/auth/models/otp_request.dart';
import 'package:mobile_client/src/auth/models/register_request.dart';
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

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<ApiResponse<void>> register(RegisterRequest request) async {
    final body = await _post('/client/register', data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  Future<ApiResponse<TokenResponse>> login(LoginRequest request) async {
    final body = await _post('/auth/login', data: request.toJson());
    return ApiResponse<TokenResponse>(
      code: body['code'],
      message: body['message'],
      data: TokenResponse.fromJson(body['data']),
    );
  }

  Future<ApiResponse<TokenResponse>> loginWithGoogle(String idToken) async {
    final body = await _post('/auth/login/google', data: {'idToken': idToken});
    return ApiResponse<TokenResponse>(
      code: body['code'],
      message: body['message'],
      data: TokenResponse.fromJson(body['data']),
    );
  }

  Future<ApiResponse<void>> logout(String token) async {
    final body = await _delete('/auth/logout', token: token);
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  Future<ApiResponse<TokenResponse>> verifyOtp(VerifyOtpRequest request) async {
    final body = await _post('/auth/otp/verify', data: request.toJson());
    return ApiResponse<TokenResponse>(
      code: body['code'],
      message: body['message'],
      data: TokenResponse.fromJson(body['data']),
    );
  }

  Future<ApiResponse<TokenResponse>> activeAccount(String token) async {
    final body = await _post('/auth/active', token: token);
    return ApiResponse<TokenResponse>(
      code: body['code'],
      message: body['message'],
      data: TokenResponse.fromJson(body['data']),
    );
  }

  Future<ApiResponse<void>> requestOtp(OtpRequest request) async {
    final body = await _post('/auth/otp/request', data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  Future<ApiResponse<void>> forgotPassword(OtpRequest request) async {
    final body = await _post('/auth/forgot-password', data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  Future<ApiResponse<void>> resetPassword({
    required String token,
    required ResetPasswordRequest request,
  }) async {
    final body = await _post('/auth/reset-password', token: token, data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  Future<ApiResponse<void>> changePassword({
    required String token,
    required ChangePasswordRequest request,
  }) async {
    final body = await _post('/auth/change-password', token: token, data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  Future<ApiResponse<UserInfo>> getCurrentUser(String token) async {
    final body = await _get('/client/me', token: token);
    return ApiResponse<UserInfo>(
      code: body['code'],
      message: body['message'],
      data: UserInfo.fromJson(body['data']),
    );
  }

  Future<ApiResponse<UserInfo>> changeUserName({
    required String token,
    required String name,
  }) async {
    final body = await _put('/client/change-name', token: token, data: {'name': name});
    return ApiResponse<UserInfo>(
      code: body['code'],
      message: body['message'],
      data: UserInfo.fromJson(body['data']),
    );
  }

  Future<ApiResponse<void>> preChangeEmail({
    required String token,
    required String newEmail,
  }) async {
    final body = await _post('/client/email/pre-change', token: token, data: {'newEmail': newEmail});
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  Future<ApiResponse<TokenResponse>> changeEmail({
    required String token,
    required String otp,
    required String newEmail,
  }) async {
    final body = await _put('/client/email/change', token: token, data: {
      'otp': otp,
      'newEmail': newEmail,
    });
    return ApiResponse<TokenResponse>(
      code: body['code'],
      message: body['message'],
      data: TokenResponse.fromJson(body['data']),
    );
  }

  Future<ApiResponse<AvatarFile>> uploadAvatarFile({
    required String token,
    required File file,
  }) async {
    final uri = Uri.parse('$baseUrl/files/upload').replace(queryParameters: {'type': 'image'});
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      log('[API][REQ] POST $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      log('[API][RES] POST $uri => ${response.statusCode}');

      final Map<String, dynamic> body = response.body.isEmpty ? {} : jsonDecode(response.body);
      _ensureSuccess(response.statusCode, body);

      return ApiResponse<AvatarFile>(
        code: body['code'],
        message: body['message'],
        data: AvatarFile.fromJson(body['data']),
      );
    } on SocketException {
      throw const AuthApiException('Khong the ket noi may chu.');
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Loi upload: $e');
    }
  }

  Future<ApiResponse<AvatarFile>> changeAvatar({
    required String token,
    required int fileId,
  }) async {
    final body = await _put('/client/avatar/change', token: token, data: {'id': fileId});
    return ApiResponse<AvatarFile>(
      code: body['code'],
      message: body['message'],
      data: AvatarFile.fromJson(body['data']),
    );
  }

  // Helper HTTP methods

  Future<Map<String, dynamic>> _get(String path, {String? token}) => _request('GET', path, token: token);
  Future<Map<String, dynamic>> _post(String path, {String? token, Map<String, dynamic>? data}) => _request('POST', path, token: token, data: data);
  Future<Map<String, dynamic>> _put(String path, {String? token, Map<String, dynamic>? data}) => _request('PUT', path, token: token, data: data);
  Future<Map<String, dynamic>> _delete(String path, {String? token}) => _request('DELETE', path, token: token);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? data,
  }) async {
    final url = '$baseUrl$path';
    try {
      log('[API][REQ] $method $url');
      final uri = Uri.parse(url);
      final headers = _headers(token);
      late http.Response response;

      if (method == 'POST') {
        response = await _client.post(uri, headers: headers, body: jsonEncode(data));
      } else if (method == 'PUT') {
        response = await _client.put(uri, headers: headers, body: jsonEncode(data));
      } else if (method == 'DELETE') {
        response = await _client.delete(uri, headers: headers);
      } else {
        response = await _client.get(uri, headers: headers);
      }

      log('[API][RES] $url => ${response.statusCode}');
      final Map<String, dynamic> body = response.body.isEmpty ? {} : jsonDecode(response.body);
      _ensureSuccess(response.statusCode, body);
      return body;
    } on SocketException {
      throw const AuthApiException('Khong the ket noi may chu.');
    } on http.ClientException catch (e) {
      throw AuthApiException('Loi ket noi: ${e.message}');
    } on FormatException {
      throw const AuthApiException('Dinh dang phan hoi khong hop le.');
    }
  }

  void _ensureSuccess(int statusCode, Map<String, dynamic> body) {
    if (statusCode < 200 || statusCode >= 300 || body['code'] != 1000) {
      throw AuthApiException(body['message']?.toString() ?? body['error']?.toString() ?? 'Request that bai ($statusCode)');
    }
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

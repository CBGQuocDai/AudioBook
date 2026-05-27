import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/auth/models/api_response.dart';
import 'package:mobile_client/src/auth/models/change_password_request.dart';
import 'package:mobile_client/src/auth/models/login_request.dart';
import 'package:mobile_client/src/auth/models/otp_request.dart';
import 'package:mobile_client/src/auth/models/reset_password_request.dart';
import 'package:mobile_client/src/auth/models/token_response.dart';
import 'package:mobile_client/src/auth/models/verify_otp_request.dart';
import 'package:mobile_client/src/core/config/app_config.dart';

/// Dịch vụ kết nối API xác thực (Authentication API Service).
///
/// Thực hiện các yêu cầu HTTP (POST, GET, DELETE) liên quan đến đăng nhập, đăng xuất, OTP và quản lý mật khẩu.
class AuthApiService {
  /// Địa chỉ API cơ sở mặc định được cấu hình trong [AppConfig].
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  /// Khởi tạo [AuthApiService] với [baseUrl] và một [http.Client] tùy chọn.
  AuthApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Địa chỉ API cơ sở của dịch vụ.
  final String baseUrl;
  final http.Client _client;

  /// Thiết lập các Header tiêu chuẩn cho các yêu cầu HTTP.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT token tùy chọn để đính kèm vào Header Authorization.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về bản đồ [Map<String, String>] chứa các key-value Header.
  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Gửi yêu cầu đăng nhập bằng tài khoản (email và mật khẩu).
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [request]: Đối tượng [LoginRequest] chứa email và mật khẩu.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<TokenResponse>>] chứa thông tin TokenResponse từ server.
  Future<ApiResponse<TokenResponse>> login(LoginRequest request) async {
    final body = await _post('/auth/login', data: request.toJson());
    return ApiResponse<TokenResponse>(
      code: body['code'],
      message: body['message'],
      data: TokenResponse.fromJson(body['data']),
    );
  }

  /// Gửi yêu cầu đăng nhập bằng Google ID Token.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [idToken]: Chuỗi ID Token lấy từ Google Sign-In SDK.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<TokenResponse>>] chứa thông tin TokenResponse tương ứng.
  Future<ApiResponse<TokenResponse>> loginWithGoogle(String idToken) async {
    final body = await _post('/auth/login/google', data: {'idToken': idToken});
    return ApiResponse<TokenResponse>(
      code: body['code'],
      message: body['message'],
      data: TokenResponse.fromJson(body['data']),
    );
  }

  /// Gửi yêu cầu đăng xuất để hủy phiên làm việc của token hiện tại trên Backend.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT token hiện tại đang đăng nhập.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<void>>] biểu thị trạng thái đăng xuất.
  Future<ApiResponse<void>> logout(String token) async {
    final body = await _delete('/auth/logout', token: token);
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  /// Xác thực mã OTP được gửi cho một mục đích cụ thể.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [request]: Đối tượng [VerifyOtpRequest] chứa mã OTP, email và mục đích OTP.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<TokenResponse>>] chứa token xác minh nếu OTP hợp lệ.
  Future<ApiResponse<TokenResponse>> verifyOtp(VerifyOtpRequest request) async {
    final body = await _post('/auth/otp/verify', data: request.toJson());
    return ApiResponse<TokenResponse>(
      code: body['code'],
      message: body['message'],
      data: TokenResponse.fromJson(body['data']),
    );
  }

  /// Kích hoạt tài khoản người dùng sau khi xác thực email thành công.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT token tạm thời được cấp sau khi xác minh OTP thành công.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<TokenResponse>>] chứa token chính thức.
  Future<ApiResponse<TokenResponse>> activeAccount(String token) async {
    final body = await _post('/auth/active', token: token);
    return ApiResponse<TokenResponse>(
      code: body['code'],
      message: body['message'],
      data: TokenResponse.fromJson(body['data']),
    );
  }

  /// Yêu cầu gửi lại mã OTP mới đến email người dùng.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [request]: Đối tượng [OtpRequest] chứa email nhận mã.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<void>>].
  Future<ApiResponse<void>> requestOtp(OtpRequest request) async {
    final body = await _post('/auth/otp/request', data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  /// Gửi yêu cầu quên mật khẩu để hệ thống gửi mã OTP khôi phục đến email.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [request]: Đối tượng [OtpRequest] chứa email cần đặt lại mật khẩu.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<void>>].
  Future<ApiResponse<void>> forgotPassword(OtpRequest request) async {
    final body = await _post('/auth/forgot-password', data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  /// Gửi yêu cầu đặt lại mật khẩu mới sử dụng token đặt lại mật khẩu.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: Token khôi phục mật khẩu tạm thời.
  ///   - [request]: Đối tượng [ResetPasswordRequest] chứa mật khẩu mới cần thiết lập.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<void>>].
  Future<ApiResponse<void>> resetPassword({
    required String token,
    required ResetPasswordRequest request,
  }) async {
    final body = await _post('/auth/reset-password', token: token, data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  /// Gửi yêu cầu đổi mật khẩu đối với người dùng đang đăng nhập.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT token của tài khoản đang đăng nhập hiện tại.
  ///   - [request]: Đối tượng [ChangePasswordRequest] chứa mật khẩu cũ và mật khẩu mới.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<void>>].
  Future<ApiResponse<void>> changePassword({
    required String token,
    required ChangePasswordRequest request,
  }) async {
    final body = await _post('/auth/change-password', token: token, data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  // Helper HTTP methods

  Future<Map<String, dynamic>> _get(String path, {String? token}) => _request('GET', path, token: token);
  Future<Map<String, dynamic>> _post(String path, {String? token, Map<String, dynamic>? data}) => _request('POST', path, token: token, data: data);
  Future<Map<String, dynamic>> _delete(String path, {String? token}) => _request('DELETE', path, token: token);

  /// Phương thức cơ sở xử lý việc gửi yêu cầu mạng HTTP và kiểm tra lỗi.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [method]: Phương thức HTTP (GET, POST, DELETE).
  ///   - [path]: Đường dẫn API endpoint.
  ///   - [token]: JWT token (nếu cần xác thực).
  ///   - [data]: Dữ liệu body gửi kèm dưới dạng Map (cho POST).
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<Map<String, dynamic>>] chứa dữ liệu JSON giải mã từ server.
  /// * **Ngoại lệ (Exception):**
  ///   - Ném ra [AuthApiException] nếu xảy ra lỗi kết nối hoặc mã phản hồi không thành công.
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

  /// Đảm bảo rằng yêu cầu API trả về mã trạng thái thành công và mã code nghiệp vụ là 1000.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [statusCode]: Mã trạng thái HTTP (2xx, 4xx, 5xx...).
  ///   - [body]: Dữ liệu phản hồi dạng Map.
  /// * **Ngoại lệ (Exception):**
  ///   - Ném ra [AuthApiException] nếu yêu cầu thất bại.
  void _ensureSuccess(int statusCode, Map<String, dynamic> body) {
    if (statusCode < 200 || statusCode >= 300 || body['code'] != 1000) {
      throw AuthApiException(body['message']?.toString() ?? body['error']?.toString() ?? 'Request that bai ($statusCode)');
    }
  }
}

/// Ngoại lệ tùy chỉnh đại diện cho các lỗi xảy ra trong quá trình gọi Auth API.
class AuthApiException implements Exception {
  /// Khởi tạo [AuthApiException] với thông điệp mô tả lỗi.
  const AuthApiException(this.message);

  /// Thông điệp lỗi chi tiết.
  final String message;

  @override
  String toString() => message;
}

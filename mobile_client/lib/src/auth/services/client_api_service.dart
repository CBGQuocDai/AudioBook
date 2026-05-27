import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/auth/models/api_response.dart';
import 'package:mobile_client/src/auth/models/avatar_file.dart';
import 'package:mobile_client/src/auth/models/register_request.dart';
import 'package:mobile_client/src/auth/models/token_response.dart';
import 'package:mobile_client/src/auth/models/user_info.dart';
import 'package:mobile_client/src/core/config/app_config.dart';

/// Dịch vụ kết nối API quản lý thông tin khách hàng (Client API Service).
///
/// Thực hiện các thao tác đăng ký, lấy thông tin cá nhân hiện tại, thay đổi thông tin (tên hiển thị, email, ảnh đại diện) và tải lên tệp ảnh.
class ClientApiService {
  /// Địa chỉ API cơ sở mặc định cấu hình từ [AppConfig].
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  /// Khởi tạo [ClientApiService] với [baseUrl] và một [http.Client] tùy chọn.
  ClientApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Địa chỉ API cơ sở của dịch vụ.
  final String baseUrl;
  final http.Client _client;

  /// Thiết lập các Header tiêu chuẩn cho các yêu cầu HTTP.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT token tùy chọn dùng để xác thực.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Map<String, String>] chứa thông tin Header.
  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Đăng ký tài khoản khách hàng mới.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [request]: Đối tượng [RegisterRequest] chứa thông tin đăng ký (tên, email, mật khẩu).
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<void>>] kết quả đăng ký từ server.
  Future<ApiResponse<void>> register(RegisterRequest request) async {
    final body = await _post('/client/register', data: request.toJson());
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  /// Lấy thông tin cá nhân của người dùng hiện tại dựa trên JWT Token.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token của người dùng.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<UserInfo>>] chứa thông tin tài khoản đầy đủ.
  Future<ApiResponse<UserInfo>> getCurrentUser(String token) async {
    final body = await _get('/client/me', token: token);
    return ApiResponse<UserInfo>(
      code: body['code'],
      message: body['message'],
      data: UserInfo.fromJson(body['data']),
    );
  }

  /// Thay đổi tên hiển thị của khách hàng hiện tại.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token của người dùng.
  ///   - [name]: Tên hiển thị mới muốn đổi.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<UserInfo>>] chứa thông tin tài khoản đã cập nhật.
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

  /// Gửi yêu cầu chuẩn bị thay đổi email (sinh mã OTP gửi tới email mới).
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token xác thực phiên đăng nhập hiện tại.
  ///   - [newEmail]: Địa chỉ email mới muốn thay thế.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<void>>].
  Future<ApiResponse<void>> preChangeEmail({
    required String token,
    required String newEmail,
  }) async {
    final body = await _post('/client/email/pre-change', token: token, data: {'newEmail': newEmail});
    return ApiResponse<void>(code: body['code'], message: body['message']);
  }

  /// Gửi yêu cầu thay đổi email chính thức sau khi nhận được mã OTP xác thực tại email mới.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token hiện tại.
  ///   - [otp]: Mã OTP nhận được ở email mới.
  ///   - [newEmail]: Địa chỉ email mới muốn thay đổi.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<TokenResponse>>] chứa thông tin Token mới do thay đổi email làm phiên đăng nhập thay đổi.
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

  /// Tải tệp tin ảnh từ thiết bị lên hệ thống Backend (sử dụng Multipart HTTP).
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token người dùng.
  ///   - [file]: Đối tượng [File] ảnh cần tải lên.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<AvatarFile>>] chứa thông tin tệp tin đã lưu trữ thành công trên server.
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
      throw const ClientApiException('Khong the ket noi may chu.');
    } catch (e) {
      if (e is ClientApiException) rethrow;
      throw ClientApiException('Loi upload: $e');
    }
  }

  /// Cập nhật ảnh đại diện của người dùng sử dụng ID của tệp tin đã tải lên thành công trước đó.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token của người dùng.
  ///   - [fileId]: ID tệp tin ảnh đại diện mới.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<ApiResponse<AvatarFile>>] chứa thông tin tệp tin ảnh đại diện mới.
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

  /// Phương thức xử lý chung gửi yêu cầu HTTP và kiểm tra phản hồi từ Backend.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [method]: Phương thức HTTP (GET, POST, PUT).
  ///   - [path]: Đường dẫn API endpoint cần gọi.
  ///   - [token]: Token xác thực.
  ///   - [data]: Dữ liệu gửi kèm ở dạng Map.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về bản đồ [Future<Map<String, dynamic>>] kết quả JSON.
  /// * **Ngoại lệ (Exception):**
  ///   - Ném ra [ClientApiException] nếu yêu cầu thất bại.
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
      } else {
        response = await _client.get(uri, headers: headers);
      }

      log('[API][RES] $url => ${response.statusCode}');
      final Map<String, dynamic> body = response.body.isEmpty ? {} : jsonDecode(response.body);
      _ensureSuccess(response.statusCode, body);
      return body;
    } on SocketException {
      throw const ClientApiException('Khong the ket noi may chu.');
    } on http.ClientException catch (e) {
      throw ClientApiException('Loi ket noi: ${e.message}');
    } on FormatException {
      throw const ClientApiException('Dinh dang phan hoi khong hop le.');
    }
  }

  /// Đảm bảo yêu cầu API thành công (HTTP status 2xx và code nghiệp vụ 1000).
  void _ensureSuccess(int statusCode, Map<String, dynamic> body) {
    if (statusCode < 200 || statusCode >= 300 || body['code'] != 1000) {
      throw ClientApiException(body['message']?.toString() ?? body['error']?.toString() ?? 'Request that bai ($statusCode)');
    }
  }
}

/// Ngoại lệ tùy chỉnh xảy ra trong quá trình tương tác với Client API.
class ClientApiException implements Exception {
  /// Khởi tạo [ClientApiException] với thông điệp lỗi cụ thể.
  const ClientApiException(this.message);

  /// Thông điệp lỗi chi tiết.
  final String message;

  @override
  String toString() => message;
}

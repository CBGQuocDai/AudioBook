import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/core/config/app_config.dart';
import 'package:mobile_client/src/payment/models/subscription_info.dart';

import '../models/payment_models.dart';

/// Dịch vụ kết nối API thanh toán và đăng ký gói (Payment API Service).
///
/// Xử lý các yêu cầu liên quan đến tạo Payment Intent với Stripe, kiểm tra trạng thái thanh toán, mua xu/credit, và đăng ký/hủy gói hội viên.
class PaymentApiService {
  /// Địa chỉ API cơ sở mặc định cấu hình từ [AppConfig].
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  /// Khởi tạo [PaymentApiService] với [baseUrl] và một [http.Client] tùy chọn.
  PaymentApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Địa chỉ API cơ sở của dịch vụ.
  final String baseUrl;
  final http.Client _client;

  /// Thiết lập các Header tiêu chuẩn cho các yêu cầu HTTP.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT token xác thực phiên người dùng.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về bản đồ [Map<String, String>] chứa các Header.
  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  /// Thực hiện khảo sát (Polling) kiểm tra trạng thái giao dịch thanh toán trên máy chủ cho tới khi đạt trạng thái cuối cùng (thành công, thất bại...).
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token của người dùng.
  ///   - [paymentId]: ID giao dịch cần kiểm tra.
  ///   - [maxAttempts]: Số lần thử tối đa. Mặc định là 6 lần.
  ///   - [interval]: Khoảng thời gian nghỉ giữa các lần thử. Mặc định là 2 giây.
  ///   - [onUpdate]: Hàm callback kích hoạt mỗi lần có cập nhật thông tin giao dịch mới.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<PaymentDetailResponse>] chứa thông tin chi tiết giao dịch ở trạng thái cuối.
  /// * **Ngoại lệ (Exception):**
  ///   - Ném ra [PaymentApiException] nếu vượt quá số lần thử hoặc xảy ra lỗi API.
  Future<PaymentDetailResponse> waitForPaymentStatus({
    required String token,
    required int paymentId,
    int maxAttempts = 6,
    Duration interval = const Duration(seconds: 2),
    void Function(PaymentDetailResponse)? onUpdate,
  }) async {
    PaymentDetailResponse? latest;
    
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) await Future.delayed(interval);

      try {
        latest = await getPaymentDetail(token: token, paymentId: paymentId);
        if (onUpdate != null) onUpdate(latest);

        if (latest.isFinalStatus) return latest;
      } on PaymentApiException catch (e) {
        // If payment not found yet, it might be a sync delay, continue polling.
        if (!e.message.toLowerCase().contains('not found') || attempt == maxAttempts - 1) {
          rethrow;
        }
      }
    }

    if (latest == null) {
      throw const PaymentApiException('Khong the lay thong tin thanh toan.');
    }
    return latest;
  }

  /// Tạo ý định thanh toán Stripe Payment Intent để Frontend tiến hành thanh toán đơn hàng.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token của người dùng.
  ///   - [orderId]: ID đơn hàng cần thanh toán.
  ///   - [userId]: ID khách hàng.
  ///   - [amount]: Số tiền cần thanh toán.
  ///   - [currency]: Tiền tệ (ví dụ: 'usd').
  ///   - [paymentMethod]: Phương thức thanh toán (ví dụ: 'CARD').
  ///   - [idempotencyKey]: Khóa chống trùng lặp gửi yêu cầu.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<CreateStripeIntentResponse>] chứa khóa bí mật client_secret và mã giao dịch.
  Future<CreateStripeIntentResponse> createStripeIntent({
    required String token,
    required String orderId,
    required String userId,
    required int amount,
    required String currency,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    final body = await _post(
      '/payments/stripe/create-intent',
      token: token,
      data: {
        'orderId': orderId,
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'idempotencyKey': idempotencyKey,
      },
    );
    return CreateStripeIntentResponse.fromJson(body);
  }

  /// Lấy thông tin chi tiết của một giao dịch thanh toán bằng ID.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token người dùng.
  ///   - [paymentId]: ID giao dịch thanh toán.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<PaymentDetailResponse>] mô tả chi tiết giao dịch.
  Future<PaymentDetailResponse> getPaymentDetail({
    required String token,
    required int paymentId,
  }) async {
    final body = await _get('/payments/$paymentId', token: token);
    return PaymentDetailResponse.fromJson(body);
  }

  /// Lấy thông tin gói đăng ký hội viên hiện tại của người dùng cùng lịch sử hóa đơn.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token người dùng.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<SubscriptionInfo>] thông tin gói đăng ký và lịch sử.
  Future<SubscriptionInfo> getSubscriptionInfo({required String token}) async {
    final body = await _get('/subscription', token: token);
    return SubscriptionInfo.fromJson(body);
  }

  /// Tạo ý định thanh toán Stripe Payment Intent để phục vụ cho việc mua gói nạp xu/credit.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token người dùng.
  ///   - [creditPlanId]: ID của gói credit muốn mua.
  ///   - [paymentMethod]: Phương thức thanh toán (ví dụ: 'CARD').
  ///   - [idempotencyKey]: Khóa chống trùng lặp.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<CreateStripeIntentResponse>].
  Future<CreateStripeIntentResponse> createCreditPurchaseIntent({
    required String token,
    required int creditPlanId,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    final body = await _post(
      '/credit-plan/purchase-intent',
      token: token,
      data: {
        'creditPlanId': creditPlanId,
        'paymentMethod': paymentMethod,
        'idempotencyKey': idempotencyKey,
      },
    );
    return CreateStripeIntentResponse.fromJson(body);
  }

  /// Xác nhận việc hoàn tất giao dịch mua credit trên máy chủ sau khi thanh toán trên cổng Stripe hoàn tất.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token người dùng.
  ///   - [paymentId]: ID giao dịch thanh toán tương ứng.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<PaymentDetailResponse>] mô tả chi tiết giao dịch đã cập nhật.
  Future<PaymentDetailResponse> confirmCreditPurchase({
    required String token,
    required int paymentId,
  }) async {
    final body = await _post(
      '/credit-plan/purchase-confirm',
      token: token,
      data: {'paymentId': paymentId},
    );
    return PaymentDetailResponse.fromJson(body);
  }

  /// Kích hoạt gói đăng ký hội viên của người dùng sau khi giao dịch thanh toán gói thành công.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token người dùng.
  ///   - [planId]: ID gói hội viên đăng ký.
  ///   - [paymentId]: ID giao dịch thanh toán thành công của gói.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  Future<void> subscribe({
    required String token,
    required int planId,
    required int paymentId,
  }) async {
    await _post(
      '/subscription',
      token: token,
      data: {'planId': planId, 'paymentId': paymentId},
    );
  }

  /// Hủy bỏ gói đăng ký hội viên hiện tại của người dùng.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [token]: JWT Token người dùng.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  Future<void> unsubscribe({required String token}) async {
    await _delete('/subscription', token: token);
  }

  // Helper HTTP methods to reduce boilerplate

  Future<Map<String, dynamic>> _get(String path, {String? token}) {
    return _request('GET', path, token: token);
  }

  Future<Map<String, dynamic>> _post(String path, {String? token, Map<String, dynamic>? data}) {
    return _request('POST', path, token: token, data: data);
  }

  Future<Map<String, dynamic>> _delete(String path, {String? token}) {
    return _request('DELETE', path, token: token);
  }

  /// Phương thức chung xử lý gửi yêu cầu HTTP và lọc dữ liệu JSON phản hồi.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [method]: Phương thức HTTP (GET, POST, DELETE).
  ///   - [path]: Đường dẫn endpoint cần gọi.
  ///   - [token]: JWT Token xác thực.
  ///   - [data]: Dữ liệu body gửi kèm.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<Map<String, dynamic>>] chứa dữ liệu giải mã hoặc data map.
  /// * **Ngoại lệ (Exception):**
  ///   - Ném ra [PaymentApiException] nếu yêu cầu thất bại hoặc lỗi kết nối.
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
      switch (method) {
        case 'POST':
          response = await _client.post(uri, headers: headers, body: jsonEncode(data));
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          response = await _client.get(uri, headers: headers);
      }

      log('[API][RES] $url => ${response.statusCode}');
      
      final Map<String, dynamic> body = response.body.isEmpty 
          ? {} 
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300 || body['code'] != 1000) {
        throw PaymentApiException(
          body['message']?.toString() ?? body['error']?.toString() ?? 'Request that bai ($method $path)',
        );
      }

      final result = body['data'];
      if (result is Map<String, dynamic>) return result;
      return body;
    } on SocketException {
      throw const PaymentApiException('Khong the ket noi may chu.');
    } on http.ClientException catch (e) {
      throw PaymentApiException('Loi ket noi: ${e.message}');
    } on FormatException {
      throw const PaymentApiException('Response format khong hop le.');
    }
  }
}

/// Ngoại lệ tùy chỉnh xảy ra trong quá trình tương tác với hệ thống Payment API.
class PaymentApiException implements Exception {
  /// Khởi tạo [PaymentApiException] với thông điệp mô tả lỗi cụ thể.
  const PaymentApiException(this.message);

  /// Thông điệp lỗi chi tiết.
  final String message;

  @override
  String toString() => message;
}

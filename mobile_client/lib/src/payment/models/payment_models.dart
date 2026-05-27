/// Lớp mô tả thông tin phản hồi khi tạo một Payment Intent từ Stripe.
///
/// Chứa thông tin mã định danh thanh toán, trạng thái thanh toán và clientSecret của Stripe để tiến hành xác thực phía Frontend.
class CreateStripeIntentResponse {
  /// ID giao dịch thanh toán trong hệ thống Backend.
  final int paymentId;

  /// Mã code giao dịch thanh toán hiển thị cho người dùng.
  final String paymentCode;

  /// Trạng thái của giao dịch (Ví dụ: 'PENDING', 'SUCCESS').
  final String status;

  /// Nhà cung cấp thanh toán (Ví dụ: 'STRIPE').
  final String provider;

  /// Phương thức thanh toán (Ví dụ: 'CARD').
  final String method;

  /// Mã định danh Payment Intent do Stripe cung cấp.
  final String stripePaymentIntentId;

  /// Khóa bí mật client_secret dùng để khởi tạo Stripe SDK trên mobile xác nhận thanh toán.
  final String clientSecret;

  /// Thông điệp mô tả kết quả tạo giao dịch.
  final String message;

  /// Khởi tạo [CreateStripeIntentResponse].
  const CreateStripeIntentResponse({
    required this.paymentId,
    required this.paymentCode,
    required this.status,
    required this.provider,
    required this.method,
    required this.stripePaymentIntentId,
    required this.clientSecret,
    required this.message,
  });

  /// Tạo đối tượng [CreateStripeIntentResponse] từ dữ liệu JSON.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [json]: Bản đồ JSON chứa thông tin Stripe Payment Intent phản hồi từ API.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [CreateStripeIntentResponse].
  factory CreateStripeIntentResponse.fromJson(Map<String, dynamic> json) {
    final paymentIntentId = json['stripePaymentIntentId']?.toString() ??
        json['stripe_payment_intent_id']?.toString() ??
        json['paymentIntentId']?.toString() ??
        json['payment_intent_id']?.toString() ??
        '';

    return CreateStripeIntentResponse(
      paymentId: json['paymentId'] is int
          ? json['paymentId'] as int
          : int.tryParse('${json['paymentId']}') ?? 0,
      paymentCode: json['paymentCode']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      stripePaymentIntentId: paymentIntentId,
      clientSecret: json['clientSecret']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}

/// Lớp mô tả thông tin chi tiết của một giao dịch thanh toán trong hệ thống.
class PaymentDetailResponse {
  /// ID giao dịch thanh toán trong cơ sở dữ liệu.
  final int paymentId;

  /// Mã hiển thị giao dịch.
  final String paymentCode;

  /// ID của đơn hàng liên kết (nếu có).
  final String orderId;

  /// ID người dùng thực hiện thanh toán.
  final String userId;

  /// Nhà cung cấp thanh toán.
  final String provider;

  /// Phương thức thực hiện thanh toán.
  final int amount;

  /// Đơn vị tiền tệ của số tiền thanh toán (ví dụ: 'usd', 'vnd').
  final String currency;

  /// Trạng thái hiện tại của giao dịch thanh toán (ví dụ: 'SUCCESS', 'FAILED', 'PENDING').
  final String status;

  /// Mã định danh Payment Intent của Stripe.
  final String stripePaymentIntentId;

  /// Khóa chống trùng lặp yêu cầu thanh toán (Idempotency Key).
  final String idempotencyKey;

  /// Lý do thất bại của giao dịch (nếu có).
  final String failureReason;

  /// Thời gian giao dịch được tạo trên hệ thống.
  final String createdAt;

  /// Thời gian giao dịch cập nhật trạng thái gần nhất.
  final String updatedAt;

  /// Khởi tạo [PaymentDetailResponse].
  const PaymentDetailResponse({
    required this.paymentId,
    required this.paymentCode,
    required this.orderId,
    required this.userId,
    required this.provider,
    required this.method,
    required this.amount,
    required this.currency,
    required this.status,
    required this.stripePaymentIntentId,
    required this.idempotencyKey,
    required this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Getter kiểm tra xem giao dịch đã ở trạng thái kết quả cuối cùng chưa (Thành công, Thất bại hoặc Bị hủy).
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [bool] xác định trạng thái cuối cùng của giao dịch.
  bool get isFinalStatus =>
      status == 'SUCCESS' || status == 'FAILED' || status == 'CANCELED';

  /// Tạo đối tượng [PaymentDetailResponse] từ dữ liệu JSON.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [json]: Bản đồ JSON chứa thông tin chi tiết giao dịch.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [PaymentDetailResponse].
  factory PaymentDetailResponse.fromJson(Map<String, dynamic> json) {
    final paymentIntentId = json['stripePaymentIntentId']?.toString() ??
        json['stripe_payment_intent_id']?.toString() ??
        json['paymentIntentId']?.toString() ??
        json['payment_intent_id']?.toString() ??
        '';

    return PaymentDetailResponse(
      paymentId: json['paymentId'] is int
          ? json['paymentId'] as int
          : int.tryParse('${json['paymentId']}') ?? 0,
      paymentCode: json['paymentCode']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse('${json['amount']}') ?? 0,
      currency: json['currency']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      stripePaymentIntentId: paymentIntentId,
      idempotencyKey: json['idempotencyKey']?.toString() ?? '',
      failureReason: json['failureReason']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

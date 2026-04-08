class CreateStripeIntentResponse {
  final int paymentId;
  final String paymentCode;
  final String status;
  final String provider;
  final String method;
  final String stripePaymentIntentId;
  final String clientSecret;
  final String message;

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

class PaymentDetailResponse {
  final int paymentId;
  final String paymentCode;
  final String orderId;
  final String userId;
  final String provider;
  final String method;
  final int amount;
  final String currency;
  final String status;
  final String stripePaymentIntentId;
  final String idempotencyKey;
  final String failureReason;
  final String createdAt;
  final String updatedAt;

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

class MockConfirmResponse {
  final int paymentId;
  final String status;
  final String failureReason;
  final String updatedAt;

  const MockConfirmResponse({
    required this.paymentId,
    required this.status,
    required this.failureReason,
    required this.updatedAt,
  });

  factory MockConfirmResponse.fromJson(Map<String, dynamic> json) {
    return MockConfirmResponse(
      paymentId: json['paymentId'] is int
          ? json['paymentId'] as int
          : int.tryParse('${json['paymentId']}') ?? 0,
      status: json['status']?.toString() ?? '',
      failureReason: json['failureReason']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

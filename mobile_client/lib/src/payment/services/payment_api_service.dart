import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/core/config/app_config.dart';
import 'package:mobile_client/src/payment/models/credit_plan.dart';
import 'package:mobile_client/src/payment/models/subscription_info.dart';

import '../models/payment_models.dart';

class PaymentApiService {
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  PaymentApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<CreateStripeIntentResponse> createStripeIntent({
    required String token,
    required String orderId,
    required String userId,
    required int amount,
    required String currency,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    final response = await _guardedRequest(
      'POST $baseUrl/payments/stripe/create-intent',
      () => _client.post(
        Uri.parse('$baseUrl/payments/stripe/create-intent'),
        headers: _headers(token),
        body: jsonEncode({
          'orderId': orderId,
          'userId': userId,
          'amount': amount,
          'currency': currency,
          'paymentMethod': paymentMethod,
          'idempotencyKey': idempotencyKey,
        }),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    return CreateStripeIntentResponse.fromJson(data);
  }

  Future<MockConfirmResponse> mockConfirm({
    required String token,
    required int paymentId,
    required String result,
    String? failureReason,
  }) async {
    final response = await _guardedRequest(
      'POST $baseUrl/payments/stripe/mock-confirm',
      () => _client.post(
        Uri.parse('$baseUrl/payments/stripe/mock-confirm'),
        headers: _headers(token),
        body: jsonEncode({
          'paymentId': paymentId,
          'result': result,
          if (failureReason != null && failureReason.trim().isNotEmpty)
            'failureReason': failureReason,
        }),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    return MockConfirmResponse.fromJson(data);
  }

  Future<PaymentDetailResponse> getPaymentDetail({
    required String token,
    required int paymentId,
  }) async {
    final response = await _guardedRequest(
      'GET $baseUrl/payments/$paymentId',
      () => _client.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: _headers(token),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    return PaymentDetailResponse.fromJson(data);
  }

  Future<SubscriptionInfo> getSubscriptionInfo({
    required String token,
  }) async {
    final response = await _guardedRequest(
      'GET $baseUrl/subscription',
      () => _client.get(
        Uri.parse('$baseUrl/subscription'),
        headers: _headers(token),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    return SubscriptionInfo.fromJson(data);
  }

  Future<List<CreditPlanModel>> getCreditPlans({
    required String token,
  }) async {
    final response = await _guardedRequest(
      'GET $baseUrl/credit-plan',
      () => _client.get(
        Uri.parse('$baseUrl/credit-plan'),
        headers: _headers(token),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    return _extractDataList(body)
        .whereType<Map<String, dynamic>>()
        .map(CreditPlanModel.fromJson)
        .toList();
  }

  Future<CreateStripeIntentResponse> createCreditPurchaseIntent({
    required String token,
    required int creditPlanId,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    final response = await _guardedRequest(
      'POST $baseUrl/credit-plan/purchase-intent',
      () => _client.post(
        Uri.parse('$baseUrl/credit-plan/purchase-intent'),
        headers: _headers(token),
        body: jsonEncode({
          'creditPlanId': creditPlanId,
          'paymentMethod': paymentMethod,
          'idempotencyKey': idempotencyKey,
        }),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    return CreateStripeIntentResponse.fromJson(data);
  }

  Future<PaymentDetailResponse> confirmCreditPurchase({
    required String token,
    required int paymentId,
  }) async {
    final response = await _guardedRequest(
      'POST $baseUrl/credit-plan/purchase-confirm',
      () => _client.post(
        Uri.parse('$baseUrl/credit-plan/purchase-confirm'),
        headers: _headers(token),
        body: jsonEncode({'paymentId': paymentId}),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);

    final data = _extractData(body);
    return PaymentDetailResponse.fromJson(data);
  }

  Future<void> subscribe({
    required String token,
    required int planId,
  }) async {
    final response = await _guardedRequest(
      'POST $baseUrl/subscription',
      () => _client.post(
        Uri.parse('$baseUrl/subscription'),
        headers: _headers(token),
        body: jsonEncode({'planId': planId}),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);
  }

  Future<void> unsubscribe({
    required String token,
  }) async {
    final response = await _guardedRequest(
      'DELETE $baseUrl/subscription',
      () => _client.delete(
        Uri.parse('$baseUrl/subscription'),
        headers: _headers(token),
      ),
    );

    final body = _decodeJson(response.body);
    _ensureSuccess(response.statusCode, body);
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final dynamic decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const PaymentApiException('Response format khong hop le.');
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> body) {
    final dynamic data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractDataList(Map<String, dynamic> body) {
    final dynamic data = body['data'];
    if (data is List<dynamic>) {
      return data;
    }
    return const <dynamic>[];
  }

  void _ensureSuccess(int statusCode, Map<String, dynamic> body) {
    if (statusCode < 200 || statusCode >= 300) {
      throw PaymentApiException(_extractErrorMessage(body, statusCode));
    }

    final code = _extractCode(body);
    if (code != 1000) {
      throw PaymentApiException(_extractErrorMessage(body, statusCode));
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

  String _extractErrorMessage(Map<String, dynamic> body, int statusCode) {
    return body['message']?.toString() ??
        body['error']?.toString() ??
        'Request that bai ($statusCode).';
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
      throw const PaymentApiException(
        'Khong the ket noi may chu. Kiem tra API dang chay va base URL.',
      );
    } on http.ClientException catch (error) {
      throw PaymentApiException('Loi ket noi: ${error.message}');
    }
  }
}

class PaymentApiException implements Exception {
  const PaymentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

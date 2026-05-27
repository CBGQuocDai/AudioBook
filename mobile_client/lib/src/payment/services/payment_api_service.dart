import 'dart:async';
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

  /// Main method for polling payment status until it reaches a final state.
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

  Future<PaymentDetailResponse> getPaymentDetail({
    required String token,
    required int paymentId,
  }) async {
    final body = await _get('/payments/$paymentId', token: token);
    return PaymentDetailResponse.fromJson(body);
  }

  Future<SubscriptionInfo> getSubscriptionInfo({required String token}) async {
    final body = await _get('/subscription', token: token);
    return SubscriptionInfo.fromJson(body);
  }

  Future<List<CreditPlanModel>> getCreditPlans({required String token}) async {
    final body = await _get('/credit-plan', token: token);
    final data = body['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(CreditPlanModel.fromJson).toList();
    }
    return [];
  }

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

class PaymentApiException implements Exception {
  const PaymentApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

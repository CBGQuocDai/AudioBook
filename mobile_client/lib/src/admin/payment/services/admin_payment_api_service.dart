import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../user/models/api_response.dart';
import '../../user/models/page_response.dart';
import '../../../payment/models/payment_models.dart';

class AdminPaymentApiService {
  final String baseUrl;
  final Future<String?> Function() getAccessToken;

  AdminPaymentApiService({
    required this.baseUrl,
    required this.getAccessToken,
  });

  Future<Map<String, String>> _headers() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body);
  }

  Exception _buildException(http.Response response) {
    try {
      final body = _decodeResponse(response);
      if (body is Map<String, dynamic>) {
        return Exception(body['message'] ?? 'Request failed');
      }
      return Exception('Request failed');
    } catch (_) {
      return Exception('Request failed: ${response.statusCode}');
    }
  }

  Future<PageResponse<PaymentDetailResponse>> getPaymentLogs({
    int page = 0,
    int size = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/payments/logs').replace(
      queryParameters: {
        'page': '$page',
        'size': '$size',
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = _decodeResponse(response) as Map<String, dynamic>;
      final apiResponse = ApiResponse<PageResponse<PaymentDetailResponse>>.fromJson(
        body,
        (data) => PageResponse<PaymentDetailResponse>.fromJson(
          data as Map<String, dynamic>,
          PaymentDetailResponse.fromJson,
        ),
      );
      return apiResponse.data;
    }

    throw _buildException(response);
  }
}

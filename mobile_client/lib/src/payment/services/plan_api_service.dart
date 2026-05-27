import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_client/src/core/config/app_config.dart';
import 'package:mobile_client/src/payment/models/credit_plan.dart';
import 'package:mobile_client/src/payment/models/plan.dart';

class PlanApiService {
  static const String defaultBaseUrl = AppConfig.apiBaseUrl;

  PlanApiService({
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

  /// Lấy danh sách gói hội viên (Premium Plans)
  Future<List<PlanModel>> getPlans({String? token}) async {
    final response = await _get('/plans', token: token);
    // Bóc tách mảng từ field 'data' theo cấu trúc: { "code": 1000, "message": "success", "data": [...] }
    final List<dynamic> data = response['data'] is List ? response['data'] : [];
    return data.whereType<Map<String, dynamic>>().map(PlanModel.fromJson).toList();
  }

  /// Lấy danh sách gói Credit
  Future<List<CreditPlanModel>> getCreditPlans({String? token}) async {
    final response = await _get('/credit-plan', token: token);
    // Tương tự cho credit-plans
    final List<dynamic> data = response['data'] is List ? response['data'] : [];
    return data.whereType<Map<String, dynamic>>().map(CreditPlanModel.fromJson).toList();
  }

  // Helper HTTP methods

  Future<Map<String, dynamic>> _get(String path, {String? token}) => 
      _request('GET', path, token: token);

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
      } else {
        response = await _client.get(uri, headers: headers);
      }

      log('[API][RES] $url => ${response.statusCode}');
      final Map<String, dynamic> body = response.body.isEmpty ? {} : jsonDecode(response.body);
      
      if (response.statusCode < 200 || response.statusCode >= 300 || body['code'] != 1000) {
        throw Exception(body['message']?.toString() ?? 'Request thất bại (${response.statusCode})');
      }
      return body;
    } on SocketException {
      throw const SocketException('Không thể kết nối máy chủ.');
    } catch (e) {
      rethrow;
    }
  }
}

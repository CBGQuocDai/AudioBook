import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/payment/models/payment_models.dart';
import 'package:mobile_client/src/payment/services/payment_api_service.dart';

class BuyCreditScreen extends StatefulWidget {
  const BuyCreditScreen({super.key});

  @override
  State<BuyCreditScreen> createState() => _BuyCreditScreenState();
}

class _BuyCreditScreenState extends State<BuyCreditScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: PaymentApiService.defaultBaseUrl,
  );

  final TokenStorageService _tokenStorageService = TokenStorageService();

  late final PaymentApiService _paymentApiService;

  final List<int> _creditPackages = [50000, 100000, 200000, 500000];

  int _selectedAmount = 100000;
  String _selectedMethod = 'CARD';
  bool _isLoading = false;
  bool _isLoadingUser = true;
  String? _currentUserId;
  String? _currentUserEmail;

  CreateStripeIntentResponse? _lastIntent;
  PaymentDetailResponse? _paymentDetail;

  @override
  void initState() {
    super.initState();
    _paymentApiService = PaymentApiService(baseUrl: _baseUrl);
    _seedDefaults();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _seedDefaults() async {
    try {
      final token = await _tokenStorageService.getToken();
      final userId = await _tokenStorageService.getUserId();
      final userEmail = await _tokenStorageService.getUserEmail();

      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
            _currentUserId = null;
            _currentUserEmail = null;
          });
        }
        return;
      }

      if (userId != null) {
        if (mounted) {
          setState(() {
            _currentUserId = userId.toString();
            _currentUserEmail = userEmail;
            _isLoadingUser = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  String _buildOrderId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final suffix = 100 + Random().nextInt(900);
    return 'ORD_$millis$suffix';
  }

  String _buildIdempotencyKey() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1 << 32).toRadixString(16);
    return 'idem_$millis$random';
  }

  Future<void> _payWithStripe() async {
    if ((_currentUserId ?? '').isEmpty) {
      _showError('Khong lay duoc thong tin user hien tai. Vui long dang nhap lai.');
      return;
    }

    await _runAction(() async {
      final token = await _requireToken();
      final orderId = _buildOrderId();
      final intent = await _paymentApiService.createStripeIntent(
        token: token,
        orderId: orderId,
        userId: _currentUserId!,
        amount: _selectedAmount,
        currency: 'vnd',
        paymentMethod: _selectedMethod,
        idempotencyKey: _buildIdempotencyKey(),
      );

      final clientSecret = intent.clientSecret.trim();
      if (clientSecret.isEmpty) {
        throw const PaymentApiException('Backend chua tra ve client secret hop le.');
      }

      try {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            merchantDisplayName: 'AudioBook',
            paymentIntentClientSecret: clientSecret,
            allowsDelayedPaymentMethods: true,
          ),
        );

        await Stripe.instance.presentPaymentSheet();
      } on StripeException catch (error) {
        throw PaymentApiException(
          error.error.localizedMessage ?? 'Thanh toan Stripe da bi huy/that bai.',
        );
      }

      final detail = await _waitForFinalStatus(
        token: token,
        paymentId: intent.paymentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastIntent = intent;
        _paymentDetail = detail;
      });

      if (detail.status == 'SUCCESS') {
        _showSuccess('Thanh toan thanh cong.');
      } else if (detail.status == 'FAILED') {
        _showError('Thanh toan that bai.');
      } else {
        _showSuccess('Da tao thanh toan, trang thai hien tai: ${detail.status}.');
      }
    });
  }

  Future<PaymentDetailResponse> _waitForFinalStatus({
    required String token,
    required int paymentId,
  }) async {
    PaymentDetailResponse? latest;
    PaymentApiException? lastLookupError;

    for (var attempt = 0; attempt < 6; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      try {
        latest = await _paymentApiService.getPaymentDetail(
          token: token,
          paymentId: paymentId,
        );
        lastLookupError = null;
      } on PaymentApiException catch (error) {
        final message = error.message.toLowerCase();
        if (message.contains('payment not found')) {
          lastLookupError = error;
          continue;
        }
        rethrow;
      }

      if (!mounted) {
        break;
      }

      setState(() {
        _paymentDetail = latest;
      });

      if (latest.status == 'SUCCESS' ||
          latest.status == 'FAILED' ||
          latest.status == 'CANCELED') {
        return latest;
      }
    }

    if (latest == null && lastLookupError != null) {
      throw const PaymentApiException(
        'Da tao thanh toan nhung he thong chua dong bo kip. Vui long thu lai sau it giay.',
      );
    }

    return latest ??
        await _paymentApiService.getPaymentDetail(
          token: token,
          paymentId: paymentId,
        );
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const PaymentApiException('Khong tim thay token. Vui long dang nhap lai.');
    }
    return token;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await action();
    } on PaymentApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentDetail = _paymentDetail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Credit - Stripe Sandbox'),
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top-up Credits',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Thanh toan Stripe that voi PaymentSheet.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLoadingUser
                            ? 'Dang tai thong tin tai khoan...'
                            : (_currentUserEmail ?? 'Khong xac dinh user'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chon goi nap',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _creditPackages
                    .map(
                      (amount) => ChoiceChip(
                        selected: _selectedAmount == amount,
                        onSelected: (_) {
                          setState(() {
                            _selectedAmount = amount;
                          });
                        },
                        label: Text('${amount ~/ 1000}k VND'),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'CARD', child: Text('CARD')),
                  DropdownMenuItem(
                    value: 'GOOGLE_PAY',
                    child: Text('GOOGLE_PAY'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedMethod = value;
                  });
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _isLoadingUser ? null : _payWithStripe,
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Thanh toan ngay'),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (paymentDetail != null) ...[
                const SizedBox(height: 20),
                _buildPaymentDetailCard(paymentDetail),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailCard(PaymentDetailResponse detail) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x332196F3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Detail',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Divider(height: 20),
            _detailRow('Status', detail.status),
            _detailRow('Payment ID', detail.paymentId.toString()),
            _detailRow('Payment Code', detail.paymentCode),
            _detailRow('Method', detail.method),
            _detailRow('Amount', '${detail.amount} ${detail.currency.toUpperCase()}'),
            _detailRow('Intent ID', detail.stripePaymentIntentId),
            if (detail.failureReason.trim().isNotEmpty)
              _detailRow('Failure Reason', detail.failureReason),
            _detailRow('Updated At', detail.updatedAt),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }
}

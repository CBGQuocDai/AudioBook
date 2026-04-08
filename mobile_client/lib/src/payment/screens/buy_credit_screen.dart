import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/payment/models/credit_plan.dart';
import 'package:mobile_client/src/payment/models/payment_models.dart';
import 'package:mobile_client/src/payment/services/payment_api_service.dart';
import 'package:mobile_client/src/util/routes.dart';

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
  late final AuthApiService _authApiService;

  List<CreditPlanModel> _creditPlans = const [];
  CreditPlanModel? _selectedPlan;
  String _selectedMethod = 'CARD';
  bool _isLoading = false;
  bool _isLoadingUser = true;
  bool _isPremium = false;
  String? _currentUserEmail;

  PaymentDetailResponse? _paymentDetail;

  @override
  void initState() {
    super.initState();
    _paymentApiService = PaymentApiService(baseUrl: _baseUrl);
    _authApiService = AuthApiService(baseUrl: _baseUrl);
    _seedDefaults();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _seedDefaults() async {
    try {
      final token = await _tokenStorageService.getToken();

      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
            _isPremium = false;
            _currentUserEmail = null;
            _creditPlans = const [];
            _selectedPlan = null;
          });
        }
        return;
      }

      final currentUser = await _authApiService.getCurrentUser(token);
      final userInfo = currentUser.data;
      final tier = userInfo?.tier?.toUpperCase() ?? '';
      final role = userInfo?.role?.toUpperCase() ?? '';
      final isPremium = tier == 'PREMIUM' ||
          tier == 'VIP' ||
          role == 'PREMIUM' ||
          role == 'VIP';

      List<CreditPlanModel> plans = const [];
      if (isPremium) {
        plans = await _paymentApiService.getCreditPlans(token: token);
      }

      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _isPremium = isPremium;
          _currentUserEmail = userInfo?.email;
          _creditPlans = plans;
          _selectedPlan = plans.isNotEmpty ? plans.first : null;
        });
      }
    } on AuthApiException catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } on PaymentApiException catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  String _buildIdempotencyKey() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1 << 32).toRadixString(16);
    return 'credit_idem_$millis$random';
  }

  Future<void> _payWithStripe() async {
    if (!_isPremium) {
      _showError('Tính năng này chỉ dành cho Hội viên.');
      return;
    }

    final selectedPlan = _selectedPlan;
    if (selectedPlan == null) {
      _showError('Vui lòng chọn gói credit hợp lệ.');
      return;
    }

    await _runAction(() async {
      final token = await _requireToken();
      final intent = await _paymentApiService.createCreditPurchaseIntent(
        token: token,
        creditPlanId: selectedPlan.id,
        paymentMethod: _selectedMethod,
        idempotencyKey: _buildIdempotencyKey(),
      );

      if (intent.stripePaymentIntentId.trim().isEmpty) {
        throw const PaymentApiException(
          'Backend khong tra ve stripe payment intent id hop le.',
        );
      }

      final clientSecret = intent.clientSecret.trim();
      if (clientSecret.isEmpty) {
        throw const PaymentApiException(
            'Backend chua tra ve client secret hop le.');
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
          error.error.localizedMessage ??
              'Thanh toan Stripe da bi huy/that bai.',
        );
      }

      final detail = await _waitForFinalStatus(
        token: token,
        paymentId: intent.paymentId,
      );

      if (detail.status != 'SUCCESS') {
        throw PaymentApiException('Thanh toan that bai (${detail.status}).');
      }

      final confirmed = await _paymentApiService.confirmCreditPurchase(
        token: token,
        paymentId: detail.paymentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _paymentDetail = confirmed;
      });
      _showSuccess('Mua credit thanh cong.');
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
      throw const PaymentApiException(
          'Khong tim thay token. Vui long dang nhap lai.');
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
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isPremium) {
      return _buildBaseUserGateway();
    }

    final paymentDetail = _paymentDetail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mua Credit'),
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nạp Credit',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chỉ áp dụng cho tài khoản Hội viên.',
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
                        _currentUserEmail ?? 'Khong xac dinh user',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn gói nạp',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (_creditPlans.isEmpty)
                const Text(
                  'Chưa có gói credit khả dụng.',
                  style: TextStyle(color: Colors.orangeAccent),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _creditPlans
                      .map(
                        (plan) => ChoiceChip(
                          selected: _selectedPlan?.id == plan.id,
                          onSelected: (_) {
                            setState(() {
                              _selectedPlan = plan;
                            });
                          },
                          label: Text(
                            '${plan.name} • ${plan.price ~/ 1000}k VND',
                          ),
                        ),
                      )
                      .toList(),
                ),
              if (_selectedPlan != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Bạn nhận: ${_selectedPlan!.amount} credit',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
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
                  onPressed: _isLoading ||
                          _creditPlans.isEmpty ||
                          _selectedPlan == null
                      ? null
                      : _payWithStripe,
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Thanh toán ngay'),
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
    return _buildPaymentDetailCardContent(detail);
  }

  Widget _buildBaseUserGateway() {
    return Scaffold(
      appBar: AppBar(title: const Text('Mua Credit')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF2D2622), Color(0xFF1D1B24)],
              ),
              border: Border.all(color: const Color(0x66FFB338)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Color(0xFFFFB338)),
                    SizedBox(width: 8),
                    Text(
                      'Chỉ dành cho Hội viên',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bạn cần đăng ký Hội viên để mua credit và sử dụng nội dung nâng cao.',
                  style: TextStyle(color: Color(0xFFB7B8BD), fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        AppRoutes.premiumPlan,
                      );
                      if (!mounted) return;
                      if (result == true) {
                        await _seedDefaults();
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Đăng ký Hội viên ngay'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailCardContent(PaymentDetailResponse detail) {
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
            _detailRow(
                'Amount', '${detail.amount} ${detail.currency.toUpperCase()}'),
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

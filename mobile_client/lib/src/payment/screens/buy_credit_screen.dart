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
  bool _isLoading = false;
  bool _isLoadingUser = true;
  bool _isPremium = false;
  int _currentCreditBalance = 0;
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
            _currentCreditBalance = 0;
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
          _currentCreditBalance = userInfo?.totalCredit ?? 0;
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

  Future<void> _payWithStripe({
    required CreditPlanModel selectedPlan,
    required String paymentMethod,
  }) async {
    if (!_isPremium) {
      _showError('TÍNH NĂNG NÀY CHỈ DÀNH CHO HỘI VIÊN.');
      return;
    }

    if (selectedPlan.id <= 0) {
      _showError('VUI LÒNG CHỌN GÓI CREDIT HỢP LỆ.');
      return;
    }

    await _runAction(() async {
      final token = await _requireToken();
      final intent = await _paymentApiService.createCreditPurchaseIntent(
        token: token,
        creditPlanId: selectedPlan.id,
        paymentMethod: paymentMethod,
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

      final detail = await _paymentApiService.waitForPaymentStatus(
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
      await _refreshCurrentUser(token);
      _showSuccess('MUA CREDIT THÀNH CÔNG.');
    });
  }

  Future<void> _refreshCurrentUser(String token) async {
    try {
      final currentUser = await _authApiService.getCurrentUser(token);
      final userInfo = currentUser.data;
      if (!mounted || userInfo == null) {
        return;
      }

      setState(() {
        _currentCreditBalance = userInfo.totalCredit;
        _currentUserEmail = userInfo.email;
      });
    } catch (_) {}
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const PaymentApiException(
          'KHÔNG TÌM THẤY TOKEN. VUI LÒNG ĐĂNG NHẬP LẠI.');
    }
    return token;
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      return;
    }
    if (index == 0) {
      Navigator.pushReplacementNamed(context, AppRoutes.discovery);
      return;
    }
    if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.discovery);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.profile);
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
      backgroundColor: const Color(0xFF1B1D23),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B1D23), Color(0xFF1B1D23)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF444248), Color(0xFF2E3139)],
                      ),
                      border: Border.all(color: const Color(0x26FFFFFF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'SỐ DƯ HIỆN TẠI',
                                style: TextStyle(
                                  color: Color(0xFFC3C5CA),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFE9801),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_currentCreditBalance CREDIT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Color(0xFF8D929B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (_currentUserEmail ?? 'HỘI VIÊN').toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFFF9C13),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'MUA CREDIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_creditPlans.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF262A31),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                      child: const Text(
                        'CHƯA CÓ GÓI CREDIT KHẢ DỤNG.',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    )
                  else
                    ..._creditPlans.map((plan) {
                      final isSelected = _selectedPlan?.id == plan.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPlan = plan;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFF262A31),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFE9801)
                                    : const Color(0x26FFFFFF),
                                width: isSelected ? 1.4 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFE9801)
                                            .withValues(alpha: 0.18),
                                        blurRadius: 16,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan.name.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_parseCreditAmount(plan.amount)} CREDIT',
                                            style: const TextStyle(
                                              color: Color(0xFFA6A9B0),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatPrice(plan.price),
                                      style: const TextStyle(
                                        color: Color(0xFFFFA214),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _payWithStripe(
                                              selectedPlan: plan,
                                              paymentMethod: 'CARD',
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected
                                          ? const Color(0xFFFE9801)
                                          : const Color(0xFF3A3530),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          const Color(0xFF3A3530),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                    child: const Text(
                                      'MUA NGAY',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
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
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: Color(0xFF141A24),
        border: Border(top: BorderSide(color: Color(0x2FFFFFFF))),
      ),
      child: Row(
        children: [
          _navItem(icon: Icons.explore_outlined, label: 'KHÁM PHÁ', index: 0),
          _navItem(
              icon: Icons.add_circle_outline, label: 'MUA CREDIT', index: 1),
          _navItem(
              icon: Icons.library_books_outlined, label: 'THƯ VIỆN', index: 2),
          _navItem(icon: Icons.person_outline, label: 'HỒ SƠ', index: 3),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = index == 1;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFFFFA321)
                  : const Color(0xFF8D93A6),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFFFA321)
                    : const Color(0xFF8D93A6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int value) {
    final withDot = value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
    return '$withDot₫';
  }

  int _parseCreditAmount(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 0;
    }
    final match = RegExp(r'\d+').firstMatch(raw);
    if (match == null) {
      return 0;
    }
    return int.tryParse(match.group(0) ?? '') ?? 0;
  }

  Widget _buildPaymentDetailCard(PaymentDetailResponse detail) {
    return _buildPaymentDetailCardContent(detail);
  }

  Widget _buildBaseUserGateway() {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1D23),
      body: SafeArea(
        child: Center(
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
                        'CHỈ DÀNH CHO HỘI VIÊN',
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
                    'BẠN CẦN ĐĂNG KÝ HỘI VIÊN ĐỂ MUA CREDIT VÀ SỬ DỤNG NỘI DUNG NÂNG CAO.',
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
                      label: const Text('ĐĂNG KÝ HỘI VIÊN NGAY'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildPaymentDetailCardContent(PaymentDetailResponse detail) {
    return const SizedBox.shrink();
  }
}

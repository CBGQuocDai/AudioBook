import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/payment/models/subscription_info.dart';
import 'package:mobile_client/src/payment/services/payment_api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TokenStorageService _tokenStorageService = TokenStorageService();
  late final PaymentApiService _paymentApiService;

  bool _isLoading = true;
  bool _isCancelling = false;
  String? _error;
  SubscriptionInfo? _info;

  @override
  void initState() {
    super.initState();
    _paymentApiService =
        PaymentApiService(baseUrl: PaymentApiService.defaultBaseUrl);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const PaymentApiException(
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }

      final info = await _paymentApiService.getSubscriptionInfo(token: token);
      if (!mounted) return;
      setState(() {
        _info = info;
      });
    } on PaymentApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelMembership() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const PaymentApiException(
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }

      await _paymentApiService.unsubscribe(token: token);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy hội viên thành công.'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadData();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on PaymentApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Đang hoạt động';
      case 'CANCELED':
        return 'Đã hủy';
      case 'PENDING':
        return 'Đang chờ';
      case 'CHUA_DANG_KY':
        return 'Chưa đăng ký';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF29D98B);
      case 'CANCELED':
        return const Color(0xFFFF6464);
      case 'PENDING':
        return const Color(0xFFFFB338);
      default:
        return const Color(0xFFA8AFC0);
    }
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) {
      return '--/--/----';
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }

  String _formatPrice(int price, String timeUnit) {
    final value = price.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );

    final suffix = timeUnit.toUpperCase() == 'YEARS'
        ? '/năm'
        : timeUnit.toUpperCase() == 'MONTHS'
            ? '/tháng'
            : '';

    return '$value₫$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1D27),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C2A2F), Color(0xFF1E212D)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final info = _info;
    final history = info?.billingHistory ?? const <SubscriptionHistoryItem>[];
    final hasMembership = (info?.planName ?? '').trim().isNotEmpty;
    final isActive = (info?.status ?? '').toUpperCase() == 'ACTIVE';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF232A3B),
                child: IconButton(
                  iconSize: 14,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const Spacer(),
              const Text(
                'Hội viên',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasMembership)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF272B36),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x1FFFFFFF)),
              ),
              child: const Text(
                'Bạn chưa đăng ký hội viên.',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2F333F), Color(0xFF252934)],
                ),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFFF8B1F),
                        ),
                        child: const Text(
                          'HỘI VIÊN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF1F2430),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFFF8B1F),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info?.planName ?? 'Gói hội viên',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow('Trạng thái', _statusLabel(info?.status ?? ''),
                      valueColor: _statusColor(info?.status ?? '')),
                  _infoRow(
                      'Ngày gia hạn', _formatDate(info?.nextBillingDate ?? '')),
                  _infoRow(
                    'Giá',
                    _formatPrice(info?.price ?? 0, info?.timeUnit ?? ''),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'LỊCH SỬ THANH TOÁN',
            style: TextStyle(
              color: Color(0xFF8A8E9B),
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0x80242A37),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: history.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Chưa có lịch sử thanh toán.',
                      style: TextStyle(color: Color(0xFFA3ABBF)),
                    ),
                  )
                : Column(
                    children: history
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0x332F3747),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFFFF8B1F),
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.planName.isEmpty
                                            ? 'Gói hội viên'
                                            : item.planName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(item.startDate),
                                        style: const TextStyle(
                                          color: Color(0xFF8A8E9B),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatPrice(item.price, item.timeUnit),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 20),
          if (isActive)
            TextButton(
              onPressed: _isCancelling ? null : _cancelMembership,
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: const Color(0xFFFF6464),
              ),
              child:
                  Text(_isCancelling ? 'Đang hủy hội viên...' : 'Hủy hội viên'),
            ),
          if (isActive)
            const Text(
              'Việc hủy sẽ có hiệu lực vào cuối chu kỳ hiện tại.',
              style: TextStyle(color: Color(0xFF8A8E9B), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFA3ABBF)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

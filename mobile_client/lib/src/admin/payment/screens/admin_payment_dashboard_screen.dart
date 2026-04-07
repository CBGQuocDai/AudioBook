import 'package:flutter/material.dart';

import '../../home/models/admin_dashboard_models.dart';
import '../../home/services/admin_dashboard_api_service.dart';

class AdminPaymentDashboardScreen extends StatefulWidget {
  final AdminDashboardApiService dashboardApiService;

  const AdminPaymentDashboardScreen({
    super.key,
    required this.dashboardApiService,
  });

  @override
  State<AdminPaymentDashboardScreen> createState() =>
      _AdminPaymentDashboardScreenState();
}

class _AdminPaymentDashboardScreenState
    extends State<AdminPaymentDashboardScreen> {
  late Future<PaymentDashboardData> _paymentFuture;

  @override
  void initState() {
    super.initState();
    _paymentFuture = widget.dashboardApiService.getPaymentDashboard();
  }

  void _reload() {
    setState(() {
      _paymentFuture = widget.dashboardApiService.getPaymentDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231D0F),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFC89B3C),
          backgroundColor: const Color(0xFF2A1D07),
          onRefresh: () async {
            _reload();
            await _paymentFuture;
          },
          child: FutureBuilder<PaymentDashboardData>(
            future: _paymentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC89B3C)),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error?.toString());
              }

              final data = snapshot.data;
              if (data == null) {
                return _buildErrorState('Dữ liệu thanh toán đang rỗng.');
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildMainStats(data),
                    const SizedBox(height: 14),
                    _buildCurrencyBreakdown(data),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3E2C10)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thống kê thanh toán',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tổng tiền nạp thành công và chi tiết theo tiền tệ',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _reload,
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFFF7DFA5),
              backgroundColor: const Color(0xFF3A2D14),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats(PaymentDashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3E2C10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _metricCard(
              title: 'Tổng tiền nạp thành công',
              value: _formatNumber(data.totalDepositedAmount),
              icon: Icons.savings,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metricCard(
              title: 'Số giao dịch thành công',
              value: _formatNumber(data.successfulTransactionCount),
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF241706),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B381A)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFC89B3C).withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFC89B3C)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBreakdown(PaymentDashboardData data) {
    final totalAmount = data.currencySummaries.fold<int>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final maxAmount = data.currencySummaries.fold<int>(
      0,
      (max, item) => item.totalAmount > max ? item.totalAmount : max,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3E2C10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết theo tiền tệ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (data.currencySummaries.isEmpty)
            _emptyText('Chưa có dữ liệu giao dịch thành công.')
          else
            ...data.currencySummaries.map(
              (item) {
                final percent = totalAmount <= 0
                    ? 0.0
                    : (item.totalAmount / totalAmount) * 100;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _currencyItem(
                    item: item,
                    maxAmount: maxAmount,
                    percent: percent,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _currencyItem({
    required PaymentCurrencySummary item,
    required int maxAmount,
    required double percent,
  }) {
    final normalizedMax = maxAmount <= 0 ? 1 : maxAmount;
    final ratio = (item.totalAmount / normalizedMax).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF241706),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B381A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.currency.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatNumber(item.totalAmount)} • ${item.transactionCount} gd',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tỉ trọng: ${percent.toStringAsFixed(2)}%',
            style: const TextStyle(
              color: Color(0xFFD8C7A1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFF3A2D14),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC89B3C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3E2C10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Không thể tải thống kê thanh toán',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error ?? 'Lỗi không xác định',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reload,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC89B3C)),
              foregroundColor: const Color(0xFFF7DFA5),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF241706),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4B381A)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final isLast = i == digits.length - 1;
      if (!isLast && (digits.length - i - 1) % 3 == 0) {
        buffer.write(',');
      }
    }

    return negative ? '-$buffer' : '$buffer';
  }
}

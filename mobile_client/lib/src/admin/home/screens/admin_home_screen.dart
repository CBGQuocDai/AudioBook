import 'package:flutter/material.dart';
import '../models/admin_dashboard_models.dart';
import '../services/admin_dashboard_api_service.dart';

class AdminHomeScreen extends StatefulWidget {
  final AdminDashboardApiService dashboardApiService;

  const AdminHomeScreen({
    super.key,
    required this.dashboardApiService,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<AdminDashboardBundle> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.dashboardApiService.getDashboardBundle();
  }

  void _reload() {
    setState(() {
      _dashboardFuture = widget.dashboardApiService.getDashboardBundle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231D0F),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _dashboardFuture;
          },
          color: const Color(0xFFC89B3C),
          backgroundColor: const Color(0xFF2A1D07),
          child: FutureBuilder<AdminDashboardBundle>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFC89B3C),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error);
              }

              final data = snapshot.data;
              if (data == null) {
                return _buildErrorState('Dữ liệu bảng điều khiển đang rỗng.');
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildUsersDashboard(data.users),
                    const SizedBox(height: 14),
                    _buildBooksDashboard(data.books),
                    const SizedBox(height: 14),
                    _buildPaymentsDashboard(data.payments),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    final message = error?.toString() ?? 'Lỗi không xác định';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3E2C10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Không thể tải bảng điều khiển quản trị',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3E2C10),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảng điều khiển quản trị',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tổng quan số liệu người dùng, sách và thanh toán',
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

  Widget _buildUsersDashboard(UserDashboardData users) {
    final dailyData = users.dailyRegistrations.length > 7
        ? users.dailyRegistrations.sublist(users.dailyRegistrations.length - 7)
        : users.dailyRegistrations;
    final monthlyData = users.monthlyRegistrations.length > 12
        ? users.monthlyRegistrations.sublist(
            users.monthlyRegistrations.length - 12,
          )
        : users.monthlyRegistrations;
    final growth = users.growthPercent;
    final isUp = users.growthDirection.toUpperCase().contains('UP');
    final growthColor = isUp ? const Color(0xFF00D26A) : const Color(0xFFFF7A7A);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF3E2C10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê người dùng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKeyMetricCard(
                  label: 'Tổng người dùng',
                  value: _formatNumber(users.totalUsers),
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKeyMetricCard(
                  label: 'Đang hoạt động / Ngừng hoạt động',
                  value:
                      '${_formatNumber(users.activeUsers)} / ${_formatNumber(users.inactiveUsers)}',
                  icon: Icons.manage_accounts,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF241706),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4B381A)),
            ),
            child: Row(
              children: [
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  color: growthColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tăng trưởng: ${growth.toStringAsFixed(2)}% (${users.growthDirection})',
                  style: TextStyle(
                    color: growthColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildChartCard(
            title: 'Đăng ký 7 ngày gần nhất',
            child: _MiniBarChart(
              data: dailyData,
              labelMax: 7,
            ),
          ),
          const SizedBox(height: 10),
          _buildChartCard(
            title: 'Đăng ký 12 tháng gần nhất',
            child: _MiniBarChart(
              data: monthlyData,
              labelMax: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksDashboard(BookDashboardData books) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF3E2C10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê sách',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildKeyMetricCard(
            label: 'Tổng số sách',
            value: _formatNumber(books.totalBooks),
            icon: Icons.menu_book,
          ),
          const SizedBox(height: 10),
          const Text(
            'Top sách được mua nhiều nhất',
            style: TextStyle(
              color: Color(0xFFE0A100),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (books.topPurchasedBooks.isEmpty)
            _buildEmptyText('Chưa có dữ liệu sách đã mua.')
          else
            ...books.topPurchasedBooks.take(5).toList().asMap().entries.map(
              (entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8),
                  child: _buildTopPurchasedBookRow(item, index + 1),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentsDashboard(PaymentDashboardData payments) {
    final maxAmount = payments.currencySummaries.fold<int>(
      0,
      (current, item) => item.totalAmount > current ? item.totalAmount : current,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF3E2C10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê thanh toán',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKeyMetricCard(
                  label: 'Tổng tiền nạp thành công',
                  value: _formatNumber(payments.totalDepositedAmount),
                  icon: Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKeyMetricCard(
                  label: 'Giao dịch thành công',
                  value: _formatNumber(payments.successfulTransactionCount),
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Chi tiết theo tiền tệ',
            style: TextStyle(
              color: Color(0xFFE0A100),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (payments.currencySummaries.isEmpty)
            _buildEmptyText('Chưa có dữ liệu thanh toán thành công.')
          else
            ...payments.currencySummaries.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCurrencyRow(item, maxAmount),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF241706),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B381A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildKeyMetricCard({
    required String label,
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
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFFC89B3C),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildTopPurchasedBookRow(BookTopPurchased item, int rank) {
    final coverUrl = item.coverFile?.filePath;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF241706),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B381A)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              color: const Color(0xFFC89B3C).withOpacity(0.16),
              child: coverUrl == null || coverUrl.trim().isEmpty
                  ? Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Color(0xFFF7DFA5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              color: Color(0xFFF7DFA5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? 'Không rõ tên sách' : item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.author.isEmpty ? 'Không rõ tác giả' : item.author,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatNumber(item.purchasedCount)} lượt mua',
            style: const TextStyle(
              color: Color(0xFFE0A100),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyRow(PaymentCurrencySummary item, int maxAmount) {
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
                '${_formatNumber(item.totalAmount)} • ${_formatNumber(item.transactionCount)} gd',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
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

  Widget _buildEmptyText(String text) {
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

class _MiniBarChart extends StatelessWidget {
  final List<TimeSeriesPoint> data;
  final int labelMax;

  const _MiniBarChart({
    required this.data,
    required this.labelMax,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text(
        'Không có dữ liệu biểu đồ.',
        style: TextStyle(color: Colors.white60, fontSize: 12),
      );
    }

    final maxValue = data.fold<int>(0, (max, item) => item.value > max ? item.value : max);
    final normalizedMax = maxValue <= 0 ? 1 : maxValue;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          final ratio = (item.value / normalizedMax).clamp(0, 1).toDouble();
          final shortLabel = item.label.length > labelMax
              ? item.label.substring(item.label.length - labelMax)
              : item.label;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 14,
                        height: 90 * ratio,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC89B3C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../payment/models/payment_models.dart';
import '../../user/models/page_response.dart';
import '../services/admin_payment_api_service.dart';

class AdminPaymentLogScreen extends StatefulWidget {
  final AdminPaymentApiService apiService;

  const AdminPaymentLogScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<AdminPaymentLogScreen> createState() => _AdminPaymentLogScreenState();
}

class _AdminPaymentLogScreenState extends State<AdminPaymentLogScreen> {
  List<PaymentDetailResponse> logs = [];
  bool isLoading = false;
  int currentPage = 0;
  int totalPages = 0;
  int totalElements = 0;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => isLoading = true);

    try {
      final PageResponse<PaymentDetailResponse> pageData =
          await widget.apiService.getPaymentLogs(
        page: currentPage,
        size: pageSize,
      );

      if (!mounted) return;
      setState(() {
        logs = pageData.content;
        totalPages = pageData.totalPages;
        totalElements = pageData.totalElements;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tải log thanh toán thất bại: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _reloadFirstPage() async {
    currentPage = 0;
    await _fetchLogs();
  }

  String _formatAmount(int amount, String currency) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '$formatted ${currency.toUpperCase()}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFF5CB85C);
      case 'FAILED':
        return const Color(0xFFD9534F);
      default:
        return const Color(0xFFF0AD4E);
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF47361C)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhật ký thanh toán',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lịch sử toàn bộ giao dịch nạp tiền',
                  style: TextStyle(
                    color: Color(0xFFD8C7A1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _reloadFirstPage,
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

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF47361C)),
      ),
      child: Text(
        'Tổng giao dịch: $totalElements',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFD8C7A1),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLogItem(PaymentDetailResponse item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF45341B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.paymentCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(item.status).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: _statusColor(item.status),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Số tiền: ${_formatAmount(item.amount, item.currency)}',
            style: const TextStyle(
              color: Color(0xFFF4D28A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'User: ${item.userId} | Order: ${item.orderId}',
            style: const TextStyle(color: Color(0xFFD8C7A1), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Provider: ${item.provider} | Method: ${item.method}',
            style: const TextStyle(color: Color(0xFFD8C7A1), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Tạo lúc: ${item.createdAt}',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          if (item.failureReason.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Lý do lỗi: ${item.failureReason}',
              style: const TextStyle(color: Color(0xFFFFB4B0), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final displayTotalPages = totalPages == 0 ? 1 : totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF47361C)),
      ),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            onPressed: currentPage > 0
                ? () async {
                    currentPage--;
                    await _fetchLogs();
                  }
                : null,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF3A2D14)),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${currentPage + 1}/$displayTotalPages',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: (currentPage + 1) < totalPages
                ? () async {
                    currentPage++;
                    await _fetchLogs();
                  }
                : null,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF3A2D14)),
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC89B3C)),
      );
    }

    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2416),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4A3A1A)),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined, color: Color(0xFFC89B3C), size: 44),
            SizedBox(height: 12),
            Text(
              'Chưa có log thanh toán',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildLogItem(logs[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231D0F),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFC89B3C),
          backgroundColor: const Color(0xFF2A1D07),
          onRefresh: _reloadFirstPage,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildSummary(),
                const SizedBox(height: 12),
                _buildBody(),
                const SizedBox(height: 12),
                _buildPagination(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

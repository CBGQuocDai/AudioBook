import 'package:flutter/material.dart';

class PremiumPlanScreen extends StatefulWidget {
  const PremiumPlanScreen({super.key});

  @override
  State<PremiumPlanScreen> createState() => _PremiumPlanScreenState();
}

class _PremiumPlanScreenState extends State<PremiumPlanScreen> {
  String _selectedPlan = 'annual';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D202B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF26222B), Color(0xFF1C1F2A)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Premium Plan',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFFF7A1F),
                    child: Icon(Icons.workspace_premium,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nâng cấp Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tham gia cùng hàng ngàn độc giả và mở khóa\nkhông giới hạn toàn bộ thư viện.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFA8AFC0), height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  _planCard(
                    title: 'GÓI THÁNG',
                    price: '\$9.99',
                    suffix: '/ tháng',
                    value: 'monthly',
                  ),
                  const SizedBox(height: 10),
                  _planCard(
                    title: 'GÓI NĂM',
                    price: '\$89.99',
                    suffix: '/ năm',
                    value: 'annual',
                    badge: 'TIẾT KIỆM NHẤT',
                    subText: 'Tiết kiệm 25% mỗi năm',
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'QUYỀN LỢI PREMIUM',
                    style: TextStyle(
                      color: Color(0xFF8A8F9D),
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _FeatureItem(
                    title: 'Thư viện thành viên',
                    subtitle: 'Mở khóa hàng trăm đầu sách độc quyền.',
                  ),
                  const _FeatureItem(
                    title: '1 credit mỗi tháng',
                    subtitle: 'Nhận 1 credit để mở khóa bất kỳ đầu sách nào.',
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8B1F), Color(0xFFE96A15)],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Chức năng thanh toán sẽ được triển khai sau.'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Tiếp tục thanh toán  →',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gói sẽ tự động gia hạn. Bạn có thể hủy bất kỳ lúc nào.\nĐiều khoản sử dụng • Chính sách bảo mật',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF7F8698), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required String suffix,
    required String value,
    String? badge,
    String? subText,
  }) {
    final selected = _selectedPlan == value;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1E2433),
          border: Border.all(
            color: selected ? const Color(0xFFFF8B1F) : const Color(0x443A4258),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            color: Color(0xFF9EA5B7), fontSize: 11),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8B1F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: price,
                          style: const TextStyle(
                            color: Color(0xFFFF8B1F),
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: suffix,
                          style: const TextStyle(
                            color: Color(0xFF9EA5B7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (subText != null)
                    Text(
                      subText,
                      style: const TextStyle(
                          color: Color(0xFFFFA74B), fontSize: 11),
                    ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color:
                  selected ? const Color(0xFFFF8B1F) : const Color(0xFF5B6378),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_outline,
                color: Color(0xFFFF9E31), size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(color: Color(0xFFA3ABBF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

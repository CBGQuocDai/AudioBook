import 'package:flutter/material.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231D0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin dashboard',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              _buildWelcomeCard(),
              const SizedBox(height: 16),

              _buildRevenueCard(),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildSmallStatCard(
                      title: 'TOTAL USERS',
                      value: '1.2M',
                      percent: '+4%',
                      percentColor: Color(0xFF00D26A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallStatCard(
                      title: 'CONVERSION',
                      value: '8.5%',
                      percent: '-2.1%',
                      percentColor: Color(0xFFFF4D4F),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildSubscriptionCard(),
              const SizedBox(height: 16),

              const Text(
                'Trending Books',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              _buildBookItem(
                title: 'Echoes of the Void',
                subtitle: 'Sci-Fi • Sarah Jenkins',
                reads: '12.4k',
                coverColor: const Color(0xFF5D8C7B),
              ),
              const SizedBox(height: 12),
              _buildBookItem(
                title: 'The Golden Ledger',
                subtitle: 'Mystery • Arthur Doyle',
                reads: '9.8k',
                coverColor: const Color(0xFF3E9A97),
              ),
              const SizedBox(height: 12),
              _buildBookItem(
                title: 'Whispering Shadows',
                subtitle: 'Fantasy • Elena Roe',
                reads: '8.2k',
                coverColor: const Color(0xFF6C9D8E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF3E2C10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF2C94C),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Alex Thompson',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
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

  Widget _buildRevenueCard() {
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY REVENUE',
            style: TextStyle(
              color: Color(0xFFE0A100),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '\$45,200',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '↗ +12.5% vs last month',
            style: TextStyle(
              color: Color(0xFF00D26A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard({
    required String title,
    required String value,
    required String percent,
    required Color percentColor,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            percent,
            style: TextStyle(
              color: percentColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3E2C10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscription Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _BarItem(
                  amount: '850k',
                  label: 'FREE',
                  height: 36,
                ),
                _BarItem(
                  amount: '250k',
                  label: 'BASIC',
                  height: 70,
                ),
                _BarItem(
                  amount: '100k',
                  label: 'PRO',
                  height: 100,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookItem({
    required String title,
    required String subtitle,
    required String reads,
    required Color coverColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4B381A),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: coverColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                reads,
                style: const TextStyle(
                  color: Color(0xFFE0A100),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'READS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final String amount;
  final String label;
  final double height;

  const _BarItem({
    required this.amount,
    required this.label,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          amount,
          style: const TextStyle(
            color: Color(0xFFE0A100),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE0A100),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
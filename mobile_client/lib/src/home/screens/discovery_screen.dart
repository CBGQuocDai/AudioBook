import 'package:flutter/material.dart';
import 'package:mobile_client/src/util/routes.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  int _selectedTabIndex = 0;

  void _onBottomNavTap(int index) async {
    if (index == 1) {
      await Navigator.pushNamed(context, AppRoutes.buyCredit);
      if (!mounted) return;
      setState(() => _selectedTabIndex = 0);
      return;
    }

    if (index == 3) {
      await Navigator.pushNamed(context, AppRoutes.profile);
      if (!mounted) return;
      setState(() => _selectedTabIndex = 0);
      return;
    }

    setState(() => _selectedTabIndex = index);
  }

  Widget _buildPageContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const Center(
          child: Text(
            'Trang chủ',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        );
      case 2:
        return const Center(
          child: Text(
            'Thư viện',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        );
      default:
        return const Center(
          child: Text(
            'Trang chủ',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(child: _buildPageContent()),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF171B25),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: Row(
          children: [
            _navItem(icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: 'Khám phá', index: 0),
            _navItem(icon: Icons.add_circle_outline, selectedIcon: Icons.add_circle, label: 'Mua Credit', index: 1),
            _navItem(icon: Icons.library_books_outlined, selectedIcon: Icons.library_books, label: 'Thư viện', index: 2),
            _navItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Hồ sơ', index: 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 24,
              color: isSelected ? const Color(0xFFFFA321) : const Color(0xFF8D93A6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFFA321) : const Color(0xFF8D93A6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

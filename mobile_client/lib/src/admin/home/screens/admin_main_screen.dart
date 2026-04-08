import 'package:flutter/material.dart';
import '../../book/screens/admin_book_list_screen.dart';
import '../../book/services/admin_book_api_service.dart';
import '../../../auth/services/token_storage_service.dart';
import '../../../core/config/app_config.dart';
import '../../payment/screens/admin_payment_log_screen.dart';
import '../../payment/services/admin_payment_api_service.dart';
import '../../user/screens/admin_user_list_screen.dart';
import '../../user/services/admin_user_api_service.dart';
import '../services/admin_dashboard_api_service.dart';
import 'admin_home_screen.dart';
import 'admin_profile_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int currentIndex = 0;

  final List<_AdminNavItem> _items = const [
    _AdminNavItem(
      label: 'Tổng quan',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
    ),
    _AdminNavItem(
      label: 'Sách',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    _AdminNavItem(
      label: 'Người dùng',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    _AdminNavItem(
      label: 'Thanh toán',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    _AdminNavItem(
      label: 'Cá nhân',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  late final AdminUserApiService _adminUserApiService;
  late final AdminBookApiService _adminBookApiService;
  late final AdminPaymentApiService _adminPaymentApiService;
  late final AdminDashboardApiService _adminDashboardApiService;
  final TokenStorageService _tokenStorage = TokenStorageService();

  @override
  void initState() {
    super.initState();

    _adminUserApiService = AdminUserApiService(
      baseUrl: AppConfig.apiBaseUrl,
      getAccessToken: () => _tokenStorage.getToken(),
    );

    _adminBookApiService = AdminBookApiService(
      baseUrl: AppConfig.apiBaseUrl,
      getAccessToken: () => _tokenStorage.getToken(),
    );

    _adminPaymentApiService = AdminPaymentApiService(
      baseUrl: AppConfig.apiBaseUrl,
      getAccessToken: () => _tokenStorage.getToken(),
    );

    _adminDashboardApiService = AdminDashboardApiService(
      baseUrl: AppConfig.apiBaseUrl,
      getAccessToken: () => _tokenStorage.getToken(),
    );
  }

  List<Widget> get pages => [
    AdminHomeScreen(dashboardApiService: _adminDashboardApiService),
    AdminBookListScreen(apiService: _adminBookApiService),
    AdminUserListScreen(apiService: _adminUserApiService),
    AdminPaymentLogScreen(apiService: _adminPaymentApiService),
    AdminProfileScreen(), // Thêm màn hình thông tin cá nhân
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1409),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF3A2D14)),
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? const Color(0xFFC89B3C).withOpacity(0.18)
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color: isSelected
                              ? const Color(0xFFC89B3C)
                              : Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFF7DFA5)
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

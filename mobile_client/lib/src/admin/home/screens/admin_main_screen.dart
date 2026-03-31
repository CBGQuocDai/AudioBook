import 'package:flutter/material.dart';
import '../../../auth/services/token_storage_service.dart';
import '../../user/screens/admin_user_list_screen.dart';
import '../../user/services/admin_user_api_service.dart';
import 'admin_home_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int currentIndex = 0;

  late final AdminUserApiService _adminUserApiService;
  final TokenStorageService _tokenStorage = TokenStorageService();

  @override
  void initState() {
    super.initState();

    _adminUserApiService = AdminUserApiService(
      baseUrl: 'http://10.0.2.2:8080/api',
      getAccessToken: () => _tokenStorage.getToken(),
    );
  }

  List<Widget> get pages => [
    const AdminHomeScreen(),
    const PlaceholderScreen(title: 'Books'),
    AdminUserListScreen(apiService: _adminUserApiService),
    const PlaceholderScreen(title: 'Payments'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B1409),
          border: Border(
            top: BorderSide(
              color: Color(0xFF3A2D14),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF1B1409),
          selectedItemColor: const Color(0xFFE0A100),
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Books',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Payments',
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF231D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF231D0F),
        elevation: 0,
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title Screen',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
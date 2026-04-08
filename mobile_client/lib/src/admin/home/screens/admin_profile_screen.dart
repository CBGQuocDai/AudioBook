import 'package:flutter/material.dart';


import '../../../auth/services/token_storage_service.dart';
import '../../user/services/admin_user_api_service.dart';
import '../../user/models/user_response.dart';
import '../../../core/config/app_config.dart';



class AdminProfileScreen extends StatefulWidget {
  AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final AdminUserApiService _userApi = AdminUserApiService(
    baseUrl: AppConfig.apiBaseUrl,
    getAccessToken: () => TokenStorageService().getToken(),
  );

  UserResponse? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await _tokenStorage.getUserId();
    print('DEBUG userId: $userId');
    if (userId != null) {
      try {
        final user = await _userApi.getUserProfile(userId);
        print('DEBUG user from API: \\n${user.toJson()}');
        setState(() {
          _user = user;
          _loading = false;
        });
        return;
      } catch (e) {
        print('DEBUG error when getUserProfile: $e');
        // fallback
      }
    }
    // fallback nếu không có userId hoặc lỗi
    final email = await _tokenStorage.getUserEmail();
    final role = await _tokenStorage.getUserRole();
    print('DEBUG fallback email: $email, role: $role');
    setState(() {
      _user = UserResponse(
        id: userId ?? 0,
        email: email ?? '',
        name: email ?? '',
        avatarFile: null,
        avatarUrl: null,
        role: RoleEnum.fromString(role),
        active: null,
      );
      _loading = false;
    });
  }


  void _logout(BuildContext context) async {
    await _tokenStorage.clearToken();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (() {
                    String? avatar = _user?.avatarUrl;
                    if ((avatar == null || avatar.isEmpty) && _user?.avatarFile?.filePath != null && _user!.avatarFile!.filePath!.isNotEmpty) {
                      avatar = _user!.avatarFile!.filePath;
                    }
                    return avatar != null && avatar.isNotEmpty
                        ? CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(avatar),
                          )
                        : const CircleAvatar(
                            radius: 40,
                            child: Icon(Icons.person, size: 48),
                          );
                  })(),
                  const SizedBox(height: 24),
                  Text('Tên: ${_user?.name ?? "(Không có)"}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Email: ${_user?.email ?? "(Không có)"}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Vai trò: ${_user?.role.displayName ?? "(Không có)"}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _logout(context),
                  ),
                ],
              ),
            ),
    );
  }
}

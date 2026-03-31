import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/models/user_info.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/util/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AuthApiService.defaultBaseUrl,
  );

  final AuthApiService _authApiService = AuthApiService(baseUrl: _baseUrl);
  final TokenStorageService _tokenStorageService = TokenStorageService();

  bool _isLoading = true;
  String? _errorMessage;
  UserInfo? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const AuthApiException('Không tìm thấy token, vui lòng đăng nhập lại.');
      }

      final response = await _authApiService.getCurrentUser(token);

      if (!mounted) {
        return;
      }

      setState(() {
        _userInfo = response.data;
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _tokenStorageService.clearToken();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadProfile,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  : _buildUserInfo(),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final userInfo = _userInfo;
    if (userInfo == null) {
      return const Center(child: Text('Không có dữ liệu người dùng.'));
    }

    final avatarUrl = userInfo.avatarUrl?.isNotEmpty == true
        ? userInfo.avatarUrl
        : userInfo.avatarFile?.filePath;

    return ListView(
      children: [
        if (avatarUrl != null && avatarUrl.isNotEmpty)
          CircleAvatar(
            radius: 45,
            backgroundImage: NetworkImage(avatarUrl),
          )
        else
          const CircleAvatar(
            radius: 45,
            child: Icon(Icons.person, size: 40),
          ),
        const SizedBox(height: 20),
        _infoTile('ID', '${userInfo.id ?? ''}'),
        _infoTile('Email', userInfo.email),
        _infoTile('Tên', userInfo.name ?? ''),
        _infoTile('Role', userInfo.role ?? ''),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }
}

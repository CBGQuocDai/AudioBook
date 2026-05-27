import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_client/src/auth/models/user_info.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/util/routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: AuthApiService.defaultBaseUrl,
  );

  final _tokenStorageService = TokenStorageService();
  final _authApiService = AuthApiService(baseUrl: _baseUrl);
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isUpdatingAvatar = false;
  String? _error;
  UserInfo? _userInfo;

  bool get _isPremium {
    final tier = _userInfo?.tier?.toUpperCase() ?? '';
    if (tier == 'PREMIUM' || tier == 'VIP') {
      return true;
    }

    final role = _userInfo?.role?.toUpperCase() ?? '';
    return role == 'PREMIUM' || role == 'VIP';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const AuthApiException('Phiên đăng nhập đã hết hạn.');
      }
      final response = await _authApiService.getCurrentUser(token);
      if (!mounted) return;
      setState(() {
        _userInfo = response.data;
      });
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openAndRefresh(String routeName, {Object? args}) async {
    await Navigator.pushNamed(context, routeName, arguments: args);
    if (!mounted) return;
    _loadProfile();
  }

  Future<void> _logout() async {
    final token = await _tokenStorageService.getToken();
    try {
      if (token != null && token.isNotEmpty) {
        await _authApiService.logout(token);
      }
    } catch (_) {
      // ignore logout API errors and still clear local session
    }

    await _tokenStorageService.clearToken();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  Future<void> _showAvatarActionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1C24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                const Text(
                  'Cập nhật avatar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                _avatarActionTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Chụp ảnh mới',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSaveAvatar(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                _avatarActionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Chọn từ thư viện',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSaveAvatar(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF252830),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(
                      color: Color(0xFFFF9A27),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _avatarActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF22252E),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0x33FF9800),
              ),
              child: Icon(icon, color: const Color(0xFFFF9A27), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8D93A6)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSaveAvatar(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
      );
      if (picked == null) return;

      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw const AuthApiException('Phiên đăng nhập đã hết hạn.');
      }

      setState(() => _isUpdatingAvatar = true);

      final uploaded = await _authApiService.uploadAvatarFile(
        token: token,
        file: File(picked.path),
      );
      final fileId = uploaded.data?.id;
      if (fileId == null || fileId <= 0) {
        throw const AuthApiException('Upload ảnh không trả về id hợp lệ.');
      }

      final changed = await _authApiService.changeAvatar(
        token: token,
        fileId: fileId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(changed.message)),
      );
      await _loadProfile();
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
      }
    }
  }

  Future<void> _onBottomNavTap(int index) async {
    if (index == 1) {
      await Navigator.pushNamed(context, AppRoutes.buyCredit);
      return;
    }
    if (index == 3) return;
    if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.discovery);
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.discovery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF161A24),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2E3A), Color(0xFF171C28)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadProfile,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  : _buildContent(),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildContent() {
    final user = _userInfo;
    final displayName = (user?.name?.trim().isNotEmpty ?? false)
        ? user!.name!.trim()
        : 'Người dùng';
    final avatarUrl = user?.avatarFile?.filePath ?? user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    final avatarChar = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'U';

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFFFA321),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF202432),
                          backgroundImage:
                              hasAvatar ? NetworkImage(avatarUrl) : null,
                          child: hasAvatar
                              ? null
                              : Text(
                                  avatarChar,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: GestureDetector(
                          onTap:
                              _isUpdatingAvatar ? null : _showAvatarActionSheet,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF161A24),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFFFA321)),
                            ),
                            child: _isUpdatingAvatar
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFFA321),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Color(0xFFFFA321),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_isPremium) ...[
                const SizedBox(height: 8),
                Align(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0x33FFB338),
                      border: Border.all(color: const Color(0x66FFB338)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          size: 16,
                          color: Color(0xFFFFB338),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Hội viên',
                          style: TextStyle(
                            color: Color(0xFFFFB338),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 34),
              if (!_isPremium)
                InkWell(
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.premiumPlan,
                    );
                    if (!mounted) return;
                    if (result == true) {
                      await _loadProfile();
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF493017), Color(0xFF40372A)],
                      ),
                      border: Border.all(color: const Color(0xAAFF9B29)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mở khóa Hội viên',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Nghe không giới hạn & nội dung độc quyền',
                                style: TextStyle(
                                    color: Color(0xFFB7B8BD), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFFF9B29),
                          child: Icon(Icons.arrow_forward,
                              size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_isPremium) const SizedBox(height: 18),
              const SizedBox(height: 28),
              _menuTile(
                icon: Icons.person_outline,
                iconColor: const Color(0xFF5EA0FF),
                title: 'Đổi tên người dùng',
                onTap: () => _openAndRefresh(
                  AppRoutes.changeUsername,
                  args: user?.name ?? '',
                ),
              ),
              _menuTile(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF9E74FF),
                title: 'Đổi email',
                onTap: () => _openAndRefresh(
                  AppRoutes.changeEmail,
                  args: user?.email ?? '',
                ),
              ),
              _menuTile(
                icon: Icons.lock_outline,
                iconColor: const Color(0xFF29CC74),
                title: 'Đổi mật khẩu',
                onTap: () => _openAndRefresh(AppRoutes.changePassword),
              ),
              _menuTile(
                icon: Icons.credit_card,
                iconColor: const Color(0xFF2AC77A),
                title: 'Quản lý hội viên',
                onTap: () => _openAndRefresh(AppRoutes.subscription),
              ),
              _menuTile(
                icon: Icons.logout,
                iconColor: const Color(0xFFFF5D5D),
                title: 'Đăng xuất',
                textColor: const Color(0xFFFF6767),
                onTap: _logout,
                showChevron: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    bool showChevron = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0x80303A4D),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: iconColor.withValues(alpha: 0.18),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (showChevron)
                const Icon(Icons.chevron_right, color: Color(0xFF6C7282)),
            ],
          ),
        ),
      ),
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
    final isSelected = index == 3;
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

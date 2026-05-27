import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_client/src/auth/models/user_info.dart';
import 'package:mobile_client/src/auth/services/auth_api_service.dart';
import 'package:mobile_client/src/auth/services/client_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/util/routes.dart';

/// Màn hình hồ sơ cá nhân của người dùng (Profile Screen).
///
/// Hiển thị thông tin tên hiển thị, email, avatar, huy hiệu Premium (nếu là hội viên)
/// và các tùy chọn điều hướng sang đổi tên, đổi email, đổi mật khẩu, quản lý gói hội viên hoặc đăng xuất.
class ProfileScreen extends StatefulWidget {
  /// Khởi tạo [ProfileScreen].
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ClientApiService.defaultBaseUrl,
  );

  final _tokenStorageService = TokenStorageService();
  final _authApiService = AuthApiService(baseUrl: _baseUrl);
  final _clientApiService = ClientApiService(baseUrl: _baseUrl);
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isUpdatingAvatar = false;
  String? _error;
  UserInfo? _userInfo;

  /// Cờ kiểm tra tài khoản người dùng có quyền hội viên (Premium hoặc VIP) hay không.
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

  /// Tải thông tin tài khoản người dùng hiện tại từ máy chủ để hiển thị trên giao diện.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _tokenStorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Phiên đăng nhập đã hết hạn.');
      }
      final response = await _clientApiService.getCurrentUser(token);
      if (!mounted) return;
      setState(() {
        _userInfo = response.data;
      });
    } on ClientApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
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

  /// Mở màn hình thiết lập con theo tên đường dẫn [routeName], sau khi màn hình đó đóng sẽ tự động gọi [_loadProfile] để cập nhật lại dữ liệu.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [routeName]: Tên đường dẫn màn hình cần điều hướng.
  ///   - [args]: Đối số truyền kèm sang màn hình đó.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  Future<void> _openAndRefresh(String routeName, {Object? args}) async {
    await Navigator.pushNamed(context, routeName, arguments: args);
    if (!mounted) return;
    _loadProfile();
  }

  /// Thực hiện đăng xuất tài khoản:
  /// 1. Gửi yêu cầu đăng xuất lên Backend thông qua [AuthApiService.logout].
  /// 2. Xóa sạch thông tin token lưu cục bộ thông qua [TokenStorageService.clearToken].
  /// 3. Điều hướng người dùng về màn hình đăng nhập [AppRoutes.login].
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
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

  /// Hiển thị danh sách các lựa chọn cập nhật ảnh đại diện (chụp ảnh mới hoặc chọn từ thư viện) thông qua Bottom Sheet.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
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

  /// Tạo một dòng lựa chọn hành động cập nhật ảnh đại diện.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [icon]: [IconData] biểu tượng hiển thị cho hành động.
  ///   - [title]: [String] tiêu đề mô tả hành động.
  ///   - [onTap]: [VoidCallback] hàm callback xử lý khi người dùng chọn.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về widget [Widget] giao diện dòng lựa chọn.
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

  /// Thực hiện chọn ảnh từ camera hoặc thư viện thiết bị và tải lên làm ảnh đại diện mới.
  ///
  /// Phương thức này thực hiện:
  /// 1. Mở camera hoặc thư viện bằng [ImagePicker.pickImage].
  /// 2. Tải tệp tin ảnh lên máy chủ thông qua [ClientApiService.uploadAvatarFile].
  /// 3. Thay đổi ảnh đại diện tài khoản bằng cách cập nhật ID tệp qua [ClientApiService.changeAvatar].
  /// 4. Làm mới thông tin hồ sơ bằng cách gọi lại [_loadProfile].
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [source]: Nguồn lấy ảnh (Camera hoặc Gallery).
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
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

      final uploaded = await _clientApiService.uploadAvatarFile(
        token: token,
        file: File(picked.path),
      );
      final fileId = uploaded.data?.id;
      if (fileId == null || fileId <= 0) {
        throw Exception('Upload ảnh không trả về id hợp lệ.');
      }

      final changed = await _clientApiService.changeAvatar(
        token: token,
        fileId: fileId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(changed.message)),
      );
      await _loadProfile();
    } on ClientApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
      }
    }
  }

  /// Xử lý sự kiện điều hướng khi người dùng nhấn vào các mục trên thanh Bottom Navigation Bar.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [index]: [int] chỉ số (0-3) của mục được nhấn.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
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

  /// Xây dựng nội dung giao diện hiển thị thông tin chi tiết hồ sơ cá nhân của người dùng.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về widget [Widget] giao diện chính của trang cá nhân.
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

  /// Tạo một mục menu điều hướng trong danh sách thiết lập tài khoản.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [icon]: [IconData] biểu tượng hiển thị bên trái.
  ///   - [iconColor]: [Color] màu sắc của biểu tượng.
  ///   - [title]: [String] nhãn tiêu đề của mục menu.
  ///   - [onTap]: [VoidCallback] hàm callback kích hoạt khi người dùng nhấn vào.
  ///   - [textColor]: [Color] màu sắc của chữ tiêu đề (mặc định là trắng).
  ///   - [showChevron]: [bool] quyết định hiển thị mũi tên chevron chỉ hướng bên phải (mặc định là true).
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về widget [Widget] cấu trúc một dòng menu.
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

  /// Xây dựng thanh Bottom Navigation Bar phía dưới màn hình.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về widget [Widget] thanh điều hướng dưới.
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

  /// Tạo một nút điều hướng cụ thể trên thanh Bottom Navigation Bar.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [icon]: [IconData] biểu tượng trạng thái bình thường.
  ///   - [selectedIcon]: [IconData] biểu tượng khi mục này đang được chọn.
  ///   - [label]: [String] nhãn văn bản hiển thị dưới biểu tượng.
  ///   - [index]: [int] chỉ mục tương ứng của nút này.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về widget [Widget] hiển thị nút điều hướng.
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

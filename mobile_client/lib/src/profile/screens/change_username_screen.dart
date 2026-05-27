import 'package:flutter/material.dart';
import 'package:mobile_client/src/auth/services/client_api_service.dart';
import 'package:mobile_client/src/auth/services/token_storage_service.dart';
import 'package:mobile_client/src/core/utils/error_translator.dart';
import 'package:mobile_client/src/core/widgets/form_error_widget.dart';

/// Màn hình thay đổi tên người dùng (Change Username Screen).
///
/// Cho phép người dùng cập nhật lại họ tên hiển thị của mình trên hệ thống.
class ChangeUsernameScreen extends StatefulWidget {
  /// Khởi tạo [ChangeUsernameScreen].
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ClientApiService.defaultBaseUrl,
  );

  final _newNameController = TextEditingController();
  final _clientApiService = ClientApiService(baseUrl: _baseUrl);
  final _tokenStorageService = TokenStorageService();

  bool _isLoading = false;
  String _currentName = '';
  String _nameError = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _currentName.isEmpty) {
      _currentName = args;
    }
  }

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  /// Hợp lệ hóa tên người dùng nhập vào.
  ///
  /// Yêu cầu: Không rỗng, dài từ 4-15 ký tự và không chứa các ký tự đặc biệt.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [bool] xác định tính hợp lệ của tên.
  bool _validateField() {
    setState(() => _nameError = '');

    final name = _newNameController.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = 'Vui lòng nhập tên mới');
      return false;
    }

    if (!RegExp(r'^[a-zA-Z0-9 ]{4,15}').hasMatch(name)) {
      setState(() => _nameError = 'Tên 4-15 ký tự, không chứa ký tự đặc biệt');
      return false;
    }

    return true;
  }

  /// Gửi yêu cầu lưu tên người dùng mới lên máy chủ.
  ///
  /// Phương thức này thực hiện:
  /// 1. Kiểm tra tính hợp lệ dữ liệu nhập qua [_validateField].
  /// 2. Gửi yêu cầu đổi tên qua [ClientApiService.changeUserName].
  /// 3. Nếu thành công, quay về màn hình trước đó và trả về `true` biểu thị cập nhật thành công.
  ///
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về [Future<void>].
  Future<void> _save() async {
    if (!_validateField()) return;

    final token = await _tokenStorageService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập đã hết hạn.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _clientApiService.changeUserName(
        token: token,
        name: _newNameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      Navigator.pop(context, true);
    } on ClientApiException catch (e) {
      if (!mounted) return;
      final message = ErrorTranslator.translate(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF22242D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF22242D),
        title: const Text('Đổi tên người dùng'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'TÊN HIỆN TẠI',
                style: TextStyle(color: Color(0xFF8D95A8), fontSize: 11),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(
                  text: _currentName.isEmpty ? '-' : _currentName,
                ),
                enabled: false,
                decoration: InputDecoration(
                  suffixIcon: const Icon(Icons.lock_outline, size: 16),
                  filled: true,
                  fillColor: const Color(0xFF1D2331),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'TÊN MỚI',
                style: TextStyle(color: Color(0xFF8D95A8), fontSize: 11),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newNameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập tên người dùng mới',
                  filled: true,
                  fillColor: const Color(0xFF1D2331),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: _nameError.isNotEmpty
                        ? const BorderSide(color: Color(0xFFFF4444), width: 1)
                        : BorderSide.none,
                  ),
                ),
              ),
              if (_nameError.isNotEmpty) ...[
                const SizedBox(height: 6),
                FormErrorWidget(error: _nameError),
              ],
              const SizedBox(height: 10),
              const Text(
                'Tên phải 4-15 ký tự, không chứa ký tự đặc biệt.',
                style: TextStyle(color: Color(0xFF7C8292), fontSize: 11),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8B1F), Color(0xFFE96A15)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

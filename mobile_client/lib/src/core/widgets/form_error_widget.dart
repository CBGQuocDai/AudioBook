import 'package:flutter/material.dart';

/// Widget hiển thị thông báo lỗi của một trường nhập liệu dưới dạng văn bản màu đỏ.
///
/// Thường được đặt ở phía dưới trường nhập liệu (TextField) để chỉ ra lỗi hợp lệ hóa (validation error).
class FormErrorWidget extends StatelessWidget {
  /// Chuỗi chứa nội dung lỗi cần hiển thị. Nếu null hoặc rỗng, widget sẽ không hiển thị gì.
  final String? error;

  /// Khoảng đệm (Padding) xung quanh thông báo lỗi.
  final EdgeInsets padding;

  /// Khởi tạo [FormErrorWidget].
  const FormErrorWidget({
    super.key,
    this.error,
    this.padding = const EdgeInsets.only(top: 4, left: 12),
  });

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Text(
        error!,
        style: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 12,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Widget bọc sẵn trường nhập liệu [TextFormField] kèm theo nhãn tiêu đề (Label) và thông báo lỗi tích hợp ở phía dưới.
///
/// Hỗ trợ cấu hình nâng cao như hiển thị icon tiền tố/hậu tố, chế độ ẩn mật khẩu, cấu hình tự động thay đổi viền đỏ khi có lỗi.
class FormFieldWithError extends StatelessWidget {
  /// Nhãn hiển thị phía trên trường nhập liệu.
  final String label;

  /// Nội dung thông báo lỗi (nếu có). Khi có giá trị, viền của trường nhập liệu sẽ tự động chuyển sang màu đỏ.
  final String? error;

  /// Bộ điều khiển văn bản (Controller) để lấy hoặc thiết lập giá trị cho trường nhập liệu.
  final TextEditingController controller;

  /// Hàm kiểm tra tính hợp lệ của dữ liệu đầu vào.
  final String? Function(String?)? validator;

  /// Kiểu bàn phím hiển thị cho người dùng (ví dụ: emailAddress, phone, text).
  final TextInputType keyboardType;

  /// Cờ xác định xem có ẩn văn bản đi hay không (thường dùng cho mật khẩu).
  final bool obscureText;

  /// Icon hiển thị ở đầu trường nhập liệu (Prefix Icon).
  final IconData? prefixIcon;

  /// Icon hiển thị ở cuối trường nhập liệu (Suffix Icon).
  final IconData? suffixIcon;

  /// Hàm callback kích hoạt khi nhấn vào icon cuối trường nhập liệu.
  final VoidCallback? onSuffixIconTap;

  /// Văn bản gợi ý hiển thị bên trong trường nhập liệu khi chưa có dữ liệu.
  final String? hintText;

  /// Số dòng tối đa của trường nhập liệu. Mặc định là 1.
  final int? maxLines;

  /// Số dòng tối thiểu của trường nhập liệu.
  final int? minLines;

  /// Hàm callback được gọi mỗi khi nội dung trường nhập liệu thay đổi.
  final void Function(String)? onChanged;

  /// Khởi tạo [FormFieldWithError].
  const FormFieldWithError({
    super.key,
    required this.label,
    this.error,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.hintText,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E97AE),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF7D8599)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: const Color(0xFF7D8599), size: 18)
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    onPressed: onSuffixIconTap,
                    icon: Icon(suffixIcon, color: const Color(0xFF7D8599), size: 18),
                  )
                : null,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: error != null && error!.isNotEmpty
                  ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: error != null && error!.isNotEmpty
                  ? const BorderSide(color: Color(0xFFEF4444), width: 1.5)
                  : BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
          validator: validator,
        ),
        if (error != null && error!.isNotEmpty) ...[
          const SizedBox(height: 4),
          FormErrorWidget(error: error),
        ],
      ],
    );
  }
}

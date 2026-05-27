/// Đối tượng phản hồi chung từ API (Generic API Response wrapper).
///
/// Lớp này bọc toàn bộ dữ liệu trả về từ hệ thống API của Backend, bao gồm mã trạng thái, dữ liệu và thông điệp.
class ApiResponse<T> {
  /// Mã phản hồi của API (Ví dụ: 1000 cho thành công).
  final int code;

  /// Dữ liệu phản hồi chính thuộc kiểu generic [T], có thể null.
  final T? data;

  /// Thông điệp phản hồi từ API (ví dụ: 'success' hoặc thông báo lỗi).
  final String message;

  /// Khởi tạo [ApiResponse] với các giá trị mặc định.
  const ApiResponse({
    this.code = 1000,
    this.data,
    this.message = 'success',
  });
}

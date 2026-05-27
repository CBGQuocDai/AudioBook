/// Lớp biểu diễn thông tin file ảnh đại diện của người dùng.
class AvatarFile {
  /// ID của file ảnh trên hệ thống.
  final int? id;

  /// Đường dẫn lưu trữ file trên server.
  final String? filePath;

  /// Tên file ảnh đại diện.
  final String? fileName;

  /// Khởi tạo đối tượng [AvatarFile].
  const AvatarFile({
    this.id,
    this.filePath,
    this.fileName,
  });

  /// Tạo đối tượng [AvatarFile] từ dữ liệu định dạng JSON.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [json]: Bản đồ [Map] chứa dữ liệu JSON từ API.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [AvatarFile] tương ứng.
  factory AvatarFile.fromJson(Map<String, dynamic> json) {
    return AvatarFile(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      filePath: json['filePath']?.toString(),
      fileName: json['fileName']?.toString(),
    );
  }
}

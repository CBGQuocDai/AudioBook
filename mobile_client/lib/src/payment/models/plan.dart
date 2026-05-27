/// Lớp mô tả thông tin gói hội viên đăng ký (ví dụ: gói Premium 1 tháng).
class PlanModel {
  /// ID duy nhất của gói hội viên.
  final int id;

  /// Giá tiền đăng ký gói.
  final int price;

  /// Tên gọi của gói hội viên (ví dụ: 'Premium').
  final String name;

  /// Đơn vị thời gian gia hạn gói (ví dụ: 'MONTH', 'YEAR').
  final String timeUnit;

  /// Khởi tạo [PlanModel].
  const PlanModel({
    required this.id,
    required this.price,
    required this.name,
    required this.timeUnit,
  });

  /// Tạo đối tượng [PlanModel] từ dữ liệu JSON.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [json]: Bản đồ JSON chứa thông tin chi tiết gói hội viên.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [PlanModel] tương ứng.
  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      price: json['price'] is int ? json['price'] as int : int.tryParse('${json['price']}') ?? 0,
      name: json['name']?.toString() ?? '',
      timeUnit: json['timeUnit']?.toString() ?? '',
    );
  }
}

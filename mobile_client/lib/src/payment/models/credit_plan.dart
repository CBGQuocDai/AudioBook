/// Lớp mô tả thông tin của một gói xu/credit (ví dụ nạp 100 xu).
class CreditPlanModel {
  /// ID duy nhất của gói credit.
  final int id;

  /// Giá tiền của gói (đơn vị tiền tệ tương ứng).
  final int price;

  /// Tên của gói credit.
  final String name;

  /// Số lượng credit sẽ nhận được sau khi mua gói.
  final String amount;

  /// Khởi tạo [CreditPlanModel].
  const CreditPlanModel({
    required this.id,
    required this.price,
    required this.name,
    required this.amount,
  });

  /// Tạo đối tượng [CreditPlanModel] từ dữ liệu JSON.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [json]: Bản đồ JSON chứa thông tin gói credit.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [CreditPlanModel] tương ứng.
  factory CreditPlanModel.fromJson(Map<String, dynamic> json) {
    return CreditPlanModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      price: json['price'] is int
          ? json['price'] as int
          : int.tryParse('${json['price']}') ?? 0,
      name: json['name']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
    );
  }
}

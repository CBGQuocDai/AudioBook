/// Lớp mô tả một bản ghi trong lịch sử thanh toán đăng ký gói hội viên của người dùng.
class SubscriptionHistoryItem {
  /// Tên của gói hội viên đã mua (ví dụ: 'Premium').
  final String planName;

  /// Giá tiền của gói đã thanh toán.
  final int price;

  /// Đơn vị chu kỳ thời gian (ví dụ: 'MONTH').
  final String timeUnit;

  /// Ngày bắt đầu kích hoạt giao dịch mua này.
  final String startDate;

  /// Trạng thái của chu kỳ đăng ký tương ứng (ví dụ: 'ACTIVE', 'EXPIRED').
  final String status;

  /// Khởi tạo [SubscriptionHistoryItem].
  const SubscriptionHistoryItem({
    required this.planName,
    required this.price,
    required this.timeUnit,
    required this.startDate,
    required this.status,
  });

  /// Tạo đối tượng [SubscriptionHistoryItem] từ dữ liệu JSON.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [json]: Bản đồ JSON chứa thông tin lịch sử thanh toán chu kỳ đăng ký.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [SubscriptionHistoryItem].
  factory SubscriptionHistoryItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryItem(
      planName: json['planName']?.toString() ?? '',
      price: json['price'] is int
          ? json['price'] as int
          : int.tryParse('${json['price']}') ?? 0,
      timeUnit: json['timeUnit']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

/// Lớp chứa thông tin gói đăng ký hội viên hiện tại và lịch sử thanh toán đi kèm.
class SubscriptionInfo {
  /// Tên gói hội viên hiện tại (ví dụ: 'Premium').
  final String planName;

  /// Trạng thái đăng ký hiện tại (ví dụ: 'ACTIVE', 'CANCELED').
  final String status;

  /// Ngày thanh toán gia hạn tiếp theo.
  final String nextBillingDate;

  /// Giá của chu kỳ đăng ký hiện tại.
  final int price;

  /// Đơn vị thời gian chu kỳ đăng ký.
  final String timeUnit;

  /// Danh sách lịch sử các hóa đơn thanh toán của gói đăng ký này.
  final List<SubscriptionHistoryItem> billingHistory;

  /// Khởi tạo [SubscriptionInfo].
  const SubscriptionInfo({
    required this.planName,
    required this.status,
    required this.nextBillingDate,
    required this.price,
    required this.timeUnit,
    required this.billingHistory,
  });

  /// Tạo đối tượng [SubscriptionInfo] từ dữ liệu JSON.
  ///
  /// * **Tham số đầu vào (Input):**
  ///   - [json]: Bản đồ JSON phản hồi từ API chứa thông tin đăng ký.
  /// * **Kết quả đầu ra (Output):**
  ///   - Trả về đối tượng [SubscriptionInfo].
  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['billingHistory'];
    final history = rawHistory is List
        ? rawHistory
            .whereType<Map<String, dynamic>>()
            .map(SubscriptionHistoryItem.fromJson)
            .toList()
        : <SubscriptionHistoryItem>[];

    return SubscriptionInfo(
      planName: json['planName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      nextBillingDate: json['nextBillingDate']?.toString() ?? '',
      price: json['price'] is int
          ? json['price'] as int
          : int.tryParse('${json['price']}') ?? 0,
      timeUnit: json['timeUnit']?.toString() ?? '',
      billingHistory: history,
    );
  }
}

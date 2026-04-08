class SubscriptionHistoryItem {
  final String planName;
  final int price;
  final String timeUnit;
  final String startDate;
  final String status;

  const SubscriptionHistoryItem({
    required this.planName,
    required this.price,
    required this.timeUnit,
    required this.startDate,
    required this.status,
  });

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

class SubscriptionInfo {
  final String planName;
  final String status;
  final String nextBillingDate;
  final int price;
  final String timeUnit;
  final List<SubscriptionHistoryItem> billingHistory;

  const SubscriptionInfo({
    required this.planName,
    required this.status,
    required this.nextBillingDate,
    required this.price,
    required this.timeUnit,
    required this.billingHistory,
  });

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

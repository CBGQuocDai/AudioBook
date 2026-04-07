import '../../user/models/file_dto.dart';

class TimeSeriesPoint {
  final String label;
  final int value;

  const TimeSeriesPoint({
    required this.label,
    required this.value,
  });

  factory TimeSeriesPoint.fromJson(Map<String, dynamic> json) {
    return TimeSeriesPoint(
      label: json['label']?.toString() ?? '',
      value: _toInt(json['value']),
    );
  }
}

class UserDashboardData {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int usersThisMonth;
  final int usersLastMonth;
  final double growthPercent;
  final String growthDirection;
  final List<TimeSeriesPoint> dailyRegistrations;
  final List<TimeSeriesPoint> monthlyRegistrations;

  const UserDashboardData({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.usersThisMonth,
    required this.usersLastMonth,
    required this.growthPercent,
    required this.growthDirection,
    required this.dailyRegistrations,
    required this.monthlyRegistrations,
  });

  factory UserDashboardData.fromJson(Map<String, dynamic> json) {
    return UserDashboardData(
      totalUsers: _toInt(json['totalUsers']),
      activeUsers: _toInt(json['activeUsers']),
      inactiveUsers: _toInt(json['inactiveUsers']),
      usersThisMonth: _toInt(json['usersThisMonth']),
      usersLastMonth: _toInt(json['usersLastMonth']),
      growthPercent: _toDouble(json['growthPercent']),
      growthDirection: json['growthDirection']?.toString() ?? 'FLAT',
      dailyRegistrations: _parsePoints(json['dailyRegistrations']),
      monthlyRegistrations: _parsePoints(json['monthlyRegistrations']),
    );
  }
}

class BookTopPurchased {
  final int bookId;
  final String name;
  final String author;
  final FileDto? coverFile;
  final int purchasedCount;

  const BookTopPurchased({
    required this.bookId,
    required this.name,
    required this.author,
    this.coverFile,
    required this.purchasedCount,
  });

  factory BookTopPurchased.fromJson(Map<String, dynamic> json) {
    return BookTopPurchased(
      bookId: _toInt(json['bookId']),
      name: json['name']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      coverFile: json['coverFile'] is Map<String, dynamic>
          ? FileDto.fromJson(json['coverFile'] as Map<String, dynamic>)
          : null,
      purchasedCount: _toInt(json['purchasedCount']),
    );
  }
}

class BookDashboardData {
  final int totalBooks;
  final List<BookTopPurchased> topPurchasedBooks;

  const BookDashboardData({
    required this.totalBooks,
    required this.topPurchasedBooks,
  });

  factory BookDashboardData.fromJson(Map<String, dynamic> json) {
    final items = (json['topPurchasedBooks'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(BookTopPurchased.fromJson)
        .toList();

    return BookDashboardData(
      totalBooks: _toInt(json['totalBooks']),
      topPurchasedBooks: items,
    );
  }
}

class PaymentCurrencySummary {
  final String currency;
  final int totalAmount;
  final int transactionCount;

  const PaymentCurrencySummary({
    required this.currency,
    required this.totalAmount,
    required this.transactionCount,
  });

  factory PaymentCurrencySummary.fromJson(Map<String, dynamic> json) {
    return PaymentCurrencySummary(
      currency: json['currency']?.toString() ?? '',
      totalAmount: _toInt(json['totalAmount']),
      transactionCount: _toInt(json['transactionCount']),
    );
  }
}

class PaymentDashboardData {
  final int totalDepositedAmount;
  final int successfulTransactionCount;
  final List<PaymentCurrencySummary> currencySummaries;

  const PaymentDashboardData({
    required this.totalDepositedAmount,
    required this.successfulTransactionCount,
    required this.currencySummaries,
  });

  factory PaymentDashboardData.fromJson(Map<String, dynamic> json) {
    final items = (json['currencySummaries'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PaymentCurrencySummary.fromJson)
        .toList();

    return PaymentDashboardData(
      totalDepositedAmount: _toInt(json['totalDepositedAmount']),
      successfulTransactionCount: _toInt(json['successfulTransactionCount']),
      currencySummaries: items,
    );
  }
}

class AdminDashboardBundle {
  final UserDashboardData users;
  final BookDashboardData books;
  final PaymentDashboardData payments;

  const AdminDashboardBundle({
    required this.users,
    required this.books,
    required this.payments,
  });
}

List<TimeSeriesPoint> _parsePoints(dynamic raw) {
  return (raw as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(TimeSeriesPoint.fromJson)
      .toList();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

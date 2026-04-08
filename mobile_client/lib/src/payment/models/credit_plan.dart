class CreditPlanModel {
  final int id;
  final int price;
  final String name;
  final String amount;

  const CreditPlanModel({
    required this.id,
    required this.price,
    required this.name,
    required this.amount,
  });

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

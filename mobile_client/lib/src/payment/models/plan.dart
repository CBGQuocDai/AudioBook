class PlanModel {
  final int id;
  final int price;
  final String name;
  final String timeUnit;

  const PlanModel({
    required this.id,
    required this.price,
    required this.name,
    required this.timeUnit,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      price: json['price'] is int ? json['price'] as int : int.tryParse('${json['price']}') ?? 0,
      name: json['name']?.toString() ?? '',
      timeUnit: json['timeUnit']?.toString() ?? '',
    );
  }
}

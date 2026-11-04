
class BudgetModel {
  final int? id;
  final int categoryId;
  final String month;
  final double amount;

  BudgetModel({
    this.id,
    required this.categoryId,
    required this.month,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'month': month,
      'amount': amount,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      month: map['month'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}


class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final int categoryId;
  final DateTime date;
  final String type;
  final String note;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.type,
    this.note = '',
  });

  // Convert transaction into a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'type': type,
      'note': note,
    };
  }

  // Convert database Map back into a transaction
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      note: map['note'] ?? '',
    );
  }
}

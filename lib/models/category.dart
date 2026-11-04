
class CategoryModel {
  final int? id;
  final String name;
  final String type;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
  });

  // Convert category into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  // Convert Map into a Category object
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
    );
  }
}

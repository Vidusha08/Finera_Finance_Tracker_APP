//models/category.dart

class CategoryModel {
  final int? id;
  final String name;
  final String type; // "Income" or "Expense"
  final String color; // hex like #007bff
  final String? icon; // icon name string

  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.color,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      color: json['color'] as String? ?? '#007bff',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
    };
  }
}
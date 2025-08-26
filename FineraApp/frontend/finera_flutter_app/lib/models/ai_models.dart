// models/ai_models.dart

class AiSuggestionItem {
  final String title;
  final String description;
  final String category;
  final double estimatedCost;

  AiSuggestionItem({
    required this.title,
    required this.description,
    required this.category,
    required this.estimatedCost,
  });

  factory AiSuggestionItem.fromJson(Map<String, dynamic> json) {
    return AiSuggestionItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

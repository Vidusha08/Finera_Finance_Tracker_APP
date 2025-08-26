// services/ai_service.dart

import 'dart:convert';
import 'api_client.dart';
import '../models/ai_models.dart';

class AiService {
  
  AiService();

  Future<List<AiSuggestionItem>> getSuggestions({
    required double amount,
    String? location,
    String currency = "LKR",
    List<String>? categories,
  }) async {
    final body = {
      "Amount": amount,
      "Location": location,
      "Currency": currency,
      "Categories": categories
    };

    final res = await ApiClient.post("/api/ai/suggestions", body);
    if (res.statusCode != 200) {
      throw Exception("AI error ${res.statusCode}: ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data["suggestions"] as List<dynamic>? ?? []);
    return list.map((e) => AiSuggestionItem.fromJson(e)).toList();
  }
}

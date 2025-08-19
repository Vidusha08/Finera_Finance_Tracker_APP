//services/api_client.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_store.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:5049';

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStore.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Future<http.Response> get(String path) async {
    final headers = await _headers();
    return await http.get(_uri(path), headers: headers);
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    return await http.post(_uri(path), headers: headers, body: json.encode(body));
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    return await http.put(_uri(path), headers: headers, body: json.encode(body));
  }

  static Future<http.Response> delete(String path) async {
    final headers = await _headers();
    return await http.delete(_uri(path), headers: headers);
  }
}

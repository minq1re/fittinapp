import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://109.172.7.214:8080/api/v1';
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Future<String?> createTestTaker({required bool isMale}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/test_taker'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'is_male': isMale}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access_token'];
      return _token;
    } else {
      print('createTestTaker error: \\${response.statusCode} \\${response.body}');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getRandomQuestion() async {
    final response = await http.get(
      Uri.parse('$baseUrl/question/random'),
      headers: authHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('getRandomQuestion error: \\${response.statusCode} \\${response.body}');
    }
    return null;
  }

  Future<bool> sendAnswer({required String questionId, required String option}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/answer'),
      headers: authHeaders(),
      body: jsonEncode({'question': questionId, 'option': option}),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print('sendAnswer error: \\${response.statusCode} \\${response.body}');
    }
    return false;
  }

  Future<Map<String, dynamic>?> getResult() async {
    final response = await http.get(
      Uri.parse('$baseUrl/result'),
      headers: authHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('getResult error: \\${response.statusCode} \\${response.body}');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCategoryResults(String resultId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/category-results/$resultId'),
      headers: authHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('getCategoryResults error: \\${response.statusCode} \\${response.body}');
    }
    return null;
  }

  Future<int?> getQuestionCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/question/count'),
      headers: authHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] as int;
    }
    return null;
  }

  Future<String?> getResultId() async {
    final url = '$baseUrl/result';
    final headers = authHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as String?;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getMainCategoryResults(String resultId) async {
    final url = '$baseUrl/category_results/main/$resultId';
    final headers = authHeaders();
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['category_results']);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getOtherCategoryResults(String resultId) async {
    final url = '$baseUrl/category_results/other/$resultId';
    final headers = authHeaders();
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['category_results']);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUiAnalysisResult(String resultId) async {
    final url = '$baseUrl/ui_analysis/$resultId';
    final headers = authHeaders();
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Map<String, String> authHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
  }
} 
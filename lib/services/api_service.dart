import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(
      String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> changeRole(String role) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('$baseUrl/accounts/change-role/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'role': role}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getFarmerProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/farmer/profile/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateFarmerProfile({
    String? farmName,
    String? address,
    double? lat,
    double? lon,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{};

    if (farmName != null) body['farm_name'] = farmName;
    if (address != null) body['address'] = address;
    if (lat != null) body['lat'] = lat;
    if (lon != null) body['lon'] = lon;

    final response = await http.patch(
      Uri.parse('$baseUrl/accounts/farmer/profile/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/'),
      headers: {'Content-Type': 'application/json'},
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getProducts() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/products/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> compareRoutes(
      List<int> productIds, double startLat, double startLon) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/routing/compare/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_ids': productIds,
        'start': {'lat': startLat, 'lon': startLon},
        'road_quality': 'medium',
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getOrders() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  static Future<http.Response> _request(
      Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException(
        'Сервер не ответил вовремя. Проверь API_BASE_URL: $baseUrl',
      );
    } on http.ClientException {
      throw ApiException(
        'Нет соединения с сервером. Проверь API_BASE_URL: $baseUrl',
      );
    } on Exception catch (e) {
      throw ApiException('Сетевая ошибка: $e');
    }
  }

  static Future<http.Response> _send(
      Future<http.Response> Function() request) {
    return _request(request);
  }

  static dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  static List<dynamic> _decodeList(http.Response response) {
    final decoded = _decodeBody(response);
    if (decoded is List<dynamic>) return decoded;
    return [];
  }

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeMap(response);
      final detail = body['detail']?.toString() ?? 'Server error';
      throw ApiException(detail, response.statusCode);
    }
  }

  // ── Token ──────────────────────────────────────────────────────

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

  // ── Auth ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/accounts/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> register(
      String email, String password, String role) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/accounts/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> verifyEmail(
      String email, String code) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/accounts/verify/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> resendCode(String email) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/accounts/resend-code/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/accounts/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> changeRole(String role) async {
    final token = await getToken();
    final response = await _send(
      () => http.patch(
        Uri.parse('$baseUrl/accounts/change-role/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'role': role}),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  // ── Farmer Profile ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> getFarmerProfile() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/accounts/farmer/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
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

    final response = await _send(
      () => http.patch(
        Uri.parse('$baseUrl/accounts/farmer/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  // ── Products ───────────────────────────────────────────────────

  static Future<List<dynamic>> getCategories() async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _ensureSuccess(response);
    return _decodeList(response);
  }

  static Future<List<dynamic>> getProducts() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _ensureSuccess(response);
    final decoded = _decodeBody(response);
    if (decoded is Map && decoded.containsKey('results')) {
        return decoded['results'] as List<dynamic>;
    }
    if (decoded is List) return decoded;
    return [];
  }

  static Future<Map<String, dynamic>> createProduct({
    required String title,
    required String price,
    String? weightKg,
    String? description,
    int? categoryId,
    int? quantity,
    String? imageUrl,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{
      'title': title,
      'price': price,
    };
    if (weightKg != null && weightKg.isNotEmpty) body['weight_kg'] = weightKg;
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (categoryId != null) body['category'] = categoryId;
    if (quantity != null) body['quantity'] = quantity;
    if (imageUrl != null && imageUrl.isNotEmpty) body['image'] = imageUrl;

    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/products/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  // ── Routing ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> compareRoutes(
    List<int> productIds,
    double startLat,
    double startLon, {
    double? fuelPrice,
    double? fuelConsumption,
    String roadQuality = 'medium',
  }) async {
    final token = await getToken();
    final payload = <String, dynamic>{
      'product_ids': productIds,
      'start': {'lat': startLat, 'lon': startLon},
      'road_quality': roadQuality,
    };
    if (fuelPrice != null) payload['fuel_price'] = fuelPrice;
    if (fuelConsumption != null) payload['fuel_consumption'] = fuelConsumption;

    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/routing/compare/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  // ── Orders ─────────────────────────────────────────────────────

  static Future<List<dynamic>> getOrders() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/orders/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _ensureSuccess(response);
    return _decodeList(response);
  }

  static Future<Map<String, dynamic>> createOrder({
    required String deliveryName,
    required String deliveryAddress,
    required String deliveryPhone,
    String deliveryCity = 'Бишкек',
    String? comment,
    required List<Map<String, dynamic>> items,
  }) async {
    final token = await getToken();
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/orders/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'delivery_name': deliveryName,
          'delivery_address': deliveryAddress,
          'delivery_phone': deliveryPhone,
          'delivery_city': deliveryCity,
          'comment': comment ?? '',
          'items': items,
        }),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  // ── Likes & Reviews ────────────────────────────────────────────

  static Future<Map<String, dynamic>> toggleLike(int productId) async {
    final token = await getToken();
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/products/$productId/like/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<List<dynamic>> getReviews(int productId) async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/products/$productId/reviews/'),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _ensureSuccess(response);
    return _decodeList(response);
  }

  static Future<Map<String, dynamic>> addReview(
      int productId, int rating, String text) async {
    final token = await getToken();
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/products/$productId/reviews/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rating': rating, 'text': text}),
      ),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
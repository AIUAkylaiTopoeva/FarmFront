import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL');

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
      throw ApiException('Сервер не ответил вовремя. API: $baseUrl');
    } on http.ClientException {
      throw ApiException('Нет соединения с сервером. API: $baseUrl');
    } on Exception catch (e) {
      throw ApiException('Сетевая ошибка: $e');
    }
  }

  static Future<http.Response> _send(
          Future<http.Response> Function() request) =>
      _request(request);

  static dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
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
      final detail = body['detail']?.toString() ?? 'Ошибка сервера';
      throw ApiException(detail, response.statusCode);
    }
  }

  // Token
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

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _send(
      () => http.post(Uri.parse('$baseUrl/accounts/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password})),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> register(String email, String password, String role) async {
    final response = await _send(
      () => http.post(Uri.parse('$baseUrl/accounts/register/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password, 'role': role})),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final response = await _send(
      () => http.post(Uri.parse('$baseUrl/accounts/verify/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'code': code})),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> resendCode(String email) async {
    final response = await _send(
      () => http.post(Uri.parse('$baseUrl/accounts/resend-code/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email})),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/accounts/me/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? phone,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (phone != null) body['phone'] = phone;
    final response = await _send(
      () => http.patch(Uri.parse('$baseUrl/accounts/me/'),
          headers: {'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'},
          body: jsonEncode(body)),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> changeRole(String role) async {
    final token = await getToken();
    final response = await _send(
      () => http.patch(Uri.parse('$baseUrl/accounts/change-role/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'role': role})),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  // Farmer Profile
  static Future<Map<String, dynamic>> getFarmerProfile() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/accounts/farmer/profile/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> updateFarmerProfile({
    String? farmName, String? address, double? lat, double? lon,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{};
    if (farmName != null) body['farm_name'] = farmName;
    if (address != null) body['address'] = address;
    if (lat != null) body['lat'] = lat;
    if (lon != null) body['lon'] = lon;
    final response = await _send(
      () => http.patch(Uri.parse('$baseUrl/accounts/farmer/profile/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(body)),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  // Farmers Map
  static Future<List<dynamic>> getFarmersMap() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/accounts/farmers/map/'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          }),
    );
    _ensureSuccess(response);
    return _decodeList(response);
  }

  // Admin Users
  static Future<List<dynamic>> getAdminUsers() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/accounts/users/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 404 || response.statusCode == 403) return [];
    _ensureSuccess(response);
    final decoded = _decodeBody(response);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded.containsKey('results')) return decoded['results'] as List<dynamic>;
    return [];
  }

  // Categories
  static Future<List<dynamic>> getCategories() async {
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/categories/'),
          headers: {'Content-Type': 'application/json'}),
    );
    _ensureSuccess(response);
    return _decodeList(response);
  }

  // Products
  static Future<List<dynamic>> getProducts() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/products/'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          }),
    );
    _ensureSuccess(response);
    final decoded = _decodeBody(response);
    if (decoded is Map && decoded.containsKey('results')) return decoded['results'] as List<dynamic>;
    if (decoded is List) return decoded;
    return [];
  }

  static Future<List<dynamic>> getMyProducts() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/products/my/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    _ensureSuccess(response);
    final decoded = _decodeBody(response);
    if (decoded is Map && decoded.containsKey('results')) return decoded['results'] as List<dynamic>;
    if (decoded is List) return decoded;
    return [];
  }

  static Future<Map<String, dynamic>> createProduct({
    required String title, required String price,
    String? weightKg, String? description,
    int? categoryId, int? quantity, String? imageUrl,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{'title': title, 'price': price};
    if (weightKg != null && weightKg.isNotEmpty) body['weight_kg'] = weightKg;
    if (description != null && description.isNotEmpty) body['description'] = description;
    if (categoryId != null) body['category'] = categoryId;
    if (quantity != null) body['quantity'] = quantity;
    if (imageUrl != null && imageUrl.isNotEmpty) body['image'] = imageUrl;
    final response = await _send(
      () => http.post(Uri.parse('$baseUrl/products/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(body)),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  /// Создать товар через multipart (всегда, с фото или без)
  static Future<Map<String, dynamic>> createProductWithImage({
    required String title,
    required String price,
    String? weightKg,
    String? description,
    int? categoryId,
    int? quantity,
    XFile? imageXFile,
    List<int>? imageBytes,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/products/');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['price'] = price;
    if (weightKg != null && weightKg.isNotEmpty) {
      request.fields['weight_kg'] = weightKg;
    }
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }
    if (categoryId != null) request.fields['category'] = categoryId.toString();
    if (quantity != null) request.fields['quantity'] = quantity.toString();

    // Добавляем фото только если есть байты
    if (imageXFile != null && imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageXFile.name.isNotEmpty ? imageXFile.name : 'photo.jpg',
      ));
    }

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      _ensureSuccess(response);
      return _decodeMap(response);
    } on TimeoutException {
      throw ApiException('Превышено время загрузки файла');
    } catch (e) {
      throw ApiException('Ошибка загрузки: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProduct(
    int productId, {
    String? title, String? price, String? weightKg,
    String? description, bool? isActive,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{};
    if (title != null && title.isNotEmpty) body['title'] = title;
    if (price != null && price.isNotEmpty) body['price'] = price;
    if (weightKg != null) body['weight_kg'] = weightKg;
    if (description != null) body['description'] = description;
    if (isActive != null) body['is_active'] = isActive;
    final response = await _send(
      () => http.patch(Uri.parse('$baseUrl/products/$productId/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(body)),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<void> deleteProduct(int productId) async {
    final token = await getToken();
    final response = await _send(
      () => http.delete(Uri.parse('$baseUrl/products/$productId/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      final body = _decodeMap(response);
      throw ApiException(body['detail']?.toString() ?? 'Ошибка удаления');
    }
  }

  static Future<void> adminToggleProduct(int productId, bool isActive) async {
    await updateProduct(productId, isActive: isActive);
  }

  // Routing
  static Future<Map<String, dynamic>> compareRoutes(
    List<int> productIds, double startLat, double startLon, {
    double? fuelPrice, double? fuelConsumption, String roadQuality = 'medium',
  }) async {
    final token = await getToken();
    final payload = <String, dynamic>{
      'product_ids': productIds,
      'start': {'lat': startLat, 'lon': startLon},
      'road_quality': roadQuality,
    };
    if (fuelPrice != null) payload['fuel_price'] = fuelPrice;
    if (fuelConsumption != null) payload['fuel_consumption'] = fuelConsumption;

    try {
      // Таймаут 90 секунд — OSRM + OR-Tools долго считают
      final response = await http.post(
        Uri.parse('$baseUrl/routing/compare/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 90));
      _ensureSuccess(response);
      return _decodeMap(response);
    } on TimeoutException {
      throw ApiException('Маршрут считается слишком долго. Попробуйте снова.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ошибка маршрута: $e');
    }
  }

  // Orders
  static Future<List<dynamic>> getOrders() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/orders/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    _ensureSuccess(response);
    final decoded = _decodeBody(response);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded.containsKey('results')) return decoded['results'] as List<dynamic>;
    return [];
  }

  static Future<List<dynamic>> getFarmerOrders() async {
    return getOrders();
  }

  static Future<List<dynamic>> getAdminOrders() async {
    final token = await getToken();
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/orders/admin/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 404 || response.statusCode == 403) return getOrders();
    _ensureSuccess(response);
    final decoded = _decodeBody(response);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded.containsKey('results')) return decoded['results'] as List<dynamic>;
    return [];
  }

  static Future<void> updateOrderStatus(int orderId, String status) async {
    final token = await getToken();
    final response = await _send(
      () => http.patch(Uri.parse('$baseUrl/orders/$orderId/status/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'status': status})),
    );
    _ensureSuccess(response);
  }

  static Future<Map<String, dynamic>> createOrder({
    required String deliveryName, required String deliveryAddress,
    required String deliveryPhone, String deliveryCity = 'Бишкек',
    String? comment, required List<Map<String, dynamic>> items,
  }) async {
    final token = await getToken();
    final response = await _send(
      () => http.post(Uri.parse('$baseUrl/orders/create/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({
            'delivery_name': deliveryName,
            'delivery_address': deliveryAddress,
            'delivery_phone': deliveryPhone,
            'delivery_city': deliveryCity,
            'comment': comment ?? '',
            'items': items,
          })),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  // Likes & Reviews
  static Future<Map<String, dynamic>> getLikeStatus(int productId) async {
    final token = await getToken();
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/products/$productId/likes/'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          }),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<Map<String, dynamic>> toggleLike(int productId) async {
    final token = await getToken();
    final response = await _send(
      () => http.post(Uri.parse('$baseUrl/products/$productId/like/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<List<dynamic>> getReviews(int productId) async {
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/products/$productId/reviews/'),
          headers: {'Content-Type': 'application/json'}),
    );
    _ensureSuccess(response);
    return _decodeList(response);
  }

  static Future<Map<String, dynamic>> addReview(
      int productId, int rating, String text) async {
    final token = await getToken();
    final response = await _send(
      () => http.post(Uri.parse('$baseUrl/products/$productId/reviews/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'rating': rating, 'text': text})),
    );
    _ensureSuccess(response);
    return _decodeMap(response);
  }

  static Future<void> deleteReview(int reviewId) async {
    final token = await getToken();
    final response = await _send(
      () => http.delete(Uri.parse('$baseUrl/reviews/$reviewId/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException('Ошибка удаления отзыва');
    }
  }

   static Future<Map<String, dynamic>> updateReview(
        int reviewId, int rating, String text) async {
    final token = await getToken();
    final response = await _send(
        () => http.patch(Uri.parse('$baseUrl/reviews/$reviewId/edit/'),  // ← /edit/
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'rating': rating, 'text': text})),
    ); 
    _ensureSuccess(response);
    return _decodeMap(response);
    }

  static Future<List<dynamic>> getLikedProducts() async {
    final token = await getToken();
    final response = await _send(
        () => http.get(Uri.parse('$baseUrl/liked-products/'),  // ← изменили
            headers: {'Content-Type': 'application/json', 
                    'Authorization': 'Bearer $token'}),
    );
    _ensureSuccess(response);
    final decoded = _decodeBody(response);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded.containsKey('results')) 
        return decoded['results'] as List<dynamic>;
    return [];
    }

  static Future<void> deleteAccount() async {
    final token = await getToken();
    final response = await _send(
      () => http.delete(Uri.parse('$baseUrl/accounts/me/'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException('Ошибка удаления аккаунта');
    }
    await clearToken();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
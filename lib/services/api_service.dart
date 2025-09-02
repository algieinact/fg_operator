import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://10.1.101.90:8000/api';
  static const String imageBaseUrl = 'http://10.1.101.90:8000/storage/';
  static String? _token;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Initialize token from shared preferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    print(
      'ApiService: Initialized with token: ${_token?.substring(0, 10) ?? "null"}...',
    );
  }

  // Set token and save to shared preferences
  static Future<void> setToken(String token) async {
    print('ApiService: Setting token: ${token.substring(0, 10)}...');
    print('ApiService: Token length: ${token.length}');

    // Set static variable first
    _token = token;
    print('ApiService: Static variable set: ${_token?.substring(0, 10)}...');

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print('ApiService: Token saved to SharedPreferences');

    // Verify token was saved
    final savedToken = prefs.getString('auth_token');
    print(
      'ApiService: Verified saved token: ${savedToken?.substring(0, 10) ?? "null"}...',
    );

    // Double check static variable
    print(
      'ApiService: Final static variable check: ${_token?.substring(0, 10)}...',
    );
    print('ApiService: hasToken after set: $hasToken');
  }

  // Clear token
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get current token (for debugging)
  static String? getCurrentToken() {
    return _token;
  }

  // Check if token exists
  static bool get hasToken => _token != null && _token!.isNotEmpty;

  // Force refresh token from SharedPreferences
  static Future<void> refreshTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    print(
      'ApiService: Raw token from SharedPreferences: ${storedToken?.substring(0, 10) ?? "null"}...',
    );

    _token = storedToken;
    print(
      'ApiService: Static variable updated: ${_token?.substring(0, 10) ?? "null"}...',
    );

    // Check if token is valid
    if (_token != null && _token!.isNotEmpty) {
      print('ApiService: Token is valid and available');
    } else {
      print('ApiService: Token is null or empty');
    }
  }

  // Get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    print('ApiService: _getHeaders called');
    print(
      'ApiService: Current static token: ${ApiService._token?.substring(0, 10) ?? "null"}...',
    );
    print('ApiService: hasToken: ${ApiService.hasToken}');

    // Force refresh token from storage if not available
    if (!ApiService.hasToken) {
      print('ApiService: Token not available, refreshing from storage...');
      await ApiService.refreshTokenFromStorage();
      print(
        'ApiService: After refresh, static token: ${ApiService._token?.substring(0, 10) ?? "null"}...',
      );
    }

    // Get current token from static variable
    final currentToken = ApiService._token;
    if (currentToken != null && currentToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $currentToken';
      print(
        'ApiService: Adding token to headers: Bearer ${currentToken.substring(0, 10)}...',
      );
    } else {
      print('ApiService: No token available for request after refresh');
      print(
        'ApiService: Final check - static token: ${ApiService._token?.substring(0, 10) ?? "null"}...',
      );
    }

    return headers;
  }

  // Generic HTTP request method
  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();

      print('ApiService: Making $method request to $endpoint');
      print('ApiService: Token available: ${ApiService.hasToken}');
      print(
        'ApiService: Current token: ${ApiService.getCurrentToken()?.substring(0, 10) ?? "null"}...',
      );
      print('ApiService: Headers: $headers');

      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      print('ApiService: Response status: ${response.statusCode}');
      print('ApiService: Response body: $responseData');

      // For login endpoint, we want to return the response even if status code is not 2xx
      // because the API might return success: true with a different status code
      if (endpoint == '/auth/login') {
        return responseData;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        print('ApiService: Request failed with status ${response.statusCode}');
        throw ApiException(
          message: responseData['message'] ?? 'Unknown error occurred',
          statusCode: response.statusCode,
          data: responseData,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('ApiService: Attempting login for username: $username');

      final response = await _request(
        'POST',
        '/auth/login',
        body: {'username': username, 'password': password},
      );

      print('ApiService: Login response: $response');

      if (response['success'] == true) {
        // Check for token in different possible locations
        String? token;
        if (response['data'] != null && response['data']['token'] != null) {
          token = response['data']['token'];
          print(
            'ApiService: Found token in data.token: ${token?.substring(0, 10)}...',
          );
        } else if (response['token'] != null) {
          token = response['token'];
          print(
            'ApiService: Found token in response.token: ${token?.substring(0, 10)}...',
          );
        }

        if (token != null) {
          await setToken(token);
          print('ApiService: Token saved successfully');
        } else {
          print('ApiService: Warning - No token found in response');
          print('ApiService: Response structure: $response');
        }
      }

      return response;
    } catch (e) {
      print('ApiService: Login error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await _request('POST', '/auth/logout');
    await clearToken();
    return response;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _request('GET', '/auth/me');
  }

  // Operator endpoints
  Future<Map<String, dynamic>> scanSlotForPosting(String slotName) async {
    return await _request(
      'POST',
      '/operator/posting/scan-slot',
      body: {'slot_name': slotName},
    );
  }

  Future<Map<String, dynamic>> storeByErp({
    required String erpCode,
    required String slotName,
  }) async {
    return await _request(
      'POST',
      '/operator/posting/store-by-erp',
      body: {'erp_code': erpCode, 'slot_name': slotName},
    );
  }

  Future<Map<String, dynamic>> scanSlotForPull(String slotName) async {
    return await _request(
      'POST',
      '/operator/pulling/scan-slot',
      body: {'slot_name': slotName},
    );
  }

  Future<Map<String, dynamic>> pullByLotNumber(
    String lotNumber,
    int quantity,
  ) async {
    return await _request(
      'POST',
      '/operator/pulling/pull-by-lot',
      body: {'lot_number': lotNumber, 'quantity': quantity},
    );
  }

  Future<Map<String, dynamic>> getSlotInfo(String slotName) async {
    return await _request('GET', '/operator/slot/$slotName');
  }

  Future<Map<String, dynamic>> getSlotLotNumbers(String slotName) async {
    return await _request('GET', '/operator/slot/$slotName/lots');
  }

  Future<Map<String, dynamic>> searchItems({
    required String query,
    String? type,
    int? limit,
  }) async {
    final params = <String, String>{'q': query};
    if (type != null) params['type'] = type;
    if (limit != null) params['limit'] = limit.toString();

    final queryString = Uri(queryParameters: params).query;
    return await _request('GET', '/operator/search/items?$queryString');
  }

  Future<Map<String, dynamic>> getActivityHistory({
    int? limit,
    String? dateFrom,
    String? dateTo,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;

    final queryString =
        params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    return await _request('GET', '/operator/activities$queryString');
  }

  Future<Map<String, dynamic>> getDashboard() async {
    return await _request('GET', '/operator/dashboard');
  }

  // Debug endpoints
  Future<Map<String, dynamic>> debugSimple() async {
    return await _request('GET', '/debug/simple');
  }

  Future<Map<String, dynamic>> debugToken() async {
    return await _request('GET', '/debug/token');
  }

  Future<Map<String, dynamic>> testAuth() async {
    return await _request('GET', '/test/auth');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? data;

  ApiException({required this.message, required this.statusCode, this.data});

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}

// User model class
class User {
  final int id;
  final String username;
  final String name;
  final int roleId;
  final String? roleName;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.roleId,
    this.roleName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle nested role structure
    int roleId = 0;
    String? roleName;

    if (json['role'] != null && json['role'] is Map<String, dynamic>) {
      final role = json['role'] as Map<String, dynamic>;
      roleId = role['id'] ?? 0;
      roleName = role['name'];
    } else {
      roleId = json['role_id'] ?? 0;
      roleName = json['role_name'];
    }

    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      roleId: roleId,
      roleName: roleName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role_id': roleId,
      'role_name': roleName,
    };
  }
}

// Slot model class
class SlotInfo {
  final int id;
  final String slotName;
  final int itemId;
  final int rackId;
  final int capacity;
  final int currentQty;
  final String? packageImageUrl;
  final String? partImageUrl;
  final ItemInfo? item;
  final RackInfo? rack;

  SlotInfo({
    required this.id,
    required this.slotName,
    required this.itemId,
    required this.rackId,
    required this.capacity,
    required this.currentQty,
    this.packageImageUrl,
    this.partImageUrl,
    this.item,
    this.rack,
  });

  factory SlotInfo.fromJson(Map<String, dynamic> json) {
    return SlotInfo(
      id: json['id'] ?? 0,
      slotName: json['slot_name'] ?? '',
      itemId: json['item_id'] ?? 0,
      rackId: json['rack_id'] ?? 0,
      capacity: json['capacity'] ?? 0,
      currentQty: json['current_qty'] ?? 0,
      packageImageUrl: json['packaging_image_url'],
      partImageUrl: json['part_image_url'],
      item: json['item'] != null ? ItemInfo.fromJson(json['item']) : null,
      rack: json['rack'] != null ? RackInfo.fromJson(json['rack']) : null,
    );
  }
}

class ItemInfo {
  final int id;
  final String erpCode;
  final String partNo;
  final String description;
  final String model;
  final String customer;
  final int qty;
  final String? partImg;
  final String? packagingImg;

  ItemInfo({
    required this.id,
    required this.erpCode,
    required this.partNo,
    required this.description,
    required this.model,
    required this.customer,
    required this.qty,
    this.partImg,
    this.packagingImg,
  });

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(
      id: json['id'] ?? 0,
      erpCode: json['erp_code'] ?? '',
      partNo: json['part_no'] ?? '',
      description: json['description'] ?? '',
      model: json['model'] ?? '',
      customer: json['customer'] ?? '',
      qty: json['qty'] ?? 0,
      partImg: json['part_img'],
      packagingImg: json['packaging_img'],
    );
  }
}

class RackInfo {
  final int id;
  final String rackName;
  final int totalSlots;

  RackInfo({
    required this.id,
    required this.rackName,
    required this.totalSlots,
  });

  factory RackInfo.fromJson(Map<String, dynamic> json) {
    return RackInfo(
      id: json['id'] ?? 0,
      rackName: json['rack_name'] ?? '',
      totalSlots: json['total_slots'] ?? 0,
    );
  }
}

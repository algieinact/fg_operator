import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class UserManager {
  static User? _currentUser;
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  // Get current user
  static User? get currentUser => _currentUser;

  // Initialize user from shared preferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userMap);
      } catch (e) {
        // If there's an error parsing, clear the stored user
        await clearUser();
      }
    }
  }

  // Set current user and save to shared preferences
  static Future<void> setUser(User user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  // Clear current user
  static Future<void> clearUser() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
  }

  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;

  // Get username safely
  static String get username => _currentUser?.username ?? 'User';

  // Get user name safely
  static String get name => _currentUser?.name ?? 'Unknown';

  // Get user role safely
  static String get roleName => _currentUser?.roleName ?? 'Unknown';

  // Login user
  static Future<User> login(String username, String password) async {
    try {
      print('UserManager: Starting login process...');

      final apiService = ApiService();
      final response = await apiService.login(username, password);

      print('UserManager: API response: $response');

      if (response['success'] == true) {
        // Check if user data exists in data.user structure
        Map<String, dynamic>? userData;
        if (response['data'] != null && response['data']['user'] != null) {
          userData = response['data']['user'];
        } else if (response['user'] != null) {
          userData = response['user'];
        }

        if (userData != null) {
          print('UserManager: Found user data: $userData');
          final user = User.fromJson(userData);
          print('UserManager: Parsed user object: ${user.toJson()}');
          await setUser(user);

          // Verify token was saved
          print('UserManager: Verifying token was saved...');

          // Check SharedPreferences directly
          final prefs = await SharedPreferences.getInstance();
          final storedToken = prefs.getString('auth_token');
          print(
            'UserManager: Token in SharedPreferences: ${storedToken?.substring(0, 10) ?? "null"}...',
          );

          // Check static variable
          print(
            'UserManager: Token in static variable: ${ApiService.getCurrentToken()?.substring(0, 10) ?? "null"}...',
          );

          // Force refresh
          await ApiService.refreshTokenFromStorage();
          print(
            'UserManager: Token after refresh: ${ApiService.getCurrentToken()?.substring(0, 10) ?? "null"}...',
          );

          print('UserManager: User logged in successfully: ${user.username}');
          return user;
        } else {
          print('UserManager: Login failed - no user data found');
          print('UserManager: Response structure: $response');
          throw ApiException(
            message: response['message'] ?? 'Login failed - no user data',
            statusCode: 401,
            data: response,
          );
        }
      } else {
        print('UserManager: Login failed - API returned success: false');
        throw ApiException(
          message: response['message'] ?? 'Login failed - API error',
          statusCode: 401,
          data: response,
        );
      }
    } catch (e) {
      print('UserManager: Login error: $e');
      rethrow;
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      final apiService = ApiService();
      await apiService.logout();
    } catch (e) {
      // Even if logout API fails, we still clear local data
      print('Logout API failed: $e');
    } finally {
      await clearUser();
      await ApiService.clearToken();
    }
  }

  // Refresh user data from API
  static Future<User?> refreshUser() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getCurrentUser();

      if (response['id'] != null) {
        final user = User.fromJson(response);
        await setUser(user);
        return user;
      }
    } catch (e) {
      print('Failed to refresh user: $e');
      // If refresh fails, clear user data
      await clearUser();
    }
    return null;
  }

  // Debug method to check token status
  static void debugTokenStatus() {
    print('UserManager: Current user: ${_currentUser?.username ?? "null"}');
    print('UserManager: Token available: ${ApiService.hasToken}');
    print(
      'UserManager: Token: ${ApiService.getCurrentToken()?.substring(0, 10) ?? "null"}...',
    );
  }
}

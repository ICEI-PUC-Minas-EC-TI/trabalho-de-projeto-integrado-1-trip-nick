import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to sync Firebase users with your Azure SQL database
class UserSyncService {
  // Replace with your actual Azure Functions URL
  static const String _baseUrl = 'http://192.168.0.59:7071/api';

  /// Sync Firebase user with your database and return internal user_id
  static Future<UserSyncResult> syncFirebaseUser(User firebaseUser) async {
    try {
      // Prepare Firebase user data for sync
      final requestData = {
        'firebase_uid': firebaseUser.uid,
        'email': firebaseUser.email!,
        'display_name': firebaseUser.displayName,
        'photo_url': firebaseUser.photoURL,
        'provider': _getProviderName(firebaseUser),
      };

      // Make API call to sync user
      final response = await http.post(
        Uri.parse('$_baseUrl/users/sync-firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final userId = data['user_id'] as int;
          final userData = data['user_data'] as Map<String, dynamic>;

          // Store user_id locally for API calls
          await _storeUserIdLocally(userId);

          return UserSyncResult.success(
            userId: userId,
            action: data['action'],
            userData: UserData.fromJson(userData),
          );
        } else {
          return UserSyncResult.failure(data['error'] ?? 'Unknown error');
        }
      } else {
        final errorData = jsonDecode(response.body);
        return UserSyncResult.failure(errorData['error'] ?? 'Sync failed');
      }
    } catch (e) {
      return UserSyncResult.failure('Network error: ${e.toString()}');
    }
  }

  /// Get the current user's internal user_id from local storage
  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  /// Clear stored user data (for logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  /// Store user_id locally for API calls
  static Future<void> _storeUserIdLocally(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  /// Determine provider name from Firebase user
  static String _getProviderName(User firebaseUser) {
    for (final provider in firebaseUser.providerData) {
      switch (provider.providerId) {
        case 'google.com':
          return 'google';
        case 'facebook.com':
          return 'facebook';
        case 'apple.com':
          return 'apple';
        case 'password':
          return 'firebase';
        default:
          continue;
      }
    }
    return 'firebase';
  }
}

/// Result of user sync operation
class UserSyncResult {
  final bool success;
  final int? userId;
  final String? action; // 'created' or 'updated'
  final UserData? userData;
  final String? error;

  UserSyncResult.success({
    required this.userId,
    required this.action,
    required this.userData,
  }) : success = true,
       error = null;

  UserSyncResult.failure(this.error)
    : success = false,
      userId = null,
      action = null,
      userData = null;
}

/// User data model for local use
class UserData {
  final int userId;
  final String firebaseUid;
  final String displayName;
  final String username;
  final String email;
  final String? createdVia;

  UserData({
    required this.userId,
    required this.firebaseUid,
    required this.displayName,
    required this.username,
    required this.email,
    this.createdVia,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'] as int,
      firebaseUid: json['firebase_uid'] as String,
      displayName: json['display_name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      createdVia: json['created_via'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'firebase_uid': firebaseUid,
      'display_name': displayName,
      'username': username,
      'email': email,
      'created_via': createdVia,
    };
  }
}

/// Helper service for making authenticated API calls to your backend
class ApiService {
  static const String _baseUrl =
      'https://your-function-app.azurewebsites.net/api';

  /// Make authenticated API call using stored user_id
  static Future<http.Response> authenticatedPost(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final userId = await UserSyncService.getCurrentUserId();

    if (userId == null) {
      throw Exception('User not authenticated. Please log in again.');
    }

    // Add user_id to request data for your existing APIs
    data['user_id'] = userId;

    return await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  /// Make authenticated GET request
  static Future<http.Response> authenticatedGet(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final userId = await UserSyncService.getCurrentUserId();

    if (userId == null) {
      throw Exception('User not authenticated. Please log in again.');
    }

    // Add user_id to query parameters
    final params = queryParams ?? {};
    params['userId'] = userId.toString();

    final uri = Uri.parse(
      '$_baseUrl/$endpoint',
    ).replace(queryParameters: params);

    return await http.get(uri, headers: {'Content-Type': 'application/json'});
  }
}

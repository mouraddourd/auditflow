import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';

/// Authentication result
class AuthResult {
  final bool success;
  final String? error;
  final AuthUser? user;
  final String? token;

  AuthResult({
    required this.success,
    this.error,
    this.user,
    this.token,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    if (json['success'] == true && json['data'] != null) {
      final data = json['data'] as Map<String, dynamic>;
      return AuthResult(
        success: true,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
        token: data['token'] as String?,
      );
    }
    return AuthResult(
      success: false,
      error: json['error'] as String? ?? 'Une erreur est survenue',
    );
  }
}

/// User data from authentication
class AuthUser {
  final String id;
  final String email;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

/// Service for handling authentication with the backend
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {'Content-Type': 'application/json'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );

      final result = AuthResult.fromJson(response.data);

      if (result.success && result.token != null) {
        await _saveAuthData(
          token: result.token!,
          userId: result.user!.id,
          email: result.user!.email,
          name: result.user!.name,
        );
      }

      return result;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'email': email,
          'password': password,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );

      final result = AuthResult.fromJson(response.data);

      if (result.success && result.token != null) {
        await _saveAuthData(
          token: result.token!,
          userId: result.user!.id,
          email: result.user!.email,
          name: result.user!.name,
        );
      }

      return result;
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, error: 'Erreur inattendue: $e');
    }
  }

  /// Get current user info from the backend
  Future<AuthUser?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        ApiConfig.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return AuthUser.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  /// Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Get stored user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Get stored user name
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Logout and clear stored data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
  }

  /// Save authentication data to local storage
  Future<void> _saveAuthData({
    required String token,
    required String userId,
    required String email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    if (name != null) {
      await prefs.setString(_userNameKey, name);
    }
  }

  /// Handle Dio errors and return appropriate error message
  AuthResult _handleDioError(DioException e) {
    String errorMessage;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connexion au serveur impossible. Vérifiez votre connexion.';
        break;
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map && data['error'] != null) {
          errorMessage = data['error'] as String;
        } else {
          errorMessage = 'Erreur serveur (${e.response?.statusCode ?? 'inconnu'})';
        }
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Impossible de se connecter au serveur.';
        break;
      default:
        errorMessage = 'Une erreur est survenue. Veuillez réessayer.';
    }

    return AuthResult(success: false, error: errorMessage);
  }
}

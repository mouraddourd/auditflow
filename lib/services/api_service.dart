import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import 'auth_service.dart';

/// Centralized HTTP client for API calls
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void init() {
    debugPrint('ApiService: Initializing with baseUrl=${ApiConfig.baseUrl}');

    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('ApiService: ${options.method} ${options.uri}');
        debugPrint('ApiService: Request data=${options.data}');

        // Add user-id header from AuthService
        final userId = await AuthService().getUserId();
        if (userId != null) {
          options.headers['x-user-id'] = userId;
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
            'ApiService: Response ${response.statusCode} from ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('ApiService: Error ${error.type} - ${error.message}');
        if (error.response != null) {
          debugPrint(
              'ApiService: Error response ${error.response?.statusCode} - ${error.response?.data}');
        }
        // Handle 401 errors - token expired
        if (error.response?.statusCode == 401) {
          // Could trigger re-auth here
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  // ==================== TEMPLATES ====================

  Future<Map<String, dynamic>> createTemplate(
      Map<String, dynamic> template) async {
    final response = await _dio.post('/templates', data: template);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getTemplates(String organizationId) async {
    final response = await _dio.get('/templates', queryParameters: {
      'organizationId': organizationId,
    });
    final data = response.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getTemplate(String templateId) async {
    final response = await _dio.get('/templates/$templateId');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateTemplate(
      String templateId, Map<String, dynamic> data) async {
    final response = await _dio.put('/templates/$templateId', data: data);
    return response.data;
  }

  Future<void> deleteTemplate(String templateId) async {
    await _dio.delete('/templates/$templateId');
  }

  // ==================== AUDITS ====================

  Future<Map<String, dynamic>> createAudit(Map<String, dynamic> audit) async {
    final response = await _dio.post('/audits', data: audit);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getAudits(String organizationId,
      {String? status}) async {
    final response = await _dio.get('/audits', queryParameters: {
      'organizationId': organizationId,
      if (status != null) 'status': status,
    });
    final data = response.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getAudit(String auditId) async {
    final response = await _dio.get('/audits/$auditId');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> updateAudit(
      String auditId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/audits/$auditId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> saveAnswers(
      String auditId, List<Map<String, dynamic>> answers) async {
    final response = await _dio.put('/audits/$auditId/answers', data: {
      'answers': answers,
    });
    return response.data;
  }

  Future<void> deleteAudit(String auditId) async {
    await _dio.delete('/audits/$auditId');
  }

  // ==================== CATEGORIES ====================

  Future<Map<String, dynamic>> createCategory(
      Map<String, dynamic> category) async {
    final response = await _dio.post('/categories', data: category);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getCategories(
      String organizationId) async {
    final response = await _dio.get('/categories', queryParameters: {
      'organizationId': organizationId,
    });
    final data = response.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> updateCategory(
      String categoryId, Map<String, dynamic> data) async {
    final response = await _dio.put('/categories/$categoryId', data: data);
    return response.data;
  }

  Future<void> deleteCategory(String categoryId) async {
    await _dio.delete('/categories/$categoryId');
  }

  // ==================== HEALTH CHECK ====================

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

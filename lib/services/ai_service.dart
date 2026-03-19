import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../hive/service.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'sync_service.dart';

/// AI Analysis result from backend
class AIAnalysis {
  final String summary;
  final List<String> strengths;
  final List<String> concerns;
  final int? estimatedScore;
  final List<String> recommendations;
  final String rawResponse;
  final String model;
  final DateTime generatedAt;

  AIAnalysis({
    required this.summary,
    required this.strengths,
    required this.concerns,
    this.estimatedScore,
    required this.recommendations,
    required this.rawResponse,
    required this.model,
    required this.generatedAt,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] as Map<String, dynamic>? ?? {};
    return AIAnalysis(
      summary: analysis['summary'] ?? '',
      strengths: List<String>.from(analysis['strengths'] ?? []),
      concerns: List<String>.from(analysis['concerns'] ?? []),
      estimatedScore: analysis['estimatedScore'] as int?,
      recommendations: List<String>.from(analysis['recommendations'] ?? []),
      rawResponse: analysis['raw'] ?? '',
      model: json['model'] ?? 'unknown',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  bool get hasContent =>
      summary.isNotEmpty || strengths.isNotEmpty || concerns.isNotEmpty;
}

/// Service for AI analysis via Ollama backend
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = ApiService().dio;
  final _syncService = SyncService();
  final _authService = AuthService();

  /// Check if AI service is available (online + backend healthy)
  Future<bool> isAvailable() async {
    if (!await _syncService.isOnline()) return false;

    try {
      final response = await _dio.get(
        '/ai/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.data['available'] == true;
    } catch (e) {
      debugPrint('AI service health check failed: $e');
      return false;
    }
  }

  /// Analyze audit with AI
  ///
  /// [auditData] should contain:
  /// - templateName: String
  /// - templateDescription: String?
  /// - responses: List<Map> with questionText, value, comment?
  Future<AIAnalysis?> analyzeAudit(Map<String, dynamic> auditData) async {
    // Check online status
    if (!await _syncService.isOnline()) {
      debugPrint('AI: Device offline, cannot analyze');
      return null;
    }

    try {
      final response = await _dio.post(
        '/ai/analyze',
        data: {'auditData': auditData},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 120), // 2 min for LLM
        ),
      );

      if (response.data['success'] == true) {
        return AIAnalysis.fromJson(response.data);
      }

      debugPrint('AI analysis failed: ${response.data['error']}');
      return null;
    } on DioException catch (e) {
      debugPrint('AI analysis DioException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('AI analysis error: $e');
      return null;
    }
  }

  /// Convenience method to analyze audit by ID
  /// Fetches audit data from Hive and formats it for AI analysis
  Future<AIAnalysis?> analyzeAuditById(String auditId) async {
    final hive = HiveService();
    final audit = hive.getAuditById(auditId);
    if (audit == null) return null;

    final template = hive.getTemplateById(audit['template_id'] as String);
    final questions =
        hive.getQuestionsForTemplate(audit['template_id'] as String);
    final answers = hive.getAnswersForAudit(auditId);

    // Format responses
    final responses = <Map<String, dynamic>>[];
    for (final answer in answers) {
      final question = questions.firstWhere(
        (q) => q['id'] == answer['question_id'],
        orElse: () => {'text': 'Question inconnue'},
      );

      responses.add({
        'questionText': question['text'] ?? 'Question',
        'value': answer['value']?.toString() ?? '',
        'comment': answer['comment'] as String?,
      });
    }

    final auditData = {
      'templateName': template?['name'] ?? 'Audit',
      'templateDescription': template?['description'],
      'responses': responses,
    };

    return analyzeAudit(auditData);
  }
}

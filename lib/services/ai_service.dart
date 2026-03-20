import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../hive/service.dart';
import 'api_service.dart';
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

  /// Convert to JSON for debug logging
  Map<String, dynamic> toJson() => {
        'summary': summary,
        'strengths': strengths,
        'concerns': concerns,
        'estimatedScore': estimatedScore,
        'recommendations': recommendations,
        'model': model,
        'generatedAt': generatedAt.toIso8601String(),
        'hasContent': hasContent,
      };

  /// Check if analysis has meaningful content
  bool get hasContent =>
      summary.isNotEmpty || strengths.isNotEmpty || concerns.isNotEmpty;
}

/// Detected anomaly in audit history
class Anomaly {
  final String type;
  final String severity;
  final String title;
  final String description;
  final int occurrences;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final List<String>? affectedQuestions;

  Anomaly({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.occurrences,
    required this.firstSeen,
    required this.lastSeen,
    this.affectedQuestions,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      type: json['type'] ?? '',
      severity: json['severity'] ?? 'low',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      occurrences: json['occurrences'] ?? 1,
      firstSeen: DateTime.tryParse(json['firstSeen'] ?? '') ?? DateTime.now(),
      lastSeen: DateTime.tryParse(json['lastSeen'] ?? '') ?? DateTime.now(),
      affectedQuestions: json['affectedQuestions'] != null
          ? List<String>.from(json['affectedQuestions'])
          : null,
    );
  }

  bool get isHigh => severity == 'high';
  bool get isMedium => severity == 'medium';
  bool get isLow => severity == 'low';
}

/// Detected pattern in audit responses
class Pattern {
  final String type;
  final String? category;
  final String description;
  final int dataPoints;

  Pattern({
    required this.type,
    this.category,
    required this.description,
    required this.dataPoints,
  });

  factory Pattern.fromJson(Map<String, dynamic> json) {
    return Pattern(
      type: json['type'] ?? 'stable',
      category: json['category'],
      description: json['description'] ?? '',
      dataPoints: json['dataPoints'] ?? 0,
    );
  }

  bool get isImprovement => type == 'improvement';
  bool get isDecline => type == 'decline';
  bool get isStable => type == 'stable';
}

/// Audit insights with historical analysis
class AuditInsights {
  final Map<String, dynamic> currentAudit;
  final Map<String, dynamic> history;
  final List<Anomaly> anomalies;
  final List<Pattern> patterns;
  final DateTime generatedAt;

  AuditInsights({
    required this.currentAudit,
    required this.history,
    required this.anomalies,
    required this.patterns,
    required this.generatedAt,
  });

  factory AuditInsights.fromJson(Map<String, dynamic> json) {
    final insights = json['insights'] as Map<String, dynamic>? ?? json;
    return AuditInsights(
      currentAudit: insights['currentAudit'] as Map<String, dynamic>? ?? {},
      history: insights['history'] as Map<String, dynamic>? ?? {},
      anomalies: (insights['anomalies'] as List<dynamic>? ?? [])
          .map((a) => Anomaly.fromJson(a as Map<String, dynamic>))
          .toList(),
      patterns: (insights['patterns'] as List<dynamic>? ?? [])
          .map((p) => Pattern.fromJson(p as Map<String, dynamic>))
          .toList(),
      generatedAt:
          DateTime.tryParse(insights['generatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  int? get currentScore => currentAudit['score'] as int?;
  int get totalAudits => history['totalAudits'] as int? ?? 0;
  int get averageScore => history['averageScore'] as int? ?? 0;
  String get trend => history['trend'] as String? ?? 'stable';
  int? get previousScore => history['previousScore'] as int?;

  bool get hasAnomalies => anomalies.isNotEmpty;
  bool get hasPatterns => patterns.isNotEmpty;
  bool get isTrendingUp => trend == 'improving';
  bool get isTrendingDown => trend == 'declining';
}

/// Real-time suggestions for audit in progress
class RealTimeSuggestions {
  final int currentScore;
  final int predictedScore;
  final double confidence;
  final List<RTAlert> alerts;
  final List<String> suggestions;
  final double progress;

  RealTimeSuggestions({
    required this.currentScore,
    required this.predictedScore,
    required this.confidence,
    required this.alerts,
    required this.suggestions,
    required this.progress,
  });

  factory RealTimeSuggestions.fromJson(Map<String, dynamic> json) {
    final suggestions = json['suggestions'] as Map<String, dynamic>? ?? json;
    return RealTimeSuggestions(
      currentScore: suggestions['currentScore'] as int? ?? 0,
      predictedScore: suggestions['predictedScore'] as int? ?? 0,
      confidence: (suggestions['confidence'] as num?)?.toDouble() ?? 0.0,
      alerts: (suggestions['alerts'] as List<dynamic>? ?? [])
          .map((a) => RTAlert.fromJson(a as Map<String, dynamic>))
          .toList(),
      suggestions: List<String>.from(suggestions['suggestions'] ?? []),
      progress: (suggestions['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get hasAlerts => alerts.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
}

/// Alert during audit
class RTAlert {
  final String type;
  final String message;
  final String? questionId;

  RTAlert({
    required this.type,
    required this.message,
    this.questionId,
  });

  factory RTAlert.fromJson(Map<String, dynamic> json) {
    return RTAlert(
      type: json['type'] ?? 'info',
      message: json['message'] ?? '',
      questionId: json['questionId'] as String?,
    );
  }

  bool get isDanger => type == 'danger';
  bool get isWarning => type == 'warning';
  bool get isInfo => type == 'info';
}

/// Service for AI analysis via Ollama backend
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  Dio get _dio => ApiService().dio;
  final _syncService = SyncService();

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

      debugPrint('AI: Response received: ${response.data}');

      if (response.data['success'] == true) {
        debugPrint('AI: Parsing analysis from response');
        final analysis = AIAnalysis.fromJson(response.data);
        debugPrint('AI: Analysis parsed successfully: ${analysis.toJson()}');
        return analysis;
      }

      debugPrint('AI analysis failed: ${response.data['error']}');
      return null;
    } on DioException catch (e) {
      debugPrint('AI analysis DioException: ${e.message}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('AI analysis error: $e');
      debugPrint('AI analysis stackTrace: $stackTrace');
      return null;
    }
  }

  /// Convenience method to analyze audit by ID
  /// Fetches audit data from Hive and formats it for AI analysis
  Future<AIAnalysis?> analyzeAuditById(String auditId) async {
    debugPrint('AI: analyzeAuditById called for auditId: $auditId');
    final hive = HiveService();
    final audit = hive.getAuditById(auditId);
    if (audit == null) {
      debugPrint('AI: Audit not found in Hive: $auditId');
      return null;
    }

    final template = hive.getTemplateById(audit['template_id'] as String);
    final questions =
        hive.getQuestionsForTemplate(audit['template_id'] as String);
    final answers = hive.getAnswersForAudit(auditId);

    debugPrint('AI: Found ${answers.length} answers for audit');

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

    debugPrint('AI: Calling analyzeAudit with ${responses.length} responses');

    return analyzeAudit(auditData);
  }

  /// Get audit insights with historical analysis
  ///
  /// Returns anomalies, patterns, and score trends based on audit history
  Future<AuditInsights?> getInsights(String auditId) async {
    if (!await _syncService.isOnline()) {
      debugPrint('AI: Device offline, cannot get insights');
      return null;
    }

    try {
      final response = await _dio.get(
        '/ai/insights/$auditId',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data['success'] == true) {
        return AuditInsights.fromJson(response.data);
      }

      debugPrint('AI insights failed: ${response.data['error']}');
      return null;
    } on DioException catch (e) {
      debugPrint('AI insights DioException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('AI insights error: $e');
      return null;
    }
  }

  /// Get real-time suggestions for audit in progress
  ///
  /// [answers] should be a list of {questionId, value}
  Future<RealTimeSuggestions?> getRealTimeSuggestions(
    String auditId,
    List<Map<String, String>> answers,
  ) async {
    if (!await _syncService.isOnline()) {
      debugPrint('AI: Device offline, cannot get real-time suggestions');
      return null;
    }

    try {
      final response = await _dio.post(
        '/ai/real-time-suggestions/$auditId',
        data: {'answers': answers},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.data['success'] == true) {
        return RealTimeSuggestions.fromJson(response.data);
      }

      debugPrint('AI real-time suggestions failed: ${response.data['error']}');
      return null;
    } on DioException catch (e) {
      debugPrint('AI real-time suggestions DioException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('AI real-time suggestions error: $e');
      return null;
    }
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../hive/service.dart';
import 'api_service.dart';

/// Sync status for entities
enum SyncStatus {
  synced,
  pending,
  failed,
}

/// Mutation type for sync queue
enum MutationType {
  create,
  update,
  delete,
}

/// Sync queue entry
class SyncQueueEntry {
  final String id;
  final String entityType; // 'template', 'audit', 'category', 'answer'
  final String entityId;
  final MutationType mutationType;
  final Map<String, dynamic>? data;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final String? lastError;

  SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.mutationType,
    this.data,
    this.retryCount = 0,
    required this.createdAt,
    this.lastAttemptAt,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'mutationType': mutationType.name,
        'data': data,
        'retryCount': retryCount,
        'createdAt': createdAt.toIso8601String(),
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
        'lastError': lastError,
      };

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) => SyncQueueEntry(
        id: json['id'] as String,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        mutationType: MutationType.values
            .firstWhere((e) => e.name == json['mutationType']),
        data: json['data'] != null
            ? Map<String, dynamic>.from(json['data'] as Map)
            : null,
        retryCount: json['retryCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastAttemptAt: json['lastAttemptAt'] != null
            ? DateTime.parse(json['lastAttemptAt'] as String)
            : null,
        lastError: json['lastError'] as String?,
      );
}

/// Service for synchronizing local data with backend
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String syncQueueBox = 'sync_queue';
  static const int maxRetries = 3;

  final HiveService _hive = HiveService();
  final ApiService _api = ApiService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Timer? _periodicSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Initialize sync service
  Future<void> initialize() async {
    await Hive.openBox(syncQueueBox);
    _api.init();

    // Start periodic sync (every 5 minutes)
    _startPeriodicSync();

    // Listen to connectivity changes
    _listenToConnectivity();
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) async {
        if (await isOnline()) {
          await processQueue();
        }
      },
    );
  }

  /// Listen to connectivity changes and sync when coming online
  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      // Check if any connection is available (not just 'none')
      final hasConnection = !result.contains(ConnectivityResult.none);
      if (hasConnection) {
        // Came online - process queue
        debugPrint('SyncService: Connectivity restored, processing queue...');
        processQueue();
      }
    });
  }

  /// Dispose resources
  void dispose() {
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ==================== QUEUE MANAGEMENT ====================

  /// Add mutation to sync queue
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required MutationType mutationType,
    Map<String, dynamic>? data,
  }) async {
    final box = Hive.box(syncQueueBox);
    final entry = SyncQueueEntry(
      id: _generateId(),
      entityType: entityType,
      entityId: entityId,
      mutationType: mutationType,
      data: data,
      createdAt: DateTime.now(),
    );

    await box.put(entry.id, entry.toJson());

    // Update entity sync status to pending
    await _updateEntitySyncStatus(entityType, entityId, SyncStatus.pending);

    // Try to sync immediately if online
    if (await isOnline()) {
      await processQueue();
    }
  }

  /// Get all pending mutations
  List<SyncQueueEntry> getPendingMutations() {
    final box = Hive.box(syncQueueBox);
    return box.values
        .map((e) => SyncQueueEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Remove entry from queue
  Future<void> _removeFromQueue(String entryId) async {
    final box = Hive.box(syncQueueBox);
    await box.delete(entryId);
  }

  /// Update entry in queue
  Future<void> _updateQueueEntry(SyncQueueEntry entry) async {
    final box = Hive.box(syncQueueBox);
    await box.put(entry.id, entry.toJson());
  }

  // ==================== SYNC PROCESSING ====================

  /// Process all pending mutations in queue
  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final online = await isOnline();
      debugPrint('SyncService: Processing queue, online=$online');

      if (!online) {
        debugPrint('SyncService: Device is offline, skipping queue processing');
        return;
      }

      final entries = getPendingMutations();
      // Priorité: template -> category -> audit -> answer, puis date (createdAt)
      final priority = {
        'template': 1,
        'category': 2,
        'audit': 3,
        'answer': 4,
      };
      entries.sort((a, b) {
        final pa = priority[a.entityType] ?? 99;
        final pb = priority[b.entityType] ?? 99;
        if (pa != pb) return pa.compareTo(pb);
        return a.createdAt.compareTo(b.createdAt);
      });

      debugPrint('SyncService: Found ${entries.length} pending mutations');

      for (final entry in entries) {
        debugPrint(
            'SyncService: Processing ${entry.mutationType.name} ${entry.entityType} ${entry.entityId}');

        if (entry.retryCount >= maxRetries) {
          // Mark as failed
          await _updateEntitySyncStatus(
            entry.entityType,
            entry.entityId,
            SyncStatus.failed,
          );
          continue;
        }

        try {
          await _processMutation(entry);
          // Success - remove from queue and mark as synced
          await _removeFromQueue(entry.id);
          await _updateEntitySyncStatus(
            entry.entityType,
            entry.entityId,
            SyncStatus.synced,
          );
        } catch (e) {
          // Check if it's a network error (no internet, timeout, etc.)
          final isNetworkError = _isNetworkError(e);

          if (isNetworkError) {
            // Don't increment retry count for network errors
            // Just log and continue - will retry when connection is back
            debugPrint(
                'SyncService: Network error for ${entry.entityType} ${entry.entityId}: $e');
            continue;
          }

          // Failure - update retry count and error (only for non-network errors)
          final updatedEntry = SyncQueueEntry(
            id: entry.id,
            entityType: entry.entityType,
            entityId: entry.entityId,
            mutationType: entry.mutationType,
            data: entry.data,
            retryCount: entry.retryCount + 1,
            createdAt: entry.createdAt,
            lastAttemptAt: DateTime.now(),
            lastError: e.toString(),
          );
          await _updateQueueEntry(updatedEntry);

          // If max retries reached, mark as failed
          if (updatedEntry.retryCount >= maxRetries) {
            await _updateEntitySyncStatus(
              entry.entityType,
              entry.entityId,
              SyncStatus.failed,
            );
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Process a single mutation
  Future<void> _processMutation(SyncQueueEntry entry) async {
    debugPrint(
        'SyncService: _processMutation entityType="${entry.entityType}"');

    switch (entry.entityType) {
      case 'template':
        await _processTemplateMutation(entry);
        break;
      case 'audit':
        await _processAuditMutation(entry);
        break;
      case 'category':
        await _processCategoryMutation(entry);
        break;
      case 'answer':
        await _processAnswerMutation(entry);
        break;
      default:
        debugPrint('SyncService: UNKNOWN entityType "${entry.entityType}"');
    }
  }

  // ==================== TEMPLATE MUTATIONS ====================

  Future<void> _processTemplateMutation(SyncQueueEntry entry) async {
    debugPrint('SyncService: _processTemplateMutation for ${entry.entityId}');
    debugPrint('SyncService: entry.data is null? ${entry.data == null}');
    if (entry.data != null) {
      debugPrint('SyncService: entry.data keys: ${entry.data!.keys.toList()}');
    }

    switch (entry.mutationType) {
      case MutationType.create:
      case MutationType.update:
        if (entry.data != null) {
          try {
            final templateData = _prepareTemplateData(entry.data!);
            debugPrint(
                'SyncService: Template data prepared: ${templateData['id']} - ${templateData['name']}');

            // Try create directly, fallback to update on conflict/exists
            try {
              debugPrint('SyncService: Trying createTemplate...');
              final result = await _api.createTemplate(templateData);
              debugPrint(
                  'SyncService: Template created successfully! Result: $result');
            } on DioException catch (e) {
              final status = e.response?.statusCode;
              debugPrint(
                  'SyncService: createTemplate error status=$status body=${e.response?.data}');

              // If already exists or similar (e.g., 409), try update
              if (status == 409 || status == 400) {
                debugPrint(
                    'SyncService: Trying updateTemplate after create failure...');
                final result =
                    await _api.updateTemplate(entry.entityId, templateData);
                debugPrint(
                    'SyncService: Template updated successfully after conflict. Result: $result');
              } else {
                rethrow;
              }
            } catch (e) {
              debugPrint('SyncService: Template mutation failed: $e');
              rethrow;
            }
          } catch (e, stack) {
            debugPrint('SyncService: Error in _processTemplateMutation: $e');
            debugPrint('SyncService: Stack: $stack');
            rethrow;
          }
        } else {
          debugPrint('SyncService: SKIPPING template mutation - data is null!');
        }
        break;
      case MutationType.delete:
        await _api.deleteTemplate(entry.entityId);
        break;
    }
  }

  Map<String, dynamic> _prepareTemplateData(Map<String, dynamic> data) {
    // Get questions from Hive (they are stored separately)
    final questionsFromHive =
        _hive.getQuestionsForTemplate(data['id'] as String);

    final questions = questionsFromHive
        .map((q) => {
              'id': q['id'],
              'type': q['type'],
              'text': q['text'],
              'order': q['order'],
              'required': q['required'] == true || q['required'] == 1,
              'options': q['options'],
            })
        .toList();

    debugPrint(
        'SyncService: Prepared ${questions.length} questions for template ${data['id']}');

    final payload = {
      'id': data['id'],
      'name': data['name'],
      'organizationId': data['organization_id'],
      'isPublic': (data['is_public'] == 1 || data['is_public'] == true),
      'questions': questions,
    };

    // Add optional fields only if non-null to satisfy backend zod schema
    if (data['description'] != null) {
      payload['description'] = data['description'];
    }
    if (data['category'] != null) {
      payload['category'] = data['category'];
    }

    return payload;
  }

  // ==================== AUDIT MUTATIONS ====================

  Future<void> _processAuditMutation(SyncQueueEntry entry) async {
    debugPrint('SyncService: _processAuditMutation for ${entry.entityId}');
    debugPrint('SyncService: audit entry.data is null? ${entry.data == null}');
    if (entry.data != null) {
      debugPrint(
          'SyncService: audit entry.data keys: ${entry.data!.keys.toList()}');
    }

    switch (entry.mutationType) {
      case MutationType.create:
        if (entry.data != null) {
          final auditPayload = _prepareAuditData(entry.data!);
          try {
            debugPrint('SyncService: Trying createAudit...');
            final result = await _api.createAudit(auditPayload);
            debugPrint(
                'SyncService: Audit created successfully! Result: $result');
          } on DioException catch (e) {
            final status = e.response?.statusCode;
            debugPrint(
                'SyncService: createAudit error status=$status body=${e.response?.data}');
            if (status == 409 || status == 400) {
              debugPrint(
                  'SyncService: Trying updateAudit after create failure...');
              final result = await _api.updateAudit(
                  entry.entityId, _prepareAuditUpdateData(entry.data!));
              debugPrint(
                  'SyncService: Audit updated successfully after conflict. Result: $result');
            } else {
              rethrow;
            }
          }
        }
        break;
      case MutationType.update:
        if (entry.data != null) {
          await _api.updateAudit(
              entry.entityId, _prepareAuditUpdateData(entry.data!));
        }
        break;
      case MutationType.delete:
        await _api.deleteAudit(entry.entityId);
        break;
    }
  }

  Map<String, dynamic> _prepareAuditData(Map<String, dynamic> data) {
    final payload = <String, dynamic>{
      'id': data['id'],
      'title': data['title'],
      'templateId': data['original_template_id'] ?? data['template_id'],
      'organizationId': data['organization_id'],
    };

    if (data['description'] != null)
      payload['description'] = data['description'];
    if (data['status'] != null) payload['status'] = data['status'];
    if (data['score'] != null) payload['score'] = data['score'];

    // startedAt/completedAt ne sont pas dans le schéma de création, seulement dans update

    return payload;
  }

  Map<String, dynamic> _prepareAuditUpdateData(Map<String, dynamic> data) {
    final payload = <String, dynamic>{};

    if (data['title'] != null) payload['title'] = data['title'];
    if (data['description'] != null)
      payload['description'] = data['description'];
    if (data['status'] != null) payload['status'] = data['status'];
    if (data['score'] != null) payload['score'] = data['score'];
    if (data['started_at'] != null) payload['startedAt'] = data['started_at'];
    if (data['completed_at'] != null)
      payload['completedAt'] = data['completed_at'];

    return payload;
  }

  // ==================== CATEGORY MUTATIONS ====================

  Future<void> _processCategoryMutation(SyncQueueEntry entry) async {
    debugPrint('SyncService: _processCategoryMutation for ${entry.entityId}');
    debugPrint(
        'SyncService: category entry.data is null? ${entry.data == null}');
    if (entry.data != null) {
      debugPrint(
          'SyncService: category entry.data keys: ${entry.data!.keys.toList()}');
    }

    switch (entry.mutationType) {
      case MutationType.create:
        if (entry.data != null) {
          final payload = _prepareCategoryData(entry.data!);
          try {
            debugPrint('SyncService: Trying createCategory...');
            final result = await _api.createCategory(payload);
            debugPrint(
                'SyncService: Category created successfully! Result: $result');
          } on DioException catch (e) {
            final status = e.response?.statusCode;
            debugPrint(
                'SyncService: createCategory error status=$status body=${e.response?.data}');
            if (status == 409 || status == 400) {
              debugPrint(
                  'SyncService: Trying updateCategory after create failure...');
              final result = await _api.updateCategory(entry.entityId, payload);
              debugPrint(
                  'SyncService: Category updated successfully after conflict. Result: $result');
            } else {
              rethrow;
            }
          }
        }
        break;
      case MutationType.update:
        if (entry.data != null) {
          final payload = _prepareCategoryUpdateData(entry.data!);
          try {
            debugPrint('SyncService: Trying updateCategory...');
            debugPrint('SyncService: updateCategory payload=$payload');
            final result = await _api.updateCategory(entry.entityId, payload);
            debugPrint(
                'SyncService: Category updated successfully! Result: $result');
          } on DioException catch (e) {
            final status = e.response?.statusCode;
            debugPrint(
                'SyncService: updateCategory error status=$status body=${e.response?.data}');
            if (status == 400 || status == 404 || status == 409) {
              // Try create if update fails (e.g., not found server-side)
              try {
                debugPrint(
                    'SyncService: Trying createCategory after update failure...');
                final createPayload = _prepareCategoryData(entry.data!);
                final result = await _api.createCategory(createPayload);
                debugPrint(
                    'SyncService: Category created after update failure. Result: $result');
              } catch (e2) {
                debugPrint('SyncService: create after update failed: $e2');
                rethrow;
              }
            } else {
              rethrow;
            }
          }
        }
        break;
      case MutationType.delete:
        await _api.deleteCategory(entry.entityId);
        break;
    }
  }

  Map<String, dynamic> _prepareCategoryData(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'],
      if (data['description'] != null) 'description': data['description'],
      if (data['color'] != null) 'color': data['color'],
      'organizationId': data['organization_id'],
    };
  }

  Map<String, dynamic> _prepareCategoryUpdateData(Map<String, dynamic> data) {
    final payload = <String, dynamic>{};
    if (data['name'] != null) payload['name'] = data['name'];
    if (data['description'] != null)
      payload['description'] = data['description'];
    if (data['color'] != null) payload['color'] = data['color'];
    return payload;
  }

  // ==================== ANSWER MUTATIONS ====================

  Future<void> _processAnswerMutation(SyncQueueEntry entry) async {
    // Answers are batched by audit, so we need to get all answers for the audit
    if (entry.data != null) {
      final auditId = entry.data!['audit_id'] as String;
      debugPrint('SyncService: _processAnswerMutation for audit $auditId');
      final audit = _hive.getAuditById(auditId);
      if (audit != null) {
        final templateId =
            audit['template_id'] ?? audit['original_template_id'];
        if (templateId == null) {
          debugPrint(
              'SyncService: No template_id found for audit $auditId, skipping answers');
          return;
        }

        // Fetch template from backend to validate question IDs
        List<dynamic> serverQuestions;
        try {
          final tpl = await _api.getTemplate(templateId.toString());
          serverQuestions = tpl['questions'] as List<dynamic>? ?? [];
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          if (status == 404) {
            debugPrint(
                'SyncService: Template $templateId not found on server, will retry later');
            return;
          }
          rethrow;
        }

        final serverQIds =
            serverQuestions.map((q) => q['id'].toString()).toSet();

        final rawAnswers = (audit['answers'] as List);

        // Map questionId -> server question id (template questions must be synced)
        // On suppose que question_id local == id question (UUID) déjà poussé avec le template.
        // Si une question n’existe pas côté serveur, on ignore sa réponse pour éviter le FK error.

        final answers = <Map<String, dynamic>>[];
        int skipped = 0;
        for (final a in rawAnswers) {
          final localQid = a['question_id'];
          if (a['id'] == null || localQid == null || a['value'] == null) {
            skipped++;
            continue;
          }

          final qidStr = localQid.toString();
          if (!serverQIds.contains(qidStr)) {
            skipped++;
            continue;
          }

          final score = a['score'];
          int? scoreInt;
          if (score is int) scoreInt = score;
          if (score is num && scoreInt == null) scoreInt = score.toInt();

          answers.add({
            'id': a['id'],
            'questionId': qidStr,
            'value': a['value'].toString(),
            if (a['comment'] != null) 'comment': a['comment'].toString(),
            if (scoreInt != null) 'score': scoreInt,
          });
        }

        debugPrint(
            'SyncService: Saving ${answers.length} answers for audit $auditId (skipped $skipped invalid/missing questionId)');
        if (answers.isNotEmpty) {
          debugPrint(
              'SyncService: First answer payload sample: ${answers.first}');
        }
        try {
          final result = await _api.saveAnswers(
              auditId, answers.cast<Map<String, dynamic>>());
          debugPrint('SyncService: saveAnswers success: $result');
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          debugPrint(
              'SyncService: saveAnswers error status=$status body=${e.response?.data}');
          rethrow;
        } catch (e) {
          debugPrint('SyncService: saveAnswers unexpected error: $e');
          rethrow;
        }
      }
    }
  }

  // ==================== PULL DATA ====================

  /// Pull all data from server for current organization
  Future<void> pullAll() async {
    if (!await isOnline()) return;

    final organizationId = _hive.organizationId;
    if (organizationId == null) return;

    try {
      // Pull templates
      final templates = await _api.getTemplates(organizationId);
      for (final template in templates) {
        await _saveTemplateLocally(template);
      }

      // Pull categories
      final categories = await _api.getCategories(organizationId);
      for (final category in categories) {
        await _saveCategoryLocally(category);
      }

      // Pull audits
      final audits = await _api.getAudits(organizationId);
      for (final audit in audits) {
        await _saveAuditLocally(audit);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveTemplateLocally(Map<String, dynamic> template) async {
    final box = Hive.box(HiveService.templatesBox);
    final localTemplate = {
      'id': template['id'],
      'name': template['name'],
      'description': template['description'],
      'category': template['category'],
      'user_id': template['userId'],
      'organization_id': template['organizationId'],
      'is_public': template['isPublic'] ?? false,
      'sync_status': 'synced',
      'created_at': template['createdAt'],
      'updated_at': template['updatedAt'],
    };
    await box.put(template['id'], localTemplate);

    // Save questions
    if (template['questions'] != null) {
      final questionsBox = Hive.box(HiveService.questionsBox);
      for (final q in template['questions']) {
        await questionsBox.put(q['id'], {
          'id': q['id'],
          'template_id': template['id'],
          'type': q['type'],
          'text': q['text'],
          'order': q['order'],
          'required': q['required'] == true ? 1 : 0,
          'options': q['options'],
          'sync_status': 'synced',
          'created_at': q['createdAt'],
        });
      }
    }
  }

  Future<void> _saveCategoryLocally(Map<String, dynamic> category) async {
    final box = Hive.box(HiveService.categoriesBox);
    await box.put(category['id'], {
      'id': category['id'],
      'name': category['name'],
      'description': category['description'],
      'color': category['color'],
      'organization_id': category['organizationId'],
      'sync_status': 'synced',
      'created_at': category['createdAt'],
      'updated_at': category['updatedAt'],
    });
  }

  Future<void> _saveAuditLocally(Map<String, dynamic> audit) async {
    final box = Hive.box(HiveService.auditsBox);
    final localAudit = {
      'id': audit['id'],
      'title': audit['title'],
      'description': audit['description'],
      'template_id': audit['templateId'],
      'user_id': audit['userId'],
      'organization_id': audit['organizationId'],
      'status': audit['status'],
      'score': audit['score'],
      'started_at': audit['startedAt'],
      'completed_at': audit['completedAt'],
      'sync_status': 'synced',
      'created_at': audit['createdAt'],
      'updated_at': audit['updatedAt'],
    };
    await box.put(audit['id'], localAudit);

    // Save answers
    if (audit['answers'] != null) {
      final answersBox = Hive.box(HiveService.answersBox);
      for (final a in audit['answers']) {
        await answersBox.put(a['id'], {
          'id': a['id'],
          'audit_id': audit['id'],
          'question_id': a['questionId'],
          'value': a['value'],
          'comment': a['comment'],
          'score': a['score'],
          'sync_status': 'synced',
          'created_at': a['createdAt'],
          'updated_at': a['updatedAt'],
        });
      }
    }
  }

  // ==================== HELPERS ====================

  Future<void> _updateEntitySyncStatus(
    String entityType,
    String entityId,
    SyncStatus status,
  ) async {
    String boxName;
    switch (entityType) {
      case 'template':
        boxName = HiveService.templatesBox;
        break;
      case 'audit':
        boxName = HiveService.auditsBox;
        break;
      case 'category':
        boxName = HiveService.categoriesBox;
        break;
      case 'answer':
        boxName = HiveService.answersBox;
        break;
      default:
        return;
    }

    final box = Hive.box(boxName);
    final entity = box.get(entityId);
    if (entity != null) {
      final updated = Map<String, dynamic>.from(entity);
      updated['sync_status'] = status.name;
      await box.put(entityId, updated);
    }
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Check if error is a network error (no connection, timeout, etc.)
  bool _isNetworkError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socketexception') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection reset') ||
        errorStr.contains('connection closed') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('no route to host') ||
        errorStr.contains('timed out') ||
        errorStr.contains('timeout') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('no internet') ||
        errorStr.contains('network error');
  }

  /// Retry failed mutations
  Future<void> retryFailed() async {
    final box = Hive.box(syncQueueBox);

    // Reset retry count for failed entries
    final entries = box.values
        .map((e) => SyncQueueEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.retryCount >= maxRetries)
        .toList();

    for (final entry in entries) {
      final resetEntry = SyncQueueEntry(
        id: entry.id,
        entityType: entry.entityType,
        entityId: entry.entityId,
        mutationType: entry.mutationType,
        data: entry.data,
        retryCount: 0,
        createdAt: entry.createdAt,
      );
      await box.put(entry.id, resetEntry.toJson());

      // Reset entity status to pending
      await _updateEntitySyncStatus(
        entry.entityType,
        entry.entityId,
        SyncStatus.pending,
      );
    }

    // Process queue
    await processQueue();
  }

  /// Get sync status for an entity
  SyncStatus getEntitySyncStatus(String entityType, String entityId) {
    String boxName;
    switch (entityType) {
      case 'template':
        boxName = HiveService.templatesBox;
        break;
      case 'audit':
        boxName = HiveService.auditsBox;
        break;
      case 'category':
        boxName = HiveService.categoriesBox;
        break;
      case 'answer':
        boxName = HiveService.answersBox;
        break;
      default:
        return SyncStatus.synced;
    }

    final box = Hive.box(boxName);
    final entity = box.get(entityId);
    if (entity == null) return SyncStatus.synced;

    final statusStr = entity['sync_status'] as String?;
    if (statusStr == null) return SyncStatus.synced;

    return SyncStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => SyncStatus.synced,
    );
  }
}

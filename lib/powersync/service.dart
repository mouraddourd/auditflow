import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Schéma SQLite local pour PowerSync
class PowerSyncSchema {
  static final Schema schema = Schema([
    const Table('templates', [
      Column.text('name'),
      Column.text('description'),
      Column.text('category'),
      Column.text('user_id'),
      Column.integer('is_public'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ]),
    const Table('questions', [
      Column.text('template_id'),
      Column.text('type'),
      Column.text('text'),
      Column.integer('order'),
      Column.integer('required'),
      Column.text('created_at'),
    ]),
    const Table('audits', [
      Column.text('title'),
      Column.text('description'),
      Column.text('status'),
      Column.integer('score'),
      Column.text('template_id'),
      Column.text('user_id'),
      Column.text('started_at'),
      Column.text('completed_at'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ]),
    const Table('answers', [
      Column.text('audit_id'),
      Column.text('question_id'),
      Column.text('value'),
      Column.text('comment'),
      Column.integer('score'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ]),
  ]);
}

/// Service PowerSync pour AuditFlow
/// Gère la synchronisation temps réel entre SQLite local et PostgreSQL
class PowerSyncService {
  static final PowerSyncService _instance = PowerSyncService._internal();
  factory PowerSyncService() => _instance;
  PowerSyncService._internal();

  PowerSyncDatabase? _db;
  bool _initialized = false;
  String? _userId;

  PowerSyncDatabase get db {
    if (_db == null) {
      throw StateError('PowerSync not initialized. Call initialize() first.');
    }
    return _db!;
  }

  bool get isInitialized => _initialized;
  bool get isConnected => _db?.currentStatus.connected ?? false;

  /// Initialise PowerSync avec le schéma local
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final dbPath = await _getDatabasePath();

      _db = PowerSyncDatabase(
        schema: PowerSyncSchema.schema,
        path: dbPath,
      );

      await _db!.initialize();

      _initialized = true;
      debugPrint('✅ PowerSync initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ PowerSync initialization failed: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  /// Connecte au service PowerSync cloud
  Future<void> connect({
    required String userId,
    required String authToken,
    String? endpoint,
  }) async {
    if (!_initialized) {
      throw StateError('PowerSync not initialized');
    }

    _userId = userId;

    try {
      // Endpoint Docker local - ws:// pour WebSocket
      // Pour Android emulator: ws://10.0.2.2:8080
      // Pour iOS simulator: ws://localhost:8080
      // Pour device physique: ws://VOTRE_IP:8080
      final powerSyncEndpoint = endpoint ?? 'ws://localhost:8080';

      final connector = _AuditFlowConnector(
        endpoint: powerSyncEndpoint,
        token: authToken,
        userId: userId,
      );

      await _db!.connect(connector: connector);

      debugPrint('✅ PowerSync connected for user: $userId');
    } catch (e, stackTrace) {
      debugPrint('❌ PowerSync connection failed: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  /// Déconnecte du service PowerSync
  Future<void> disconnect() async {
    if (_db != null) {
      await _db!.disconnect();
      debugPrint('👋 PowerSync disconnected');
    }
  }

  /// Récupère tous les audits d'un utilisateur
  Future<List<Map<String, dynamic>>> getAudits({
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    if (_userId == null) return [];

    var sql = 'SELECT * FROM audits WHERE user_id = ?';
    var params = [_userId];

    if (status != null) {
      sql += ' AND status = ?';
      params.add(status);
    }

    if (search != null && search.isNotEmpty) {
      sql += " AND (title LIKE ? OR description LIKE ?)";
      params.add('%$search%');
      params.add('%$search%');
    }

    sql += ' ORDER BY updated_at DESC LIMIT ? OFFSET ?';
    params.add(limit.toString());
    params.add(offset.toString());

    return await db.getAll(sql, params);
  }

  /// Stream réactif des audits
  Stream<List<Map<String, dynamic>>> watchAudits({
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) {
    if (_userId == null) return Stream.value([]);

    var sql = 'SELECT * FROM audits WHERE user_id = ?';
    var params = <Object?>[_userId];

    if (status != null) {
      sql += ' AND status = ?';
      params.add(status);
    }

    if (search != null && search.isNotEmpty) {
      sql += " AND (title LIKE ? OR description LIKE ?)";
      params.add('%$search%');
      params.add('%$search%');
    }

    sql += ' ORDER BY updated_at DESC LIMIT ? OFFSET ?';
    params.add(limit.toString());
    params.add(offset.toString());

    return db.watch(sql, parameters: params);
  }

  /// Récupère un audit par ID avec ses relations
  Future<Map<String, dynamic>?> getAuditById(String auditId) async {
    if (_userId == null) return null;

    final audits = await db.getAll(
      'SELECT * FROM audits WHERE id = ? AND user_id = ?',
      [auditId, _userId],
    );

    if (audits.isEmpty) return null;

    final audit = audits.first;

    // Récupérer les réponses
    final answers = await db.getAll(
      'SELECT * FROM answers WHERE audit_id = ?',
      [auditId],
    );

    audit['answers'] = answers;
    return audit;
  }

  /// Crée un nouvel audit (écriture locale + sync)
  Future<Map<String, dynamic>> createAudit({
    required String title,
    String? description,
    required String templateId,
  }) async {
    if (_userId == null) throw StateError('User not authenticated');

    final id = _generateId();
    final now = DateTime.now().toIso8601String();

    await db.execute('''
      INSERT INTO audits (id, title, description, template_id, user_id, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [id, title, description, templateId, _userId, 'draft', now, now]);

    return {
      'id': id,
      'title': title,
      'description': description,
      'template_id': templateId,
      'user_id': _userId,
      'status': 'draft',
      'created_at': now,
      'updated_at': now,
    };
  }

  /// Met à jour le statut d'un audit
  Future<void> updateAuditStatus(String auditId, String status) async {
    if (_userId == null) throw StateError('User not authenticated');

    final now = DateTime.now().toIso8601String();

    String? startedAt;
    String? completedAt;

    if (status == 'in_progress') {
      startedAt = now;
    } else if (status == 'completed') {
      completedAt = now;
    }

    await db.execute('''
      UPDATE audits 
      SET status = ?, 
          ${startedAt != null ? 'started_at = ?,' : ''}
          ${completedAt != null ? 'completed_at = ?,' : ''}
          updated_at = ?
      WHERE id = ? AND user_id = ?
    ''', [
      status,
      if (startedAt != null) startedAt,
      if (completedAt != null) completedAt,
      now,
      auditId,
      _userId,
    ]);
  }

  /// Sauvegarde une réponse
  Future<void> saveAnswer({
    required String auditId,
    required String questionId,
    required String value,
    String? comment,
    int? score,
  }) async {
    if (_userId == null) throw StateError('User not authenticated');

    final now = DateTime.now().toIso8601String();

    // Vérifier si une réponse existe déjà pour ce couple audit/question
    final existing = await db.getAll(
      'SELECT id FROM answers WHERE audit_id = ? AND question_id = ?',
      [auditId, questionId],
    );

    if (existing.isNotEmpty) {
      // Mettre à jour la réponse existante
      await db.execute('''
        UPDATE answers 
        SET value = ?, comment = ?, score = ?, updated_at = ?
        WHERE id = ?
      ''', [value, comment, score, now, existing.first['id']]);
    } else {
      // Créer une nouvelle réponse avec UUID
      final id = _generateId();
      await db.execute('''
        INSERT INTO answers (id, audit_id, question_id, value, comment, score, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''', [id, auditId, questionId, value, comment, score, now, now]);
    }
  }

  /// Récupère les templates disponibles
  Future<List<Map<String, dynamic>>> getTemplates() async {
    if (_userId == null) return [];

    return await db.getAll('''
      SELECT t.*, COUNT(q.id) as question_count
      FROM templates t
      LEFT JOIN questions q ON q.template_id = t.id
      WHERE t.user_id = ? OR t.is_public = 1
      GROUP BY t.id
      ORDER BY t.updated_at DESC
    ''', [_userId]);
  }

  /// Récupère un template avec ses questions
  Future<Map<String, dynamic>?> getTemplateById(String templateId) async {
    final templates = await db.getAll(
      'SELECT * FROM templates WHERE id = ?',
      [templateId],
    );

    if (templates.isEmpty) return null;

    final template = templates.first;

    final questions = await db.getAll(
      'SELECT * FROM questions WHERE template_id = ? ORDER BY "order" ASC',
      [templateId],
    );

    template['questions'] = questions;
    return template;
  }

  /// Récupère les statistiques des audits
  Future<Map<String, dynamic>> getAuditStats() async {
    if (_userId == null) {
      return {
        'total': 0,
        'completed': 0,
        'in_progress': 0,
        'draft': 0,
        'avg_score': 0,
      };
    }

    final results = await db.getAll('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
        SUM(CASE WHEN status = 'draft' THEN 1 ELSE 0 END) as draft,
        AVG(CASE WHEN status = 'completed' AND score IS NOT NULL THEN score END) as avg_score
      FROM audits 
      WHERE user_id = ?
    ''', [_userId]);

    final stats = results.first;
    return {
      'total': stats['total'] ?? 0,
      'completed': stats['completed'] ?? 0,
      'in_progress': stats['in_progress'] ?? 0,
      'draft': stats['draft'] ?? 0,
      'avg_score': (stats['avg_score'] ?? 0).toDouble(),
    };
  }

  /// Supprime un audit
  Future<void> deleteAudit(String auditId) async {
    if (_userId == null) throw StateError('User not authenticated');

    await db.execute(
      'DELETE FROM audits WHERE id = ? AND user_id = ?',
      [auditId, _userId],
    );
  }

  /// Force une synchronisation manuelle
  /// Note: PowerSync synchronise automatiquement quand connecté.
  /// Cette méthode est conservée pour compatibilité mais n'a pas d'effet.
  Future<void> sync() async {
    // PowerSync syncs automatically when connected
    // To force a full resync, use disconnect() then connect()
    debugPrint('PowerSync sync is automatic when connected');
  }

  /// Retourne le chemin de la base de données SQLite
  Future<String> _getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return join(directory.path, 'auditflow_powersync.db');
  }

  /// Génère un ID unique
  String _generateId() {
    return const Uuid().v4();
  }
}

/// Connecteur PowerSync personnalisé pour AuditFlow
class _AuditFlowConnector extends PowerSyncBackendConnector {
  final String endpoint;
  final String token;
  final String userId;

  _AuditFlowConnector({
    required this.endpoint,
    required this.token,
    required this.userId,
  });

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // Récupérer les changements en attente
    final batch = await database.getCrudBatch();
    if (batch == null) {
      return; // Rien à uploader
    }

    try {
      final changes = batch.crud.map((crud) {
        final op = crud.op;
        final opName = _getOperationName(op);

        return {
          'op': opName,
          'table': crud.table,
          'id': crud.id,
          'data': op == UpdateType.delete ? null : crud.opData,
        };
      }).toList();

      // Appeler l'API backend avec http
      final response = await http.post(
        Uri.parse('http://localhost:3000/powersync/upload'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'changes': changes,
          'userId': userId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Marquer comme uploadé
        await batch.complete();
        debugPrint('✅ Upload successful: ${changes.length} changes');
      } else {
        // Erreurs côté serveur - ne pas compléter le batch pour permettre un retry
        final errors = responseData['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          debugPrint('⚠️ Upload errors: $errors');
        }
        debugPrint(
            '❌ Upload failed with status ${response.statusCode}, will retry later');
        return;
      }
    } catch (error) {
      debugPrint('❌ Upload failed: $error');
      rethrow;
    }
  }

  String _getOperationName(UpdateType op) {
    switch (op) {
      case UpdateType.delete:
        return 'DELETE';
      case UpdateType.put:
        return 'INSERT';
      case UpdateType.patch:
        return 'UPDATE';
    }
  }

  @override
  Future<PowerSyncCredentials> fetchCredentials() async {
    return PowerSyncCredentials(
      endpoint: endpoint,
      token: token,
    );
  }
}

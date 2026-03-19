import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String organizationsBox = 'organizations';
  static const String templatesBox = 'templates';
  static const String questionsBox = 'questions';
  static const String auditsBox = 'audits';
  static const String answersBox = 'answers';
  static const String organizationMembersBox = 'organization_members';
  static const String categoriesBox = 'categories';
  static const String usersBox = 'users';
  static const String syncQueueBox = 'sync_queue';

  bool _initialized = false;
  String? _organizationId;
  String? _userId;

  bool get isInitialized => _initialized;
  String? get organizationId => _organizationId;
  String? get userId => _userId;

  void setOrganization(String? organizationId) {
    _organizationId = organizationId;
  }

  void setUser(String? userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setString('user_id', userId);
    } else {
      await prefs.remove('user_id');
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    await Hive.openBox(organizationsBox);
    await Hive.openBox(templatesBox);
    await Hive.openBox(questionsBox);
    await Hive.openBox(auditsBox);
    await Hive.openBox(answersBox);
    await Hive.openBox(organizationMembersBox);
    await Hive.openBox(categoriesBox);
    await Hive.openBox(usersBox);
    await Hive.openBox(syncQueueBox);

    // Charger l'ID utilisateur sauvegardé (même clé que AuthService: 'user_id')
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');

    _initialized = true;
  }

  String _generateId() {
    return const Uuid().v4();
  }

  // Organizations
  Future<void> saveOrganization(Map<String, dynamic> org) async {
    final box = Hive.box(organizationsBox);
    await box.put(org['id'], org);
  }

  List<Map<String, dynamic>> getOrganizations() {
    final box = Hive.box(organizationsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic>? getOrganization(String id) {
    final box = Hive.box(organizationsBox);
    final org = box.get(id);
    if (org == null) return null;
    return Map<String, dynamic>.from(org);
  }

  Future<void> updateOrganization(String id, {String? name}) async {
    final box = Hive.box(organizationsBox);
    final org = box.get(id);
    if (org == null) return;

    final updated = Map<String, dynamic>.from(org);
    if (name != null) updated['name'] = name;
    updated['updated_at'] = DateTime.now().toIso8601String();

    await box.put(id, updated);
  }

  Future<void> deleteOrganization(String orgId) async {
    final box = Hive.box(organizationsBox);
    await box.delete(orgId);

    // Cascade: supprimer les membres de cette organisation
    final membersBox = Hive.box(organizationMembersBox);
    final membersToDelete = membersBox.keys
        .where((k) => membersBox.get(k)?['organization_id'] == orgId)
        .toList();
    for (final mId in membersToDelete) {
      await membersBox.delete(mId);
    }
  }

  // Templates
  Future<Map<String, dynamic>> createTemplate({
    required String name,
    required String category,
    String? description,
    required List<Map<String, dynamic>> questions,
  }) async {
    if (_organizationId == null) throw StateError('No organization selected');

    final id = _generateId();
    final now = DateTime.now().toIso8601String();

    final template = {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'organization_id': _organizationId,
      'user_id': _userId,
      'is_public': 0,
      'created_at': now,
      'updated_at': now,
      'question_count': questions.length,
      'sync_status': 'pending',
    };

    final box = Hive.box(templatesBox);
    await box.put(id, template);

    final questionsBoxInstance = Hive.box(questionsBox);
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final questionId = _generateId();

      await questionsBoxInstance.put(questionId, {
        'id': questionId,
        'template_id': id,
        'type': question['type'] ?? 'text',
        'text': question['text'] ?? '',
        'order': i + 1,
        'required': question['required'] == true ? 1 : 0,
        'options': question['options'], // Pour les questions de type multiple
        'created_at': now,
        'original_question_id': questionId,
        'sync_status': 'pending',
      });
    }

    return template;
  }

  List<Map<String, dynamic>> getTemplates() {
    final box = Hive.box(templatesBox);
    return box.values
        .where((t) =>
            (t['organization_id'] == _organizationId ||
                t['is_public'] == 1 ||
                t['is_public'] == true) &&
            t['is_audit_copy'] != true) // Exclure les copies d'audit
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> getQuestionsForTemplate(String templateId) {
    final box = Hive.box(questionsBox);
    return box.values
        .where((q) => q['template_id'] == templateId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> updateTemplate({
    required String id,
    required String name,
    required String category,
    String? description,
    required List<Map<String, dynamic>> questions,
  }) async {
    final box = Hive.box(templatesBox);
    final template = box.get(id);
    if (template == null) return;

    final now = DateTime.now().toIso8601String();
    final updatedTemplate = Map<String, dynamic>.from(template);
    updatedTemplate['name'] = name;
    updatedTemplate['category'] = category;
    updatedTemplate['description'] = description;
    updatedTemplate['updated_at'] = now;
    updatedTemplate['question_count'] = questions.length;
    updatedTemplate['sync_status'] = 'pending';

    await box.put(id, updatedTemplate);

    // Supprimer les anciennes questions
    final questionsBoxInstance = Hive.box(questionsBox);
    final oldQuestions = questionsBoxInstance.values
        .where((q) => q['template_id'] == id)
        .map((q) => q['id'] as String)
        .toList();
    for (final qId in oldQuestions) {
      await questionsBoxInstance.delete(qId);
    }

    // Ajouter les nouvelles questions
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final questionId = _generateId();

      final questionData = {
        'id': questionId,
        'template_id': id,
        'type': question['type'] ?? 'text',
        'text': question['text'] ?? '',
        'order': i + 1,
        'required': question['required'] == true ? 1 : 0,
        'options': question['options'], // Pour les questions de type multiple
        'created_at': now,
        'original_question_id': questionId,
        'sync_status': 'pending',
      };

      await questionsBoxInstance.put(questionId, questionData);
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    // Supprimer les questions associées
    final questionsBoxInstance = Hive.box(questionsBox);
    final questionsToDelete = questionsBoxInstance.values
        .where((q) => q['template_id'] == templateId)
        .map((q) => q['id'] as String)
        .toList();
    for (final qId in questionsToDelete) {
      await questionsBoxInstance.delete(qId);
    }

    // Supprimer le template
    final box = Hive.box(templatesBox);
    await box.delete(templateId);
  }

  Map<String, dynamic>? getTemplateById(String templateId) {
    final box = Hive.box(templatesBox);
    final template = box.get(templateId);
    if (template == null) {
      return null;
    }

    final result = Map<String, dynamic>.from(template);

    final questionsBoxInstance = Hive.box(questionsBox);
    final questions = questionsBoxInstance.values
        .where((q) => q['template_id'] == templateId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    questions.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

    result['questions'] = questions;
    return result;
  }

  // Audits
  Future<Map<String, dynamic>> createAudit({
    required String title,
    String? description,
    required String templateId,
  }) async {
    if (_userId == null) throw StateError('User not authenticated');
    if (_organizationId == null) throw StateError('No organization selected');

    final id = _generateId();
    final now = DateTime.now().toIso8601String();

    // Dupliquer la template pour cet audit
    final originalTemplate = Hive.box(templatesBox).get(templateId);

    String? auditTemplateId;
    if (originalTemplate != null) {
      // Créer une copie de la template
      auditTemplateId = _generateId();
      final copiedTemplate = Map<String, dynamic>.from(originalTemplate);
      copiedTemplate['id'] = auditTemplateId;
      copiedTemplate['is_audit_copy'] = true; // Marquer comme copie d'audit
      copiedTemplate['original_template_id'] = templateId;
      copiedTemplate['created_at'] = now;
      copiedTemplate['updated_at'] = now;
      copiedTemplate['sync_status'] = 'pending';

      await Hive.box(templatesBox).put(auditTemplateId, copiedTemplate);

      // Dupliquer les questions de la template
      final questionsBoxInstance = Hive.box(questionsBox);
      final originalQuestions = questionsBoxInstance.values
          .where((q) => q['template_id'] == templateId)
          .toList();

      for (final q in originalQuestions) {
        final questionCopy = Map<String, dynamic>.from(q);
        final newQuestionId = _generateId();

        questionCopy['id'] = newQuestionId;
        questionCopy['template_id'] = auditTemplateId;
        questionCopy['created_at'] = now;
        questionCopy['original_question_id'] =
            q['original_question_id'] ?? q['id'];
        questionCopy['sync_status'] = 'pending';
        await questionsBoxInstance.put(newQuestionId, questionCopy);
      }
    }

    final audit = {
      'id': id,
      'title': title,
      'description': description,
      'template_id': auditTemplateId ?? templateId,
      'original_template_id': templateId,
      'user_id': _userId,
      'organization_id': _organizationId,
      'status': 'draft',
      'score': null,
      'started_at': null,
      'completed_at': null,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
    };

    final box = Hive.box(auditsBox);
    await box.put(id, audit);

    return audit;
  }

  List<Map<String, dynamic>> getAudits({String? status, String? search}) {
    final box = Hive.box(auditsBox);
    var audits = box.values
        .where((a) => a['organization_id'] == _organizationId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (status != null) {
      audits = audits.where((a) => a['status'] == status).toList();
    }

    if (search != null && search.isNotEmpty) {
      final lowerSearch = search.toLowerCase();
      audits = audits
          .where((a) =>
              (a['title'] as String?)?.toLowerCase().contains(lowerSearch) ==
                  true ||
              (a['description'] as String?)
                      ?.toLowerCase()
                      .contains(lowerSearch) ==
                  true)
          .toList();
    }

    audits.sort((a, b) =>
        (b['updated_at'] as String).compareTo(a['updated_at'] as String));
    return audits;
  }

  Map<String, dynamic>? getAuditById(String auditId) {
    final box = Hive.box(auditsBox);
    final audit = box.get(auditId);
    if (audit == null) return null;

    final result = Map<String, dynamic>.from(audit);

    final answersBoxInstance = Hive.box(answersBox);
    final answers = answersBoxInstance.values
        .where((a) => a['audit_id'] == auditId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    result['answers'] = answers;
    return result;
  }

  Future<void> updateAuditStatus(String auditId, String status,
      {int? score}) async {
    final box = Hive.box(auditsBox);
    final audit = box.get(auditId);
    if (audit == null) return;

    final now = DateTime.now().toIso8601String();
    final updatedAudit = Map<String, dynamic>.from(audit);
    updatedAudit['status'] = status;
    updatedAudit['updated_at'] = now;

    if (status == 'in_progress' && audit['started_at'] == null) {
      updatedAudit['started_at'] = now;
    }
    if (status == 'completed') {
      updatedAudit['completed_at'] = now;
    }
    if (score != null) {
      updatedAudit['score'] = score;
    }
    updatedAudit['sync_status'] = 'pending';

    await box.put(auditId, updatedAudit);
  }

  /// Met à jour le score de progression d'un audit (pendant le remplissage)
  Future<void> updateAuditProgress(String auditId, int progressPercent) async {
    final box = Hive.box(auditsBox);
    final audit = box.get(auditId);
    if (audit == null) return;

    final now = DateTime.now().toIso8601String();
    final updatedAudit = Map<String, dynamic>.from(audit);
    updatedAudit['score'] = progressPercent;
    updatedAudit['updated_at'] = now;
    updatedAudit['sync_status'] = 'pending';

    await box.put(auditId, updatedAudit);
  }

  Future<void> updateAudit(String id,
      {String? title, String? description}) async {
    final box = Hive.box(auditsBox);
    final audit = box.get(id);
    if (audit == null) return;

    final now = DateTime.now().toIso8601String();
    final updatedAudit = Map<String, dynamic>.from(audit);
    if (title != null) updatedAudit['title'] = title;
    if (description != null) updatedAudit['description'] = description;
    updatedAudit['updated_at'] = now;
    updatedAudit['sync_status'] = 'pending';

    await box.put(id, updatedAudit);
  }

  Future<void> deleteAudit(String auditId) async {
    final box = Hive.box(auditsBox);
    await box.delete(auditId);

    final answersBoxInstance = Hive.box(answersBox);
    final answersToDelete = answersBoxInstance.values
        .where((a) => a['audit_id'] == auditId)
        .map((a) => a['id'])
        .toList();

    for (final answerId in answersToDelete) {
      await answersBoxInstance.delete(answerId);
    }
  }

  // Answers
  Future<void> saveAnswer({
    required String auditId,
    required String questionId,
    required String value,
    String? comment,
    int? score,
  }) async {
    final now = DateTime.now().toIso8601String();

    final answersBoxInstance = Hive.box(answersBox);

    final existingKey = answersBoxInstance.keys.cast<String>().firstWhere(
          (key) =>
              answersBoxInstance.get(key)?['audit_id'] == auditId &&
              answersBoxInstance.get(key)?['question_id'] == questionId,
          orElse: () => '',
        );

    if (existingKey.isNotEmpty) {
      final existing =
          Map<String, dynamic>.from(answersBoxInstance.get(existingKey));
      existing['value'] = value;
      existing['comment'] = comment;
      existing['score'] = score;
      existing['updated_at'] = now;
      existing['sync_status'] = 'pending';
      await answersBoxInstance.put(existingKey, existing);
    } else {
      final id = _generateId();
      await answersBoxInstance.put(id, {
        'id': id,
        'audit_id': auditId,
        'question_id': questionId,
        'value': value,
        'comment': comment,
        'score': score,
        'created_at': now,
        'updated_at': now,
        'sync_status': 'pending',
      });
    }
  }

  Map<String, dynamic>? getAnswer(String auditId, String questionId) {
    final box = Hive.box(answersBox);
    final answer = box.values.firstWhere(
      (a) => a['audit_id'] == auditId && a['question_id'] == questionId,
      orElse: () => null,
    );
    return answer != null ? Map<String, dynamic>.from(answer) : null;
  }

  List<Map<String, dynamic>> getAnswersForAudit(String auditId) {
    final box = Hive.box(answersBox);
    return box.values
        .where((a) => a['audit_id'] == auditId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> deleteAnswer(String auditId, String questionId) async {
    final box = Hive.box(answersBox);
    final key = box.keys.firstWhere(
      (k) =>
          box.get(k)?['audit_id'] == auditId &&
          box.get(k)?['question_id'] == questionId,
      orElse: () => null,
    );
    if (key != null) await box.delete(key);
  }

  // Stats
  Map<String, dynamic> getAuditStats() {
    final audits = getAudits();
    final completed = audits.where((a) => a['status'] == 'completed').toList();

    int totalScore = 0;
    int scoreCount = 0;
    for (final audit in completed) {
      final score = audit['score'];
      if (score != null) {
        totalScore += score as int;
        scoreCount++;
      }
    }

    return {
      'total': audits.length,
      'completed': completed.length,
      'in_progress': audits.where((a) => a['status'] == 'in_progress').length,
      'draft': audits.where((a) => a['status'] == 'draft').length,
      'avg_score': scoreCount > 0 ? totalScore / scoreCount : 0.0,
    };
  }

  // Audit Results
  Future<Map<String, dynamic>> getAuditResults(String auditId) async {
    final audit = getAuditById(auditId);
    if (audit == null) {
      return {'audit': null, 'categoryScores': <String, int>{}, 'issues': []};
    }

    final templateId = audit['template_id'] as String;
    final template = getTemplateById(templateId);
    if (template == null) {
      return {'audit': audit, 'categoryScores': <String, int>{}, 'issues': []};
    }

    final questions = template['questions'] as List<Map<String, dynamic>>;
    final questionMap = <String, Map<String, dynamic>>{};
    for (final q in questions) {
      questionMap[q['id'] as String] = q;
    }

    final categoryScores = <String, List<int>>{};
    final issues = <Map<String, dynamic>>[];

    final answers = audit['answers'] as List<dynamic>;
    for (final answer in answers) {
      final questionId = answer['question_id'] as String;
      final question = questionMap[questionId];
      if (question == null) continue;

      final category = question['category'] as String? ?? 'Général';
      final type = question['type'] as String?;
      final value = answer['value'] as String?;

      int? score;
      bool isIssue = false;

      if (type == 'yes_no') {
        score = value == 'true' ? 100 : 0;
        isIssue = value == 'false';
      } else if (type == 'scale') {
        final scaleValue = int.tryParse(value ?? '') ?? 0;
        if (scaleValue > 0) {
          score = ((scaleValue - 1) / 4 * 100).round();
          isIssue = scaleValue < 3;
        }
      }

      if (score != null) {
        categoryScores.putIfAbsent(category, () => []);
        categoryScores[category]!.add(score);
      }

      if (isIssue) {
        issues.add({
          'question': question['text'] as String? ?? 'Question',
          'category': category,
          'value': value,
          'comment': answer['comment'] as String?,
        });
      }
    }

    final avgCategoryScores = <String, int>{};
    categoryScores.forEach((category, scores) {
      if (scores.isNotEmpty) {
        avgCategoryScores[category] =
            (scores.reduce((a, b) => a + b) / scores.length).round();
      }
    });

    return {
      'audit': audit,
      'categoryScores': avgCategoryScores,
      'issues': issues,
    };
  }

  // Members
  List<Map<String, dynamic>> getOrganizationMembers() {
    final box = Hive.box(organizationMembersBox);
    return box.values
        .where((m) => m['organization_id'] == _organizationId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Categories
  List<Map<String, dynamic>> getCategories() {
    final box = Hive.box(categoriesBox);
    return box.values
        .where((c) => c['organization_id'] == _organizationId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    String? color,
  }) async {
    if (_organizationId == null) throw StateError('No organization selected');

    final id = _generateId();
    final now = DateTime.now().toIso8601String();

    final category = {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'organization_id': _organizationId,
      'created_at': now,
      'updated_at': now,
      'sync_status': 'pending',
    };

    final box = Hive.box(categoriesBox);
    await box.put(id, category);

    return category;
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    String? description,
    String? color,
  }) async {
    final box = Hive.box(categoriesBox);
    final category = box.get(id);
    if (category == null) return;

    final now = DateTime.now().toIso8601String();
    final updated = Map<String, dynamic>.from(category);
    updated['name'] = name;
    updated['description'] = description;
    updated['color'] = color;
    updated['updated_at'] = now;
    updated['sync_status'] = 'pending';

    await box.put(id, updated);
  }

  Future<void> deleteCategory(String id) async {
    final box = Hive.box(categoriesBox);
    await box.delete(id);
  }

  Future<void> seedDefaultCategories() async {
    if (_organizationId == null) return;

    final existing = getCategories();
    if (existing.isNotEmpty) return;

    final defaults = [
      {'name': 'Qualité', 'color': '#4CAF50'},
      {'name': 'Sécurité', 'color': '#F44336'},
      {'name': 'Environnement', 'color': '#2196F3'},
      {'name': 'Hygiène', 'color': '#FF9800'},
      {'name': 'Technique', 'color': '#9C27B0'},
      {'name': 'Conformité', 'color': '#607D8B'},
    ];

    for (final cat in defaults) {
      await createCategory(
        name: cat['name']!,
        color: cat['color'],
      );
    }
  }

  // Users
  List<Map<String, dynamic>> getUsers() {
    final box = Hive.box(usersBox);
    return box.values.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Map<String, dynamic>? getCurrentUser() {
    if (_userId == null) return null;
    final box = Hive.box(usersBox);
    final user = box.get(_userId);
    return user != null ? Map<String, dynamic>.from(user) : null;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> user) async {
    final box = Hive.box(usersBox);
    // Utiliser l'ID fourni ou générer un nouveau (pour le profil local)
    final id = user['id'] ?? _generateId();
    final newUser = {
      'id': id,
      'name': user['name'] ?? '',
      'email': user['email'] ?? '',
      'phone': user['phone'] ?? '',
      'avatar': user['avatar'] ?? '',
      'organization_id': _organizationId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await box.put(id, newUser);
    // Ne PAS écraser _userId si déjà défini par l'authentification
    if (_userId == null) {
      _userId = id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', id);
    }
    return newUser;
  }

  Future<void> updateUser(String id, Map<String, dynamic> updates) async {
    final box = Hive.box(usersBox);
    final existing = box.get(id);
    if (existing == null) throw Exception('User not found');

    final updated = Map<String, dynamic>.from(existing);
    updated['name'] = updates['name'] ?? updated['name'];
    updated['email'] = updates['email'] ?? updated['email'];
    updated['phone'] = updates['phone'] ?? updated['phone'];
    updated['avatar'] = updates['avatar'] ?? updated['avatar'];
    updated['updated_at'] = DateTime.now().toIso8601String();

    await box.put(id, updated);
  }

  Future<void> deleteUser(String id) async {
    final box = Hive.box(usersBox);
    await box.delete(id);
    if (_userId == id) _userId = null;
  }

  Future<void> clear() async {
    await Hive.box(organizationsBox).clear();
    await Hive.box(templatesBox).clear();
    await Hive.box(questionsBox).clear();
    await Hive.box(auditsBox).clear();
    await Hive.box(answersBox).clear();
    await Hive.box(organizationMembersBox).clear();
    await Hive.box(categoriesBox).clear();
    await Hive.box(usersBox).clear();
    await Hive.box(syncQueueBox).clear();
    _organizationId = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('organizationId');
  }
}

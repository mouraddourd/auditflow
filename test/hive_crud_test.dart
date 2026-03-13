import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:auditflow/hive/service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final binaryMessenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const sharedPrefs = MethodChannel('plugins.flutter.io/shared_preferences');

  setUpAll(() async {
    binaryMessenger.setMockMethodCallHandler(pathProvider,
        (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '/tmp';
      }
      return null;
    });

    binaryMessenger.setMockMethodCallHandler(sharedPrefs,
        (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, Object?>{};
      }
      return null;
    });

    await Hive.initFlutter();
    await HiveService().initialize();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    binaryMessenger.setMockMethodCallHandler(pathProvider, null);
    binaryMessenger.setMockMethodCallHandler(sharedPrefs, null);
  });

  group('HiveService CRUD Tests', () {
    test('Organization CRUD', () async {
      final service = HiveService();
      final orgId = 'test-org-${DateTime.now().millisecondsSinceEpoch}';

      // Create
      await service.saveOrganization({
        'id': orgId,
        'name': 'Test Org',
        'slug': 'test-org',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Read
      final orgs = service.getOrganizations();
      expect(orgs.any((o) => o['name'] == 'Test Org'), isTrue);

      // Update
      await service.updateOrganization(orgId, name: 'Test Org Updated');
      final updated = service.getOrganization(orgId);
      expect(updated!['name'], 'Test Org Updated');

      // Delete
      await service.deleteOrganization(orgId);
      final afterDelete = service.getOrganization(orgId);
      expect(afterDelete, isNull);
    });

    test('Template CRUD', () async {
      final service = HiveService();
      final orgId =
          'test-org-template-${DateTime.now().millisecondsSinceEpoch}';

      // Create org
      await service.saveOrganization({
        'id': orgId,
        'name': 'Template Test Org',
        'slug': 'template-test-org',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      service.setOrganization(orgId);

      // Create template
      await service.createTemplate(
        name: 'Test Template',
        category: 'quality',
        questions: [
          {'text': 'Question 1', 'type': 'yes_no'},
        ],
      );

      // Read
      final templates = service.getTemplates();
      expect(templates.isNotEmpty, isTrue);

      // Get by ID
      final template = service.getTemplateById(templates.first['id']);
      expect(template, isNotNull);
      expect(template!['name'], 'Test Template');

      // Update
      final tid = templates.first['id'];
      await service.updateTemplate(
        id: tid,
        name: 'Updated Template',
        category: 'quality',
        questions: [
          {'text': 'Question 1', 'type': 'yes_no'},
          {'text': 'Question 2', 'type': 'text'},
        ],
      );
      final updated = service.getTemplateById(tid);
      expect(updated!['name'], 'Updated Template');

      // Delete
      await service.deleteTemplate(tid);
      final afterDelete = service.getTemplateById(tid);
      expect(afterDelete, isNull);

      // Cleanup org
      await service.deleteOrganization(orgId);
    });

    test('Audit CRUD', () async {
      final service = HiveService();
      final orgId = 'test-org-audit-${DateTime.now().millisecondsSinceEpoch}';

      // Setup org and template
      await service.saveOrganization({
        'id': orgId,
        'name': 'Audit Test Org',
        'slug': 'audit-test-org',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      service.setOrganization(orgId);

      await service.createTemplate(
        name: 'Audit Template',
        category: 'quality',
        questions: [
          {'text': 'Q1', 'type': 'yes_no'}
        ],
      );

      final templates = service.getTemplates();
      final templateId = templates.first['id'];

      // Create audit
      final audit = await service.createAudit(
        templateId: templateId,
        title: 'Test Audit',
      );
      final auditId = audit['id'] as String;
      expect(auditId, isNotNull);

      // Read
      final audits = service.getAudits();
      expect(audits.any((a) => a['title'] == 'Test Audit'), isTrue);

      // Update
      await service.updateAudit(auditId, title: 'Updated Audit');
      final updated = service.getAuditById(auditId);
      expect(updated!['title'], 'Updated Audit');

      // Delete
      await service.deleteAudit(auditId);
      final afterDelete = service.getAuditById(auditId);
      expect(afterDelete, isNull);

      // Cleanup
      await service.deleteTemplate(templateId);
      await service.deleteOrganization(orgId);
    });

    test('Answer CRUD', () async {
      final service = HiveService();
      final orgId = 'test-org-answer-${DateTime.now().millisecondsSinceEpoch}';

      // Setup
      await service.saveOrganization({
        'id': orgId,
        'name': 'Answer Test Org',
        'slug': 'answer-test-org',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      service.setOrganization(orgId);

      await service.createTemplate(
        name: 'Answer Template',
        category: 'quality',
        questions: [
          {'text': 'Q1', 'type': 'yes_no'},
          {'text': 'Q2', 'type': 'scale'},
        ],
      );

      final templates = service.getTemplates();
      final templateId = templates.first['id'];

      final audit = await service.createAudit(
        templateId: templateId,
        title: 'Answer Audit',
      );
      final auditId = audit['id'] as String;

      final questions = service.getQuestionsForTemplate(templateId);
      expect(questions.length, 2);

      // Save answers
      await service.saveAnswer(
        auditId: auditId,
        questionId: questions[0]['id'],
        value: 'true',
      );
      await service.saveAnswer(
        auditId: auditId,
        questionId: questions[1]['id'],
        value: '4',
      );

      // Read
      final answers = service.getAnswersForAudit(auditId);
      expect(answers.length, 2);

      // Update
      await service.saveAnswer(
        auditId: auditId,
        questionId: questions[0]['id'],
        value: 'false',
      );
      final updatedAnswer = service.getAnswer(auditId, questions[0]['id']);
      expect(updatedAnswer!['value'], 'false');

      // Delete
      await service.deleteAnswer(auditId, questions[0]['id']);
      final afterDelete = service.getAnswersForAudit(auditId);
      expect(afterDelete.length, 1);

      // Cleanup
      await service.deleteAudit(auditId);
      await service.deleteTemplate(templateId);
      await service.deleteOrganization(orgId);
    });
  });
}

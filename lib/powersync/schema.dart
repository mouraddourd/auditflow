import 'package:powersync/powersync.dart';

/// Schéma SQLite local pour PowerSync
/// Synchronisé avec PostgreSQL via PowerSync Service
class PowerSyncSchema {
  static const String schema = '''
    -- Table des templates d'audit
    CREATE TABLE IF NOT EXISTS templates(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      category TEXT,
      user_id TEXT NOT NULL,
      is_public INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    );
    
    -- Table des questions dans les templates
    CREATE TABLE IF NOT EXISTS questions(
      id TEXT PRIMARY KEY,
      template_id TEXT NOT NULL,
      type TEXT NOT NULL,
      text TEXT NOT NULL,
      "order" INTEGER DEFAULT 0,
      required INTEGER DEFAULT 1,
      created_at TEXT
    );
    
    -- Table des audits (instances)
    CREATE TABLE IF NOT EXISTS audits(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      status TEXT DEFAULT 'draft',
      score INTEGER,
      template_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      started_at TEXT,
      completed_at TEXT,
      created_at TEXT,
      updated_at TEXT
    );
    
    -- Table des réponses aux questions
    CREATE TABLE IF NOT EXISTS answers(
      id TEXT PRIMARY KEY,
      audit_id TEXT NOT NULL,
      question_id TEXT NOT NULL,
      value TEXT NOT NULL,
      comment TEXT,
      score INTEGER,
      created_at TEXT,
      updated_at TEXT
    );
    
    -- Index pour optimiser les performances
    CREATE INDEX IF NOT EXISTS idx_templates_user ON templates(user_id);
    CREATE INDEX IF NOT EXISTS idx_templates_category ON templates(category);
    CREATE INDEX IF NOT EXISTS idx_questions_template ON questions(template_id);
    CREATE INDEX IF NOT EXISTS idx_audits_user ON audits(user_id);
    CREATE INDEX IF NOT EXISTS idx_audits_status ON audits(status);
    CREATE INDEX IF NOT EXISTS idx_audits_template ON audits(template_id);
    CREATE INDEX IF NOT EXISTS idx_answers_audit ON answers(audit_id);
    CREATE INDEX IF NOT EXISTS idx_answers_question ON answers(question_id);
  ''';
}

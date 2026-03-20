import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/responsive_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../hive/service.dart';
import '../../services/sync_service.dart';
import '../../services/ai_service.dart';
import '../../widgets/ai_analysis_card.dart';
import '../../widgets/anomalies_insights_card.dart';

/// Écran de remplissage d'audit avec questions chargées depuis Hive.
///
/// Reçoit auditId et templateId en paramètres de navigation.
/// Les questions sont chargées via getTemplateById() et les réponses
/// sont sauvegardées automatiquement via saveAnswer().
///
/// Si l'audit est en statut 'completed', l'écran passe en mode lecture seule
/// pour visualiser les questions et réponses sans pouvoir les modifier.
class AuditFillScreen extends StatefulWidget {
  final String auditId;
  final String templateId;
  final String auditTitle;
  final bool readOnly;

  const AuditFillScreen({
    super.key,
    required this.auditId,
    required this.templateId,
    required this.auditTitle,
    this.readOnly = false,
  });

  @override
  State<AuditFillScreen> createState() => _AuditFillScreenState();
}

class _AuditFillScreenState extends State<AuditFillScreen> {
  final Map<String, dynamic> _answers = {}; // questionId -> answer value
  final Map<String, TextEditingController> _textControllers =
      {}; // questionId -> controller
  double _progress = 0.0;

  bool _isLoading = true;
  String? _error;
  bool _isReadOnly = false; // Mode lecture seule pour audits terminés

  List<Map<String, dynamic>> _questions = [];
  Map<String, dynamic>?
      _existingAnswers; // Pour charger les réponses existantes

  /// Score de l'audit (affiché en mode lecture seule)
  int? _auditScore;

  /// Indique si un export PDF est en cours
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    // Nettoyer tous les TextEditingController
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Charge le template et ses questions depuis Hive.
  /// Met à jour le statut de l'audit à 'in_progress' si c'est un draft.
  /// Détecte si l'audit est terminé pour passer en mode lecture seule.
  Future<void> _loadTemplate() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Vérifier le statut de l'audit pour le mode lecture seule
      final audit = HiveService().getAuditById(widget.auditId);
      final isCompleted = audit?['status'] == 'completed';
      setState(() {
        _isReadOnly = widget.readOnly || isCompleted;
        _auditScore = audit?['score'] as int?;
      });

      // Charger le template avec ses questions
      final template = HiveService().getTemplateById(widget.templateId);

      if (template == null) {
        setState(() {
          _error = 'Template non trouvé';
          _isLoading = false;
        });
        return;
      }

      // Charger les réponses existantes pour cet audit
      final existingAnswers = await _loadExistingAnswers();

      // Mettre à jour le statut de l'audit à 'in_progress' si c'est un draft
      // et si on n'est pas en mode lecture seule
      if (!_isReadOnly) {
        await _updateAuditToInProgress();
      }

      // Charger les questions depuis Hive (stockées séparément du template)
      final questions =
          HiveService().getQuestionsForTemplate(widget.templateId);
      debugPrint(
          'Loaded ${questions.length} questions for template ${widget.templateId}');

      setState(() {
        _questions = questions;
        _existingAnswers = existingAnswers;
        _isLoading = false;
      });
      debugPrint('Loaded ${_questions.length} questions into UI');

      _updateProgress();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  /// Charge les réponses existantes pour cet audit depuis Hive.
  Future<Map<String, dynamic>> _loadExistingAnswers() async {
    try {
      final audit = HiveService().getAuditById(widget.auditId);
      if (audit == null) return {};

      final answers = audit['answers'] as List<dynamic>? ?? [];
      final Map<String, dynamic> result = {};
      for (final answer in answers) {
        result[answer['question_id'] as String] = answer['value'];
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Met à jour le statut de l'audit à 'in_progress' si c'est un draft.
  Future<void> _updateAuditToInProgress() async {
    try {
      await HiveService().updateAuditStatus(widget.auditId, 'in_progress');
    } catch (e) {
      debugPrint('Erreur mise à jour statut audit: $e');
    }
  }

  void _updateProgress() {
    // Compter les réponses nouvelles + existantes
    final answeredCount = _questions.where((q) {
      final questionId = q['id'] as String;
      return _answers.containsKey(questionId) ||
          (_existingAnswers?.containsKey(questionId) ?? false);
    }).length;
    setState(() {
      _progress = _questions.isEmpty ? 0.0 : answeredCount / _questions.length;
    });
  }

  /// Sauvegarde la réponse dans Hive (auto-save).
  /// Appelé à chaque changement de réponse pour éviter la perte de données.
  /// Ne fait rien si en mode lecture seule.
  Future<void> _saveAnswer(String questionId, dynamic answer) async {
    if (_questions.isEmpty || _isReadOnly) return;

    setState(() {
      _answers[questionId] = answer;
    });

    // Calculer la progression (incluant réponses existantes)
    final answeredCount = _questions.where((q) {
      final qId = q['id'] as String;
      return _answers.containsKey(qId) ||
          (_existingAnswers?.containsKey(qId) ?? false);
    }).length;
    final progress =
        _questions.isEmpty ? 0.0 : answeredCount / _questions.length;

    setState(() {
      _progress = progress;
    });

    // Sauvegarder dans Hive (auto-save)
    try {
      await HiveService().saveAnswer(
        auditId: widget.auditId,
        questionId: questionId,
        value: answer.toString(),
      );

      // Mettre à jour le score de progression dans l'audit
      final progressPercent = (progress * 100).round();
      await HiveService().updateAuditProgress(widget.auditId, progressPercent);

      // Enqueue sync for answer (debounced - will batch on audit completion)
      // Answers are synced as part of the audit update
    } catch (e) {
      // Afficher un snackbar d'erreur mais continuer
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Finalise l'audit: calcule le score et met à jour le statut.
  Future<void> _finishAudit() async {
    try {
      // Calculer le score basé sur les réponses
      // Pour les questions yes_no: true = 100, false = 0
      // Pour les questions scale: valeur normalisée sur 100
      int totalScore = 0;
      int scoredQuestions = 0;

      for (final question in _questions) {
        final questionId = question['id'] as String;
        final answer = _answers[questionId];
        final type = question['type'] as String?;

        if (answer == null) continue;

        if (type == 'yes_no') {
          totalScore += answer == true ? 100 : 0;
          scoredQuestions++;
        } else if (type == 'scale') {
          // Normaliser sur 100 (suppose min=1, max=5 par défaut)
          final min = (question['min'] as int?) ?? 1;
          final max = (question['max'] as int?) ?? 5;
          final normalizedScore = ((answer as int) - min) / (max - min) * 100;
          totalScore += normalizedScore.round();
          scoredQuestions++;
        }
      }

      // Score moyen si des questions ont été répondues
      final avgScore =
          scoredQuestions > 0 ? (totalScore / scoredQuestions).round() : null;

      // Mettre à jour le statut de l'audit à 'completed'
      await HiveService().updateAuditStatus(
        widget.auditId,
        'completed',
        score: avgScore,
      );

      // Enqueue sync for audit completion
      final updatedAudit = HiveService().getAuditById(widget.auditId);
      if (updatedAudit != null) {
        await SyncService().enqueue(
          entityType: 'audit',
          entityId: widget.auditId,
          mutationType: MutationType.update,
          data: updatedAudit,
        );

        // Enqueue answers batch sync for this audit
        await SyncService().enqueue(
          entityType: 'answer',
          entityId: widget.auditId,
          mutationType: MutationType.update,
          data: {'audit_id': widget.auditId},
        );
      }

      if (mounted) {
        // Retourner simplement à la page précédente
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la finalisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Prend une photo depuis la caméra ou la galerie et la sauvegarde
  Future<void> _pickImage(String questionId, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Copier l'image dans le dossier de l'application pour persistance
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/audit_images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        final fileName =
            'audit_${widget.auditId}_${questionId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage =
            await File(pickedFile.path).copy('${imagesDir.path}/$fileName');

        // Sauvegarder le chemin comme réponse
        await _saveAnswer(questionId, savedImage.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo ajoutée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la prise de photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Exporte l'audit au format PDF avec insights IA.
  Future<void> _exportToPdf() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      final exportDate = dateFormat.format(DateTime.now());

      // Récupérer les insights IA
      AuditInsights? insights;
      if (await SyncService().isOnline()) {
        insights = await AIService().getInsights(widget.auditId);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      widget.auditTitle,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (_auditScore != null)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: pw.BoxDecoration(
                          color: _getPdfScoreColor(_auditScore!),
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text(
                          '$_auditScore%',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#FFFFFF'),
                          ),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Exporté le $exportDate',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColor.fromHex('#666666'),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 16),
              ],
            );
          },
          build: (context) {
            final content = <pw.Widget>[];

            // Section Insights IA si disponible
            if (insights != null) {
              content.add(_buildInsightsSection(insights));
              content.add(pw.SizedBox(height: 24));
            }

            // Section Questions/Réponses
            content.add(
              pw.Text(
                'Détail des réponses',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            content.add(pw.SizedBox(height: 12));

            content.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: _questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  final questionId = question['id'] as String;
                  final answer =
                      _answers[questionId] ?? _existingAnswers?[questionId];

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('#E3F2FD'),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                'Q${index + 1}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#1976D2'),
                                ),
                              ),
                            ),
                            if (question['category'] != null) ...[
                              pw.SizedBox(width: 8),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('#FFF3E0'),
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  question['category'] as String,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('#F57C00'),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          question['text'] as String? ?? 'Question sans texte',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(12),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F5F5F5'),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Text(
                            _formatAnswer(
                              question['type'] as String?,
                              answer,
                            ),
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: answer != null
                                  ? PdfColor.fromHex('#333333')
                                  : PdfColor.fromHex('#999999'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );

            return content;
          },
          footer: (context) {
            return pw.Column(
              children: [
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'AuditFlow - Rapport d\'audit enrichi par IA',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#999999'),
                      ),
                    ),
                    pw.Text(
                      'Page ${context.pageNumber} sur ${context.pagesCount}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#999999'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'audit_${widget.auditId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(await pdf.save());

      // Partager le PDF avec share_plus (multi-plateforme)
      if (mounted) {
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Rapport d\'audit: ${widget.auditTitle}',
        );

        if (result.status == ShareResultStatus.unavailable) {
          // Fallback: ouvrir avec l'application par défaut sur Windows
          if (Platform.isWindows) {
            await Process.run('cmd', ['/c', 'start', filePath],
                runInShell: true);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('PDF exporté: $fileName'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  /// Construit la section Insights IA pour le PDF
  pw.Widget _buildInsightsSection(AuditInsights insights) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E3F2FD'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                '🤖 Insights IA',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1976D2'),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Basé sur ${insights.totalAudits} audits historiques',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#666666'),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Scores comparés
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildScoreBox(
                'Score actuel', insights.currentScore?.toString() ?? '-'),
            _buildScoreBox('Moyenne', insights.averageScore.toString()),
            if (insights.previousScore != null)
              _buildScoreBox('Précédent', insights.previousScore.toString()),
          ],
        ),
        pw.SizedBox(height: 12),

        // Tendance
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _getPdfTrendColor(insights.trend),
            borderRadius: pw.BorderRadius.circular(20),
          ),
          child: pw.Text(
            'Tendance: ${_getTrendLabel(insights.trend)}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#FFFFFF'),
            ),
          ),
        ),
        pw.SizedBox(height: 20),

        // Anomalies
        if (insights.hasAnomalies) ...[
          pw.Text(
            '⚠️ Anomalies détectées',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#D32F2F'),
            ),
          ),
          pw.SizedBox(height: 8),
          ...insights.anomalies.map((a) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _getPdfSeverityColor(a.severity),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      a.title,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      a.description,
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              )),
          pw.SizedBox(height: 16),
        ],

        // Patterns
        if (insights.hasPatterns) ...[
          pw.Text(
            '📊 Tendances',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1976D2'),
            ),
          ),
          pw.SizedBox(height: 8),
          ...insights.patterns.map((p) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E8F5E9'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  p.description,
                  style: pw.TextStyle(fontSize: 10),
                ),
              )),
        ],
      ],
    );
  }

  pw.Widget _buildScoreBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#666666'),
            ),
          ),
        ],
      ),
    );
  }

  PdfColor _getPdfScoreColor(int score) {
    if (score >= 80) return PdfColor.fromHex('#4CAF50');
    if (score >= 60) return PdfColor.fromHex('#FF9800');
    return PdfColor.fromHex('#F44336');
  }

  PdfColor _getPdfTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return PdfColor.fromHex('#4CAF50');
      case 'declining':
        return PdfColor.fromHex('#F44336');
      default:
        return PdfColor.fromHex('#2196F3');
    }
  }

  PdfColor _getPdfSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return PdfColor.fromHex('#FFEBEE');
      case 'medium':
        return PdfColor.fromHex('#FFF3E0');
      default:
        return PdfColor.fromHex('#E3F2FD');
    }
  }

  String _getTrendLabel(String trend) {
    switch (trend) {
      case 'improving':
        return 'En hausse ↑';
      case 'declining':
        return 'En baisse ↓';
      default:
        return 'Stable →';
    }
  }

  /// Formate la réponse pour l'affichage dans le PDF.
  String _formatAnswer(String? type, dynamic answer) {
    if (answer == null || answer.toString().isEmpty) {
      return 'Non répondu';
    }

    switch (type) {
      case 'yes_no':
        final value = answer.toString().toLowerCase();
        if (value == 'true' || value == '1') {
          return 'Conforme';
        } else if (value == 'false' || value == '0') {
          return 'Non conforme';
        }
        return answer.toString();
      case 'scale':
        return 'Note: $answer / 5';
      case 'multiple':
        final options = answer.toString().split(',');
        if (options.isEmpty || options.first.isEmpty) {
          return 'Aucune sélection';
        }
        return options.map((o) => '• $o').join('\n');
      case 'date':
        try {
          final date = DateTime.parse(answer.toString());
          return DateFormat('dd/MM/yyyy').format(date);
        } catch (_) {
          return answer.toString();
        }
      case 'number':
        return answer.toString();
      case 'text':
      default:
        return answer.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // État de chargement
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.auditTitle),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // État d'erreur
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.auditTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.triangleExclamation,
                  size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTemplate,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // État vide (pas de questions)
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.auditTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.clipboardQuestion,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Ce template ne contient aucune question',
                  style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.auditTitle),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isReadOnly && _auditScore != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.chartPie,
                      size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    '$_auditScore%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          if (!_isReadOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.cloudArrowUp,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('Auto-sauvegarde',
                      style: TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ),
            ),
          if (_isReadOnly && _auditScore == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.lock, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('Lecture seule',
                      style: TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          Expanded(
            child: ListView.builder(
              padding:
                  EdgeInsets.all(ResponsiveConfig.getPadding(context)).copyWith(
                bottom: ResponsiveConfig.getPadding(context) +
                    (_isReadOnly ? 80 : 0),
              ),
              itemCount: _questions.length +
                  (_isReadOnly && _auditScore != null ? 1 : 0) +
                  (_isReadOnly ? 1 : 0), // +1 for AI card when read-only
              itemBuilder: (context, index) {
                // Carte de score en première position en mode lecture seule
                if (_isReadOnly && _auditScore != null && index == 0) {
                  return _buildScoreCard();
                }

                // AI Analysis card at the end when read-only
                final aiCardIndex = _questions.length +
                    (_isReadOnly && _auditScore != null ? 1 : 0);
                if (_isReadOnly && index == aiCardIndex) {
                  return Column(
                    children: [
                      AIAnalysisCard(
                        auditId: widget.auditId,
                        onAnalysisComplete: () {
                          // Optional: refresh UI after analysis
                        },
                      ),
                      const SizedBox(height: 16),
                      AnomaliesInsightsCard(
                        auditId: widget.auditId,
                      ),
                    ],
                  );
                }

                final questionIndex =
                    (_isReadOnly && _auditScore != null) ? index - 1 : index;
                final question = _questions[questionIndex];
                final questionId = question['id'] as String;
                final currentAnswer =
                    _answers[questionId] ?? _existingAnswers?[questionId];

                return Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Q${index + 1}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (question['category'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                question['category'] as String,
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        question['text'] as String? ?? 'Question sans texte',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildAnswerWidget(question, currentAnswer, questionId),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${(_progress * 100).round()}% complété (${_questions.where((q) => _answers.containsKey(q['id']) || (_existingAnswers?.containsKey(q['id']) ?? false)).length}/${_questions.length})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (_isReadOnly)
                  // Bouton Export PDF uniquement
                  _isExporting
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Export...',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _exportToPdf,
                          icon: const Icon(FontAwesomeIcons.filePdf, size: 18),
                          label: const Text('Exporter PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                else
                  ElevatedButton.icon(
                    onPressed: _finishAudit,
                    icon: const Icon(FontAwesomeIcons.check),
                    label: const Text('Terminer l\'audit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerWidget(
      Map<String, dynamic> question, dynamic currentAnswer, String questionId) {
    final type = question['type'] as String?;

    // En mode lecture seule, afficher juste la réponse sans interaction
    if (_isReadOnly) {
      return _buildAnswerReadOnly(type, currentAnswer, question);
    }

    switch (type) {
      case 'yes_no':
        return Row(
          children: [
            Expanded(
              child: _ChoiceButton(
                icon: FontAwesomeIcons.check,
                label: 'Conforme',
                color: Colors.green,
                isSelected: currentAnswer == 'true' || currentAnswer == true,
                onTap: () => _saveAnswer(questionId, true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ChoiceButton(
                icon: FontAwesomeIcons.xmark,
                label: 'Non conforme',
                color: Colors.red,
                isSelected: currentAnswer == 'false' || currentAnswer == false,
                onTap: () => _saveAnswer(questionId, false),
              ),
            ),
          ],
        );
      case 'scale':
        final min = (question['min'] as int?) ?? 1;
        final max = (question['max'] as int?) ?? 5;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            max - min + 1,
            (index) {
              final value = min + index;
              return _ScaleButton(
                value: value,
                isSelected:
                    currentAnswer == value || currentAnswer == value.toString(),
                onTap: () => _saveAnswer(questionId, value),
              );
            },
          ),
        );
      case 'text':
        // Créer le controller si nécessaire
        if (!_textControllers.containsKey(questionId)) {
          _textControllers[questionId] = TextEditingController(
            text: currentAnswer?.toString() ?? '',
          );
        }
        return TextField(
          maxLines: 5,
          onChanged: (value) => _saveAnswer(questionId, value),
          controller: _textControllers[questionId],
          decoration: InputDecoration(
            hintText: 'Votre réponse...',
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      case 'multiple':
        // Pour les questions à choix multiples, les options sont stockées dans un champ 'options'
        // Si pas d'options, afficher un message
        final options = question['options'] as List<dynamic>? ?? [];
        if (options.isEmpty) {
          return Text('Options non disponibles pour cette question');
        }
        return Column(
          children: options.map((option) {
            final isSelected =
                (currentAnswer as String?)?.contains(option.toString()) ??
                    false;
            return CheckboxListTile(
              value: isSelected,
              onChanged: (checked) {
                // Pour les questions multiples, on concatène les valeurs
                final current = currentAnswer?.toString().split(',') ?? [];
                if (checked == true) {
                  current.add(option.toString());
                } else {
                  current.remove(option.toString());
                }
                _saveAnswer(questionId, current.join(','));
              },
              title: Text(option.toString()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        );
      case 'photo':
        final imagePath = currentAnswer?.toString();
        final hasImage = imagePath != null &&
            imagePath.isNotEmpty &&
            File(imagePath).existsSync();

        if (_isReadOnly) {
          // Mode lecture seule : afficher l'image ou "Non répondu"
          if (!hasImage) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.circleQuestion,
                      color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Text('Aucune photo',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic)),
                ],
              ),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(imagePath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          );
        }

        // Mode édition
        if (hasImage) {
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _pickImage(questionId, ImageSource.camera),
                      icon: const Icon(FontAwesomeIcons.camera, size: 18),
                      label: const Text('Reprendre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _pickImage(questionId, ImageSource.gallery),
                      icon: const Icon(FontAwesomeIcons.images, size: 18),
                      label: const Text('Galerie'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _saveAnswer(questionId, null),
                    icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
                  ),
                ],
              ),
            ],
          );
        }

        // Pas d'image : boutons pour choisir
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(questionId, ImageSource.camera),
                icon: const Icon(FontAwesomeIcons.camera, size: 18),
                label: const Text('Prendre une photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(questionId, ImageSource.gallery),
                icon: const Icon(FontAwesomeIcons.images, size: 18),
                label: const Text('Galerie'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      case 'number':
        // Créer le controller si nécessaire
        if (!_textControllers.containsKey(questionId)) {
          _textControllers[questionId] = TextEditingController(
            text: currentAnswer?.toString() ?? '',
          );
        }
        return TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) => _saveAnswer(questionId, num.tryParse(value)),
          controller: _textControllers[questionId],
          decoration: InputDecoration(
            hintText: 'Entrez un nombre...',
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      case 'date':
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: currentAnswer != null
                  ? DateTime.tryParse(currentAnswer.toString()) ??
                      DateTime.now()
                  : DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              _saveAnswer(questionId, picked.toIso8601String().split('T')[0]);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(FontAwesomeIcons.calendar,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  currentAnswer?.toString() ?? 'Sélectionner une date',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      default:
        return Text('Type de question non supporté: $type');
    }
  }

  /// Affiche une réponse en mode lecture seule (sans aspect interactif)
  Widget _buildAnswerReadOnly(
      String? type, dynamic currentAnswer, Map<String, dynamic> question) {
    final theme = Theme.of(context);

    if (currentAnswer == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(FontAwesomeIcons.circleQuestion,
                color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Text(
              'Non répondu',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    switch (type) {
      case 'yes_no':
        final isYes = currentAnswer == true || currentAnswer == 'true';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isYes
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isYes
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isYes ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
                color: isYes ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isYes ? 'Conforme' : 'Non conforme',
                style: TextStyle(
                  color: isYes ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );

      case 'scale':
        final min = (question['min'] as int?) ?? 1;
        final max = (question['max'] as int?) ?? 5;
        final value =
            int.tryParse(currentAnswer.toString()) ?? currentAnswer as int;
        final percentage = (value - min) / (max - min);
        final color = Color.lerp(Colors.red, Colors.green, percentage)!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$value',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note: $value / $max',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'text':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            currentAnswer.toString(),
            style: theme.textTheme.bodyLarge,
          ),
        );

      case 'number':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FontAwesomeIcons.hashtag,
                  color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                currentAnswer.toString(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        );

      case 'date':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FontAwesomeIcons.calendar, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Text(
                currentAnswer.toString(),
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );

      case 'multiple':
        final options = currentAnswer
            .toString()
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            currentAnswer.toString(),
            style: theme.textTheme.bodyLarge,
          ),
        );
    }
  }

  /// Carte de score global en mode lecture seule
  Widget _buildScoreCard() {
    final theme = Theme.of(context);
    final score = _auditScore!;

    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
      scoreIcon = FontAwesomeIcons.trophy;
    } else if (score >= 50) {
      scoreColor = Colors.orange;
      scoreLabel = 'À améliorer';
      scoreIcon = FontAwesomeIcons.circleExclamation;
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Critique';
      scoreIcon = FontAwesomeIcons.triangleExclamation;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.3),
            scoreColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
            child: Center(
              child: Icon(
                scoreIcon,
                color: scoreColor,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score Global',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score%',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    scoreLabel,
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[400], size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[400],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleButton extends StatelessWidget {
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScaleButton({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? theme.colorScheme.primary : theme.cardTheme.color,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey[700]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}

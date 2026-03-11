import 'package:flutter/material.dart';
import '../../core/config/responsive_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../hive/service.dart';
import 'package:intl/intl.dart';

/// Écran de résultats d'audit avec données réelles depuis Hive.
///
/// Reçoit auditId en paramètre de navigation.
/// Affiche le score global, les scores par catégorie et les problèmes.
class ResultsScreen extends StatefulWidget {
  final String auditId;

  const ResultsScreen({
    super.key,
    required this.auditId,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _audit;
  int _globalScore = 0;
  List<Map<String, dynamic>> _questions = [];
  Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await HiveService().getAuditResults(widget.auditId);

      final audit = results['audit'] as Map<String, dynamic>?;
      final categoryScores = results['categoryScores'] as Map<String, int>;

      // Charger les questions et réponses
      final templateId = audit?['template_id'] as String?;
      List<Map<String, dynamic>> questions = [];
      if (templateId != null) {
        final template = await HiveService().getTemplateById(templateId);
        if (template != null) {
          questions = (template['questions'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
        }
      }

      // Charger les réponses de l'audit
      final answersList = HiveService().getAnswersForAudit(widget.auditId);
      final answersMap = <String, dynamic>{};
      for (final answer in answersList) {
        final questionId = answer['question_id'] as String?;
        if (questionId != null) {
          answersMap[questionId] = answer['value'];
        }
      }

      // Calculer le score global (moyenne des scores par catégorie)
      int globalScore = 0;
      if (categoryScores.isNotEmpty) {
        globalScore = (categoryScores.values.reduce((a, b) => a + b) /
                categoryScores.length)
            .round();
      }

      setState(() {
        _audit = audit;
        _globalScore = globalScore;
        _questions = questions;
        _answers = answersMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Conformité satisfaisante';
    if (score >= 50) return 'Conformité moyenne';
    return 'Conformité insuffisante';
  }

  /// Build answer widget in read-only mode (visual only, no interaction)
  Widget _buildAnswerReadOnly(Map<String, dynamic> question, dynamic answer) {
    final type = question['type'] as String?;

    switch (type) {
      case 'yes_no':
        return Row(
          children: [
            Expanded(
              child: _buildChoiceButtonReadOnly(
                icon: FontAwesomeIcons.check,
                label: 'Conforme',
                color: Colors.green,
                isSelected: answer == true || answer == 'true',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChoiceButtonReadOnly(
                icon: FontAwesomeIcons.xmark,
                label: 'Non conforme',
                color: Colors.red,
                isSelected: answer == false || answer == 'false',
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
              return _buildScaleButtonReadOnly(
                value: value,
                isSelected: answer == value || answer == value.toString(),
              );
            },
          ),
        );
      case 'text':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Text(
            answer?.toString() ?? 'Non répondu',
            style: TextStyle(
              color: answer != null ? Colors.white : Colors.grey[500],
            ),
          ),
        );
      case 'multiple':
        final options = question['options'] as List<dynamic>? ?? [];
        final selectedOptions = answer?.toString().split(',') ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option.toString());
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? FontAwesomeIcons.squareCheck
                        : FontAwesomeIcons.square,
                    size: 20,
                    color: isSelected ? Colors.blue : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    option.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[500],
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      case 'number':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Text(
            answer?.toString() ?? 'Non répondu',
            style: TextStyle(
              color: answer != null ? Colors.white : Colors.grey[500],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'date':
        String dateText = 'Non répondu';
        if (answer != null) {
          try {
            final date = DateTime.parse(answer.toString());
            dateText = DateFormat('dd/MM/yyyy').format(date);
          } catch (_) {
            dateText = answer.toString();
          }
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              Icon(FontAwesomeIcons.calendar, color: Colors.blue, size: 16),
              const SizedBox(width: 12),
              Text(
                dateText,
                style: TextStyle(
                  color: answer != null ? Colors.white : Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            answer?.toString() ?? 'Non répondu',
            style: TextStyle(color: Colors.grey[500]),
          ),
        );
    }
  }

  Widget _buildChoiceButtonReadOnly({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? color : Colors.grey[500], size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScaleButtonReadOnly({
    required int value,
    required bool isSelected,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Colors.blue : Colors.grey[800],
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[600]!,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // État de chargement
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Résultats de l\'audit'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // État d'erreur
    if (_error != null || _audit == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Résultats de l\'audit'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.triangleExclamation,
                  size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Audit non trouvé',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadResults,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Formater la date
    final completedAt = _audit!['completed_at'] as String?;
    final dateStr = completedAt != null
        ? DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.parse(completedAt))
        : 'Non terminé';

    final status = _audit!['status'] as String? ?? 'draft';
    final statusColor = status == 'completed' ? Colors.green : Colors.orange;
    final statusLabel = status == 'completed' ? 'Terminé' : 'En cours';

    return Scaffold(
      appBar: AppBar(
        title: Text(_audit!['title'] as String? ?? 'Résultats'),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.shareNodes),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export à implémenter')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FontAwesomeIcons.circleCheck,
                          size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Score card compact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(FontAwesomeIcons.trophy,
                        size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score Global',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$_globalScore%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getScoreLabel(_globalScore),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Récapitulatif des réponses (style compact AuditFillScreen)
            if (_questions.isNotEmpty) ...[
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final questionId = question['id'] as String;
                final answer = _answers[questionId];
                final category = question['category'] as String?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.08),
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
                                color:
                                    theme.colorScheme.primary.withOpacity(0.15),
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
                            if (category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          question['text'] as String? ?? 'Question sans texte',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnswerReadOnly(question, answer),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          border: Border(
            top: BorderSide(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.08),
            ),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export PDF à implémenter')),
              );
            },
            icon: const Icon(FontAwesomeIcons.filePdf, size: 18),
            label: const Text('Exporter PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

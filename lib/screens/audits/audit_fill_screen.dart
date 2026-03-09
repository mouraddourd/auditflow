import 'package:flutter/material.dart';
import '../../core/config/responsive_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../hive/service.dart';
import '../results/results_screen.dart';

/// Écran de remplissage d'audit avec questions chargées depuis Hive.
///
/// Reçoit auditId et templateId en paramètres de navigation.
/// Les questions sont chargées via getTemplateById() et les réponses
/// sont sauvegardées automatiquement via saveAnswer().
class AuditFillScreen extends StatefulWidget {
  final String auditId;
  final String templateId;
  final String auditTitle;

  const AuditFillScreen({
    super.key,
    required this.auditId,
    required this.templateId,
    required this.auditTitle,
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

  List<Map<String, dynamic>> _questions = [];
  Map<String, dynamic>?
      _existingAnswers; // Pour charger les réponses existantes

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
  Future<void> _loadTemplate() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
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
      // Cela permet de suivre quels audits ont été commencés
      await _updateAuditToInProgress();

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
  Future<void> _saveAnswer(String questionId, dynamic answer) async {
    if (_questions.isEmpty) return;

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

      if (mounted) {
        // Naviguer vers l'écran de résultats
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(auditId: widget.auditId),
          ),
        );
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
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
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
                          const SizedBox(width: 8),
                          if (question['category'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
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
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${(_progress * 100).round()}% complété (${_questions.where((q) => _answers.containsKey(q['id']) || (_existingAnswers?.containsKey(q['id']) ?? false)).length}/${_questions.length})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
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
        // TODO: Implémenter la prise de photo avec image_picker
        return Center(
          child: Column(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: IconButton(
                  icon: const Icon(FontAwesomeIcons.camera, size: 48),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Prise de photo à implémenter')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Galerie à implémenter')),
                  );
                },
                icon: const Icon(FontAwesomeIcons.images),
                label: const Text('Choisir depuis la galerie'),
              ),
            ],
          ),
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
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[800],
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



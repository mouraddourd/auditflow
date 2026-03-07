import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../powersync/service.dart';

/// Écran de remplissage d'audit avec questions chargées depuis PowerSync.
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
  int _currentQuestion = 0;
  final Map<String, dynamic> _answers = {}; // questionId -> answer value
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

  /// Charge le template et ses questions depuis PowerSync.
  /// Met à jour le statut de l'audit à 'in_progress' si c'est un draft.
  Future<void> _loadTemplate() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Charger le template avec ses questions
      final template =
          await PowerSyncService().getTemplateById(widget.templateId);

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

      setState(() {
        _questions = (template['questions'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        _existingAnswers = existingAnswers;
        _isLoading = false;
      });

      _updateProgress();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  /// Charge les réponses existantes pour cet audit depuis PowerSync.
  Future<Map<String, dynamic>> _loadExistingAnswers() async {
    try {
      final answers = await PowerSyncService().db.getAll(
        'SELECT question_id, value FROM answers WHERE audit_id = ?',
        [widget.auditId],
      );

      // Convertir en map questionId -> value
      final Map<String, dynamic> result = {};
      for (final answer in answers) {
        result[answer['question_id'] as String] = answer['value'];
      }
      return result;
    } catch (e) {
      // Si erreur, retourner un map vide (nouvel audit)
      return {};
    }
  }

  /// Met à jour le statut de l'audit à 'in_progress' si c'est un draft.
  /// Cela permet de suivre quels audits ont été commencés.
  Future<void> _updateAuditToInProgress() async {
    try {
      await PowerSyncService().updateAuditStatus(widget.auditId, 'in_progress');
    } catch (e) {
      // Ignorer l'erreur - l'audit reste en draft
      debugPrint('Erreur mise à jour statut audit: $e');
    }
  }

  void _updateProgress() {
    final answeredCount =
        _questions.where((q) => _answers.containsKey(q['id'])).length;
    setState(() {
      _progress = _questions.isEmpty ? 0.0 : answeredCount / _questions.length;
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    }
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
    }
  }

  /// Sauvegarde la réponse dans PowerSync (auto-save).
  /// Appelé à chaque changement de réponse pour éviter la perte de données.
  Future<void> _saveAnswer(dynamic answer) async {
    if (_questions.isEmpty) return;

    final question = _questions[_currentQuestion];
    final questionId = question['id'] as String;

    setState(() {
      _answers[questionId] = answer;
    });
    _updateProgress();

    // Sauvegarder dans PowerSync (auto-save)
    try {
      await PowerSyncService().saveAnswer(
        auditId: widget.auditId,
        questionId: questionId,
        value: answer.toString(),
      );
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
      await PowerSyncService().updateAuditStatus(
        widget.auditId,
        'completed',
        score: avgScore,
      );

      if (mounted) {
        // Naviguer vers l'écran de résultats
        Navigator.pushReplacementNamed(
          context,
          '/audit/results',
          arguments: {
            'auditId': widget.auditId,
            'templateId': widget.templateId,
          },
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

    final question = _questions[_currentQuestion];
    final questionId = question['id'] as String;
    final currentAnswer = _answers[questionId] ?? _existingAnswers?[questionId];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.auditTitle),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Indicateur de sauvegarde auto
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
          // Progress bar
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.spinner,
                                size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              'En cours',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Question ${_currentQuestion + 1}/${_questions.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Category badge (if available)
                  if (question['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question['category'] as String,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Question text (use 'text' field from PowerSync)
                  Text(
                    question['text'] as String? ?? 'Question sans texte',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Answer widget based on type
                  _buildAnswerWidget(question, currentAnswer),
                ],
              ),
            ),
          ),
          // Bottom navigation
          Container(
            padding: const EdgeInsets.all(24),
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
                if (_currentQuestion > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(FontAwesomeIcons.arrowLeft),
                      label: const Text('Précédent'),
                    ),
                  ),
                if (_currentQuestion > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentQuestion < _questions.length - 1
                        ? _nextQuestion
                        : _finishAudit,
                    icon: Icon(
                      _currentQuestion < _questions.length - 1
                          ? FontAwesomeIcons.arrowRight
                          : FontAwesomeIcons.check,
                    ),
                    label: Text(
                      _currentQuestion < _questions.length - 1
                          ? 'Suivant'
                          : 'Terminer',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentQuestion < _questions.length - 1
                          ? null
                          : Colors.green,
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

  Widget _buildAnswerWidget(
      Map<String, dynamic> question, dynamic currentAnswer) {
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
                onTap: () => _saveAnswer(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ChoiceButton(
                icon: FontAwesomeIcons.xmark,
                label: 'Non conforme',
                color: Colors.red,
                isSelected: currentAnswer == 'false' || currentAnswer == false,
                onTap: () => _saveAnswer(false),
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
                onTap: () => _saveAnswer(value),
              );
            },
          ),
        );
      case 'text':
        return TextField(
          maxLines: 5,
          onChanged: _saveAnswer,
          controller:
              TextEditingController(text: currentAnswer?.toString() ?? ''),
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
                _saveAnswer(current.join(','));
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
        padding: const EdgeInsets.all(24),
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

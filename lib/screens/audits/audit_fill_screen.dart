import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/theme_provider.dart';

class AuditFillScreen extends StatefulWidget {
  const AuditFillScreen({super.key});

  @override
  State<AuditFillScreen> createState() => _AuditFillScreenState();
}

class _AuditFillScreenState extends State<AuditFillScreen> {
  int _currentQuestion = 0;
  final Map<int, dynamic> _answers = {};
  double _progress = 0.0;

  final List<Map<String, dynamic>> _questions = [
    {
      'type': 'yes_no',
      'question': 'Les équipements de sécurité sont-ils en bon état ?',
      'category': 'Sécurité',
      'help':
          'Vérifiez l\'état des extincteurs, détecteurs d\'incendie, issues de secours...',
    },
    {
      'type': 'scale',
      'question': 'Évaluez la propreté des locaux',
      'category': 'Hygiène',
      'min': 1,
      'max': 5,
      'help': '1 = Très sale, 5 = Impeccable',
    },
    {
      'type': 'text',
      'question': 'Décrivez les anomalies constatées',
      'category': 'Général',
      'help': 'Soyez précis et factuel dans votre description',
    },
    {
      'type': 'multiple',
      'question': 'Quels équipements manquent ?',
      'category': 'Matériel',
      'options': ['EPI', 'Outillage', 'Signalisation', 'Documentation'],
      'help': 'Sélectionnez tout ce qui s\'applique',
    },
    {
      'type': 'photo',
      'question': 'Prenez une photo du problème',
      'category': 'Preuves',
      'help': 'Ajoutez des photos pour documenter les anomalies',
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateProgress();
  }

  void _updateProgress() {
    setState(() {
      _progress = _answers.length / _questions.length;
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

  void _saveAnswer(dynamic answer) {
    setState(() {
      _answers[_currentQuestion] = answer;
    });
    _updateProgress();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _questions[_currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remplir l\'audit'),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.floppyDisk),
            onPressed: () {},
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
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  // Question
                  Text(
                    question['question'] as String,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Help text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.circleInfo,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            question['help'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Answer widget based on type
                  _buildAnswerWidget(question),
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
                        : () {},
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

  Widget _buildAnswerWidget(Map<String, dynamic> question) {
    final type = question['type'] as String;
    final currentAnswer = _answers[_currentQuestion];

    switch (type) {
      case 'yes_no':
        return Row(
          children: [
            Expanded(
              child: _ChoiceButton(
                icon: FontAwesomeIcons.check,
                label: 'Conforme',
                color: Colors.green,
                isSelected: currentAnswer == true,
                onTap: () => _saveAnswer(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ChoiceButton(
                icon: FontAwesomeIcons.xmark,
                label: 'Non conforme',
                color: Colors.red,
                isSelected: currentAnswer == false,
                onTap: () => _saveAnswer(false),
              ),
            ),
          ],
        );
      case 'scale':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            (question['max'] as int) - (question['min'] as int) + 1,
            (index) {
              final value = (question['min'] as int) + index;
              return _ScaleButton(
                value: value,
                isSelected: currentAnswer == value,
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
        return Column(
          children: (question['options'] as List<String>).map((option) {
            final isSelected =
                (currentAnswer as List<String>? ?? []).contains(option);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (checked) {
                final current = (currentAnswer as List<String>? ?? []).toList();
                if (checked == true) {
                  current.add(option);
                } else {
                  current.remove(option);
                }
                _saveAnswer(current);
              },
              title: Text(option),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        );
      case 'photo':
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
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(FontAwesomeIcons.images),
                label: const Text('Choisir depuis la galerie'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
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

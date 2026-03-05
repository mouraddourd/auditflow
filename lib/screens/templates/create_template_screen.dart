import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreateTemplateScreen extends StatefulWidget {
  const CreateTemplateScreen({super.key});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  final List<Map<String, dynamic>> _questions = [];

  final List<String> _categories = [
    'Qualité',
    'Sécurité',
    'Environnement',
    'Hygiène',
    'Technique',
    'Conformité',
  ];

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _AddQuestionDialog(
        onAdd: (question) {
          setState(() {
            _questions.add(question);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un template'),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(FontAwesomeIcons.floppyDisk),
            label: const Text('Sauvegarder'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info section
            Text(
              'Informations générales',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Nom du template',
                      hintText: 'Ex: Audit Qualité ISO 9001',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Décrivez l\'objectif de ce template...',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Questions section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questions (${_questions.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(FontAwesomeIcons.plus),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_questions.isEmpty)
              Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        FontAwesomeIcons.circleQuestion,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune question pour le moment',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des questions pour construire votre template',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _questions.removeAt(oldIndex);
                    _questions.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return _QuestionCard(
                    key: ValueKey(index),
                    index: index + 1,
                    question: question['text'] as String,
                    type: question['type'] as String,
                    onDelete: () => _removeQuestion(index),
                  );
                },
              ),
            const SizedBox(height: 32),
            // AI Generation
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.secondary.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.wandMagicSparkles,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Génération IA',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Laissez l\'IA générer des questions pertinentes basées sur votre catégorie et description.',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(FontAwesomeIcons.bolt),
                      label: const Text('Générer avec l\'IA'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AddQuestionDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _AddQuestionDialog({required this.onAdd});

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  final _textController = TextEditingController();
  String _type = 'yes_no';

  final List<Map<String, dynamic>> _types = [
    {
      'value': 'yes_no',
      'label': 'Oui / Non',
      'icon': FontAwesomeIcons.circleCheck
    },
    {'value': 'scale', 'label': 'Échelle 1-5', 'icon': FontAwesomeIcons.bars},
    {'value': 'text', 'label': 'Texte libre', 'icon': FontAwesomeIcons.font},
    {
      'value': 'multiple',
      'label': 'Choix multiple',
      'icon': FontAwesomeIcons.listCheck
    },
    {'value': 'photo', 'label': 'Photo', 'icon': FontAwesomeIcons.camera},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Ajouter une question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Question',
                hintText: 'Ex: Les équipements sont-ils en bon état ?',
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Type de réponse',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._types.map((type) {
              return RadioListTile<String>(
                value: type['value'] as String,
                groupValue: _type,
                onChanged: (value) => setState(() => _type = value!),
                title: Text(type['label'] as String),
                secondary: Icon(type['icon'] as IconData),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_textController.text.isNotEmpty) {
              widget.onAdd({
                'text': _textController.text,
                'type': _type,
              });
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final String question;
  final String type;
  final VoidCallback onDelete;

  const _QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.type,
    required this.onDelete,
  });

  String _getTypeLabel() {
    switch (type) {
      case 'yes_no':
        return 'Oui/Non';
      case 'scale':
        return 'Échelle';
      case 'text':
        return 'Texte';
      case 'multiple':
        return 'Multiple';
      case 'photo':
        return 'Photo';
      default:
        return type;
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case 'yes_no':
        return FontAwesomeIcons.circleCheck;
      case 'scale':
        return FontAwesomeIcons.bars;
      case 'text':
        return FontAwesomeIcons.font;
      case 'multiple':
        return FontAwesomeIcons.listCheck;
      case 'photo':
        return FontAwesomeIcons.camera;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(_getTypeIcon(), size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getTypeLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
            onPressed: onDelete,
          ),
          const Icon(FontAwesomeIcons.grip, color: Colors.grey),
        ],
      ),
    );
  }
}

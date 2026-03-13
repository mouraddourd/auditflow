import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';

/// Dialog partagé pour créer/éditer une question de template.
///
/// Supporte tous les types de réponses y compris les choix multiples
/// avec options personnalisées.
class QuestionDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final Map<String, dynamic>? initialQuestion;

  const QuestionDialog({
    super.key,
    required this.onAdd,
    this.initialQuestion,
  });

  @override
  State<QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<QuestionDialog> {
  final _textController = TextEditingController();
  final _optionsController = TextEditingController();
  String _type = 'yes_no';
  List<String> _options = [];

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
    {'value': 'number', 'label': 'Nombre', 'icon': FontAwesomeIcons.hashtag},
    {'value': 'date', 'label': 'Date', 'icon': FontAwesomeIcons.calendar},
    {'value': 'photo', 'label': 'Photo', 'icon': FontAwesomeIcons.camera},
  ];

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs existantes si on modifie une question
    if (widget.initialQuestion != null) {
      _textController.text = widget.initialQuestion!['text'] as String? ?? '';
      _type = widget.initialQuestion!['type'] as String? ?? 'yes_no';
      final opts = widget.initialQuestion!['options'] as List<dynamic>?;
      if (opts != null) {
        _options = opts.map((e) => e.toString()).toList();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionsController.text.isNotEmpty) {
      setState(() {
        _options.add(_optionsController.text);
        _optionsController.clear();
      });
    }
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  void _submit() {
    if (_textController.text.isEmpty) return;

    if (_type == 'multiple') {
      if (_options.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins une option'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Vérifier qu'aucune option n'est vide
      if (_options.any((opt) => opt.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les options ne peuvent pas être vides'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Générer un ID pour les nouvelles questions (pas pour les éditions)
    final questionData = {
      'text': _textController.text,
      'type': _type,
      if (_type == 'multiple') 'options': _options,
    };

    // Si c'est une nouvelle question (pas d'initialQuestion), générer un ID
    if (widget.initialQuestion == null) {
      questionData['id'] = const Uuid().v4();
    }

    // Fermer le dialog AVANT d'appeler onAdd
    Navigator.pop(context);
    widget.onAdd(questionData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.initialQuestion != null
          ? 'Modifier la question'
          : 'Ajouter une question'),
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
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                    // Réinitialiser les options si on change de type
                    if (_type != 'multiple') {
                      _options.clear();
                    }
                  });
                },
                title: Text(type['label'] as String),
                secondary: Icon(type['icon'] as IconData),
              );
            }),
            // Options pour les questions de type multiple
            if (_type == 'multiple') ...[
              const SizedBox(height: 24),
              Text(
                'Options de réponse',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _optionsController,
                      decoration: InputDecoration(
                        labelText: 'Nouvelle option',
                        hintText: 'Ex: Option A',
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addOption(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addOption,
                    icon: const Icon(FontAwesomeIcons.plus),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                return ListTile(
                  dense: true,
                  leading: Icon(FontAwesomeIcons.circle,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  title: Text(option),
                  trailing: IconButton(
                    icon: const Icon(FontAwesomeIcons.xmark,
                        size: 16, color: Colors.red),
                    onPressed: () => _removeOption(index),
                  ),
                );
              }),
              if (_options.isEmpty)
                Text(
                  'Ajoutez au moins une option',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.initialQuestion != null ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }
}

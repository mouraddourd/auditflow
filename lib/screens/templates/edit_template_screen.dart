import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../hive/service.dart';

class EditTemplateScreen extends StatefulWidget {
  final String templateId;

  const EditTemplateScreen({super.key, required this.templateId});

  @override
  State<EditTemplateScreen> createState() => _EditTemplateScreenState();
}

class _EditTemplateScreenState extends State<EditTemplateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  final List<Map<String, dynamic>> _questions = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _validationError;

  final List<String> _categories = [
    'Qualité',
    'Sécurité',
    'Environnement',
    'Hygiène',
    'Technique',
    'Conformité',
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final templates = HiveService().getTemplates();
      final template = templates.firstWhere(
        (t) => t['id'] == widget.templateId,
        orElse: () => <String, dynamic>{},
      );

      if (template.isEmpty) {
        setState(() {
          _error = 'Template non trouvé';
          _isLoading = false;
        });
        return;
      }

      _titleController.text = template['name'] as String? ?? '';
      _descriptionController.text = template['description'] as String? ?? '';
      _selectedCategory = template['category'] as String?;

      // Charger les questions
      final questions =
          HiveService().getQuestionsForTemplate(widget.templateId);
      _questions.addAll(questions);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

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

  Future<void> _saveTemplate() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _validationError = 'Le nom du template est requis');
      return;
    }
    if (_selectedCategory == null) {
      setState(() => _validationError = 'La catégorie est requise');
      return;
    }
    if (_questions.isEmpty) {
      setState(() => _validationError = 'Au moins une question est requise');
      return;
    }

    setState(() {
      _isSaving = true;
      _validationError = null;
    });

    try {
      await HiveService().updateTemplate(
        id: widget.templateId,
        name: _titleController.text.trim(),
        category: _selectedCategory!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        questions: _questions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _validationError = 'Erreur lors de la sauvegarde: $e';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier le template')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier le template')),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le template'),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveTemplate,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(FontAwesomeIcons.floppyDisk, size: 18),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            Text(
              'Nom du template *',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ex: Audit Sécurité Incendie',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category dropdown
            Text(
              'Catégorie *',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 24),

            // Description field
            Text(
              'Description',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Description optionnelle',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Questions section
            Row(
              children: [
                Text(
                  'Questions *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(FontAwesomeIcons.plus, size: 16),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_questions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Aucune question. Cliquez sur "Ajouter" pour commencer.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question['text'] as String? ?? '',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeQuestion(index),
                          icon: Icon(
                            FontAwesomeIcons.trash,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Validation error
            if (_validationError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.circleExclamation,
                      color: theme.colorScheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
  final _questionController = TextEditingController();
  String _questionType = 'text';

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle question'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Question',
              hintText: 'Ex: Les extincteurs sont-ils accessibles?',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _questionType,
            decoration: const InputDecoration(labelText: 'Type de réponse'),
            items: const [
              DropdownMenuItem(value: 'text', child: Text('Texte libre')),
              DropdownMenuItem(
                  value: 'yes_no', child: Text('Oui/Non (Conforme)')),
              DropdownMenuItem(value: 'number', child: Text('Nombre')),
              DropdownMenuItem(value: 'scale', child: Text('Échelle (1-5)')),
              DropdownMenuItem(
                  value: 'multiple', child: Text('Choix multiples')),
              DropdownMenuItem(value: 'photo', child: Text('Photo')),
              DropdownMenuItem(value: 'date', child: Text('Date')),
            ],
            onChanged: (value) {
              setState(() => _questionType = value!);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_questionController.text.trim().isEmpty) return;
            widget.onAdd({
              'text': _questionController.text.trim(),
              'type': _questionType,
            });
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

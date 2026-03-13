import 'package:flutter/material.dart';
import '../../core/config/responsive_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../hive/service.dart';
import '../../core/widgets/question_dialog.dart';

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
  List<Map<String, dynamic>> _categories = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = HiveService().getCategories();
      if (categories.isEmpty) {
        await HiveService().seedDefaultCategories();
        final seeded = HiveService().getCategories();
        setState(() => _categories = seeded);
      } else {
        setState(() => _categories = categories);
      }
    } catch (e) {
      // Continue with empty categories
    }
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
      builder: (context) => QuestionDialog(
        onAdd: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _editQuestion(int index) {
    final question = _questions[index];
    showDialog(
      context: context,
      builder: (dialogContext) => QuestionDialog(
        initialQuestion: question,
        onAdd: (updatedQuestion) {
          setState(() {
            _questions[index] = {
              ...updatedQuestion,
              'id': question['id'],
            };
          });
        },
      ),
    );
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
        title: const Text('Modifier'),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveTemplate,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(FontAwesomeIcons.floppyDisk),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
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
              items: _categories.map((cat) {
                final catName = cat['name'] as String;
                return DropdownMenuItem(value: catName, child: Text(catName));
              }).toList(),
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
                padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Aucune question. Cliquez sur "Ajouter" pour commencer.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                          onPressed: () => _editQuestion(index),
                          icon: Icon(
                            FontAwesomeIcons.pen,
                            size: 16,
                            color: theme.colorScheme.primary,
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

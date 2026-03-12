import 'package:flutter/material.dart';
import '../../core/config/responsive_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../hive/service.dart';
import '../../core/widgets/question_dialog.dart';
import '../../services/sync_service.dart';

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
  List<Map<String, dynamic>> _categories = [];

  bool _isSaving = false;
  bool _isLoadingCategories = true;
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
        setState(() {
          _categories = seeded;
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingCategories = false);
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

  void _editQuestion(int index) {
    final existingQuestion = _questions[index];
    showDialog(
      context: context,
      builder: (context) => QuestionDialog(
        initialQuestion: existingQuestion,
        onAdd: (question) {
          setState(() {
            _questions[index] = question;
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

  /// Sauvegarde le template dans Hive
  Future<void> _saveTemplate() async {
    // Validation
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
      final template = await HiveService().createTemplate(
        name: _titleController.text.trim(),
        category: _selectedCategory!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        questions: _questions,
      );

      // Enqueue sync to backend
      await SyncService().enqueue(
        entityType: 'template',
        entityId: template['id'],
        mutationType: MutationType.create,
        data: template,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Signal success
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _validationError = 'Erreur lors de la sauvegarde: $e';
      });
    }
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
            onPressed: _isSaving ? null : _saveTemplate,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(FontAwesomeIcons.floppyDisk),
            label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Validation error banner
            if (_validationError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.circleExclamation,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            // Info section
            Text(
              'Informations générales',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
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
                      final catName = cat['name'] as String;
                      return DropdownMenuItem(
                        value: catName,
                        child: Text(catName),
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
                    options:
                        (question['options'] as List<dynamic>?)?.cast<String>(),
                    onDelete: () => _removeQuestion(index),
                    onEdit: () => _editQuestion(index),
                  );
                },
              ),
            const SizedBox(height: 32),
            // AI Generation
            Container(
              padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
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

class _QuestionCard extends StatelessWidget {
  final int index;
  final String question;
  final String type;
  final List<String>? options;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.type,
    this.options,
    required this.onDelete,
    required this.onEdit,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                    if (options != null && options!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Options: ${options!.take(3).join(', ')}${options!.length > 3 ? '...' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(FontAwesomeIcons.pen,
                color: theme.colorScheme.primary, size: 16),
            onPressed: onEdit,
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

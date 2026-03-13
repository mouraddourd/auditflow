import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../hive/service.dart';
import '../../core/config/responsive_config.dart';

/// Écran de gestion des templates permettant de créer, éditer et supprimer des templates personnalisés.
class TemplatesManagementScreen extends StatefulWidget {
  const TemplatesManagementScreen({super.key});

  @override
  State<TemplatesManagementScreen> createState() => _TemplatesManagementScreenState();
}

class _TemplatesManagementScreenState extends State<TemplatesManagementScreen> {
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = HiveService().getTemplates();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteTemplate(String templateId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce template ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await HiveService().deleteTemplate(templateId);
      await _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template supprimé'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Templates'),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowsRotate),
            onPressed: _loadTemplates,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmptyState(theme)
              : _buildTemplatesList(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateEditor(),
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Nouveau template'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.clipboardList, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun template',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier template pour commencer',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showTemplateEditor(),
            icon: const Icon(FontAwesomeIcons.plus),
            label: const Text('Créer un template'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildTemplatesList(ThemeData theme) {
    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        final questionCount = template['question_count'] as int? ?? 0;
        final category = template['category'] as String? ?? 'Sans catégorie';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(FontAwesomeIcons.fileLines, color: theme.colorScheme.primary),
            ),
            title: Text(
              template['name'] as String? ?? 'Sans nom',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '$category • $questionCount question${questionCount > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                if (template['description'] != null)
                  Text(
                    template['description'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(FontAwesomeIcons.penToSquare, size: 18),
                  onPressed: () => _showTemplateEditor(template: template),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.trash, size: 18, color: Colors.red),
                  onPressed: () => _deleteTemplate(template['id'] as String),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
      },
    );
  }

  void _showTemplateEditor({Map<String, dynamic>? template}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(
          template: template,
          onSaved: _loadTemplates,
        ),
      ),
    );
  }
}

/// Écran d'édition de template pour créer ou modifier un template avec ses questions.
class TemplateEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? template;
  final VoidCallback? onSaved;

  const TemplateEditorScreen({super.key, this.template, this.onSaved});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  bool _isSaving = false;

  final List<String> _questionTypes = ['text', 'yes_no', 'scale', 'number', 'date', 'multiple', 'photo'];

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!['name'] as String? ?? '';
      _descriptionController.text = widget.template!['description'] as String? ?? '';
      _categoryController.text = widget.template!['category'] as String? ?? '';
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    if (widget.template == null) return;
    final questions = HiveService().getQuestionsForTemplate(widget.template!['id'] as String);
    setState(() {
      _questions.clear();
      _questions.addAll(questions.map((q) => Map<String, dynamic>.from(q)));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une question'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final questionsData = _questions.map((q) => {
        'type': q['type'],
        'text': q['text'],
        'required': q['required'] == true || q['required'] == 1,
        'options': q['options'],
      }).toList();

      if (widget.template != null) {
        // Update existing
        await HiveService().updateTemplate(
          id: widget.template!['id'] as String,
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          questions: questionsData,
        );
      } else {
        // Create new
        await HiveService().createTemplate(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          questions: questionsData,
        );
      }

      widget.onSaved?.call();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.template != null ? 'Template modifié' : 'Template créé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'type': 'text',
        'text': '',
        'required': false,
        'options': null,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  void _moveQuestion(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _questions.length) return;
    setState(() {
      final item = _questions.removeAt(index);
      _questions.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.template != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le Template' : 'Nouveau Template'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveTemplate,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
          children: [
            // Template Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informations', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du template *',
                        prefixIcon: Icon(FontAwesomeIcons.fileLines),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie *',
                        prefixIcon: Icon(FontAwesomeIcons.folder),
                        hintText: 'ex: Sécurité, Qualité, IT...',
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Catégorie requise' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(FontAwesomeIcons.alignLeft),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Questions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Questions (${_questions.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(FontAwesomeIcons.plus, size: 16),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_questions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(FontAwesomeIcons.circleQuestion, size: 32, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Aucune question', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text('Ajoutez des questions à votre template', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._questions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return _buildQuestionCard(theme, index, question);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(ThemeData theme, int index, Map<String, dynamic> question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Q${index + 1}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.arrowUp, size: 16),
                  onPressed: index > 0 ? () => _moveQuestion(index, -1) : null,
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.arrowDown, size: 16),
                  onPressed: index < _questions.length - 1 ? () => _moveQuestion(index, 1) : null,
                ),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
                  onPressed: () => _removeQuestion(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: question['text'] as String? ?? '',
              decoration: const InputDecoration(
                labelText: 'Texte de la question *',
                hintText: 'Votre question...',
              ),
              onChanged: (v) => question['text'] = v,
              validator: (v) => v?.trim().isEmpty == true ? 'Texte requis' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: question['type'] as String? ?? 'text',
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: _questionTypes.map((type) {
                      final labels = {
                        'text': 'Texte',
                        'yes_no': 'Oui/Non',
                        'scale': 'Échelle (1-5)',
                        'number': 'Nombre',
                        'date': 'Date',
                        'multiple': 'Choix multiple',
                        'photo': 'Photo',
                      };
                      return DropdownMenuItem(value: type, child: Text(labels[type] ?? type));
                    }).toList(),
                    onChanged: (v) => setState(() => question['type'] = v),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Checkbox(
                      value: question['required'] == true || question['required'] == 1,
                      onChanged: (v) => setState(() => question['required'] = v == true),
                    ),
                    const Text('Requis'),
                  ],
                ),
              ],
            ),
            // Options for multiple choice
            if (question['type'] == 'multiple')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextFormField(
                  initialValue: (question['options'] as List<dynamic>?)?.join(', ') ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Options (séparées par des virgules)',
                    hintText: 'Option 1, Option 2, Option 3',
                  ),
                  onChanged: (v) {
                    question['options'] = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

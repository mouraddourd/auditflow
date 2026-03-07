import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../powersync/service.dart';

/// Create audit screen with real data from PowerSync.
///
/// Two-step flow:
/// 1. Select a template from organization's templates
/// 2. Fill audit details (title, description, assignee)
///
/// On submit, creates audit locally in SQLite which syncs to backend.
class CreateAuditScreen extends StatefulWidget {
  final Function(Widget)? onNavigateToPage;
  final String? preselectedTemplateId;

  const CreateAuditScreen({
    super.key,
    this.onNavigateToPage,
    this.preselectedTemplateId,
  });

  @override
  State<CreateAuditScreen> createState() => _CreateAuditScreenState();
}

class _CreateAuditScreenState extends State<CreateAuditScreen> {
  /// Selected template ID (null = step 1, otherwise step 2)
  String? _selectedTemplateId;

  /// Selected template data (cached for display in step 2)
  Map<String, dynamic>? _selectedTemplate;

  /// Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// Selected assignee user ID
  String? _selectedAssigneeId;

  /// Templates loaded from PowerSync
  List<Map<String, dynamic>> _templates = [];

  /// Organization members for assignee dropdown
  List<Map<String, dynamic>> _members = [];

  /// Loading states
  bool _isLoadingTemplates = true;
  bool _isLoadingMembers = false;
  bool _isCreating = false;

  /// Form validation error
  String? _validationError;

  @override
  void initState() {
    super.initState();
    // Si un template est pré-sélectionné, l'utiliser directement
    if (widget.preselectedTemplateId != null) {
      _selectedTemplateId = widget.preselectedTemplateId;
    }
    _loadTemplates();
  }

  /// Loads templates from PowerSync on screen init.
  Future<void> _loadTemplates() async {
    setState(() => _isLoadingTemplates = true);

    try {
      final templates = await PowerSyncService().getTemplates();
      setState(() {
        _templates = templates;
        _isLoadingTemplates = false;
        // Si un template est pré-sélectionné, charger ses données
        if (_selectedTemplateId != null) {
          _selectedTemplate = templates.firstWhere(
            (t) => t['id'] == _selectedTemplateId,
            orElse: () => <String, dynamic>{},
          );
          // Passer directement à l'étape 2
          if (_selectedTemplate?.isNotEmpty == true) {
            _loadMembers();
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading templates: $e');
      setState(() => _isLoadingTemplates = false);
    }
  }

  /// Loads organization members when entering step 2.
  Future<void> _loadMembers() async {
    if (_members.isNotEmpty) return;

    setState(() => _isLoadingMembers = true);

    try {
      final members = await PowerSyncService().getOrganizationMembers();
      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    } catch (e) {
      debugPrint('Error loading members: $e');
      setState(() => _isLoadingMembers = false);
    }
  }

  /// Creates the audit in PowerSync and navigates back.
  Future<void> _createAudit() async {
    if (_selectedTemplateId == null) {
      setState(() => _validationError = 'Veuillez sélectionner un template');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _validationError = 'Le titre est obligatoire');
      return;
    }

    setState(() {
      _isCreating = true;
      _validationError = null;
    });

    try {
      await PowerSyncService().createAudit(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        templateId: _selectedTemplateId!,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating audit: $e');
      setState(() {
        _isCreating = false;
        _validationError = 'Erreur lors de la création: $e';
      });
    }
  }

  /// Returns an icon based on template category.
  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'qualité':
      case 'quality':
        return FontAwesomeIcons.circleCheck;
      case 'sécurité':
      case 'security':
        return FontAwesomeIcons.shieldHalved;
      case 'environnement':
      case 'environment':
        return FontAwesomeIcons.leaf;
      case 'hygiène':
      case 'hygiene':
        return FontAwesomeIcons.handSparkles;
      case 'technique':
      case 'technical':
        return FontAwesomeIcons.wrench;
      case 'conformité':
      case 'compliance':
        return FontAwesomeIcons.scaleBalanced;
      default:
        return FontAwesomeIcons.clipboardList;
    }
  }

  /// Handles template selection - moves to step 2
  void _selectTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedTemplateId = template['id'] as String?;
      _selectedTemplate = template;
    });
    _loadMembers();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un audit'),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: [
                _StepIndicator(
                  step: 1,
                  label: 'Template',
                  isActive: _selectedTemplateId == null,
                  isComplete: _selectedTemplateId != null,
                ),
                Expanded(
                    child: Divider(
                        color: theme.colorScheme.primary.withOpacity(0.3))),
                _StepIndicator(
                  step: 2,
                  label: 'Détails',
                  isActive: _selectedTemplateId != null,
                  isComplete: false,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Step 1: Template selection
            if (_selectedTemplateId == null) ...[
              Text(
                'Choisir un template',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez un template pour démarrer votre audit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Loading state
              if (_isLoadingTemplates)
                const Center(child: CircularProgressIndicator())
              // Empty state
              else if (_templates.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FontAwesomeIcons.folderOpen,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun template disponible',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              // Template grid
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _templates.length,
                      itemBuilder: (context, index) {
                        final template = _templates[index];
                        return _TemplateSelectionCard(
                          title: template['title'] as String? ?? 'Sans titre',
                          category: template['category'] as String? ?? 'Audit',
                          questions: (template['question_count'] as int?) ?? 0,
                          icon:
                              _getCategoryIcon(template['category'] as String?),
                          onTap: () => _selectTemplate(template),
                        );
                      },
                    );
                  },
                ),
            ],

            // Step 2: Details form
            if (_selectedTemplateId != null) ...[
              Text(
                'Détails de l\'audit',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Show selected template info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                        _getCategoryIcon(
                            _selectedTemplate?['category'] as String?),
                        color: theme.colorScheme.primary,
                        size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedTemplate?['title'] as String? ?? 'Template',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title field (required)
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de l\'audit *',
                  hintText: 'Ex: Audit Q1 2025',
                  prefixIcon: const Icon(FontAwesomeIcons.heading),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description field (optional)
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Contexte, objectifs...',
                  prefixIcon: const Icon(FontAwesomeIcons.alignLeft),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Assignee dropdown
              if (_isLoadingMembers)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Assigné à (optionnel)',
                    prefixIcon: const Icon(FontAwesomeIcons.user),
                    filled: true,
                    fillColor: theme.cardTheme.color,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  value: _selectedAssigneeId,
                  items: _members.map((member) {
                    return DropdownMenuItem(
                      value: member['user_id'] as String?,
                      child: Text(member['role'] as String? ?? 'Membre'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAssigneeId = value);
                  },
                ),

              // Validation error
              if (_validationError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(FontAwesomeIcons.circleExclamation,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCreating
                          ? null
                          : () => setState(() {
                                _selectedTemplateId = null;
                                _selectedTemplate = null;
                                _validationError = null;
                              }),
                      child: const Text('Retour'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createAudit,
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Créer l\'audit'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;
  final bool isComplete;

  const _StepIndicator({
    required this.step,
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isComplete || isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.3);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isComplete ? theme.colorScheme.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: isComplete
              ? const Icon(FontAwesomeIcons.check,
                  size: 16, color: Colors.white)
              : Center(
                  child: Text(
                    '$step',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _TemplateSelectionCard extends StatelessWidget {
  final String title;
  final String category;
  final int questions;
  final IconData icon;
  final VoidCallback onTap;

  const _TemplateSelectionCard({
    required this.title,
    required this.category,
    required this.questions,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$questions questions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

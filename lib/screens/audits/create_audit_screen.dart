import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/theme_provider.dart';

class CreateAuditScreen extends StatefulWidget {
  const CreateAuditScreen({super.key});

  @override
  State<CreateAuditScreen> createState() => _CreateAuditScreenState();
}

class _CreateAuditScreenState extends State<CreateAuditScreen> {
  String? _selectedTemplate;
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _templates = [
    {
      'id': '1',
      'title': 'Audit Qualité ISO 9001',
      'category': 'Qualité',
      'questions': 25,
      'icon': FontAwesomeIcons.circleCheck
    },
    {
      'id': '2',
      'title': 'Inspection Sécurité',
      'category': 'Sécurité',
      'questions': 18,
      'icon': FontAwesomeIcons.shieldHalved
    },
    {
      'id': '3',
      'title': 'Audit Environnement',
      'category': 'Environnement',
      'questions': 15,
      'icon': FontAwesomeIcons.leaf
    },
    {
      'id': '4',
      'title': 'Contrôle Hygiène',
      'category': 'Hygiène',
      'questions': 20,
      'icon': FontAwesomeIcons.handSparkles
    },
    {
      'id': '5',
      'title': 'Audit Technique',
      'category': 'Technique',
      'questions': 30,
      'icon': FontAwesomeIcons.wrench
    },
    {
      'id': '6',
      'title': 'Conformité RGPD',
      'category': 'Conformité',
      'questions': 22,
      'icon': FontAwesomeIcons.scaleBalanced
    },
  ];

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
                  isActive: _selectedTemplate == null,
                  isComplete: _selectedTemplate != null,
                ),
                Expanded(
                    child: Divider(
                        color: theme.colorScheme.primary.withOpacity(0.3))),
                _StepIndicator(
                  step: 2,
                  label: 'Détails',
                  isActive: _selectedTemplate != null,
                  isComplete: false,
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_selectedTemplate == null) ...[
              // Template selection
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
                        title: template['title'] as String,
                        category: template['category'] as String,
                        questions: template['questions'] as int,
                        icon: template['icon'] as IconData,
                        onTap: () => setState(
                            () => _selectedTemplate = template['id'] as String),
                      );
                    },
                  );
                },
              ),
            ] else ...[
              // Details form
              Text(
                'Détails de l\'audit',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de l\'audit',
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
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Lieu / Site',
                  hintText: 'Ex: Usine Lyon',
                  prefixIcon: const Icon(FontAwesomeIcons.locationDot),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Assigné à',
                  prefixIcon: const Icon(FontAwesomeIcons.user),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('Jean Dupont')),
                  DropdownMenuItem(value: '2', child: Text('Marie Martin')),
                  DropdownMenuItem(value: '3', child: Text('Pierre Durand')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Date début',
                        prefixIcon: const Icon(FontAwesomeIcons.calendarDays),
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Date fin (optionnel)',
                        prefixIcon: const Icon(FontAwesomeIcons.calendarDays),
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Instructions ou contexte particulier...',
                  prefixIcon: const Icon(FontAwesomeIcons.noteSticky),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selectedTemplate = null),
                      child: const Text('Retour'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Créer l\'audit'),
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

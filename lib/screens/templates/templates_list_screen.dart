import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../powersync/service.dart';
import 'create_template_screen.dart';
import '../audits/create_audit_screen.dart';

class TemplatesListScreen extends StatefulWidget {
  final Function(Widget)? onNavigateToPage;
  const TemplatesListScreen({super.key, this.onNavigateToPage});

  @override
  State<TemplatesListScreen> createState() => _TemplatesListScreenState();
}

class _TemplatesListScreenState extends State<TemplatesListScreen> {
  int _currentPage = 1;
  String? _selectedCategory;
  String _searchQuery = '';

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _templates = [];

  final List<String> _categories = [
    'Tous',
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
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final templates = await PowerSyncService().getTemplates();

      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // État de chargement
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Chargement des templates...',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    // État d'erreur
    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.triangleExclamation,
                    size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadTemplates,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Filtrer les templates
    final filteredTemplates = _templates.where((t) {
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory == 'Tous' ||
          t['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          (t['name'] as String?)
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ==
              true ||
          (t['description'] as String?)
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ==
              true;
      return matchesCategory && matchesSearch;
    }).toList();

    final itemsPerPage = 12;
    final startIndex = (_currentPage - 1) * itemsPerPage;
    final endIndex =
        (startIndex + itemsPerPage).clamp(0, filteredTemplates.length);
    final pageTemplates = filteredTemplates.sublist(
      startIndex,
      endIndex > filteredTemplates.length ? filteredTemplates.length : endIndex,
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1200
                ? 5
                : constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 3
                        : 2;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Templates',
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    .animate()
                                    .fadeIn(duration: 400.ms)
                                    .slideX(begin: -0.1),
                                const SizedBox(height: 4),
                                Text(
                                  '${filteredTemplates.length} templates disponibles',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 100.ms, duration: 400.ms),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un template...',
                            prefixIcon:
                                const Icon(FontAwesomeIcons.magnifyingGlass),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(FontAwesomeIcons.xmark),
                                    onPressed: () =>
                                        setState(() => _searchQuery = ''),
                                  )
                                : null,
                            filled: true,
                            fillColor: theme.cardTheme.color,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((category) {
                              final isSelected =
                                  _selectedCategory == category ||
                                      (category == 'Tous' &&
                                          _selectedCategory == null);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory =
                                          category == 'Tous' ? null : category;
                                      _currentPage = 1;
                                    });
                                  },
                                  backgroundColor: theme.cardTheme.color,
                                  selectedColor: theme.colorScheme.primary
                                      .withOpacity(0.2),
                                  checkmarkColor: theme.colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final template = pageTemplates[index];
                        return _TemplateCard(
                          id: template['id'] as String? ?? '',
                          title: template['name'] as String? ?? 'Sans nom',
                          category: template['category'] as String? ??
                              'Non catégorisé',
                          questionCount:
                              template['question_count'] as int? ?? 0,
                          description: template['description'] as String? ?? '',
                          onEdit: () {
                            // TODO: Navigation vers édition de template
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Édition de template à implémenter')),
                            );
                          },
                          onUse: () {
                            // Naviguer vers CreateAudit avec ce template pré-sélectionné
                            widget.onNavigateToPage?.call(
                              CreateAuditScreen(
                                  preselectedTemplateId: template['id']),
                            );
                          },
                        )
                            .animate()
                            .fadeIn(
                                delay:
                                    Duration(milliseconds: 300 + (index * 30)))
                            .slideY(
                                begin: 0.1,
                                delay:
                                    Duration(milliseconds: 300 + (index * 30)));
                      },
                      childCount: pageTemplates.length,
                    ),
                  ),
                ),
                if (filteredTemplates.length > itemsPerPage)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 1
                                ? () => setState(() => _currentPage--)
                                : null,
                            icon: const Icon(FontAwesomeIcons.chevronLeft),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Page $_currentPage',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: endIndex < filteredTemplates.length
                                ? () => setState(() => _currentPage++)
                                : null,
                            icon: const Icon(FontAwesomeIcons.chevronRight),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          widget.onNavigateToPage?.call(const CreateTemplateScreen());
        },
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Nouveau template'),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final int questionCount;
  final String description;
  final VoidCallback onEdit;
  final VoidCallback onUse;

  const _TemplateCard({
    required this.id,
    required this.title,
    required this.category,
    required this.questionCount,
    required this.description,
    required this.onEdit,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                FontAwesomeIcons.ellipsisVertical,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$questionCount question${questionCount > 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 32),
                    side: BorderSide(color: theme.colorScheme.primary),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Modifier'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: onUse,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(0, 32),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Utiliser'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

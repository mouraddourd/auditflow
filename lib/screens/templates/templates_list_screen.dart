import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'create_template_screen.dart';

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final allTemplates = List.generate(24, (index) {
      final categories = [
        'Qualité',
        'Sécurité',
        'Environnement',
        'Hygiène',
        'Technique',
        'Conformité'
      ];
      return {
        'title': 'Template ${index + 1}',
        'category': categories[index % 6],
        'questions': '${5 + index * 2} questions',
        'description':
            'Template d\'audit pour ${categories[index % 6].toLowerCase()}',
      };
    });

    final filteredTemplates = allTemplates.where((t) {
      final matchesCategory = _selectedCategory == null ||
          _selectedCategory == 'Tous' ||
          t['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          (t['title'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (t['description'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
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
                      (context, index) => _TemplateCard(
                        title: pageTemplates[index]['title'] as String,
                        category: pageTemplates[index]['category'] as String,
                        questions: pageTemplates[index]['questions'] as String,
                        description:
                            pageTemplates[index]['description'] as String,
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: 300 + (index * 30)))
                          .slideY(
                              begin: 0.1,
                              delay:
                                  Duration(milliseconds: 300 + (index * 30))),
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
  final String title;
  final String category;
  final String questions;
  final String description;

  const _TemplateCard({
    required this.title,
    required this.category,
    required this.questions,
    required this.description,
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
            questions,
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
                  onPressed: () {},
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
                  onPressed: () {},
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'create_audit_screen.dart';

class AuditsListScreen extends StatefulWidget {
  final Function(Widget)? onNavigateToPage;
  const AuditsListScreen({super.key, this.onNavigateToPage});

  @override
  State<AuditsListScreen> createState() => _AuditsListScreenState();
}

class _AuditsListScreenState extends State<AuditsListScreen> {
  String? _selectedStatus;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _audits = [
    {
      'title': 'Audit Q1 2025 - Usine Lyon',
      'template': 'Audit Qualité ISO 9001',
      'status': 'En cours',
      'progress': 65,
      'assignee': 'Jean Dupont',
      'date': '15 Fév 2025',
      'category': 'Qualité',
    },
    {
      'title': 'Inspection Sécurité Annuelle',
      'template': 'Inspection Sécurité',
      'status': 'Terminé',
      'progress': 100,
      'assignee': 'Marie Martin',
      'date': '10 Fév 2025',
      'category': 'Sécurité',
    },
    {
      'title': 'Audit Environnement Mars',
      'template': 'Audit Environnement',
      'status': 'Brouillon',
      'progress': 0,
      'assignee': 'Pierre Durand',
      'date': '20 Fév 2025',
      'category': 'Environnement',
    },
    {
      'title': 'Contrôle Hygiène Restaurant',
      'template': 'Contrôle Hygiène',
      'status': 'En cours',
      'progress': 30,
      'assignee': 'Sophie Bernard',
      'date': '22 Fév 2025',
      'category': 'Hygiène',
    },
    {
      'title': 'Audit Technique Q4 2024',
      'template': 'Audit Technique',
      'status': 'Terminé',
      'progress': 100,
      'assignee': 'Lucas Petit',
      'date': '28 Jan 2025',
      'category': 'Technique',
    },
  ];

  List<Map<String, dynamic>> get _filteredAudits {
    return _audits.where((audit) {
      final matchesStatus =
          _selectedStatus == null || audit['status'] == _selectedStatus;
      final matchesSearch = _searchQuery.isEmpty ||
          audit['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          audit['template']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          audit['assignee'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Terminé':
        return Colors.green;
      case 'En cours':
        return Colors.orange;
      case 'Brouillon':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Terminé':
        return FontAwesomeIcons.circleCheck;
      case 'En cours':
        return FontAwesomeIcons.spinner;
      case 'Brouillon':
        return FontAwesomeIcons.penToSquare;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
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
                              'Audits',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: -0.1),
                            const SizedBox(height: 4),
                            Text(
                              '${_filteredAudits.length} audits',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Search
                    TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un audit...',
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
                    // Status filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatusFilterChip(
                            label: 'Tous',
                            isSelected: _selectedStatus == null,
                            onSelected: () =>
                                setState(() => _selectedStatus = null),
                          ),
                          _StatusFilterChip(
                            label: 'En cours',
                            isSelected: _selectedStatus == 'En cours',
                            color: Colors.orange,
                            onSelected: () =>
                                setState(() => _selectedStatus = 'En cours'),
                          ),
                          _StatusFilterChip(
                            label: 'Terminé',
                            isSelected: _selectedStatus == 'Terminé',
                            color: Colors.green,
                            onSelected: () =>
                                setState(() => _selectedStatus = 'Terminé'),
                          ),
                          _StatusFilterChip(
                            label: 'Brouillon',
                            isSelected: _selectedStatus == 'Brouillon',
                            color: Colors.grey,
                            onSelected: () =>
                                setState(() => _selectedStatus = 'Brouillon'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final audit = _filteredAudits[index];
                    final statusColor =
                        _getStatusColor(audit['status'] as String);
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  audit['category'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(audit['status'] as String),
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      audit['status'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            audit['title'] as String,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            audit['template'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (audit['status'] == 'En cours') ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (audit['progress'] as int) / 100,
                                backgroundColor: Colors.grey[800],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(statusColor),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${audit['progress']}% complété',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Icon(FontAwesomeIcons.user,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                audit['assignee'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(FontAwesomeIcons.calendarDays,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                audit['date'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              const Spacer(),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  // Handle menu actions
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(FontAwesomeIcons.pen, size: 18),
                                        SizedBox(width: 8),
                                        Text('Modifier'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'fill',
                                    child: Row(
                                      children: [
                                        Icon(FontAwesomeIcons.clipboardList,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text('Remplir'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'results',
                                    child: Row(
                                      children: [
                                        Icon(FontAwesomeIcons.chartLine,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text('Voir résultats'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(FontAwesomeIcons.trash,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Supprimer',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(
                            delay: Duration(milliseconds: 300 + (index * 50)))
                        .slideX(
                            begin: 0.1,
                            delay: Duration(milliseconds: 300 + (index * 50)));
                  },
                  childCount: _filteredAudits.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          widget.onNavigateToPage?.call(const CreateAuditScreen());
        },
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Nouvel audit'),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: theme.cardTheme.color,
        selectedColor: effectiveColor.withOpacity(0.2),
        checkmarkColor: effectiveColor,
        labelStyle: TextStyle(
          color: isSelected ? effectiveColor : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

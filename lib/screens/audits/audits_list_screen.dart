import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../powersync/service.dart';
import 'create_audit_screen.dart';

/// Audits list screen displaying real-time synced audits from PowerSync.
///
/// Uses [PowerSyncService.watchAudits] to subscribe to changes
/// and automatically update the UI when data changes locally or remotely.
class AuditsListScreen extends StatefulWidget {
  final Function(Widget)? onNavigateToPage;
  const AuditsListScreen({super.key, this.onNavigateToPage});

  @override
  State<AuditsListScreen> createState() => _AuditsListScreenState();
}

class _AuditsListScreenState extends State<AuditsListScreen> {
  /// Filter by audit status (null = all statuses)
  String? _selectedStatus;

  /// Search query for filtering by title or description
  String _searchQuery = '';

  /// Returns the appropriate color for each audit status.
  ///
  /// Used for status badges and progress indicators.
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

  /// Returns the appropriate icon for each audit status.
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
    final powerSync = PowerSyncService();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          // Subscribe to real-time audit updates from PowerSync.
          // The stream automatically emits new data when:
          // - Local changes are made (create, update, delete)
          // - Remote changes are synced from the server
          stream: powerSync.watchAudits(
            status: _selectedStatus,
            search: _searchQuery.isNotEmpty ? _searchQuery : null,
          ),
          builder: (context, snapshot) {
            // Handle loading state - show skeleton while waiting for initial data
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FontAwesomeIcons.triangleExclamation,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erreur: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final audits = snapshot.data ?? [];

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
                                  'Audits',
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
                                  '${audits.length} audits',
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
                        // Search field - filters are applied via watchAudits stream
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
                        // Status filters - clicking updates stream via setState
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
                                onSelected: () => setState(
                                    () => _selectedStatus = 'En cours'),
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
                                onSelected: () => setState(
                                    () => _selectedStatus = 'Brouillon'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Empty state when no audits match filters
                if (audits.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FontAwesomeIcons.clipboardList,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun audit trouvé',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez votre premier audit pour commencer',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Audit list - each item updates reactively
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final audit = audits[index];
                          final statusColor = _getStatusColor(
                              audit['status'] as String? ?? 'Brouillon');
                          return _AuditCard(
                            audit: audit,
                            statusColor: statusColor,
                            getStatusIcon: _getStatusIcon,
                          )
                              .animate()
                              .fadeIn(
                                  delay: Duration(
                                      milliseconds: 300 + (index * 50)))
                              .slideX(
                                  begin: 0.1,
                                  delay: Duration(
                                      milliseconds: 300 + (index * 50)));
                        },
                        childCount: audits.length,
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
          widget.onNavigateToPage?.call(const CreateAuditScreen());
        },
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Nouvel audit'),
      ),
    );
  }
}

/// Audit card widget displaying a single audit's information.
///
/// Extracted to a separate widget for better performance
/// with const constructors and rebuild optimization.
class _AuditCard extends StatelessWidget {
  final Map<String, dynamic> audit;
  final Color statusColor;
  final IconData Function(String) getStatusIcon;

  const _AuditCard({
    required this.audit,
    required this.statusColor,
    required this.getStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = audit['status'] as String? ?? 'Brouillon';
    final progress = audit['score'] as int? ?? 0;

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
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  audit['template_id'] as String? ?? 'Audit',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getStatusIcon(status),
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
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
          // Title
          Text(
            audit['title'] as String? ?? 'Sans titre',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Description
          if (audit['description'] != null)
            Text(
              audit['description'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          // Progress bar for in-progress audits
          if (status == 'En cours') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$progress% complété',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Dates row
          Row(
            children: [
              Icon(FontAwesomeIcons.calendarDays,
                  size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                audit['created_at'] as String? ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              // Actions menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  // TODO: Handle menu actions (edit, fill, results, delete)
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
                        Icon(FontAwesomeIcons.clipboardList, size: 18),
                        SizedBox(width: 8),
                        Text('Remplir'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'results',
                    child: Row(
                      children: [
                        Icon(FontAwesomeIcons.chartLine, size: 18),
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
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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

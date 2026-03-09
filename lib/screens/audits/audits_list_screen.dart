import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../hive/service.dart';
import 'create_audit_screen.dart';
import 'audit_fill_screen.dart';
import 'edit_audit_screen.dart';
import '../results/results_screen.dart';

class AuditsListScreen extends StatefulWidget {
  final Future<bool> Function(Widget)? onNavigateToPage;
  const AuditsListScreen({super.key, this.onNavigateToPage});

  @override
  State<AuditsListScreen> createState() => _AuditsListScreenState();
}

class _AuditsListScreenState extends State<AuditsListScreen> {
  String? _selectedStatus;
  String _searchQuery = '';
  List<Map<String, dynamic>> _audits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudits();
  }

  void _loadAudits() {
    setState(() => _isLoading = true);
    try {
      final audits = HiveService().getAudits(
        status: _selectedStatus,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _audits = audits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Terminé';
      case 'in_progress':
        return 'En cours';
      case 'draft':
        return 'Brouillon';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return FontAwesomeIcons.circleCheck;
      case 'in_progress':
        return FontAwesomeIcons.spinner;
      case 'draft':
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
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
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 400.ms)
                                      .slideX(begin: -0.1),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_audits.length} audits',
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
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                              _loadAudits();
                            },
                            decoration: InputDecoration(
                              hintText: 'Rechercher un audit...',
                              prefixIcon:
                                  const Icon(FontAwesomeIcons.magnifyingGlass),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(FontAwesomeIcons.xmark),
                                      onPressed: () {
                                        setState(() => _searchQuery = '');
                                        _loadAudits();
                                      },
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
                              children: [
                                _StatusFilterChip(
                                  label: 'Tous',
                                  isSelected: _selectedStatus == null,
                                  onSelected: () {
                                    setState(() => _selectedStatus = null);
                                    _loadAudits();
                                  },
                                ),
                                _StatusFilterChip(
                                  label: 'En cours',
                                  isSelected: _selectedStatus == 'in_progress',
                                  color: Colors.orange,
                                  onSelected: () {
                                    setState(
                                        () => _selectedStatus = 'in_progress');
                                    _loadAudits();
                                  },
                                ),
                                _StatusFilterChip(
                                  label: 'Terminé',
                                  isSelected: _selectedStatus == 'completed',
                                  color: Colors.green,
                                  onSelected: () {
                                    setState(
                                        () => _selectedStatus = 'completed');
                                    _loadAudits();
                                  },
                                ),
                                _StatusFilterChip(
                                  label: 'Brouillon',
                                  isSelected: _selectedStatus == 'draft',
                                  color: Colors.grey,
                                  onSelected: () {
                                    setState(() => _selectedStatus = 'draft');
                                    _loadAudits();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  if (_audits.isEmpty)
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
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final audit = _audits[index];
                            final status =
                                audit['status'] as String? ?? 'draft';
                            final statusColor = _getStatusColor(status);
                            return _AuditCard(
                              audit: audit,
                              statusColor: statusColor,
                              getStatusIcon: _getStatusIcon,
                              getStatusLabel: _getStatusLabel,
                              onDelete: () async {
                                await HiveService()
                                    .deleteAudit(audit['id'] as String);
                                _loadAudits();
                              },
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditAuditScreen(
                                        auditId: audit['id'] as String),
                                  ),
                                ).then((_) => _loadAudits());
                              },
                              onFill: () {
                                final status =
                                    audit['status'] as String? ?? 'draft';
                                if (status == 'completed') {
                                  // Naviguer vers les résultats
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResultsScreen(
                                          auditId: audit['id'] as String),
                                    ),
                                  );
                                } else {
                                  // Naviguer vers le remplissage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AuditFillScreen(
                                        auditId: audit['id'] as String,
                                        templateId:
                                            audit['template_id'] as String,
                                        auditTitle: audit['title'] as String? ??
                                            'Audit',
                                      ),
                                    ),
                                  ).then((_) => _loadAudits());
                                }
                              },
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
                          childCount: _audits.length,
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
        onPressed: () async {
          final result = await widget.onNavigateToPage?.call(
              CreateAuditScreen(onNavigateToPage: widget.onNavigateToPage));
          if (result == true) {
            _loadAudits();
          }
        },
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Nouvel audit'),
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final Map<String, dynamic> audit;
  final Color statusColor;
  final IconData Function(String) getStatusIcon;
  final String Function(String) getStatusLabel;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onFill;

  const _AuditCard({
    required this.audit,
    required this.statusColor,
    required this.getStatusIcon,
    required this.getStatusLabel,
    required this.onDelete,
    required this.onEdit,
    required this.onFill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = audit['status'] as String? ?? 'draft';
    final score = audit['score'] as int?;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTemplateCategory(audit['template_id'] as String?),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
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
                      getStatusLabel(status),
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
            audit['title'] as String? ?? 'Sans titre',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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
          if (status == 'in_progress' && score != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score% complété',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
          ] else if (status == 'completed' && score != null) ...[
            Row(
              children: [
                Icon(FontAwesomeIcons.chartPie, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Score: $score%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(FontAwesomeIcons.calendarDays,
                  size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                _formatDate(audit['updated_at'] as String?),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  } else if (value == 'edit') {
                    onEdit();
                  } else if (value == 'fill') {
                    onFill();
                  }
                },
                itemBuilder: (context) => [
                  if (status != 'completed')
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
                  if (status == 'completed')
                    const PopupMenuItem(
                      value: 'fill',
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.chartPie, size: 18),
                          SizedBox(width: 8),
                          Text('Voir résultats'),
                        ],
                      ),
                    ),
                  if (status != 'completed')
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

  String _getTemplateCategory(String? templateId) {
    if (templateId == null) return 'Audit';
    final template = HiveService().getTemplateById(templateId);
    if (template == null) return 'Audit';
    return template['category'] as String? ??
        template['name'] as String? ??
        'Audit';
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Date inconnue';
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${diff.inHours}h';
      } else if (diff.inDays == 1) {
        return 'Hier';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays} jours';
      } else {
        return 'Il y a ${diff.inDays ~/ 7} sem.';
      }
    } catch (e) {
      return 'Date inconnue';
    }
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

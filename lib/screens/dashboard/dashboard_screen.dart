import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../powersync/service.dart';

/// Dashboard screen with real-time stats from PowerSync.
///
/// Displays:
/// - Audit statistics (total, completed, in progress, drafts)
/// - Average score with trend indicator
/// - Score evolution chart (placeholder for now)
/// - Recent audits list from watchAudits stream
class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final Function(Widget)? onNavigateToPage;
  const DashboardScreen({super.key, this.onNavigate, this.onNavigateToPage});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Audit statistics loaded from PowerSync
  Map<String, dynamic> _stats = {};

  /// Loading state for stats
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// Loads audit statistics from PowerSync.
  ///
  /// Stats include: total, completed, in_progress, draft, avg_score
  Future<void> _loadStats() async {
    try {
      final stats = await PowerSyncService().getAuditStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() => _isLoadingStats = false);
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
                              'Dashboard',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bienvenue sur AuditFlow',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stat cards - real data from PowerSync
                    if (_isLoadingStats)
                      const Center(child: CircularProgressIndicator())
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 800;
                          final cards = [
                            _StatCard(
                                title: 'Total Audits',
                                value: '${_stats['total'] ?? 0}',
                                icon: FontAwesomeIcons.clipboardCheck,
                                color: theme.colorScheme.primary),
                            _StatCard(
                                title: 'Terminés',
                                value: '${_stats['completed'] ?? 0}',
                                icon: FontAwesomeIcons.circleCheck,
                                color: Colors.green),
                            _StatCard(
                                title: 'En cours',
                                value: '${_stats['in_progress'] ?? 0}',
                                icon: FontAwesomeIcons.spinner,
                                color: Colors.orange),
                            _StatCard(
                                title: 'Brouillons',
                                value: '${_stats['draft'] ?? 0}',
                                icon: FontAwesomeIcons.penToSquare,
                                color: Colors.grey),
                          ];
                          return isWide
                              ? Row(
                                  children: cards.asMap().entries.map((entry) {
                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            right: entry.key < 3 ? 12 : 0),
                                        child: entry.value
                                            .animate()
                                            .fadeIn(
                                                delay: Duration(
                                                    milliseconds:
                                                        100 * entry.key))
                                            .slideX(
                                                begin: 0.2,
                                                delay: Duration(
                                                    milliseconds:
                                                        100 * entry.key)),
                                      ),
                                    );
                                  }).toList(),
                                )
                              : Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: cards.asMap().entries.map((entry) {
                                    return SizedBox(
                                      width: (constraints.maxWidth - 12) / 2,
                                      child: entry.value
                                          .animate()
                                          .fadeIn(
                                              delay: Duration(
                                                  milliseconds:
                                                      100 * entry.key))
                                          .slideY(
                                              begin: 0.2,
                                              delay: Duration(
                                                  milliseconds:
                                                      100 * entry.key)),
                                    );
                                  }).toList(),
                                );
                        },
                      ),
                    const SizedBox(height: 24),

                    // Score moyen card - real average from PowerSync
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(FontAwesomeIcons.chartLine,
                              color: Colors.white, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Score moyen',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  '${(_stats['avg_score'] ?? 0).toStringAsFixed(0)}%',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Global',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 24),

                    // Graphique FL Chart - placeholder for future enhancement
                    Container(
                      height: 200,
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
                          Text(
                            'Évolution des scores',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    // TODO: Calculate from real audit data by month
                                    spots: [
                                      FlSpot(0, 65),
                                      FlSpot(1, 72),
                                      FlSpot(2, 68),
                                      FlSpot(3, 75),
                                      FlSpot(4, 78),
                                      FlSpot(5, 82),
                                      FlSpot(
                                          6,
                                          (_stats['avg_score'] as num?)
                                                  ?.toDouble() ??
                                              78),
                                    ],
                                    isCurved: true,
                                    color: theme.colorScheme.primary,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                    const SizedBox(height: 24),
                    Text(
                      'Audits Récents',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Recent audits from PowerSync stream
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: StreamBuilder<List<Map<String, dynamic>>>(
                // Watch last 5 audits for real-time updates
                stream: PowerSyncService().watchAudits(limit: 5),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final audits = snapshot.data ?? [];

                  if (audits.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FontAwesomeIcons.clipboardList,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun audit pour le moment',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final audit = audits[index];
                        final status = audit['status'] as String? ?? 'draft';
                        final score = audit['score'] as int?;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AuditCard(
                            title: audit['title'] as String? ?? 'Sans titre',
                            status: status,
                            score: score,
                            date: _formatDate(audit['updated_at'] as String?),
                          )
                              .animate()
                              .fadeIn(
                                  delay: Duration(
                                      milliseconds: 600 + (100 * index)))
                              .slideX(
                                  begin: 0.1,
                                  delay: Duration(
                                      milliseconds: 600 + (100 * index))),
                        );
                      },
                      childCount: audits.length,
                    ),
                  );
                },
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
          // Navigate to create audit screen
          widget.onNavigateToPage?.call(const CreateAuditScreenPlaceholder());
        },
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Nouvel audit'),
      ),
    );
  }

  /// Formats ISO date string to relative time in French.
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

/// Placeholder for CreateAuditScreen to avoid circular import
class CreateAuditScreenPlaceholder extends StatelessWidget {
  const CreateAuditScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // This will be replaced by actual navigation
    return const Scaffold(body: Center(child: Text('Create Audit')));
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final String title;
  final String status;
  final int? score;
  final String date;

  const _AuditCard({
    required this.title,
    required this.status,
    this.score,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = status == 'completed';

    return Container(
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCompleted
                  ? FontAwesomeIcons.circleCheck
                  : FontAwesomeIcons.spinner,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(score!).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$score%',
                style: TextStyle(
                  color: _getScoreColor(score!),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}

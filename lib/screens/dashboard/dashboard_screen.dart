import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigate;
  final Function(Widget)? onNavigateToPage;
  const DashboardScreen({super.key, this.onNavigate, this.onNavigateToPage});

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
                    // Stat cards with animations
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 800;
                        final cards = [
                          _StatCard(
                              title: 'Total Audits',
                              value: '12',
                              icon: FontAwesomeIcons.clipboardCheck,
                              color: theme.colorScheme.primary),
                          _StatCard(
                              title: 'Terminés',
                              value: '8',
                              icon: FontAwesomeIcons.checkCircle,
                              color: Colors.green),
                          _StatCard(
                              title: 'En cours',
                              value: '3',
                              icon: FontAwesomeIcons.spinner,
                              color: Colors.orange),
                          _StatCard(
                              title: 'Brouillons',
                              value: '1',
                              icon: FontAwesomeIcons.edit,
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
                                                milliseconds: 100 * entry.key))
                                        .slideY(
                                            begin: 0.2,
                                            delay: Duration(
                                                milliseconds: 100 * entry.key)),
                                  );
                                }).toList(),
                              );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Score moyen card with animation
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
                                  '78%',
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
                              '+5% ce mois',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 24),
                    // Graphique FL Chart
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
                                    spots: [
                                      const FlSpot(0, 65),
                                      const FlSpot(1, 72),
                                      const FlSpot(2, 68),
                                      const FlSpot(3, 75),
                                      const FlSpot(4, 78),
                                      const FlSpot(5, 82),
                                      const FlSpot(6, 78),
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
            // Recent audits with animations
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AuditCard(
                      title: 'Audit Qualité Labo ${index + 1}',
                      status: index % 3 == 0 ? 'completed' : 'in_progress',
                      score: index % 3 == 0 ? 85 + index * 2 : null,
                      date: 'Il y a ${index + 1} jour${index > 0 ? 's' : ''}',
                    )
                        .animate()
                        .fadeIn(
                            delay: Duration(milliseconds: 600 + (100 * index)))
                        .slideX(
                            begin: 0.1,
                            delay: Duration(milliseconds: 600 + (100 * index))),
                  ),
                  childCount: 5,
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
        onPressed: () {},
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Nouvel audit'),
      ),
    );
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

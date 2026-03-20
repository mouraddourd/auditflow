import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/ai_service.dart';
import '../services/sync_service.dart';

/// Anomalies Insights Card widget for audit detail screen
///
/// Shows detected anomalies and patterns from historical audit analysis:
/// - Recurring issues
/// - Score drops
/// - Trend patterns
class AnomaliesInsightsCard extends StatefulWidget {
  final String auditId;
  final VoidCallback? onInsightsLoaded;

  const AnomaliesInsightsCard({
    super.key,
    required this.auditId,
    this.onInsightsLoaded,
  });

  @override
  State<AnomaliesInsightsCard> createState() => _AnomaliesInsightsCardState();
}

class _AnomaliesInsightsCardState extends State<AnomaliesInsightsCard> {
  AuditInsights? _insights;
  bool _isLoading = false;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final online = await SyncService().isOnline();
    setState(() => _isOnline = online);
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    final insights = await AIService().getInsights(widget.auditId);

    setState(() {
      _insights = insights;
      _isLoading = false;
    });

    widget.onInsightsLoaded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Offline state
    if (!_isOnline) {
      return _buildOfflineCard(theme);
    }

    // Loading state
    if (_isLoading) {
      return _buildLoadingCard(theme);
    }

    // Insights loaded
    if (_insights != null) {
      return _buildInsightsCard(theme, _insights!);
    }

    // Initial state - ready to load
    return _buildLoadCard(theme);
  }

  Widget _buildOfflineCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.grey, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insights indisponibles',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reconnectez-vous pour voir les anomalies détectées',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.chartLine,
              size: 40,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'Analyse de l\'historique...',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildLoadCard(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.triangleExclamation,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 Insights & Anomalies',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Détecter les problèmes récurrents et tendances',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadInsights,
                icon: const Icon(Icons.analytics),
                label: const Text('ANALYSER L\'HISTORIQUE'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInsightsCard(ThemeData theme, AuditInsights insights) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.chartLine,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔍 Insights & Anomalies',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${insights.totalAudits} audits analysés',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadInsights,
                  tooltip: 'Rafraîchir',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score comparison
                _buildScoreComparison(theme, insights),

                const SizedBox(height: 16),

                // Trend indicator
                _buildTrendIndicator(theme, insights),

                // Anomalies
                if (insights.hasAnomalies) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('⚠️ Anomalies détectées', theme, color: Colors.red),
                  const SizedBox(height: 8),
                  ...insights.anomalies.map((a) => _buildAnomalyItem(theme, a)),
                ],

                // Patterns
                if (insights.hasPatterns) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('📊 Tendances', theme, color: Colors.blue),
                  const SizedBox(height: 8),
                  ...insights.patterns.map((p) => _buildPatternItem(theme, p)),
                ],

                // No anomalies message
                if (!insights.hasAnomalies && !insights.hasPatterns) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aucune anomalie détectée sur l\'historique',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildScoreComparison(ThemeData theme, AuditInsights insights) {
    final currentScore = insights.currentScore;
    final avgScore = insights.averageScore;
    final prevScore = insights.previousScore;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Current score
        _buildScoreBox(
          theme,
          'Score actuel',
          currentScore?.toString() ?? '-',
          currentScore != null ? _getScoreColor(currentScore) : Colors.grey,
        ),
        // Average score
        _buildScoreBox(
          theme,
          'Moyenne',
          avgScore.toString(),
          _getScoreColor(avgScore),
        ),
        // Previous score
        if (prevScore != null)
          _buildScoreBox(
            theme,
            'Précédent',
            prevScore.toString(),
            _getScoreColor(prevScore),
          ),
      ],
    );
  }

  Widget _buildScoreBox(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(ThemeData theme, AuditInsights insights) {
    final trend = insights.trend;
    Color color;
    IconData icon;
    String text;

    switch (trend) {
      case 'improving':
        color = Colors.green;
        icon = FontAwesomeIcons.arrowTrendUp;
        text = 'Tendance à la hausse';
        break;
      case 'declining':
        color = Colors.red;
        icon = FontAwesomeIcons.arrowTrendDown;
        text = 'Tendance à la baisse';
        break;
      default:
        color = Colors.blue;
        icon = FontAwesomeIcons.arrowRight;
        text = 'Performance stable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme, {Color? color}) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildAnomalyItem(ThemeData theme, Anomaly anomaly) {
    Color severityColor;
    IconData severityIcon;

    switch (anomaly.severity) {
      case 'high':
        severityColor = Colors.red;
        severityIcon = FontAwesomeIcons.circleExclamation;
        break;
      case 'medium':
        severityColor = Colors.orange;
        severityIcon = FontAwesomeIcons.triangleExclamation;
        break;
      default:
        severityColor = Colors.blue;
        severityIcon = FontAwesomeIcons.circleInfo;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(severityIcon, color: severityColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  anomaly.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '×${anomaly.occurrences}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: severityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            anomaly.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(ThemeData theme, Pattern pattern) {
    Color color;
    IconData icon;

    if (pattern.isImprovement) {
      color = Colors.green;
      icon = FontAwesomeIcons.arrowUp;
    } else if (pattern.isDecline) {
      color = Colors.red;
      icon = FontAwesomeIcons.arrowDown;
    } else {
      color = Colors.blue;
      icon = FontAwesomeIcons.minus;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pattern.description,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

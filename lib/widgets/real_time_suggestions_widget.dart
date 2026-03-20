import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/ai_service.dart';
import '../services/sync_service.dart';

/// Real-time suggestions widget for audit fill screen
///
/// Shows alerts and suggestions while the user is filling the audit:
/// - Current score prediction
/// - Alerts for issues detected
/// - Suggestions for improvement
class RealTimeSuggestionsWidget extends StatefulWidget {
  final String auditId;
  final List<Map<String, String>> answers;
  final VoidCallback? onSuggestionsLoaded;

  const RealTimeSuggestionsWidget({
    super.key,
    required this.auditId,
    required this.answers,
    this.onSuggestionsLoaded,
  });

  @override
  State<RealTimeSuggestionsWidget> createState() => _RealTimeSuggestionsWidgetState();
}

class _RealTimeSuggestionsWidgetState extends State<RealTimeSuggestionsWidget> {
  RealTimeSuggestions? _suggestions;
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

  Future<void> _loadSuggestions() async {
    if (!_isOnline || widget.answers.isEmpty) return;

    setState(() => _isLoading = true);

    final suggestions = await AIService().getRealTimeSuggestions(
      widget.auditId,
      widget.answers,
    );

    setState(() {
      _suggestions = suggestions;
      _isLoading = false;
    });

    widget.onSuggestionsLoaded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't show if offline or no answers
    if (!_isOnline || widget.answers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Loading state
    if (_isLoading) {
      return _buildLoadingIndicator(theme);
    }

    // Has suggestions
    if (_suggestions != null && _suggestions!.hasAlerts) {
      return _buildAlertsCard(theme, _suggestions!);
    }

    // Show load button if enough answers
    if (widget.answers.length >= 3) {
      return _buildLoadButton(theme);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Analyse...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildLoadButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton.icon(
        onPressed: _loadSuggestions,
        icon: const Icon(Icons.analytics, size: 18),
        label: const Text('Voir les suggestions IA'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildAlertsCard(ThemeData theme, RealTimeSuggestions suggestions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with score
          Row(
            children: [
              Icon(
                FontAwesomeIcons.wandMagicSparkles,
                color: theme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Suggestions IA',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Predicted score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(suggestions.predictedScore).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FontAwesomeIcons.chartLine,
                      size: 12,
                      color: _getScoreColor(suggestions.predictedScore),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${suggestions.predictedScore}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getScoreColor(suggestions.predictedScore),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Alerts
          if (suggestions.hasAlerts) ...[
            const SizedBox(height: 12),
            ...suggestions.alerts.map((alert) => _buildAlertItem(theme, alert)),
          ],

          // Suggestions
          if (suggestions.hasSuggestions) ...[
            const SizedBox(height: 8),
            ...suggestions.suggestions.map((s) => _buildSuggestionItem(theme, s)),
          ],

          // Refresh button
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loadSuggestions,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Rafraîchir'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildAlertItem(ThemeData theme, RTAlert alert) {
    Color bgColor;
    Color fgColor;
    IconData icon;

    switch (alert.type) {
      case 'danger':
        bgColor = Colors.red.withOpacity(0.15);
        fgColor = Colors.red;
        icon = FontAwesomeIcons.circleExclamation;
        break;
      case 'warning':
        bgColor = Colors.orange.withOpacity(0.15);
        fgColor = Colors.orange;
        icon = FontAwesomeIcons.triangleExclamation;
        break;
      default:
        bgColor = Colors.blue.withOpacity(0.15);
        fgColor = Colors.blue;
        icon = FontAwesomeIcons.circleInfo;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(ThemeData theme, String suggestion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            FontAwesomeIcons.lightbulb,
            color: theme.colorScheme.primary,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              suggestion,
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

/// Prediction score bar widget for audit fill screen header
///
/// Shows a compact score prediction bar at the top of the screen
class PredictionScoreBar extends StatefulWidget {
  final String auditId;
  final List<Map<String, String>> answers;

  const PredictionScoreBar({
    super.key,
    required this.auditId,
    required this.answers,
  });

  @override
  State<PredictionScoreBar> createState() => _PredictionScoreBarState();
}

class _PredictionScoreBarState extends State<PredictionScoreBar> {
  RealTimeSuggestions? _suggestions;
  bool _isLoading = false;

  @override
  void didUpdateWidget(PredictionScoreBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-refresh when answers change significantly
    if ((widget.answers.length - oldWidget.answers.length).abs() >= 3) {
      _loadSuggestions();
    }
  }

  Future<void> _loadSuggestions() async {
    if (widget.answers.length < 3) return;

    setState(() => _isLoading = true);

    final suggestions = await AIService().getRealTimeSuggestions(
      widget.auditId,
      widget.answers,
    );

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't show if not enough answers
    if (widget.answers.length < 3) {
      return const SizedBox.shrink();
    }

    // Loading state
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Calcul du score prédictif...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Has prediction
    if (_suggestions != null) {
      return _buildPredictionBar(theme, _suggestions!);
    }

    // Load button
    return GestureDetector(
      onTap: _loadSuggestions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              FontAwesomeIcons.chartLine,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Voir le score prédit',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionBar(ThemeData theme, RealTimeSuggestions suggestions) {
    final score = suggestions.predictedScore;
    final confidence = suggestions.confidence;
    final progress = suggestions.progress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.chartLine,
                size: 14,
                color: _getScoreColor(score),
              ),
              const SizedBox(width: 8),
              Text(
                'Score prédit: $score%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getScoreColor(score),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${(confidence * 100).round()}% confiance)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar with prediction
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(_getScoreColor(score)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Basé sur ${widget.answers.length} réponses (${progress.round()}% complété)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 10,
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/ai_service.dart';
import '../services/sync_service.dart';

/// AI Analysis card widget for audit detail screen
/// 
/// Shows:
/// - Offline state (if no internet)
/// - Ready to analyze state (button to start)
/// - Loading state (progress indicator)
/// - Result state (summary, score, insights)
class AIAnalysisCard extends StatefulWidget {
  final String auditId;
  final VoidCallback? onAnalysisComplete;

  const AIAnalysisCard({
    super.key,
    required this.auditId,
    this.onAnalysisComplete,
  });

  @override
  State<AIAnalysisCard> createState() => _AIAnalysisCardState();
}

class _AIAnalysisCardState extends State<AIAnalysisCard> {
  AIAnalysis? _analysis;
  bool _isLoading = false;
  bool _isOnline = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final online = await SyncService().isOnline();
    final available = online ? await AIService().isAvailable() : false;
    
    setState(() {
      _isOnline = online;
      _isAvailable = available;
    });
  }

  Future<void> _analyze() async {
    setState(() => _isLoading = true);
    
    final analysis = await AIService().analyzeAuditById(widget.auditId);
    
    setState(() {
      _analysis = analysis;
      _isLoading = false;
    });
    
    widget.onAnalysisComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Offline state
    if (!_isOnline) {
      return _buildOfflineCard(theme);
    }

    // AI service unavailable
    if (!_isAvailable) {
      return _buildUnavailableCard(theme);
    }

    // Loading state
    if (_isLoading) {
      return _buildLoadingCard(theme);
    }

    // Analysis result
    if (_analysis != null && _analysis!.hasContent) {
      return _buildResultCard(theme, _analysis!);
    }

    // Initial state - ready to analyze
    return _buildAnalyzeCard(theme);
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
                    'Analyse IA indisponible',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reconnectez-vous pour utiliser l\'analyse automatique',
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

  Widget _buildUnavailableCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.psychology, color: Colors.grey, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service IA momentanément indisponible',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Le service d\'analyse IA est en cours de maintenance',
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
              FontAwesomeIcons.brain,
              size: 40,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'L\'IA analyse les réponses...',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Cela peut prendre 20-30 secondes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildAnalyzeCard(ThemeData theme) {
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
                    color: Colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.wandMagicSparkles,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🤖 Analyse IA',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analyser automatiquement cet audit avec l\'IA',
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
                onPressed: _analyze,
                icon: const Icon(Icons.play_arrow),
                label: const Text('LANCER L\'ANALYSE'),
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

  Widget _buildResultCard(ThemeData theme, AIAnalysis analysis) {
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
                    color: Colors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.brain,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🤖 Analyse IA',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'via ${analysis.model}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _analyze,
                  tooltip: 'Régénérer l\'analyse',
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
                // Score
                if (analysis.estimatedScore != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(analysis.estimatedScore!)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Score estimé: ${analysis.estimatedScore}/100',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(analysis.estimatedScore!),
                        ),
                      ),
                    ),
                  ),

                if (analysis.estimatedScore != null)
                  const SizedBox(height: 20),

                // Summary
                if (analysis.summary.isNotEmpty) ...[
                  _buildSectionTitle('Résumé', theme),
                  const SizedBox(height: 8),
                  Text(
                    analysis.summary,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                ],

                // Strengths
                if (analysis.strengths.isNotEmpty) ...[
                  _buildSectionTitle('✅ Points forts', theme,
                      color: Colors.green),
                  const SizedBox(height: 8),
                  ...analysis.strengths.map((item) => _buildListItem(item)),
                  const SizedBox(height: 20),
                ],

                // Concerns
                if (analysis.concerns.isNotEmpty) ...[
                  _buildSectionTitle('⚠️ Points de vigilance', theme,
                      color: Colors.orange),
                  const SizedBox(height: 8),
                  ...analysis.concerns.map((item) => _buildListItem(item)),
                  const SizedBox(height: 20),
                ],

                // Recommendations
                if (analysis.recommendations.isNotEmpty) ...[
                  _buildSectionTitle('💡 Recommandations', theme,
                      color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  ...analysis.recommendations.map((item) => _buildListItem(item)),
                ],

                // Disclaimer
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cette analyse est générée automatiquement par IA et fournie à titre indicatif. Vérifiez toujours les conclusions importantes.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
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

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
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

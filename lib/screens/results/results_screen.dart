import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../powersync/service.dart';
import 'package:intl/intl.dart';

/// Écran de résultats d'audit avec données réelles depuis PowerSync.
///
/// Reçoit auditId en paramètre de navigation.
/// Affiche le score global, les scores par catégorie et les problèmes.
class ResultsScreen extends StatefulWidget {
  final String auditId;

  const ResultsScreen({
    super.key,
    required this.auditId,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _audit;
  Map<String, int> _categoryScores = {};
  List<Map<String, dynamic>> _issues = [];
  int _globalScore = 0;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await PowerSyncService().getAuditResults(widget.auditId);

      final audit = results['audit'] as Map<String, dynamic>?;
      final categoryScores = results['categoryScores'] as Map<String, int>;
      final issues = results['issues'] as List<Map<String, dynamic>>;

      // Calculer le score global (moyenne des scores par catégorie)
      int globalScore = 0;
      if (categoryScores.isNotEmpty) {
        globalScore = (categoryScores.values.reduce((a, b) => a + b) /
                categoryScores.length)
            .round();
      }

      setState(() {
        _audit = audit;
        _categoryScores = categoryScores;
        _issues = issues;
        _globalScore = globalScore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Conformité satisfaisante';
    if (score >= 50) return 'Conformité moyenne';
    return 'Conformité insuffisante';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sécurité':
      case 'securite':
        return FontAwesomeIcons.shieldHalved;
      case 'hygiène':
      case 'hygiene':
        return FontAwesomeIcons.handSparkles;
      case 'qualité':
      case 'qualite':
        return FontAwesomeIcons.circleCheck;
      case 'conformité':
      case 'conformite':
        return FontAwesomeIcons.scaleBalanced;
      case 'environnement':
        return FontAwesomeIcons.leaf;
      case 'technique':
        return FontAwesomeIcons.wrench;
      default:
        return FontAwesomeIcons.clipboardList;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // État de chargement
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Résultats de l\'audit'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // État d'erreur
    if (_error != null || _audit == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Résultats de l\'audit'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.triangleExclamation,
                  size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Audit non trouvé',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadResults,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Formater la date
    final completedAt = _audit!['completed_at'] as String?;
    final dateStr = completedAt != null
        ? DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.parse(completedAt))
        : 'Non terminé';

    final status = _audit!['status'] as String? ?? 'draft';
    final statusColor = status == 'completed' ? Colors.green : Colors.orange;
    final statusLabel = status == 'completed' ? 'Terminé' : 'En cours';

    return Scaffold(
      appBar: AppBar(
        title: Text(_audit!['title'] as String? ?? 'Résultats'),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.shareNodes),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export à implémenter')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FontAwesomeIcons.circleCheck,
                          size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Score card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(FontAwesomeIcons.trophy,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    'Score Global',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '$_globalScore%',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getScoreLabel(_globalScore),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Category scores
            if (_categoryScores.isNotEmpty) ...[
              Text(
                'Scores par catégorie',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._categoryScores.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryScore(
                      category: entry.key,
                      score: entry.value,
                      color: _getScoreColor(entry.value),
                      icon: _getCategoryIcon(entry.key),
                    ),
                  )),
            ],
            // Issues
            if (_issues.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Points à améliorer',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _IssueCard(
                      title: issue['question'] as String? ?? 'Question',
                      category: issue['category'] as String? ?? 'Général',
                      severity: issue['value'] == 'false' ? 'Haute' : 'Moyenne',
                      recommendation:
                          issue['comment'] as String? ?? 'À corriger',
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Export PDF à implémenter')),
                      );
                    },
                    icon: const Icon(FontAwesomeIcons.download),
                    label: const Text('PDF'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Export Excel à implémenter')),
                      );
                    },
                    icon: const Icon(FontAwesomeIcons.fileExcel),
                    label: const Text('Excel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CategoryScore extends StatelessWidget {
  final String category;
  final int score;
  final Color color;
  final IconData icon;

  const _CategoryScore({
    required this.category,
    required this.score,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$score%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final String title;
  final String category;
  final String severity;
  final String recommendation;

  const _IssueCard({
    required this.title,
    required this.category,
    required this.severity,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = severity == 'Haute'
        ? Colors.red
        : severity == 'Moyenne'
            ? Colors.orange
            : Colors.yellow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
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
                  color: severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    fontSize: 11,
                    color: severityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(FontAwesomeIcons.lightbulb,
                  size: 16, color: Colors.yellow[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

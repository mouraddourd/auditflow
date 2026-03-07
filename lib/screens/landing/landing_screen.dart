import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [
                    const Color(0xFF0a0a0f),
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                  ]
                : [
                    const Color(0xFFf5f5f7),
                    const Color(0xFFe8e8ec),
                    const Color(0xFFd1d1d6),
                  ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Navbar
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'AuditFlow',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Fonctionnalités',
                                style: TextStyle(
                                  color: theme.brightness == Brightness.dark
                                      ? theme.colorScheme.onSurface
                                          .withOpacity(0.7)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.85),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Tarifs',
                                style: TextStyle(
                                  color: theme.brightness == Brightness.dark
                                      ? theme.colorScheme.onSurface
                                          .withOpacity(0.7)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.85),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Commencer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Hero Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 80),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '✨ Nouveau : Audits IA-powered',
                            style: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: theme.brightness == Brightness.dark
                                ? [Colors.white, Colors.white70]
                                : [
                                    theme.colorScheme.onSurface,
                                    theme.colorScheme.onSurface.withOpacity(0.7)
                                  ],
                          ).createShader(bounds),
                          child: Text(
                            'Simplifiez vos audits,\nautomatisez vos contrôles',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Créez, remplissez et analysez vos audits en quelques clics.\nGénérez des rapports professionnels instantanément.',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.brightness == Brightness.dark
                                ? theme.colorScheme.onSurface.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.85),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(FontAwesomeIcons.rocket),
                              label: const Text('Essai gratuit'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 20),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(FontAwesomeIcons.circlePlay),
                              label: const Text('Voir la démo'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 20),
                                side: BorderSide(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Features Section
                  Container(
                    padding: const EdgeInsets.all(48),
                    color: theme.brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey[100],
                    child: Column(
                      children: [
                        Text(
                          'Tout ce dont vous avez besoin',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Une suite complète d\'outils pour gérer vos audits efficacement',
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? theme.colorScheme.onSurface.withOpacity(0.7)
                                : theme.colorScheme.onSurface.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 48),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount =
                                constraints.maxWidth > 900 ? 3 : 1;
                            return Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                _FeatureCard(
                                  icon: FontAwesomeIcons.chartPie,
                                  title: 'Tableau de bord',
                                  description:
                                      'Visualisez vos audits, suivez les progrès et identifiez les priorités.',
                                  width: constraints.maxWidth / crossAxisCount -
                                      32,
                                ),
                                _FeatureCard(
                                  icon: FontAwesomeIcons.clipboardList,
                                  title: 'Audits intelligents',
                                  description:
                                      'Créez des audits depuis des templates ou from scratch avec l\'aide de l\'IA.',
                                  width: constraints.maxWidth / crossAxisCount -
                                      32,
                                ),
                                _FeatureCard(
                                  icon: FontAwesomeIcons.chartLine,
                                  title: 'Rapports détaillés',
                                  description:
                                      'Générez des rapports PDF et Excel avec analyses et recommandations.',
                                  width: constraints.maxWidth / crossAxisCount -
                                      32,
                                ),
                                _FeatureCard(
                                  icon: FontAwesomeIcons.users,
                                  title: 'Collaboration',
                                  description:
                                      'Travaillez en équipe, assignez des audits et suivez les actions.',
                                  width: constraints.maxWidth / crossAxisCount -
                                      32,
                                ),
                                _FeatureCard(
                                  icon: FontAwesomeIcons.bell,
                                  title: 'Notifications',
                                  description:
                                      'Rappels automatiques pour les audits à venir et les actions à compléter.',
                                  width: constraints.maxWidth / crossAxisCount -
                                      32,
                                ),
                                _FeatureCard(
                                  icon: FontAwesomeIcons.shieldHalved,
                                  title: 'Sécurité',
                                  description:
                                      'Données chiffrées, conformité RGPD, authentification à deux facteurs.',
                                  width: constraints.maxWidth / crossAxisCount -
                                      32,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // CTA Section
                  Padding(
                    padding: const EdgeInsets.all(80),
                    child: Container(
                      padding: const EdgeInsets.all(48),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Prêt à simplifier vos audits ?',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Rejoignez des milliers d\'entreprises qui utilisent AuditFlow',
                            style: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? theme.colorScheme.onSurface.withOpacity(0.7)
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.85),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 48, vertical: 20),
                            ),
                            child: const Text(
                              'Démarrer gratuitement',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(48),
                    color: theme.brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.grey[200],
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'À propos',
                                style: TextStyle(
                                    color: theme.brightness == Brightness.dark
                                        ? theme.colorScheme.onSurface
                                            .withOpacity(0.7)
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.85)),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Contact',
                                style: TextStyle(
                                    color: theme.brightness == Brightness.dark
                                        ? theme.colorScheme.onSurface
                                            .withOpacity(0.7)
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.85)),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Mentions légales',
                                style: TextStyle(
                                    color: theme.brightness == Brightness.dark
                                        ? theme.colorScheme.onSurface
                                            .withOpacity(0.7)
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.85)),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'CGU',
                                style: TextStyle(
                                    color: theme.brightness == Brightness.dark
                                        ? theme.colorScheme.onSurface
                                            .withOpacity(0.7)
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.85)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '© 2025 AuditFlow. Tous droits réservés.',
                          style: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.7)),
                        ),
                      ],
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
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double width;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                    : theme.colorScheme.onSurface.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }
}

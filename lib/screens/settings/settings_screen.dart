import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const SettingsScreen({super.key, this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _currentPage;

  void _navigateTo(String page) {
    setState(() => _currentPage = page);
  }

  void _goBack() {
    setState(() => _currentPage = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_currentPage == 'profil') {
      return _ProfilePage(onBack: _goBack);
    } else if (_currentPage == 'securite') {
      return _SecurityPage(onBack: _goBack);
    } else if (_currentPage == 'notifications') {
      return _NotificationsPage(onBack: _goBack);
    } else if (_currentPage == 'apparence') {
      return _AppearancePage(onBack: _goBack);
    } else if (_currentPage == 'categories') {
      return _CategoriesPage(onBack: _goBack);
    } else if (_currentPage == 'abonnement') {
      return _SubscriptionPage(onBack: _goBack);
    }

    final settingsSections = [
      {
        'title': 'Compte',
        'items': [
          {
            'icon': FontAwesomeIcons.user,
            'title': 'Profil',
            'subtitle': 'Gérer vos informations',
            'page': 'profil'
          },
          {
            'icon': FontAwesomeIcons.shieldHalved,
            'title': 'Sécurité',
            'subtitle': 'Mot de passe, 2FA',
            'page': 'securite'
          },
        ],
      },
      {
        'title': 'Application',
        'items': [
          {
            'icon': FontAwesomeIcons.bell,
            'title': 'Notifications',
            'subtitle': 'Firebase, push, email',
            'page': 'notifications'
          },
          {
            'icon': FontAwesomeIcons.palette,
            'title': 'Apparence',
            'subtitle': 'Thème, langue',
            'page': 'apparence'
          },
          {
            'icon': FontAwesomeIcons.folder,
            'title': 'Catégories',
            'subtitle': 'Gérer les catégories',
            'page': 'categories'
          },
        ],
      },
      {
        'title': 'Abonnement',
        'items': [
          {
            'icon': FontAwesomeIcons.creditCard,
            'title': 'Plan & Facturation',
            'subtitle': 'Gérer votre abonnement',
            'page': 'abonnement'
          },
        ],
      },
    ];

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
                        Text(
                          'Paramètres',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.1),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          widget.onLogout?.call();
                        },
                        icon: const Icon(FontAwesomeIcons.rightFromBracket,
                            color: Colors.red),
                        label: const Text('Se déconnecter',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...settingsSections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final section = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section['title'] as String,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ).animate().fadeIn(
                              delay:
                                  Duration(milliseconds: 300 + (index * 100))),
                          const SizedBox(height: 12),
                          Container(
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
                              children: (section['items']
                                      as List<Map<String, dynamic>>)
                                  .map((item) {
                                return ListTile(
                                  leading: Icon(item['icon'] as IconData),
                                  title: Text(item['title'] as String),
                                  subtitle: Text(
                                    item['subtitle'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                  trailing:
                                      const Icon(FontAwesomeIcons.chevronRight),
                                  onTap: () =>
                                      _navigateTo(item['page'] as String),
                                );
                              }).toList(),
                            ),
                          )
                              .animate()
                              .fadeIn(
                                  delay: Duration(
                                      milliseconds: 400 + (index * 100)))
                              .slideX(
                                  begin: 0.1,
                                  delay: Duration(
                                      milliseconds: 400 + (index * 100))),
                          const SizedBox(height: 24),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  final VoidCallback onBack;
  const _ProfilePage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: onBack,
        ),
        title: const Text('Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(FontAwesomeIcons.user,
                  size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: 'Nom complet',
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Téléphone',
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Sauvegarder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityPage extends StatelessWidget {
  final VoidCallback onBack;
  const _SecurityPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: onBack,
        ),
        title: const Text('Sécurité'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mot de passe',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Changer le mot de passe'),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Authentification à deux facteurs',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Activer 2FA'),
              subtitle: const Text(
                  'Sécuriser avec une application d\'authentification'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  final VoidCallback onBack;
  const _NotificationsPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: onBack,
        ),
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir sur cet appareil'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Notifications email'),
            subtitle: const Text('Recevoir par email'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Rappels d\'audit'),
            subtitle: const Text('Rappel pour les audits à compléter'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Nouveaux templates'),
            subtitle: const Text('Nouveaux templates disponibles'),
            value: false,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}

class _AppearancePage extends StatelessWidget {
  final VoidCallback onBack;
  const _AppearancePage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: onBack,
        ),
        title: const Text('Apparence'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Thème'),
            subtitle: Text(themeProvider.isDarkMode ? 'Sombre' : 'Clair'),
            trailing: IconButton(
              icon: Icon(themeProvider.isDarkMode
                  ? FontAwesomeIcons.sun
                  : FontAwesomeIcons.moon),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Langue'),
            subtitle: const Text('Français'),
            trailing: const Icon(FontAwesomeIcons.chevronRight),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CategoriesPage extends StatelessWidget {
  final VoidCallback onBack;
  const _CategoriesPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      {'name': 'Qualité', 'color': Colors.blue, 'count': 12},
      {'name': 'Sécurité', 'color': Colors.red, 'count': 8},
      {'name': 'Environnement', 'color': Colors.green, 'count': 6},
      {'name': 'Hygiène', 'color': Colors.orange, 'count': 5},
      {'name': 'Technique', 'color': Colors.purple, 'count': 4},
      {'name': 'Conformité', 'color': Colors.teal, 'count': 7},
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: onBack,
        ),
        title: const Text('Catégories'),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.plus),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (cat['color'] as Color).withOpacity(0.2),
                child: Icon(FontAwesomeIcons.tag, color: cat['color'] as Color),
              ),
              title: Text(cat['name'] as String),
              subtitle: Text('${cat['count']} templates'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.pen),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubscriptionPage extends StatelessWidget {
  final VoidCallback onBack;
  const _SubscriptionPage({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: onBack,
        ),
        title: const Text('Abonnement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
                  const Icon(FontAwesomeIcons.crown,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    'Plan Pro',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '29€/mois',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Prochaine facturation'),
                      subtitle: const Text('15 Mars 2025'),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Méthode de paiement'),
                      subtitle: const Text('Visa •••• 4242'),
                      trailing: TextButton(
                        onPressed: () {},
                        child: const Text('Modifier'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Annuler l\'abonnement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

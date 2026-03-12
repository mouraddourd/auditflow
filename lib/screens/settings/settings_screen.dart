import 'package:flutter/material.dart';
import '../../core/config/responsive_config.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/theme_provider.dart';
import '../categories/categories_management_screen.dart';
import '../profile/profile_management_screen.dart';
import '../../services/sync_service.dart';

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
      return ProfileManagementScreen(onBack: _goBack);
    } else if (_currentPage == 'securite') {
      return _SecurityPage(onBack: _goBack);
    } else if (_currentPage == 'notifications') {
      return _NotificationsPage(onBack: _goBack);
    } else if (_currentPage == 'apparence') {
      return _AppearancePage(onBack: _goBack);
    } else if (_currentPage == 'categories') {
      return CategoriesManagementScreen(onBack: _goBack);
    } else if (_currentPage == 'abonnement') {
      return _SubscriptionPage(onBack: _goBack);
    } else if (_currentPage == 'sync') {
      return _SyncPage(onBack: _goBack);
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
          {
            'icon': FontAwesomeIcons.rotate,
            'title': 'Synchronisation',
            'subtitle': 'Gérer les données hors-ligne',
            'page': 'sync'
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
                padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
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
        padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
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
    Theme.of(context);
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
        padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
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

class _SyncPage extends StatefulWidget {
  final VoidCallback onBack;
  const _SyncPage({required this.onBack});

  @override
  State<_SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<_SyncPage> {
  final SyncService _syncService = SyncService();
  int _pendingCount = 0;
  int _failedCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _updateCounts();
  }

  void _updateCounts() {
    final pending = _syncService.getPendingMutations();
    setState(() {
      _pendingCount = pending.where((e) => e.retryCount < 3).length;
      _failedCount = pending.where((e) => e.retryCount >= 3).length;
      _isSyncing = _syncService.isSyncing;
    });
  }

  Future<void> _processQueue() async {
    setState(() => _isSyncing = true);
    await _syncService.processQueue();
    _updateCounts();
  }

  Future<void> _retryFailed() async {
    setState(() => _isSyncing = true);
    await _syncService.retryFailed();
    _updateCounts();
  }

  Future<void> _pullAll() async {
    setState(() => _isSyncing = true);
    await _syncService.pullAll();
    _updateCounts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: widget.onBack,
        ),
        title: const Text('Synchronisation'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSyncing
                              ? FontAwesomeIcons.rotate
                              : (_failedCount > 0
                                  ? FontAwesomeIcons.circleExclamation
                                  : FontAwesomeIcons.circleCheck),
                          color: _isSyncing
                              ? Colors.blue
                              : (_failedCount > 0 ? Colors.red : Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isSyncing
                              ? 'Synchronisation en cours...'
                              : (_failedCount > 0
                                  ? 'Erreurs de synchronisation'
                                  : 'Synchronisé'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            'En attente',
                            _pendingCount,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatBox(
                            'Échoués',
                            _failedCount,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Text(
              'Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.rotate),
                    title: const Text('Synchroniser maintenant'),
                    subtitle: const Text('Envoyer les données en attente'),
                    trailing: _isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(FontAwesomeIcons.chevronRight),
                    onTap: _isSyncing ? null : _processQueue,
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      FontAwesomeIcons.arrowsRotate,
                      color: _failedCount > 0 ? Colors.red : null,
                    ),
                    title: const Text('Réessayer les échoués'),
                    subtitle: Text('$_failedCount élément(s) en erreur'),
                    trailing: _isSyncing || _failedCount == 0
                        ? null
                        : const Icon(FontAwesomeIcons.chevronRight),
                    onTap:
                        _isSyncing || _failedCount == 0 ? null : _retryFailed,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.cloudArrowDown),
                    title: const Text('Récupérer les données'),
                    subtitle: const Text('Télécharger depuis le serveur'),
                    trailing: _isSyncing
                        ? null
                        : const Icon(FontAwesomeIcons.chevronRight),
                    onTap: _isSyncing ? null : _pullAll,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.circleInfo,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Les données sont automatiquement synchronisées quand une connexion internet est disponible.',
                      style: theme.textTheme.bodySmall,
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

  Widget _buildStatBox(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

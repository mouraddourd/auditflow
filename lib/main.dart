import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/theme_toggle_button.dart';
import 'core/providers/organization_provider.dart';
import 'services/auth_service.dart';
import 'powersync/service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/organization/organization_onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/audits/audits_list_screen.dart';
import 'screens/templates/templates_list_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/error/init_error_screen.dart';

/// App initialization wrapper that handles startup errors.
///
/// Shows an error screen if PowerSync initialization fails,
/// allowing the user to retry without restarting the app.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  /// Initialization state
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Initializes all required services.
  ///
  /// Currently initializes:
  /// - PowerSync: Local SQLite database for offline-first sync
  ///
  /// If initialization fails, sets [_error] to show error screen.
  Future<void> _initialize() async {
    setState(() {
      _error = null;
    });

    try {
      // PowerSync must be initialized before any database operations.
      // It creates the local SQLite database with our schema.
      await PowerSyncService().initialize();

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint('Initialization failed: $e');
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error screen if initialization failed
    if (_error != null) {
      return InitErrorScreen(
        error: _error!,
        onRetry: _initialize,
      );
    }

    // Show loading while initializing
    if (!_initialized) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initialisation...'),
              ],
            ),
          ),
        ),
      );
    }

    // Initialization successful, run the app
    return const AuditFlowApp();
  }
}

void main() {
  // Required for async operations in main
  WidgetsFlutterBinding.ensureInitialized();

  // Run the initialization wrapper instead of the app directly
  runApp(const AppInitializer());
}

class AuditFlowApp extends StatelessWidget {
  const AuditFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OrganizationProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = context.watch<ThemeProvider>();
          return MaterialApp(
            title: 'AuditFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 480, name: MOBILE),
                const Breakpoint(start: 481, end: 800, name: TABLET),
                const Breakpoint(
                    start: 801, end: double.infinity, name: DESKTOP),
              ],
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isCheckingAuth = true;
  String? _userId;
  String? _token;

  final _authService = AuthService();
  final _powerSyncService = PowerSyncService();

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  /// Check if user is already authenticated on app start
  Future<void> _checkExistingAuth() async {
    final isAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated) {
      final userId = await _authService.getUserId();
      final token = await _authService.getToken();
      if (userId != null && token != null) {
        await _powerSyncService.connect(userId: userId, authToken: token);
        setState(() {
          _isLoggedIn = true;
          _userId = userId;
          _token = token;
        });
      }
    }
    setState(() => _isCheckingAuth = false);
  }

  void _login(String userId, String token) async {
    // Connect PowerSync with the token
    await _powerSyncService.connect(userId: userId, authToken: token);

    setState(() {
      _isLoggedIn = true;
      _userId = userId;
      _token = token;
    });
  }

  void _logout() async {
    // Logout from AuthService (clears stored token)
    await _authService.logout();

    // Disconnect PowerSync
    await _powerSyncService.disconnect();

    final orgProvider = context.read<OrganizationProvider>();
    orgProvider.clear();

    setState(() {
      _isLoggedIn = false;
      _userId = null;
      _token = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking existing auth
    if (_isCheckingAuth) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _login);
    }
    return OrganizationCheckWrapper(
      userId: _userId!,
      token: _token!,
      onLogout: _logout,
    );
  }
}

/// Checks if user has an organization, shows onboarding if not
class OrganizationCheckWrapper extends StatefulWidget {
  final String userId;
  final String token;
  final VoidCallback onLogout;

  const OrganizationCheckWrapper({
    super.key,
    required this.userId,
    required this.token,
    required this.onLogout,
  });

  @override
  State<OrganizationCheckWrapper> createState() =>
      _OrganizationCheckWrapperState();
}

class _OrganizationCheckWrapperState extends State<OrganizationCheckWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeOrganizations();
  }

  Future<void> _initializeOrganizations() async {
    final orgProvider = context.read<OrganizationProvider>();
    await orgProvider.initialize(widget.userId, widget.token);
    setState(() => _isInitializing = false);
  }

  void _onOrgComplete() {
    setState(() => _isInitializing = true);
    _initializeOrganizations();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chargement...',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final orgProvider = context.watch<OrganizationProvider>();

    // No organization -> show onboarding
    if (!orgProvider.hasOrganization) {
      return OrganizationOnboardingScreen(
        userId: widget.userId,
        token: widget.token,
        onComplete: _onOrgComplete,
      );
    }

    // Has organization -> show main app
    return MainScreen(onLogout: widget.onLogout);
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MainScreen({super.key, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              DashboardScreen(
                onNavigate: _navigateTo,
                onNavigateToPage: _navigateToPage,
              ),
              AuditsListScreen(
                onNavigateToPage: _navigateToPage,
              ),
              TemplatesListScreen(
                onNavigateToPage: _navigateToPage,
              ),
              SettingsScreen(onLogout: widget.onLogout),
            ],
          ),
          // Global theme toggle button
          const GlobalThemeFAB(
            offset: Offset(16, 8),
            size: 44,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateTo,
        destinations: [
          NavigationDestination(
            icon: Icon(FontAwesomeIcons.chartPie, size: 22),
            selectedIcon: Icon(FontAwesomeIcons.chartPie, size: 22),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(FontAwesomeIcons.clipboard, size: 22),
            selectedIcon: Icon(FontAwesomeIcons.solidClipboard, size: 22),
            label: 'Audits',
          ),
          NavigationDestination(
            icon: Icon(FontAwesomeIcons.fileLines, size: 22),
            selectedIcon: Icon(FontAwesomeIcons.solidFileLines, size: 22),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(FontAwesomeIcons.gear, size: 22),
            selectedIcon: Icon(FontAwesomeIcons.gear, size: 22),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

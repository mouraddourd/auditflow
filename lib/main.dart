import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/theme_toggle_button.dart';
import 'core/providers/organization_provider.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'hive/service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/organization/organization_onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/audits/audits_list_screen.dart';
import 'screens/templates/templates_list_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/error/init_error_screen.dart';
import 'core/splash/splash_screen.dart';

/// Global RouteObserver for tracking route changes
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

/// App initialization wrapper that handles startup errors.
///
/// Shows an error screen if Hive initialization fails,
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
  /// - Hive: Local storage for offline-first functionality
  ///
  /// If initialization fails, sets [_error] to show error screen.
  Future<void> _initialize() async {
    setState(() {
      _error = null;
    });

    try {
      // Hive must be initialized before any database operations
      await HiveService().initialize();

      // Initialize sync service for offline-first functionality
      await SyncService().initialize();

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

    // Show splash screen while initializing
    if (!_initialized) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: SplashScreen(
          onComplete: () {},
          isLoading: true,
        ),
      );
    }

    // Initialization successful, run the app
    return const AuditFlowApp();
  }
}

void main() async {
  // Required for async operations in main
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for intl date formatting
  await initializeDateFormatting('fr_FR', null);

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
            navigatorObservers: [routeObserver],
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
  final _hiveService = HiveService();

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  /// Check if user is already authenticated on app start
  Future<void> _checkExistingAuth() async {
    // Set a maximum time for auth check to prevent infinite loading
    bool completed = false;

    // Start auth check
    _authService.isAuthenticated().then((isAuthenticated) async {
      if (completed) return; // Already timed out
      completed = true;

      if (isAuthenticated) {
        final userId = await _authService.getUserId();
        final token = await _authService.getToken();
        if (userId != null && token != null) {
          _hiveService.setUser(userId);
          if (mounted) {
            setState(() {
              _isLoggedIn = true;
              _userId = userId;
              _token = token;
            });
          }
        }
      }
      if (mounted) setState(() => _isCheckingAuth = false);
    }).catchError((e) {
      debugPrint('Auth check failed: $e');
      if (mounted) setState(() => _isCheckingAuth = false);
    });

    // Timeout after 3 seconds - force show login
    await Future.delayed(const Duration(seconds: 3));
    if (!completed && mounted) {
      completed = true;
      setState(() => _isCheckingAuth = false);
    }
  }

  void _login(String userId, String token,
      {Map<String, dynamic>? organization}) async {
    _hiveService.setUser(userId);

    // Save organization to Hive if provided
    if (organization != null) {
      await _hiveService.saveOrganization(organization);
    }

    setState(() {
      _isLoggedIn = true;
      _userId = userId;
      _token = token;
    });
  }

  void _logout() async {
    await _authService.logout();
    await _hiveService.clear();

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
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.blue,
            ),
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

  Future<bool> _navigateToPage(Widget page) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
    return result ?? false;
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/theme_toggle_button.dart';
import 'core/providers/organization_provider.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/organization/organization_onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/audits/audits_list_screen.dart';
import 'screens/audits/create_audit_screen.dart';
import 'screens/audits/audit_fill_screen.dart';
import 'screens/templates/templates_list_screen.dart';
import 'screens/templates/create_template_screen.dart';
import 'screens/results/results_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() {
  runApp(const AuditFlowApp());
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
  String? _userId;
  String? _token;

  void _login(String userId, String token) {
    setState(() {
      _isLoggedIn = true;
      _userId = userId;
      _token = token;
    });
  }

  void _logout() {
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

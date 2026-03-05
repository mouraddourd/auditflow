import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/theme_toggle_button.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/login_screen.dart';
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
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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

  void _login() {
    setState(() => _isLoggedIn = true);
  }

  void _logout() {
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _login);
    }
    return MainScreen(onLogout: _logout);
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

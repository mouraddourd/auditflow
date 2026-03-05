import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/theme_toggle_button.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String userId, String token)? onLogin;
  const LoginScreen({super.key, this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    if (!_isLogin && name.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre nom');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = _isLogin
          ? await _authService.login(email: email, password: password)
          : await _authService.register(
              email: email, password: password, name: name);

      if (result.success && result.user != null && result.token != null) {
        widget.onLogin?.call(result.user!.id, result.token!);
      } else {
        setState(() => _errorMessage = result.error ?? 'Erreur inconnue');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo with animation
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
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: -0.3),
                        const SizedBox(height: 8),
                        Text(
                          'Simplifiez vos audits, automatisez vos contrôles',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[400]
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                        const SizedBox(height: 32),
                        // Tabs
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = true),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isLogin
                                        ? theme.colorScheme.primary
                                            .withOpacity(0.2)
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Connexion',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isLogin
                                          ? theme.colorScheme.primary
                                          : theme.brightness == Brightness.dark
                                              ? Colors.grey[400]
                                              : theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = false),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isLogin
                                        ? theme.colorScheme.primary
                                            .withOpacity(0.2)
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Inscription',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !_isLogin
                                          ? theme.colorScheme.primary
                                          : theme.brightness == Brightness.dark
                                              ? Colors.grey[400]
                                              : theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(FontAwesomeIcons.circleExclamation,
                                    color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Form
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nom complet',
                              prefixIcon: const Icon(FontAwesomeIcons.user),
                              filled: true,
                              fillColor: theme.brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(FontAwesomeIcons.envelope),
                            filled: true,
                            fillColor: theme.brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(FontAwesomeIcons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? FontAwesomeIcons.eyeSlash
                                    : FontAwesomeIcons.eye,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            filled: true,
                            fillColor: theme.brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Se connecter' : 'S\'inscrire',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Divider
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[700]
                                        : Colors.grey[300])),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'ou',
                                style: TextStyle(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.grey[500]
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                ),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[700]
                                        : Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Google button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(FontAwesomeIcons.google, size: 20),
                            label: const Text('Continuer avec Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (_isLogin) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Global theme toggle button
          const GlobalThemeFAB(
            offset: Offset(16, 16),
            size: 44,
          ),
        ],
      ),
    );
  }
}

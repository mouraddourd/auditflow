import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/config/responsive_config.dart';
import '../../services/invitation_service.dart';
import '../../services/auth_service.dart';

/// Screen displayed when user clicks an invitation link
/// Shows organization info and prompts login/register
class InvitationScreen extends StatefulWidget {
  final String token;
  final void Function(String userId, String token,
      {Map<String, dynamic>? organization})? onLogin;
  final VoidCallback? onInvitationAccepted;

  const InvitationScreen({
    super.key,
    required this.token,
    this.onLogin,
    this.onInvitationAccepted,
  });

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  final _invitationService = InvitationService();
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  InvitationInfo? _invitationInfo;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvitationInfo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitationInfo() async {
    try {
      final info = await _invitationService.getInvitationInfo(widget.token);
      if (mounted) {
        setState(() {
          _invitationInfo = info;
          _emailController.text = info.email;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_invitationInfo == null) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs');
      return;
    }

    if (!_isLogin && name.isEmpty) {
      setState(() => _error = 'Veuillez entrer votre nom');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // Login or register
      final result = _isLogin
          ? await _authService.login(email: email, password: password)
          : await _authService.register(
              email: email, password: password, name: name);

      if (!result.success || result.user == null || result.token == null) {
        setState(() => _error = result.error ?? 'Erreur inconnue');
        return;
      }

      // Accept invitation
      await _invitationService.acceptInvitation(widget.token);

      // Notify parent
      widget.onLogin?.call(
        result.user!.id,
        result.token!,
        organization: result.organization,
      );
      widget.onInvitationAccepted?.call();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_error != null && _invitationInfo == null) {
      return _buildErrorScreen(theme);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildHeader(theme),
              const SizedBox(height: 32),
              _buildInvitationCard(theme),
              const SizedBox(height: 32),
              _buildAuthForm(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.circleExclamation,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Invitation invalide',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            FontAwesomeIcons.userPlus,
            size: 32,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: -0.2, duration: 400.ms),
        const SizedBox(height: 16),
        Text(
          'Invitation',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: -0.1, duration: 400.ms),
      ],
    );
  }

  Widget _buildInvitationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.building,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _invitationInfo!.organizationName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Organisation',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.user,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _invitationInfo!.invitedByName,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Vous a invité',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.clock,
                  color: _invitationInfo!.isExpired
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _invitationInfo!.isExpired
                      ? 'Expirée'
                      : 'Expire le ${_formatDate(_invitationInfo!.expiresAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _invitationInfo!.isExpired
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms);
  }

  Widget _buildAuthForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle login/register
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _isLogin = true),
                style: TextButton.styleFrom(
                  backgroundColor:
                      _isLogin ? theme.colorScheme.primaryContainer : null,
                ),
                child: Text(
                  'Connexion',
                  style: TextStyle(
                    color: _isLogin
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _isLogin = false),
                style: TextButton.styleFrom(
                  backgroundColor:
                      !_isLogin ? theme.colorScheme.primaryContainer : null,
                ),
                child: Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: !_isLogin
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Name field (register only)
        if (!_isLogin) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              prefixIcon: Icon(FontAwesomeIcons.user),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(FontAwesomeIcons.envelope),
          ),
        ),
        const SizedBox(height: 16),

        // Password field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: const Icon(FontAwesomeIcons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? FontAwesomeIcons.eye
                    : FontAwesomeIcons.eyeSlash,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),

        // Error message
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.circleExclamation,
                  color: theme.colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Submit button
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isLogin ? 'Se connecter' : 'Créer un compte'),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

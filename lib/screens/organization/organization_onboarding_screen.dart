import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/providers/organization_provider.dart';
import '../../core/widgets/theme_toggle_button.dart';

class OrganizationOnboardingScreen extends StatefulWidget {
  final String userId;
  final String token;
  final VoidCallback onComplete;

  const OrganizationOnboardingScreen({
    super.key,
    required this.userId,
    required this.token,
    required this.onComplete,
  });

  @override
  State<OrganizationOnboardingScreen> createState() => _OrganizationOnboardingScreenState();
}

class _OrganizationOnboardingScreenState extends State<OrganizationOnboardingScreen> {
  final _nameController = TextEditingController();
  final _inviteTokenController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _inviteTokenController.dispose();
    super.dispose();
  }

  Future<void> _createOrganization() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez entrer un nom pour votre organisation');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    final orgProvider = context.read<OrganizationProvider>();
    final org = await orgProvider.createOrganization(
      _nameController.text.trim(),
      widget.userId,
      widget.token,
    );

    if (org != null) {
      widget.onComplete();
    } else {
      setState(() {
        _isCreating = false;
        _error = orgProvider.error ?? 'Erreur lors de la création';
      });
    }
  }

  Future<void> _joinOrganization() async {
    if (_inviteTokenController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez entrer le token d\'invitation');
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    final orgProvider = context.read<OrganizationProvider>();
    final org = await orgProvider.joinOrganization(
      _inviteTokenController.text.trim(),
      widget.userId,
      widget.token,
    );

    if (org != null) {
      widget.onComplete();
    } else {
      setState(() {
        _isJoining = false;
        _error = orgProvider.error ?? 'Token invalide ou expiré';
      });
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
                  constraints: const BoxConstraints(maxWidth: 500),
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
                        // Logo
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
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
                        const SizedBox(height: 8),
                        Text(
                          'Bienvenue ! Créez ou rejoignez une organisation',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[400]
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                        const SizedBox(height: 32),

                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Create organization section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    FontAwesomeIcons.building,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Créer une organisation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Parfait pour démarrer avec votre équipe.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nom de l\'organisation',
                                  prefixIcon: const Icon(FontAwesomeIcons.briefcase, size: 18),
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
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isCreating ? null : _createOrganization,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isCreating
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Créer'),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'ou',
                                style: TextStyle(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Join organization section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.secondary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    FontAwesomeIcons.link,
                                    color: theme.colorScheme.secondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Rejoindre une organisation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Vous avez reçu un lien d\'invitation ?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _inviteTokenController,
                                decoration: InputDecoration(
                                  labelText: 'Token d\'invitation',
                                  prefixIcon: const Icon(FontAwesomeIcons.key, size: 18),
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
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isJoining ? null : _joinOrganization,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: theme.colorScheme.secondary),
                                    foregroundColor: theme.colorScheme.secondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isJoining
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        )
                                      : const Text('Rejoindre'),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const GlobalThemeFAB(
            offset: Offset(16, 16),
            size: 44,
          ),
        ],
      ),
    );
  }
}

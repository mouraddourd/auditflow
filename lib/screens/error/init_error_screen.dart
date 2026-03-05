import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Error screen shown when app initialization fails.
///
/// This is displayed when critical services like PowerSync
/// fail to initialize on app startup. Provides a retry button
/// to attempt re-initialization without restarting the app.
class InitErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const InitErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.dark
                  ? [
                      const Color(0xFF0a0a0f),
                      const Color(0xFF1a1a2e),
                    ]
                  : [
                      const Color(0xFFf5f5f7),
                      const Color(0xFFe8e8ec),
                    ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FontAwesomeIcons.triangleExclamation,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Erreur d\'initialisation',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'L\'application n\'a pas pu démarrer correctement.\n'
                    'Vérifiez votre connexion et réessayez.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Error details (expandable)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.bug,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Détails de l\'erreur',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(FontAwesomeIcons.rotate),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

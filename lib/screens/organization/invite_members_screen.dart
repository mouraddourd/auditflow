import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/responsive_config.dart';
import '../../services/invitation_service.dart';

/// Screen for admins to invite members to organization
class InviteMembersScreen extends StatefulWidget {
  final String organizationId;
  final String organizationName;
  final Future<bool> Function(Widget)? onNavigateToPage;

  const InviteMembersScreen({
    super.key,
    required this.organizationId,
    required this.organizationName,
    this.onNavigateToPage,
  });

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  final _invitationService = InvitationService();
  final _emailController = TextEditingController();
  final _scrollController = ScrollController();

  List<Invitation> _invitations = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitations() async {
    try {
      final invitations = await _invitationService
          .getOrganizationInvitations(widget.organizationId);
      if (mounted) {
        setState(() {
          _invitations = invitations;
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

  Future<void> _createInvitation() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _error = 'Veuillez entrer un email');
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final invitation = await _invitationService.createInvitation(
        organizationId: widget.organizationId,
        email: email,
      );

      _emailController.clear();

      // Show success with share option
      if (mounted) {
        setState(() {
          _invitations.insert(0, invitation);
          _isCreating = false;
        });

        _showShareDialog(invitation);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isCreating = false;
        });
      }
    }
  }

  void _showShareDialog(Invitation invitation) {
    final link = _invitationService.getInvitationLink(invitation.token);
    final webLink = _invitationService.getWebInvitationLink(invitation.token);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(FontAwesomeIcons.check, color: Colors.green),
            const SizedBox(width: 12),
            const Text('Invitation créée'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invitation envoyée à ${invitation.email}'),
            const SizedBox(height: 16),
            Text(
              'Lien à partager:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              webLink,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Share.share(
                'Rejoignez ${widget.organizationName} sur AuditFlow!\n\n$link',
                subject: 'Invitation à ${widget.organizationName}',
              );
            },
            icon: const Icon(FontAwesomeIcons.share, size: 16),
            label: const Text('Partager'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInvitation(Invitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'invitation'),
        content: Text(
          'Voulez-vous annuler l\'invitation envoyée à ${invitation.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _invitationService.deleteInvitation(invitation.id);
      if (mounted) {
        setState(() {
          _invitations.removeWhere((i) => i.id == invitation.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation annulée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inviter des membres'),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: theme.colorScheme.primary),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(ResponsiveConfig.getPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Organization info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
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
                                  widget.organizationName,
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
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create invitation form
                  Text(
                    'Inviter par email',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(FontAwesomeIcons.envelope),
                          ),
                          onSubmitted: (_) => _createInvitation(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isCreating ? null : _createInvitation,
                        child: _isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(FontAwesomeIcons.plus),
                      ),
                    ],
                  ),

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 12),
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

                  const SizedBox(height: 32),

                  // Pending invitations list
                  Text(
                    'Invitations en attente',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  if (_invitations.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              FontAwesomeIcons.inbox,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune invitation en attente',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _invitations.length,
                      itemBuilder: (context, index) {
                        final invitation = _invitations[index];
                        return _buildInvitationCard(invitation, theme);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInvitationCard(Invitation invitation, ThemeData theme) {
    final isExpired = invitation.isExpired || invitation.status == 'expired';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isExpired ? FontAwesomeIcons.clock : FontAwesomeIcons.envelope,
          color:
              isExpired ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        title: Text(invitation.email),
        subtitle: Text(
          isExpired
              ? 'Expirée'
              : 'Expire le ${_formatDate(invitation.expiresAt)}',
          style: TextStyle(
            color: isExpired
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isExpired)
              IconButton(
                icon: const Icon(FontAwesomeIcons.share, size: 18),
                onPressed: () {
                  final link =
                      _invitationService.getInvitationLink(invitation.token);
                  Share.share(
                    'Rejoignez ${widget.organizationName} sur AuditFlow!\n\n$link',
                    subject: 'Invitation à ${widget.organizationName}',
                  );
                },
              ),
            IconButton(
              icon: Icon(
                FontAwesomeIcons.trash,
                size: 18,
                color: theme.colorScheme.error,
              ),
              onPressed: () => _deleteInvitation(invitation),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1, duration: 200.ms);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

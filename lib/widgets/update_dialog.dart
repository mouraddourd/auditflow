import 'package:flutter/material.dart';
import 'package:auditflow/services/update_service.dart';

/// Widget de dialogue pour afficher les notifications de mise à jour
class UpdateDialog extends StatefulWidget {
  final VersionInfo version;
  final UpdateService updateService;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.updateService,
    this.onDismiss,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  int _downloadProgress = 0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.system_update, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Mise à jour disponible'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${widget.version.fullVersion}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Build ${widget.version.buildNumber}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Taille: ${widget.version.androidSizeFormatted}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          if (widget.version.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.version.releaseNotes,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vos données seront préservées',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _downloadProgress / 100,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 8),
            Text(
              'Téléchargement: $_downloadProgress%',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style:
                              TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isDownloading ? null : _startDownload,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Réessayer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDownloading
              ? null
              : () {
                  Navigator.of(context).pop();
                  widget.onDismiss?.call();
                },
          child: const Text('Plus tard'),
        ),
        ElevatedButton.icon(
          onPressed: _isDownloading ? null : _startDownload,
          icon: _isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(_isDownloading ? 'Téléchargement...' : 'Mettre à jour'),
        ),
      ],
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      final filePath = await widget.updateService.downloadApk(
        widget.version,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = ((received / total) * 100).round();
            });
          }
        },
      );

      final installed = await widget.updateService.installApk(filePath);
      if (!installed && mounted) {
        setState(() {
          _error =
              'Erreur lors de l\'installation. Vérifiez que vous autorisez les installations d\'applications inconnues.';
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isDownloading = false;
        });
      }
    }
  }
}

/// Affiche un dialogue de mise à jour si une nouvelle version est disponible
Future<void> checkAndShowUpdateDialog(
  BuildContext context,
  UpdateService updateService,
) async {
  final version = await updateService.checkForUpdate();

  if (version != null && context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(
        version: version,
        updateService: updateService,
      ),
    );
  }
}

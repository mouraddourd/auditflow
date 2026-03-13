import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/sync_service.dart';

/// Widget that displays sync status in the AppBar
class SyncStatusIndicator extends StatefulWidget {
  final bool showLabel;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = false,
    this.onTap,
  });

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  final SyncService _syncService = SyncService();
  int _pendingCount = 0;
  int _failedCount = 0;
  bool _isSyncing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _updateCounts();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _updateCounts());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _updateCounts() {
    final pending = _syncService.getPendingMutations();
    final pendingCount = pending.where((e) => e.retryCount < 3).length;
    final failedCount = pending.where((e) => e.retryCount >= 3).length;

    setState(() {
      _pendingCount = pendingCount;
      _failedCount = failedCount;
      _isSyncing = _syncService.isSyncing;
    });
  }

  Future<void> _handleTap() async {
    if (_failedCount > 0) {
      // Retry failed mutations
      await _syncService.retryFailed();
    } else if (_pendingCount > 0) {
      // Process pending queue
      await _syncService.processQueue();
    } else {
      // Pull latest data
      await _syncService.pullAll();
    }
    _updateCounts();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Determine status
    SyncDisplayStatus status;
    if (_isSyncing) {
      status = SyncDisplayStatus.syncing;
    } else if (_failedCount > 0) {
      status = SyncDisplayStatus.failed;
    } else if (_pendingCount > 0) {
      status = SyncDisplayStatus.pending;
    } else {
      status = SyncDisplayStatus.synced;
    }

    final tooltip = _failedCount > 0
        ? 'Synchronisation en échec ($_failedCount)'
        : _pendingCount > 0
            ? 'Synchronisation en attente ($_pendingCount)'
            : 'Synchronisation (appuyer pour forcer)';

    final label = switch (status) {
      SyncDisplayStatus.failed => 'Failed ($_failedCount)',
      SyncDisplayStatus.pending => 'Pending ($_pendingCount)',
      _ => status.label,
    };

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: status.backgroundColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: status.backgroundColor.withValues(alpha: 0.4),
                width: 1.2),
            boxShadow: [
              BoxShadow(
                color: status.backgroundColor.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSyncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: status.iconColor,
                  ),
                )
              else
                Icon(
                  status.icon,
                  size: 16,
                  color: status.iconColor,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: status.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_pendingCount > 0 || _failedCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_failedCount > 0 ? _failedCount : _pendingCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum SyncDisplayStatus {
  synced,
  pending,
  syncing,
  failed,
}

extension SyncDisplayStatusExtension on SyncDisplayStatus {
  IconData get icon {
    switch (this) {
      case SyncDisplayStatus.synced:
        return FontAwesomeIcons.circleCheck;
      case SyncDisplayStatus.pending:
        return FontAwesomeIcons.clock;
      case SyncDisplayStatus.syncing:
        return FontAwesomeIcons.rotate;
      case SyncDisplayStatus.failed:
        return FontAwesomeIcons.circleExclamation;
    }
  }

  Color get iconColor {
    switch (this) {
      case SyncDisplayStatus.synced:
        return Colors.green;
      case SyncDisplayStatus.pending:
        return Colors.orange;
      case SyncDisplayStatus.syncing:
        return Colors.blue;
      case SyncDisplayStatus.failed:
        return Colors.red;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case SyncDisplayStatus.synced:
        return Colors.green;
      case SyncDisplayStatus.pending:
        return Colors.orange;
      case SyncDisplayStatus.syncing:
        return Colors.blue;
      case SyncDisplayStatus.failed:
        return Colors.red;
    }
  }

  Color get textColor {
    switch (this) {
      case SyncDisplayStatus.synced:
        return Colors.green.shade700;
      case SyncDisplayStatus.pending:
        return Colors.orange.shade700;
      case SyncDisplayStatus.syncing:
        return Colors.blue.shade700;
      case SyncDisplayStatus.failed:
        return Colors.red.shade700;
    }
  }

  String get label {
    switch (this) {
      case SyncDisplayStatus.synced:
        return 'Synced';
      case SyncDisplayStatus.pending:
        return 'Pending';
      case SyncDisplayStatus.syncing:
        return 'Syncing...';
      case SyncDisplayStatus.failed:
        return 'Failed';
    }
  }
}

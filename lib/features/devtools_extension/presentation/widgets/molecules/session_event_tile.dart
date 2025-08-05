import 'package:flutter/material.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:intl/intl.dart';

class SessionEventTile extends StatelessWidget {
  final SessionEvent event;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

  const SessionEventTile({
    super.key,
    required this.event,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm:ss.SSS');

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          border: Border(
            left: BorderSide(
              color: isActive ? theme.colorScheme.primary : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: theme.dividerColor),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventIcon(theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getEventTitle(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isActive ? FontWeight.bold : null,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeFormat.format(event.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildEventDetails(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventIcon(ThemeData theme) {
    IconData icon;
    Color color;

    switch (event.type) {
      case 'log':
        final logEvent = event as LogEvent;
        icon = _getLogIcon(logEvent.logEntry.level);
        color = _getLogColor(logEvent.logEntry.level);
        break;
      case 'user_action':
        icon = Icons.touch_app;
        color = Colors.blue;
        break;
      case 'network':
        icon = Icons.cloud;
        color = Colors.teal;
        break;
      case 'navigation':
        icon = Icons.navigation;
        color = Colors.purple;
        break;
      case 'app_state':
        icon = Icons.phonelink_setup;
        color = Colors.orange;
        break;
      default:
        icon = Icons.event;
        color = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  String _getEventTitle() {
    switch (event.type) {
      case 'log':
        final logEvent = event as LogEvent;
        return '[${logEvent.logEntry.level.name.toUpperCase()}] ${logEvent.logEntry.category ?? 'Log'}';
      case 'user_action':
        final actionEvent = event as UserActionEvent;
        return 'User Action: ${actionEvent.action}';
      case 'network':
        final networkEvent = event as NetworkEvent;
        return '${networkEvent.method} ${Uri.parse(networkEvent.url).path}';
      case 'navigation':
        final navEvent = event as ScreenNavigationEvent;
        return 'Navigate: ${navEvent.fromScreen} → ${navEvent.toScreen}';
      case 'app_state':
        final stateEvent = event as AppStateEvent;
        return 'App State: ${stateEvent.state}';
      default:
        return 'Unknown Event';
    }
  }

  Widget _buildEventDetails(ThemeData theme) {
    switch (event.type) {
      case 'log':
        final logEvent = event as LogEvent;
        return Text(
          logEvent.logEntry.message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      case 'user_action':
        final actionEvent = event as UserActionEvent;
        return Row(
          children: [
            if (actionEvent.screen != null) ...[
              Icon(Icons.mobile_screen_share, size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                actionEvent.screen!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionEvent.properties != null && actionEvent.properties!.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${actionEvent.properties!.length} props',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ],
        );
      case 'network':
        final networkEvent = event as NetworkEvent;
        return Row(
          children: [
            if (networkEvent.statusCode != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusCodeColor(networkEvent.statusCode!).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${networkEvent.statusCode}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getStatusCodeColor(networkEvent.statusCode!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (networkEvent.duration != null)
              Text(
                '${networkEvent.duration!.inMilliseconds}ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        );
      case 'navigation':
        final navEvent = event as ScreenNavigationEvent;
        if (navEvent.parameters != null && navEvent.parameters!.isNotEmpty) {
          return Text(
            'Params: ${navEvent.parameters!.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        return const SizedBox.shrink();
      case 'app_state':
        final stateEvent = event as AppStateEvent;
        if (stateEvent.details != null && stateEvent.details!.isNotEmpty) {
          return Text(
            stateEvent.details!.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  IconData _getLogIcon(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Icons.text_snippet;
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
      case LogLevel.fatal:
        return Icons.dangerous;
    }
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.fatal:
        return Colors.red.shade900;
    }
  }

  Color _getStatusCodeColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return Colors.green;
    } else if (statusCode >= 300 && statusCode < 400) {
      return Colors.blue;
    } else if (statusCode >= 400 && statusCode < 500) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
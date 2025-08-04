import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voo_logging/core/domain/extensions/log_level_extensions.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/atoms/log_level_chip.dart';
import 'package:voo_logging/features/logging/domain/entities/log_entry.dart';

class LogDetailsPanel extends StatelessWidget {
  final LogEntry log;
  final VoidCallback? onClose;

  const LogDetailsPanel({
    super.key,
    required this.log,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Message',
                    SelectableText(log.message),
                    theme,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Timestamp',
                    log.timestamp.toIso8601String(),
                    theme,
                  ),
                  _buildInfoRow('Level', log.level.displayName, theme),
                  if (log.category != null) _buildInfoRow('Category', log.category!, theme),
                  if (log.tag != null) _buildInfoRow('Tag', log.tag!, theme),
                  if (log.userId != null) _buildInfoRow('User ID', log.userId!, theme),
                  if (log.sessionId != null) _buildInfoRow('Session ID', log.sessionId!, theme),
                  if (log.error != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      'Error',
                      SelectableText(
                        log.error.toString(),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      theme,
                    ),
                  ],
                  if (log.stackTrace != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      'Stack Trace',
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          log.stackTrace!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      theme,
                    ),
                  ],
                  if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      'Metadata',
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          const JsonEncoder.withIndent('  ').convert(log.metadata),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      theme,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
            ),
          ),
        ),
        child: Row(
          children: [
            LogLevelChip(level: log.level),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Log Details',
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyAllToClipboard(context),
              tooltip: 'Copy all details',
            ),
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                tooltip: 'Close details',
              ),
          ],
        ),
      );

  Widget _buildSection(String title, Widget content, ThemeData theme) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      );

  Widget _buildInfoRow(String label, String value, ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );

  void _copyAllToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('=== LOG DETAILS ===');
    buffer.writeln('Timestamp: ${log.timestamp.toIso8601String()}');
    buffer.writeln('Level: ${log.level.displayName}');
    if (log.category != null) buffer.writeln('Category: ${log.category}');
    if (log.tag != null) buffer.writeln('Tag: ${log.tag}');
    if (log.userId != null) buffer.writeln('User ID: ${log.userId}');
    if (log.sessionId != null) buffer.writeln('Session ID: ${log.sessionId}');
    buffer.writeln('\nMessage:\n${log.message}');

    if (log.error != null) {
      buffer.writeln('\nError:\n${log.error}');
    }

    if (log.stackTrace != null) {
      buffer.writeln('\nStack Trace:\n${log.stackTrace}');
    }

    if (log.metadata != null && log.metadata!.isNotEmpty) {
      buffer.writeln('\nMetadata:');
      buffer.writeln(const JsonEncoder.withIndent('  ').convert(log.metadata));
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log details copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

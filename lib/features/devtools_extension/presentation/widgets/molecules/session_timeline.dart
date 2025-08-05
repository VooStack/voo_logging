import 'package:flutter/material.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';

class SessionTimeline extends StatefulWidget {
  final List<SessionEvent> events;
  final int currentIndex;
  final void Function(int) onSeek;

  const SessionTimeline({
    super.key,
    required this.events,
    required this.currentIndex,
    required this.onSeek,
  });

  @override
  State<SessionTimeline> createState() => _SessionTimelineState();
}

class _SessionTimelineState extends State<SessionTimeline> {
  double? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final firstEvent = widget.events.first;
    final lastEvent = widget.events.last;
    final totalDuration = lastEvent.timestamp.difference(firstEvent.timestamp);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: MouseRegion(
        onHover: (event) {
          setState(() {
            _hoverPosition = event.localPosition.dx;
          });
        },
        onExit: (_) {
          setState(() => _hoverPosition = null);
        },
        child: GestureDetector(
          onTapDown: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final width = box.size.width - 32; // Account for padding
            final position = (details.localPosition.dx - 16).clamp(0.0, width);
            final ratio = position / width;
            final targetIndex = (ratio * (widget.events.length - 1)).round();
            widget.onSeek(targetIndex);
          },
          child: CustomPaint(
            painter: _TimelinePainter(
              events: widget.events,
              currentIndex: widget.currentIndex,
              totalDuration: totalDuration,
              theme: theme,
              hoverPosition: _hoverPosition,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<SessionEvent> events;
  final int currentIndex;
  final Duration totalDuration;
  final ThemeData theme;
  final double? hoverPosition;

  _TimelinePainter({
    required this.events,
    required this.currentIndex,
    required this.totalDuration,
    required this.theme,
    this.hoverPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (events.isEmpty) return;

    final paint = Paint()
      ..color = theme.colorScheme.surfaceContainerHighest
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw timeline background
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Draw progress
    if (currentIndex > 0) {
      paint.color = theme.colorScheme.primary;
      final progress = currentIndex / (events.length - 1);
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width * progress, size.height / 2),
        paint,
      );
    }

    // Draw event markers
    final markerPaint = Paint()..style = PaintingStyle.fill;
    final firstTimestamp = events.first.timestamp;

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final timeDiff = event.timestamp.difference(firstTimestamp);
      final position = totalDuration.inMilliseconds > 0
          ? (timeDiff.inMilliseconds / totalDuration.inMilliseconds) * size.width
          : 0.0;

      // Skip drawing markers too close together
      if (i > 0 && events.length > 50) {
        final prevPosition = _getEventPosition(i - 1, size.width);
        if ((position - prevPosition).abs() < 3) continue;
      }

      final color = _getEventColor(event);
      markerPaint.color = i == currentIndex 
          ? color 
          : color.withValues(alpha: 0.5);

      final radius = i == currentIndex ? 6.0 : 4.0;
      canvas.drawCircle(
        Offset(position, size.height / 2),
        radius,
        markerPaint,
      );
    }

    // Draw hover indicator
    if (hoverPosition != null) {
      final hoverPaint = Paint()
        ..color = theme.colorScheme.onSurface.withValues(alpha: 0.3)
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(hoverPosition!, 0),
        Offset(hoverPosition!, size.height),
        hoverPaint,
      );
    }

    // Draw current position indicator
    final currentPosition = _getEventPosition(currentIndex, size.width);
    final indicatorPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;

    // Draw triangle pointer
    final path = Path()
      ..moveTo(currentPosition, 0)
      ..lineTo(currentPosition - 6, -8)
      ..lineTo(currentPosition + 6, -8)
      ..close();

    canvas.drawPath(path, indicatorPaint);
  }

  double _getEventPosition(int index, double width) {
    if (events.isEmpty || index >= events.length) return 0;
    
    final firstTimestamp = events.first.timestamp;
    final event = events[index];
    final timeDiff = event.timestamp.difference(firstTimestamp);
    
    return totalDuration.inMilliseconds > 0
        ? (timeDiff.inMilliseconds / totalDuration.inMilliseconds) * width
        : 0.0;
  }

  Color _getEventColor(SessionEvent event) {
    switch (event.type) {
      case 'log':
        final logEvent = event as LogEvent;
        switch (logEvent.logEntry.level.name) {
          case 'error':
          case 'fatal':
            return Colors.red;
          case 'warning':
            return Colors.orange;
          case 'info':
            return Colors.green;
          default:
            return Colors.blue;
        }
      case 'user_action':
        return Colors.purple;
      case 'network':
        return Colors.teal;
      case 'navigation':
        return Colors.indigo;
      case 'app_state':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.hoverPosition != hoverPosition ||
        oldDelegate.events.length != events.length;
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_state.dart';

class LogRateIndicator extends StatefulWidget {
  const LogRateIndicator({super.key});

  @override
  State<LogRateIndicator> createState() => _LogRateIndicatorState();
}

class _LogRateIndicatorState extends State<LogRateIndicator> {
  Timer? _timer;
  int _previousLogCount = 0;
  double _logsPerSecond = 0;
  final List<double> _rateHistory = [];
  static const int _maxHistorySize = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = context.read<LogBloc>().state;
      final currentCount = state.logs.length;
      final newLogs = currentCount - _previousLogCount;
      
      setState(() {
        _logsPerSecond = newLogs.toDouble();
        _previousLogCount = currentCount;
        
        _rateHistory.add(_logsPerSecond);
        if (_rateHistory.length > _maxHistorySize) {
          _rateHistory.removeAt(0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<LogBloc, LogState>(
      builder: (context, state) {
        final avgRate = _rateHistory.isEmpty 
            ? 0.0 
            : _rateHistory.reduce((a, b) => a + b) / _rateHistory.length;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRateIndicator(theme),
              const SizedBox(width: 16),
              _buildSparkline(theme),
              const SizedBox(width: 16),
              _buildStats(theme, avgRate),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRateIndicator(ThemeData theme) {
    final color = _logsPerSecond > 10 
        ? Colors.red 
        : _logsPerSecond > 5 
            ? Colors.orange 
            : Colors.green;
    
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_logsPerSecond.toStringAsFixed(1)} logs/s',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'Current rate',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSparkline(ThemeData theme) {
    return SizedBox(
      width: 100,
      height: 30,
      child: CustomPaint(
        painter: SparklinePainter(
          data: _rateHistory,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStats(ThemeData theme, double avgRate) {
    final maxRate = _rateHistory.isEmpty ? 0.0 : _rateHistory.reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Avg: ${avgRate.toStringAsFixed(1)}/s',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          'Peak: ${maxRate.toStringAsFixed(1)}/s',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = 0.0;
    final range = maxValue - minValue;
    
    if (range == 0) return;

    final path = Path();
    final fillPath = Path();
    
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SparklinePainter oldDelegate) {
    return data != oldDelegate.data;
  }
}
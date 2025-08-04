import 'package:equatable/equatable.dart';
import "package:voo_logging/src/domain/entities/log_entry.dart";
import "package:voo_logging/src/domain/entities/log_filter.dart";
import 'package:voo_logging/src/devtools_extension/domain/repositories/log_repository.dart';

abstract class LogEvent extends Equatable {
  const LogEvent();

  @override
  List<Object?> get props => [];
}

class LoadLogs extends LogEvent {}

class FilterLogsChanged extends LogEvent {
  final LogFilter filter;

  const FilterLogsChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

class LogReceived extends LogEvent {
  final LogEntry log;

  const LogReceived(this.log);

  @override
  List<Object?> get props => [log];
}

class SelectLog extends LogEvent {
  final LogEntry? log;

  const SelectLog(this.log);

  @override
  List<Object?> get props => [log];
}

class ClearLogs extends LogEvent {}

class ExportLogs extends LogEvent {
  final ExportFormat format;

  const ExportLogs({this.format = ExportFormat.json});

  @override
  List<Object?> get props => [format];
}

class ToggleAutoScroll extends LogEvent {}

class SearchQueryChanged extends LogEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class StreamChanged extends LogEvent {
  final Stream<LogEntry> stream;

  const StreamChanged(this.stream);

  @override
  List<Object?> get props => [stream];
}

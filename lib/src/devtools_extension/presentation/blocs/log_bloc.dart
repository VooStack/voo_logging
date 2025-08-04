import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import "package:voo_logging/src/domain/entities/log_entry.dart";
import "package:voo_logging/src/domain/entities/log_filter.dart";
import 'package:voo_logging/src/domain/entities/log_filter_extensions.dart';
import "package:voo_logging/src/domain/entities/log_statistics.dart";
import 'package:voo_logging/src/devtools_extension/domain/repositories/log_repository.dart';
import 'package:voo_logging/src/devtools_extension/domain/usecases/export_logs_usecase.dart';
import 'package:voo_logging/src/devtools_extension/domain/usecases/get_logs_usecase.dart';
import 'package:voo_logging/src/devtools_extension/domain/usecases/get_statistics_usecase.dart';
import 'package:voo_logging/src/devtools_extension/domain/usecases/stream_logs_usecase.dart';
import 'package:voo_logging/src/devtools_extension/presentation/blocs/log_event.dart';
import 'package:voo_logging/src/devtools_extension/presentation/blocs/log_state.dart';

class LogBloc extends Bloc<LogEvent, LogState> {
  final LogRepository repository;
  final GetLogsUseCase getLogsUseCase;
  final StreamLogsUseCase streamLogsUseCase;
  final GetStatisticsUseCase getStatisticsUseCase;
  final ExportLogsUseCase exportLogsUseCase;

  late StreamSubscription<LogEntry>? logStreamSubscription;

  LogBloc({
    required this.repository,
    required this.getLogsUseCase,
    required this.streamLogsUseCase,
    required this.getStatisticsUseCase,
    required this.exportLogsUseCase,
  }) : super(const LogState()) {
    on<LoadLogs>(_onLoadLogs);
    on<FilterLogsChanged>(_onFilterLogsChanged);
    on<LogReceived>(_onLogReceived);
    on<SelectLog>(_onSelectLog);
    on<ClearLogs>(_onClearLogs);
    on<ExportLogs>(_onExportLogs);
    on<ToggleAutoScroll>(_onToggleAutoScroll);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<StreamChanged>(_onStreamChanged);

    add(LoadLogs());
    // Start listening to log stream
    _startListeningToLogs();
  }
  
  void _startListeningToLogs() {
    logStreamSubscription = streamLogsUseCase().listen(
      (log) => add(LogReceived(log)),
      onError: (Object error) => add(LoadLogs()), // Reload on error
    );
  }

  void _onStreamChanged(StreamChanged event, Emitter<LogState> emit) {
    logStreamSubscription?.cancel();
    logStreamSubscription = event.stream.listen(
      (log) => add(LogReceived(log)),
      onError: (Object error) => emit(state.copyWith(error: error.toString())),
    );
  }

  Future<void> _onLoadLogs(LoadLogs event, Emitter<LogState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Load logs
      final logs = await getLogsUseCase(
        const GetLogsParams(limit: 10000),
      );

      // Load metadata
      final categories = await repository.getUniqueCategories();
      final tags = await repository.getUniqueTags();
      final sessions = await repository.getUniqueSessions();

      // Calculate statistics
      final statistics = await getStatisticsUseCase(state.filter);

      // Apply filter
      final filteredLogs = _filterLogs(logs, state.filter);

      emit(
        state.copyWith(
          logs: logs,
          filteredLogs: filteredLogs,
          categories: categories,
          tags: tags,
          sessions: sessions,
          statistics: statistics,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFilterLogsChanged(
    FilterLogsChanged event,
    Emitter<LogState> emit,
  ) async {
    final filteredLogs = _filterLogs(state.logs, event.filter);
    final statistics = await getStatisticsUseCase(event.filter);

    emit(
      state.copyWith(
        filter: event.filter,
        filteredLogs: filteredLogs,
        statistics: statistics,
      ),
    );
  }

  void _onLogReceived(LogReceived event, Emitter<LogState> emit) {
    final updatedLogs = [event.log, ...state.logs];
    final filteredLogs = _filterLogs(updatedLogs, state.filter);

    emit(
      state.copyWith(
        logs: updatedLogs,
        filteredLogs: filteredLogs,
      ),
    );

    // Update statistics
    getStatisticsUseCase(state.filter).then((statistics) {
      emit(state.copyWith(statistics: statistics));
    });
  }

  void _onSelectLog(SelectLog event, Emitter<LogState> emit) {
    emit(
      state.copyWith(
        selectedLog: event.log,
        clearSelectedLog: event.log == null,
      ),
    );
  }

  Future<void> _onClearLogs(ClearLogs event, Emitter<LogState> emit) async {
    try {
      await repository.clearLogs();
      emit(
        state.copyWith(
          logs: [],
          filteredLogs: [],
          clearSelectedLog: true,
          statistics: LogStatistics.empty(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onExportLogs(ExportLogs event, Emitter<LogState> emit) async {
    try {
      await exportLogsUseCase(
        ExportLogsParams(filter: state.filter, format: event.format),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onToggleAutoScroll(ToggleAutoScroll event, Emitter<LogState> emit) {
    emit(state.copyWith(autoScroll: !state.autoScroll));
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<LogState> emit,
  ) {
    final filter = state.filter.copyWith(
      searchQuery: event.query.isEmpty ? null : event.query,
    );
    add(FilterLogsChanged(filter));
  }

  List<LogEntry> _filterLogs(List<LogEntry> logs, LogFilter filter) => logs.where((log) => filter.matches(log)).toList();

  @override
  Future<void> close() {
    logStreamSubscription?.cancel();
    return super.close();
  }
}

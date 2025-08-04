import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voo_logging/features/devtools_extension/domain/repositories/devtools_log_repository.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_event.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_state.dart';
import 'package:voo_logging/features/logging/data/models/log_entry_model.dart';

class LogBloc extends Bloc<LogEvent, LogState> {
  final DevToolsLogRepository repository;

  late final StreamSubscription<LogEntryModel>? logStreamSubscription;

  LogBloc({required this.repository}) : super(const LogState()) {
    on<LoadLogs>(_onLoadLogs);
    on<FilterLogsChanged>(_onFilterLogsChanged);
    on<LogReceived>(_onLogReceived);
    on<SelectLog>(_onSelectLog);
    on<ClearLogs>(_onClearLogs);
    on<ToggleAutoScroll>(_onToggleAutoScroll);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<StreamChanged>(_onStreamChanged);

    add(LoadLogs());
    logStreamSubscription = repository.logStream.listen(
      (log) => add(LogReceived(log)),
      onError: (Object error) {
        log('Error receiving log: $error', name: 'LogBloc', level: 1000);
      },
    );
  }

  void _onStreamChanged(StreamChanged event, Emitter<LogState> emit) {
    logStreamSubscription = event.stream.listen(
      (log) => add(LogReceived(log)),
      onError: (Object error) => emit(state.copyWith(error: error.toString())),
    );
  }

  Future<void> _onLoadLogs(LoadLogs event, Emitter<LogState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));

      final cachedLogs = repository.getCachedLogs();

      log('LoadLogs - Found ${cachedLogs.length} cached logs', name: 'LogBloc', level: 800);

      emit(
        state.copyWith(
          logs: cachedLogs,
          isLoading: false,
          filteredLogs: _applyFilters(cachedLogs, state),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: e.toString(),
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onFilterLogsChanged(FilterLogsChanged event, Emitter<LogState> emit) async {
    emit(
      state.copyWith(
        selectedLevels: event.levels,
        selectedCategory: event.category,
        filteredLogs: _applyFilters(
          state.logs,
          state.copyWith(
            selectedLevels: event.levels,
            selectedCategory: event.category,
          ),
        ),
      ),
    );
  }

  void _onLogReceived(LogReceived event, Emitter<LogState> emit) {
    log('Log received: ${event.log.id} - ${event.log.message}', name: 'LogBloc', level: 800);

    final updatedLogs = [...state.logs, event.log];
    final filtered = _applyFilters(updatedLogs, state);

    log('Total logs: ${updatedLogs.length}, Filtered: ${filtered.length}', name: 'LogBloc', level: 800);

    emit(
      state.copyWith(
        logs: updatedLogs,
        filteredLogs: filtered,
      ),
    );
  }

  void _onSelectLog(SelectLog event, Emitter<LogState> emit) {
    if (event.log == null) {
      emit(state.copyWith(clearSelectedLog: true));
    } else {
      emit(state.copyWith(selectedLog: event.log));
    }
  }

  Future<void> _onClearLogs(ClearLogs event, Emitter<LogState> emit) async {
    repository.clearLogs();
    emit(state.copyWith(logs: [], filteredLogs: []));
  }

  void _onToggleAutoScroll(ToggleAutoScroll event, Emitter<LogState> emit) {
    emit(state.copyWith(autoScroll: !state.autoScroll));
  }

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<LogState> emit) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        filteredLogs: _applyFilters(
          state.logs,
          state.copyWith(searchQuery: event.query),
        ),
      ),
    );
  }

  List<LogEntryModel> _applyFilters(List<LogEntryModel> logs, LogState state) {
    var filtered = logs;

    // Apply level filter
    if (state.selectedLevels != null && state.selectedLevels!.isNotEmpty) {
      filtered = filtered.where((log) => state.selectedLevels!.contains(log.level)).toList();
    }

    // Apply category filter
    if (state.selectedCategory != null && state.selectedCategory!.isNotEmpty) {
      filtered = filtered.where((log) => log.category == state.selectedCategory).toList();
    }

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (log) =>
                log.message.toLowerCase().contains(query) ||
                (log.category?.toLowerCase().contains(query) ?? false) ||
                (log.tag?.toLowerCase().contains(query) ?? false) ||
                (log.error?.toString().toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Future<void> close() {
    logStreamSubscription?.cancel();
    return super.close();
  }
}

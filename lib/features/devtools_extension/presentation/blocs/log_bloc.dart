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

      // Get cached logs
      final cachedLogs = repository.getCachedLogs();

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
    log('Log received: ${event.log.id}', name: 'LogBloc', level: 800);

    final updatedLogs = [...state.logs, event.log];

    emit(
      state.copyWith(
        logs: updatedLogs,
        filteredLogs: _applyFilters(updatedLogs, state),
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

  List<LogEntryModel> _applyFilters(List<LogEntryModel> logs, LogState state) => repository.filterLogs(
        levels: state.selectedLevels,
        searchQuery: state.searchQuery,
        category: state.selectedCategory,
      );

  @override
  Future<void> close() {
    logStreamSubscription?.cancel();
    return super.close();
  }
}

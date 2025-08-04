import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_event.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_state.dart';
import 'package:voo_logging/voo_logging.dart';

class LogBloc extends Bloc<LogEvent, LogState> {
  final LoggerRepository repository;

  StreamSubscription<LogEntry>? logStreamSubscription;

  LogBloc({
    required this.repository,
  }) : super(const LogState()) {
    on<LoadLogs>(_onLoadLogs);
    on<FilterLogsChanged>(_onFilterLogsChanged);
    on<LogReceived>(_onLogReceived);
    on<SelectLog>(_onSelectLog);
    on<ClearLogs>(_onClearLogs);
    on<ToggleAutoScroll>(_onToggleAutoScroll);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<StreamChanged>(_onStreamChanged);

    add(LoadLogs());
    logStreamSubscription = repository.stream.listen(
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

  Future<void> _onLoadLogs(LoadLogs event, Emitter<LogState> emit) async {}

  Future<void> _onFilterLogsChanged(FilterLogsChanged event, Emitter<LogState> emit) async {}

  void _onLogReceived(LogReceived event, Emitter<LogState> emit) {
    log('Log received: ${event.log.id}', name: 'LogBloc', level: 800);

    emit(state.copyWith(logs: [...state.logs, event.log]));
  }

  void _onSelectLog(SelectLog event, Emitter<LogState> emit) {}

  Future<void> _onClearLogs(ClearLogs event, Emitter<LogState> emit) async {}

  void _onToggleAutoScroll(ToggleAutoScroll event, Emitter<LogState> emit) {}

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<LogState> emit) {}

  @override
  Future<void> close() {
    logStreamSubscription?.cancel();
    return super.close();
  }
}

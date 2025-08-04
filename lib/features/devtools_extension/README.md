# Voo Logger DevTools Extension

This DevTools extension provides a real-time log viewer for applications using Voo Logger.

## Architecture

### Data Flow
1. **Logger Repository** → Sends logs via `developer.postEvent('voo_logger.log', data)`
2. **DevTools Extension** → Listens to extension events from VM Service
3. **Data Source** → Receives and caches log entries
4. **Repository** → Provides filtering and data access
5. **Bloc** → Manages state and business logic
6. **UI** → Displays logs with filtering and search capabilities

### Key Components

- **DevToolsLogDataSource**: Listens to VM Service extension events
- **DevToolsLogRepository**: Handles log filtering and caching
- **LogBloc**: State management using BLoC pattern
- **VooLoggerPage**: Main UI with log list and details panel

## Testing

1. Run the test example to generate logs:
   ```bash
   dart run example/test_devtools.dart
   ```

2. In another terminal, build and serve the DevTools extension:
   ```bash
   flutter pub global activate devtools_extensions
   dart run devtools_extensions build_and_copy --source=lib/features/devtools_extension
   ```

3. Open DevTools and navigate to the Voo Logger tab

## Features

- Real-time log streaming
- Log level filtering
- Search functionality
- Category-based filtering
- Log details panel
- Auto-scroll toggle
- Export logs
- Statistics view
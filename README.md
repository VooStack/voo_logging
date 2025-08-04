# Voo Logging

A comprehensive logging package for Flutter and Dart applications with DevTools integration.

## Features

- **Easy to use API** - Simple methods for different log levels
- **DevTools Integration** - View and filter logs in Flutter DevTools
- **Persistent Storage** - Logs are stored locally using Sembast
- **Session Tracking** - Automatic session and user tracking
- **Structured Logging** - Support for metadata, categories, and tags
- **Performance Focused** - Non-blocking, efficient storage
- **Cross-platform** - Works on iOS, Android, Web, and Desktop

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  voo_logging: ^0.0.1
```

## Usage

### Basic Logging

```dart
import 'package:voo_logging/voo_logging.dart';

// Initialize the logger
await VooLogger.initialize();

// Log messages at different levels
VooLogger.debug('Debug message');
VooLogger.info('Information message');
VooLogger.warning('Warning message');
VooLogger.error('Error message', error: exception, stackTrace: stackTrace);

// Log with additional context
VooLogger.info('User action', 
  category: 'UI',
  tag: 'button_click',
  metadata: {'button_id': 'submit', 'screen': 'login'}
);
```

### User Context

```dart
// Set user context for all subsequent logs
VooLogger.setUserId('user123');

// Clear user context on logout
VooLogger.clearUserId();
```

### Querying Logs

```dart
// Get recent logs
final logs = await VooLogger.getLogs(limit: 100);

// Get logs for a specific session
final sessionLogs = await VooLogger.getLogsBySession(sessionId);

// Get logs by level
final errors = await VooLogger.getLogsByLevel(LogLevel.error);

// Search logs
final results = await VooLogger.searchLogs('payment');
```

### DevTools Extension

The package includes a DevTools extension for viewing and filtering logs in real-time.

1. Run your app with DevTools
2. Open the Voo Logger tab
3. View, filter, and export logs

## Log Levels

- `verbose` - Detailed information for debugging
- `debug` - Debug information
- `info` - General information
- `warning` - Warning messages
- `error` - Error messages
- `fatal` - Fatal errors that may crash the app

## Advanced Usage

### Custom Categories and Tags

```dart
// Use categories to group related logs
VooLogger.info('Payment processed', category: 'payment');
VooLogger.error('Payment failed', category: 'payment', error: e);

// Use tags for more specific filtering
VooLogger.debug('Cache hit', tag: 'cache:hit');
VooLogger.debug('Cache miss', tag: 'cache:miss');
```

### Structured Metadata

```dart
VooLogger.info('API Request', metadata: {
  'endpoint': '/api/users',
  'method': 'GET',
  'duration_ms': 234,
  'status_code': 200,
});
```

### Export Logs

```dart
// Export as JSON
final json = await VooLogger.exportLogs(format: 'json');

// Export as CSV
final csv = await VooLogger.exportLogs(format: 'csv');
```

## Performance

- Logs are written asynchronously to avoid blocking the UI
- Automatic log rotation when storage exceeds limits
- Efficient indexing for fast queries
- Minimal memory footprint

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
# Voo Logging

[![Flutter Package CI](https://github.com/voostack/voo_logging/actions/workflows/dart.yml/badge.svg)](https://github.com/voostack/voo_logging/actions/workflows/dart.yml)
[![pub package](https://img.shields.io/pub/v/voo_logging.svg)](https://pub.dev/packages/voo_logging)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive, production-ready logging package for Flutter and Dart applications with DevTools integration, persistent storage, and powerful filtering capabilities.

## 🚀 Features

- **🎯 Simple API** - Intuitive methods for different log levels (verbose, debug, info, warning, error, fatal)
- **🔧 DevTools Integration** - Real-time log viewing and filtering in Flutter DevTools
- **💾 Persistent Storage** - Logs survive app restarts using Sembast database
- **🏷️ Rich Context** - Categories, tags, metadata, user tracking, and session management
- **⚡ High Performance** - Non-blocking async operations with efficient indexing
- **🌐 Cross-Platform** - Works on iOS, Android, Web, macOS, Windows, and Linux
- **📊 Statistics** - Built-in analytics for log patterns and error tracking
- **🔍 Advanced Filtering** - Filter by level, time range, category, tag, or text search
- **📤 Export Options** - Export logs as JSON or CSV for external analysis

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  voo_logging: ^0.0.1
```

Then run:
```bash
flutter pub get
```

## 🎯 Quick Start

```dart
import 'package:voo_logging/voo_logging.dart';

void main() async {
  // Initialize the logger
  await VooLogger.initialize();
  
  // Start logging!
  VooLogger.info('App started successfully');
  
  runApp(MyApp());
}
```

## 📖 Usage Examples

### Basic Logging

```dart
// Different log levels
VooLogger.verbose('Detailed trace information');
VooLogger.debug('Debug information for development');
VooLogger.info('General information');
VooLogger.warning('Warning: This might be a problem');
VooLogger.error('Error occurred', error: exception, stackTrace: stack);
VooLogger.fatal('Fatal error - app might crash');
```

### Structured Logging with Context

```dart
// Log with categories and tags
VooLogger.info('User logged in',
  category: 'Auth',
  tag: 'login_success',
  metadata: {
    'userId': user.id,
    'method': 'email',
    'timestamp': DateTime.now().toIso8601String(),
  }
);

// Track API calls
VooLogger.debug('API Request',
  category: 'Network',
  tag: 'api_call',
  metadata: {
    'endpoint': '/api/users',
    'method': 'GET',
    'headers': headers,
  }
);

// Log errors with full context
VooLogger.error('Payment failed',
  category: 'Payment',
  tag: 'payment_error',
  error: exception,
  stackTrace: stackTrace,
  metadata: {
    'amount': 99.99,
    'currency': 'USD',
    'provider': 'stripe',
    'errorCode': 'insufficient_funds',
  }
);
```

### User and Session Tracking

```dart
// Set user context (persists across all logs)
VooLogger.setUserId('user_123');

// Get current session ID
final sessionId = VooLogger.currentSessionId;

// Clear user context on logout
VooLogger.clearUserId();
```

### Querying and Filtering Logs

```dart
// Get recent logs
final recentLogs = await VooLogger.getLogs(limit: 100);

// Filter by log level
final errors = await VooLogger.getLogsByLevel(LogLevel.error);
final warnings = await VooLogger.getLogsByLevel(LogLevel.warning);

// Filter by time range
final todayLogs = await VooLogger.getLogsByTimeRange(
  startTime: DateTime.now().subtract(Duration(days: 1)),
  endTime: DateTime.now(),
);

// Filter by category
final authLogs = await VooLogger.getLogsByCategory('Auth');

// Filter by tag
final loginLogs = await VooLogger.getLogsByTag('login_success');

// Search logs by text
final searchResults = await VooLogger.searchLogs('payment');

// Get logs for specific session
final sessionLogs = await VooLogger.getLogsBySession(sessionId);

// Get logs for specific user
final userLogs = await VooLogger.getLogsByUser('user_123');

// Get unique values for filtering
final categories = await VooLogger.getCategories();
final tags = await VooLogger.getTags();
final sessions = await VooLogger.getSessions();
```

### Statistics and Analytics

```dart
// Get log statistics
final stats = await VooLogger.getStatistics();

print('Total logs: ${stats.totalLogs}');
print('Logs by level: ${stats.logsByLevel}');
print('Logs by category: ${stats.logsByCategory}');
print('Error rate: ${stats.errorRate}%');
print('Most frequent categories: ${stats.topCategories}');
print('Most frequent tags: ${stats.topTags}');
```

### Exporting Logs

```dart
// Export as JSON
final jsonExport = await VooLogger.exportLogs(
  format: 'json',
  filter: LogFilter(
    levels: [LogLevel.error, LogLevel.fatal],
    startTime: DateTime.now().subtract(Duration(days: 7)),
  ),
);

// Export as CSV
final csvExport = await VooLogger.exportLogs(
  format: 'csv',
  filter: LogFilter(
    category: 'Payment',
  ),
);

// Save to file
final file = File('logs_export.json');
await file.writeAsString(jsonExport);
```

### Log Management

```dart
// Clear all logs
await VooLogger.clearLogs();

// Clear old logs (older than 30 days)
await VooLogger.clearOldLogs(days: 30);

// Get storage info
final storageInfo = await VooLogger.getStorageInfo();
print('Storage used: ${storageInfo.sizeInBytes} bytes');
print('Number of logs: ${storageInfo.logCount}');
```

## 🔧 DevTools Extension

The package includes a powerful DevTools extension for real-time log monitoring and analysis.

### Features:
- 📊 Real-time log streaming
- 🔍 Advanced filtering and search
- 📈 Visual statistics and charts
- 🎨 Syntax highlighting for metadata
- 📤 Export functionality
- 🔄 Auto-scroll and pause options

### Using DevTools:
1. Run your app in debug mode
2. Open Flutter DevTools
3. Navigate to the "Voo Logger" tab
4. Start monitoring your logs!

## ⚙️ Configuration

### Custom Configuration

```dart
await VooLogger.initialize(
  config: VooLoggerConfig(
    // Maximum number of logs to keep
    maxLogs: 100000,
    
    // Auto-delete logs older than X days
    autoDeleteAfterDays: 30,
    
    // Enable/disable console output
    enableConsoleOutput: true,
    
    // Minimum level for console output
    consoleLogLevel: LogLevel.debug,
    
    // Enable/disable DevTools integration
    enableDevTools: true,
    
    // Custom log format
    logFormat: (log) => '[${log.level}] ${log.message}',
  ),
);
```

### Performance Considerations

- Logs are written asynchronously to avoid blocking the UI
- Automatic indexing on timestamp, level, category, and tag
- Configurable cache size and retention policies
- Efficient batch operations for bulk queries

## 🏗️ Architecture

The package follows clean architecture principles:

```
lib/
├── src/
│   ├── data/
│   │   ├── enums/          # LogLevel enum
│   │   ├── models/         # Data models
│   │   └── sources/        # Storage implementation
│   └── domain/
│       └── entities/       # Core entities
├── voo_logging.dart        # Public API
└── devtools_extension/     # DevTools integration
```

## 🧪 Testing

```dart
// Use InMemoryLogStorage for testing
testWidgets('test with logging', (tester) async {
  await VooLogger.initialize(useInMemoryStorage: true);
  
  // Your test code
  VooLogger.info('Test started');
  
  // Verify logs
  final logs = await VooLogger.getLogs();
  expect(logs.length, 1);
  expect(logs.first.message, 'Test started');
});
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📋 Roadmap

- [ ] Remote logging support
- [ ] Log encryption
- [ ] Custom storage backends
- [ ] Log rotation strategies
- [ ] Performance metrics
- [ ] Integration with crash reporting services

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Sembast](https://pub.dev/packages/sembast) for efficient local storage
- Inspired by enterprise logging solutions
- Thanks to the Flutter community for feedback and contributions

## 📞 Support

- 📧 Email: support@voostack.com
- 🐛 Issues: [GitHub Issues](https://github.com/voostack/voo_logging/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/voostack/voo_logging/discussions)

---

Made with ❤️ by [VooStack](https://voostack.com)
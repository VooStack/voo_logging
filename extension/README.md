# Voo Logger DevTools Extension

A Flutter DevTools extension for the Voo Logger package that provides real-time log visualization and analysis.

## Features

- **Real-time Log Streaming**: View logs as they're generated in your Flutter app
- **Advanced Filtering**: Filter logs by level, category, tag, and search query
- **Log Statistics**: View aggregated statistics about your logs
- **Export Functionality**: Export logs in JSON, CSV, or text format
- **Clean Architecture**: Built with strict clean architecture principles

## Architecture

The extension follows clean architecture principles with clear separation of concerns:

### Domain Layer
- **Entities**: Core business objects (LogEntry, LogFilter, LogStatistics)
- **Repository Interfaces**: Abstract definitions for data operations
- **Use Cases**: Business logic implementation

### Data Layer
- **Data Sources**: DevTools API integration for receiving logs
- **Models**: Data transfer objects
- **Repository Implementations**: Concrete implementations of domain repositories

### Presentation Layer
- **Providers**: Riverpod state management
- **Widgets**: Reusable UI components
- **Pages**: Main application screens

## Usage

1. Run your Flutter app with DevTools:
   ```bash
   flutter run --observe
   ```

2. Open DevTools and navigate to the Voo Logger tab

3. Your logs will appear in real-time as they're generated

## Development

To build the extension:

```bash
cd devtools_extension
flutter pub get
flutter build web
```

## Integration with Voo Logger

The extension automatically receives log events from the main Voo Logger library through the DevTools extension API. No additional configuration is required.
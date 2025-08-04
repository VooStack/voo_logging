# Testing Voo Logging with DevTools

## Running the Example

1. **Install dependencies** (in the root directory):
   ```bash
   flutter pub get
   ```

2. **Run the example app**:
   ```bash
   cd example
   flutter run
   ```

3. **Open DevTools**:
   - Press `c` in the terminal where Flutter is running to open DevTools
   - Or run: `flutter pub global run devtools`
   - Navigate to the "Voo Logger" tab

## Fixed Issues

### 1. Database Permission Error
- **Problem**: The logger was trying to create the database at `/awesome_logs.db` (root directory)
- **Solution**: Updated to use proper application documents directory with `path_provider`

### 2. DevTools Extension Build Error
- **Problem**: Split widget naming conflict between packages
- **Solution**: Upgraded `devtools_extensions` to version `^0.3.0-dev.0`

### 3. DevTools Extension Configuration
- **Added**: `devtools_extension` configuration to main `pubspec.yaml`
- **Fixed**: Material design configuration in extension

## What You Should See

### In the Console
- Logs should appear without permission errors
- Format: `[Category] [Tag] Message`

### In DevTools
- A "Voo Logger" tab should appear
- Real-time log streaming
- Filtering by level, category, and search
- Export functionality
- Statistics view

## Testing Different Features

1. **Custom Logs**: Use the form to create logs with different levels
2. **Quick Actions**: Click the colored buttons to test each log level
3. **Scenarios**: Test network requests, user actions, errors, and performance
4. **Management**: View statistics, export logs, clear logs, change user

## Troubleshooting

If the DevTools tab doesn't appear:
1. Make sure you're running the latest Flutter version
2. Try closing and reopening DevTools
3. Check that the extension was built successfully in `devtools_extension/build/web/`
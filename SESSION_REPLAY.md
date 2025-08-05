# Session Replay Feature

## Overview

The Session Replay feature allows you to record and replay user sessions for debugging purposes. This feature captures logs, user actions, network requests, navigation events, and app state changes in a timeline that can be replayed to reproduce bugs exactly as users experienced them.

## Features

- **Session Recording**: Automatically capture all logs and events during a user session
- **Event Types**: Logs, user actions, network requests, navigation, app state changes
- **Timeline Visualization**: Interactive timeline showing all events in chronological order
- **Playback Controls**: Play, pause, step through events with adjustable speed
- **Storage Optimization**: Compressed storage with automatic cleanup of old sessions
- **Export/Import**: Share session recordings for collaborative debugging
- **DevTools Integration**: Seamless integration with Flutter DevTools

## Quick Start

### 1. Start Recording a Session

```dart
// Start recording with optional metadata
await VooLogger.startSessionRecording(
  metadata: {
    'user': 'test@example.com',
    'feature': 'checkout',
    'version': '1.0.0',
  },
);

// Your app continues running normally...
// All logs and events are automatically captured

// Stop recording when done
await VooLogger.stopSessionRecording();
```

### 2. Track User Actions

```dart
// Use TrackedGestureDetector for automatic tracking
TrackedGestureDetector(
  action: 'Add to Cart',
  screen: 'Product Details',
  properties: {'product_id': '12345', 'price': 29.99},
  onTap: () {
    // Your tap handler
  },
  child: ElevatedButton(
    child: Text('Add to Cart'),
    onPressed: null, // Handled by TrackedGestureDetector
  ),
)

// Or track manually
SessionReplayTracker.trackUserAction(
  'Custom Action',
  screen: 'Home',
  properties: {'custom': 'data'},
);
```

### 3. Track Navigation

```dart
// Add navigator observer to MaterialApp
MaterialApp(
  navigatorObservers: [
    SessionReplayNavigatorObserver(),
  ],
  // ... rest of your app
)

// Or track manually
SessionReplayTracker.trackNavigation(
  'ProductDetails',
  fromScreen: 'Home',
  parameters: {'productId': '12345'},
);
```

### 4. Track Network Requests

```dart
// Track request
SessionReplayTracker.trackNetworkRequest(
  'GET',
  'https://api.example.com/products',
  headers: {'Authorization': 'Bearer ...'},
);

// Track response
SessionReplayTracker.trackNetworkResponse(
  'GET',
  'https://api.example.com/products',
  200,
  Duration(milliseconds: 245),
  metadata: {'items_count': 50},
);
```

### 5. Track App State

```dart
// Track lifecycle changes automatically
void main() {
  WidgetsBinding.instance.initSessionReplayTracking();
  runApp(MyApp());
}

// Or track custom state
SessionReplayTracker.trackAppState(
  'user_logged_in',
  details: {'user_id': '12345', 'timestamp': DateTime.now()},
);
```

## Viewing Sessions in DevTools

1. Open Flutter DevTools
2. Navigate to the "Voo Logger" tab
3. Click on "Session Replay" tab
4. Sessions are listed on the left with:
   - Recording status indicator
   - User information
   - Duration and event count
   - Metadata tags

## Playback Features

- **Timeline Scrubbing**: Click anywhere on the timeline to jump to that point
- **Event Details**: Click on any event to see full details
- **Playback Speed**: Adjust speed from 0.5x to 5x
- **Step Navigation**: Step through events one by one
- **Event Filtering**: Filter by event type (coming soon)

## Storage Management

Sessions are stored using Sembast with gzip compression to minimize storage impact:

- **Automatic Compression**: Events are compressed in batches
- **Storage Limits**: Monitor storage usage in the UI
- **Cleanup**: Delete sessions older than 7 days with one click
- **Manual Deletion**: Delete individual sessions as needed

## Export/Import

Export sessions for sharing with team members:

```dart
// Sessions can be exported from the UI
// Export format is JSON with all events and metadata
{
  "exportDate": "2024-01-15T10:30:00Z",
  "version": 1,
  "session": {
    "id": "uuid",
    "sessionId": "session-123",
    "startTime": "2024-01-15T10:00:00Z",
    "endTime": "2024-01-15T10:15:00Z",
    "userId": "user@example.com",
    "events": [...]
  }
}
```

## Performance Considerations

- **Minimal Overhead**: Events are batched and saved asynchronously
- **Conditional Recording**: Only records when explicitly started
- **Memory Management**: Events are periodically flushed to storage
- **No UI Blocking**: All operations are non-blocking

## Best Practices

1. **Start Recording on Error Reports**: When users report issues, start recording to capture reproduction steps
2. **Add Metadata**: Include relevant context like user ID, feature flags, app version
3. **Track Key Actions**: Focus on tracking user interactions that affect app state
4. **Regular Cleanup**: Set up periodic cleanup of old sessions to manage storage
5. **Privacy**: Be mindful of sensitive data - don't record passwords or payment info

## API Reference

### VooLogger Methods

```dart
// Start recording
static Future<void> startSessionRecording({Map<String, dynamic>? metadata})

// Stop recording
static Future<void> stopSessionRecording()

// Pause/Resume recording
static Future<void> pauseSessionRecording()
static Future<void> resumeSessionRecording()

// Check recording status
static bool get isRecordingSession
```

### SessionReplayTracker Methods

```dart
// Track user action
static Future<void> trackUserAction(String action, {String? screen, Map<String, dynamic>? properties})

// Track navigation
static Future<void> trackNavigation(String toScreen, {String? fromScreen, Map<String, dynamic>? parameters})

// Track network
static Future<void> trackNetworkRequest(String method, String url, {Map<String, String>? headers, Map<String, dynamic>? metadata})
static Future<void> trackNetworkResponse(String method, String url, int statusCode, Duration duration, {Map<String, String>? headers, Map<String, dynamic>? metadata})

// Track app state
static Future<void> trackAppState(String state, {Map<String, dynamic>? details})
```

## Troubleshooting

### Sessions not appearing in DevTools
- Ensure VooLogger is initialized before starting recording
- Check that the DevTools extension is properly installed
- Verify that events are being tracked (check console logs)

### High storage usage
- Use the cleanup feature to remove old sessions
- Consider reducing the recording frequency for high-traffic apps
- Implement selective recording based on user actions

### Export not working
- Web platform: Check browser permissions for downloads
- Mobile platforms: Feature not yet implemented (use web for exports)

## Future Enhancements

- [ ] Event filtering and search in replay view
- [ ] Video recording integration
- [ ] Performance metrics overlay
- [ ] Heatmap visualization
- [ ] Session comparison tools
- [ ] Cloud storage integration
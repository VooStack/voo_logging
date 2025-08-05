import 'package:flutter/material.dart';
import 'package:voo_logging/features/logging/domain/entities/voo_logger.dart';
import 'package:voo_logging/features/session_replay/domain/entities/session_recording.dart';

/// Provides easy-to-use methods for tracking session events
class SessionReplayTracker {
  static SessionReplayTracker? _instance;
  static String? _currentScreen;
  
  factory SessionReplayTracker() {
    _instance ??= SessionReplayTracker._internal();
    return _instance!;
  }
  
  SessionReplayTracker._internal();

  /// Track a user action
  static Future<void> trackUserAction(
    String action, {
    String? screen,
    Map<String, dynamic>? properties,
  }) async {
    if (!VooLogger.isRecordingSession) return;
    
    await VooLogger.instance.sessionRecorder.addEvent(
      UserActionEvent(
        timestamp: DateTime.now(),
        action: action,
        screen: screen ?? _currentScreen,
        properties: properties,
      ),
    );
  }

  /// Track a screen navigation
  static Future<void> trackNavigation(String toScreen, {String? fromScreen, Map<String, dynamic>? parameters}) async {
    if (!VooLogger.isRecordingSession) return;
    
    await VooLogger.instance.sessionRecorder.addEvent(
      ScreenNavigationEvent(
        timestamp: DateTime.now(),
        fromScreen: fromScreen ?? _currentScreen ?? 'unknown',
        toScreen: toScreen,
        parameters: parameters,
      ),
    );
    
    _currentScreen = toScreen;
  }

  /// Track a network request/response
  static Future<void> trackNetworkRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? metadata,
  }) async {
    if (!VooLogger.isRecordingSession) return;
    
    await VooLogger.instance.sessionRecorder.addEvent(
      NetworkEvent(
        timestamp: DateTime.now(),
        method: method,
        url: url,
        headers: headers,
        metadata: metadata,
      ),
    );
  }

  /// Track a network response
  static Future<void> trackNetworkResponse(
    String method,
    String url,
    int statusCode,
    Duration duration, {
    Map<String, String>? headers,
    Map<String, dynamic>? metadata,
  }) async {
    if (!VooLogger.isRecordingSession) return;
    
    await VooLogger.instance.sessionRecorder.addEvent(
      NetworkEvent(
        timestamp: DateTime.now(),
        method: method,
        url: url,
        statusCode: statusCode,
        duration: duration,
        headers: headers,
        metadata: metadata,
      ),
    );
  }

  /// Track app state changes
  static Future<void> trackAppState(String state, {Map<String, dynamic>? details}) async {
    if (!VooLogger.isRecordingSession) return;
    
    await VooLogger.instance.sessionRecorder.addEvent(
      AppStateEvent(
        timestamp: DateTime.now(),
        state: state,
        details: details,
      ),
    );
  }
}

/// A NavigatorObserver that automatically tracks navigation events
class SessionReplayNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    if (route.settings.name != null) {
      SessionReplayTracker.trackNavigation(
        route.settings.name!,
        fromScreen: previousRoute?.settings.name,
        parameters: route.settings.arguments as Map<String, dynamic>?,
      );
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    
    if (previousRoute?.settings.name != null) {
      SessionReplayTracker.trackNavigation(
        previousRoute!.settings.name!,
        fromScreen: route.settings.name,
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    
    if (newRoute?.settings.name != null) {
      SessionReplayTracker.trackNavigation(
        newRoute!.settings.name!,
        fromScreen: oldRoute?.settings.name,
        parameters: newRoute.settings.arguments as Map<String, dynamic>?,
      );
    }
  }
}

/// Widget wrapper that tracks user interactions
class TrackedGestureDetector extends StatelessWidget {
  final Widget child;
  final String action;
  final String? screen;
  final Map<String, dynamic>? properties;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  const TrackedGestureDetector({
    super.key,
    required this.child,
    required this.action,
    this.screen,
    this.properties,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SessionReplayTracker.trackUserAction(
          action,
          screen: screen,
          properties: properties,
        );
        onTap?.call();
      },
      onLongPress: onLongPress != null
          ? () {
              SessionReplayTracker.trackUserAction(
                '$action (long press)',
                screen: screen,
                properties: properties,
              );
              onLongPress!.call();
            }
          : null,
      onDoubleTap: onDoubleTap != null
          ? () {
              SessionReplayTracker.trackUserAction(
                '$action (double tap)',
                screen: screen,
                properties: properties,
              );
              onDoubleTap!.call();
            }
          : null,
      child: child,
    );
  }
}

/// Extension on WidgetsBinding to track app lifecycle
extension SessionReplayWidgetsBinding on WidgetsBinding {
  void initSessionReplayTracking() {
    addObserver(_SessionReplayLifecycleObserver());
  }
}

class _SessionReplayLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SessionReplayTracker.trackAppState(
      state.name,
      details: {
        'timestamp': DateTime.now().toIso8601String(),
        'state': state.toString(),
      },
    );
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    SessionReplayTracker.trackAppState(
      'metrics_changed',
      details: {
        'screen_size': '${view.physicalSize.width}x${view.physicalSize.height}',
        'device_pixel_ratio': view.devicePixelRatio,
      },
    );
  }
}
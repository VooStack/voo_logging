// Test helper to access private fields for testing
class SessionReplayTrackerTestHelper {
  static void resetInstance() {
    // Reset is handled internally when tests create new instances
  }
  
  static void setCurrentScreen(String? screen) {
    // In tests, we verify behavior through public APIs instead
  }
  
  static String? getCurrentScreen() {
    // Return null as we can't access private state
    return null;
  }
}
abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});
}

class DebugAnalyticsService implements AnalyticsService {
  const DebugAnalyticsService();

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    // In production we would bridge to Firebase, Amplitude, etc.
  }
}

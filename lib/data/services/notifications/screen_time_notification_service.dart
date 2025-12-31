import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'usage_thresholds.dart';

/// Screen Time notification service
/// Sends polite, non-intrusive reminders when usage exceeds thresholds
/// Only sends each notification ONCE per day (not per session)
class ScreenTimeNotificationService {
  static final ScreenTimeNotificationService _instance = 
      ScreenTimeNotificationService._internal();
  
  factory ScreenTimeNotificationService() => _instance;
  
  ScreenTimeNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Track which thresholds have been triggered for each app TODAY
  // Key: packageName, Value: Set of triggered threshold durations in minutes
  final Map<String, Set<int>> _triggeredThresholds = {};
  
  // Track the last reset date to detect day changes
  DateTime _lastResetDate = DateTime.now();

  bool _initialized = false;
  bool _permissionGranted = false;

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    if (_permissionGranted) return true;

    final status = await Permission.notification.request();
    _permissionGranted = status.isGranted;
    return _permissionGranted;
  }

  /// Initialize notification plugin
  Future<void> initialize() async {
    if (_initialized) return;

    // Request permission first
    await requestPermission();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );

    _initialized = true;
  }

  /// Check if day has changed and reset notifications if needed
  void _checkAndResetForNewDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(_lastResetDate.year, _lastResetDate.month, _lastResetDate.day);

    if (today.isAfter(lastReset)) {
      // New day detected - reset all triggered notifications
      _triggeredThresholds.clear();
      _lastResetDate = now;
    }
  }

  /// Check usage and send notification if threshold exceeded
  /// 
  /// [packageName] - The app package being monitored
  /// [usageDuration] - Current TOTAL DAILY usage duration (cumulative)
  /// [appDisplayName] - Optional friendly name for the app
  Future<void> checkAndNotifyIfNeeded(
    String packageName,
    Duration usageDuration, {
    String? appDisplayName,
  }) async {
    // Ignore system apps
    if (UsageThresholds.isSystemApp(packageName)) {
      return;
    }

    // Ensure initialized
    if (!_initialized) {
      await initialize();
    }

    // Check permission - fail silently if not granted
    if (!_permissionGranted) {
      return;
    }

    // Check if day has changed and reset if needed
    _checkAndResetForNewDay();

    // Get or create threshold tracker for this app
    _triggeredThresholds.putIfAbsent(packageName, () => {});

    // Check each threshold against CUMULATIVE daily usage
    for (final threshold in UsageThresholds.all) {
      if (usageDuration >= threshold.duration) {
        final thresholdMinutes = threshold.duration.inMinutes;
        
        // Only notify if not already sent TODAY
        if (!_triggeredThresholds[packageName]!.contains(thresholdMinutes)) {
          await _sendNotification(
            packageName: packageName,
            threshold: threshold,
            appDisplayName: appDisplayName ?? UsageThresholds.getAppDisplayName(packageName),
          );
          
          // Mark as triggered for TODAY
          _triggeredThresholds[packageName]!.add(thresholdMinutes);
        }
      }
    }
  }

  /// Send a notification
  Future<void> _sendNotification({
    required String packageName,
    required UsageThreshold threshold,
    required String appDisplayName,
  }) async {
    final notificationId = packageName.hashCode + threshold.duration.inMinutes;

    const androidDetails = AndroidNotificationDetails(
      'screen_time_reminders',
      'Screen Time Reminders',
      channelDescription: 'Gentle reminders about app usage',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    // Customize message with app name if available
    final body = _personalizeMessage(threshold.body, appDisplayName);

    await _notifications.show(
      notificationId,
      threshold.title,
      body,
      details,
    );
  }

  /// Personalize notification message with app name
  String _personalizeMessage(String template, String appName) {
    // Simple personalization - could be enhanced
    return template.replaceFirst('this app', appName);
  }

  /// Reset threshold tracking for a specific app
  /// MANUAL USE ONLY - Normally resets happen automatically at day change
  void resetAppSession(String packageName) {
    _triggeredThresholds.remove(packageName);
  }

  /// Clear all threshold tracking
  /// MANUAL USE ONLY - Normally resets happen automatically at day change
  void resetAllSessions() {
    _triggeredThresholds.clear();
  }

  /// Force reset to new day (for testing)
  void forceNewDayReset() {
    _triggeredThresholds.clear();
    _lastResetDate = DateTime.now();
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

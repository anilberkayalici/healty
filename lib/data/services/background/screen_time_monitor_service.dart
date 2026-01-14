import 'package:flutter/services.dart';
import '../notifications/screen_time_notification_service.dart';

/// Dart wrapper for the native Android ScreenTimeMonitoringService
/// Handles communication between Dart and native service via MethodChannel
class ScreenTimeMonitorService {
  static const _channel = MethodChannel('com.example.posture_guard/screen_time_monitor');
  static final ScreenTimeMonitorService _instance = ScreenTimeMonitorService._internal();
  
  factory ScreenTimeMonitorService() => _instance;
  
  ScreenTimeMonitorService._internal() {
    _setupMethodCallHandler();
  }

  final _notificationService = ScreenTimeNotificationService();
  bool _initialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    
    await _notificationService.initialize();
    _initialized = true;
  }

  /// Setup handler for callbacks from native service
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onThresholdExceeded':
          await _handleThresholdExceeded(call.arguments);
          break;
        default:
          break;
      }
    });
  }

  /// Handle threshold exceeded callback from native service
  Future<void> _handleThresholdExceeded(dynamic arguments) async {
    if (arguments is! Map) return;

    final packageName = arguments['packageName'] as String?;
    final thresholdMinutes = arguments['thresholdMinutes'] as int?;
    final usageMs = arguments['usage'] as int?;

    if (packageName == null || thresholdMinutes == null || usageMs == null) {
      return;
    }

    final usageDuration = Duration(milliseconds: usageMs);

    // Send notification through our notification service
    await _notificationService.checkAndNotifyIfNeeded(
      packageName,
      usageDuration,
    );
  }

  /// Start the background monitoring service
  Future<bool> startMonitoring() async {
    try {
      await initialize();
      final result = await _channel.invokeMethod('startMonitoring');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Stop the background monitoring service
  Future<bool> stopMonitoring() async {
    try {
      final result = await _channel.invokeMethod('stopMonitoring');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Check if monitoring service is currently running
  Future<bool> isMonitoring() async {
    try {
      final result = await _channel.invokeMethod('isMonitoring');
      return result == true;
    } catch (e) {
      return false;
    }
  }
}

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/steps/step_service.dart';
import '../../../data/services/screen_time_service.dart';
import '../domain/home_metrics.dart';

/// Clean facade for Home screen to access real-time metrics
/// NO business logic, NO service initialization, READ-ONLY
class HomeMetricsService {
  final _stepService = StepService();
  final _screenTimeService = ScreenTimeService();
  
  /// Get real-time steps stream from existing StepService
  Stream<int> get todayStepsStream => _stepService.stepCountStream;
  
  /// Get today's steps synchronously (for initial value)
  int get todayStepsSync => _stepService.getTodayStepsSync();
  
  /// Get today's total screen time
  Future<Duration> getTodayScreenTime() async {
    try {
      final summary = await _screenTimeService.getTodayUsageSummary();
      return summary.totalForegroundTime;
    } catch (e) {
      return Duration.zero;
    }
  }
  
  /// Get screen time delta vs yesterday
  Future<ScreenTimeDelta> getScreenTimeDeltaVsYesterday() async {
    try {
      // Get today and yesterday usage
      final todaySummary = await _screenTimeService.getTodayUsageSummary();
      final yesterdaySummary = await _screenTimeService.getYesterdayUsageSummary();
      
      final todayMs = todaySummary.totalForegroundTime.inMilliseconds;
      final yesterdayMs = yesterdaySummary.totalForegroundTime.inMilliseconds;
      
      // No yesterday data
      if (yesterdayMs == 0) {
        return ScreenTimeDelta.noData();
      }
      
      // Calculate percent change
      final percentChange = ((todayMs - yesterdayMs) / yesterdayMs) * 100;
      
      return ScreenTimeDelta(
        percentChange: percentChange,
        hasData: true,
      );
    } catch (e) {
      return ScreenTimeDelta.noData();
    }
  }
  
  /// Format steps with locale-aware thousands separator
  String formatSteps(int steps) {
    // Turkish format: 6.420
    if (steps >= 1000) {
      final thousands = steps ~/ 1000;
      final remainder = steps % 1000;
      return '$thousands.${remainder.toString().padLeft(3, '0')}';
    }
    return steps.toString();
  }
}

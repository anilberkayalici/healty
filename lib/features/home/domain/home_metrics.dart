import 'dart:async';

/// Domain model for Home screen metrics
/// Provides read-only access to real-time app health data

class ScreenTimeDelta {
  final double percentChange;
  final bool hasData;
  final bool isIncrease;
  
  ScreenTimeDelta({
    required this.percentChange,
    required this.hasData,
  }) : isIncrease = percentChange > 0;
  
  factory ScreenTimeDelta.noData() => ScreenTimeDelta(
    percentChange: 0,
    hasData: false,
  );
  
  String get formattedPercent {
    if (!hasData) return "—";
    final sign = isIncrease ? "+" : "";
    return "$sign${percentChange.abs().toStringAsFixed(0)}%";
  }
}

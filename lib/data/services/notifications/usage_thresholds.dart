/// Usage threshold definitions for Screen Time notifications
/// Provides polite, non-judgmental messages in Duolingo style

class UsageThreshold {
  final Duration duration;
  final String title;
  final String body;
  final String emoji;

  const UsageThreshold({
    required this.duration,
    required this.title,
    required this.body,
    required this.emoji,
  });
}

class UsageThresholds {
  // System apps to ignore (launchers, settings, system UI)
  static const Set<String> systemApps = {
    'com.android.launcher',
    'com.google.android.apps.nexuslauncher',
    'com.android.settings',
    'com.android.systemui',
    'com.android.vending', // Play Store
    'android',
    'com.sec.android.app.launcher', // Samsung launcher
    'com.miui.home', // Xiaomi launcher
    'com.huawei.android.launcher', // Huawei launcher
    'com.oneplus.launcher', // OnePlus launcher
  };

  // TEST MODE: Soft warning at 5 minutes
  static const UsageThreshold softWarning = UsageThreshold(
    duration: Duration(minutes: 5),
    title: 'Küçük bir mola?',
    body: 'Bir süredir buradasın 🙂 Küçük bir mola iyi gelebilir.',
    emoji: '🙂',
  );

  // TEST MODE: Stronger reminder at 10 minutes
  static const UsageThreshold strongReminder = UsageThreshold(
    duration: Duration(minutes: 10),
    title: 'Ara vermek ister misin?',
    body: 'Belki kısa bir ara vermek ister misin? 🌱',
    emoji: '🌱',
  );

  /// All thresholds in ascending order
  static const List<UsageThreshold> all = [
    softWarning,
    strongReminder,
  ];

  /// Check if a package is a system app that should be ignored
  static bool isSystemApp(String packageName) {
    return systemApps.any((systemApp) => 
      packageName.contains(systemApp) || packageName == systemApp
    );
  }

  /// Get app display name from package name (fallback)
  static String getAppDisplayName(String packageName) {
    // Extract readable name from package
    final parts = packageName.split('.');
    if (parts.length > 2) {
      return parts.last
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word.isNotEmpty 
              ? word[0].toUpperCase() + word.substring(1) 
              : '')
          .join(' ');
    }
    return packageName;
  }
}

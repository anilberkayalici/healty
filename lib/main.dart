import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/home/presentation/new_home_screen.dart';
import 'presentation/screens/screen_time/screen_time_screen.dart';
import 'presentation/screens/posture/posture_monitor_screen.dart';
import 'presentation/screens/steps/steps_weekly_screen.dart';
import 'presentation/screens/common/coming_soon_screen.dart';
import 'features/hydration/presentation/water_tracker_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'data/services/background/screen_time_monitor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize and start screen time monitoring service
  final monitorService = ScreenTimeMonitorService();
  await monitorService.initialize();
  
  // Start monitoring in background
  // This will trigger real-time notifications
  monitorService.startMonitoring().catchError((_) {
    // Silent fail if service can't start
  });
  
  runApp(const PostureGuardApp());
}

class PostureGuardApp extends StatelessWidget {
  const PostureGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      // New Stitch-designed home screen
      home: const NewHomeScreen(),
      // Centralized routing
      routes: {
        '/screen-time': (context) => const ScreenTimeScreen(),
        '/hydration': (context) => const WaterTrackerScreen(),
        '/posture': (context) => const PostureMonitorScreen(),
        '/pedometer': (context) => const StepsWeeklyScreen(),
        '/insights': (context) => const ComingSoonScreen(featureName: 'Insights'),
        '/settings': (context) => const ComingSoonScreen(featureName: 'Settings'),
        '/focus': (context) => const ComingSoonScreen(featureName: 'Focus Details'),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

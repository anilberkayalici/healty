import 'package:flutter/material.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';

void main() {
  runApp(const PostureGuardApp());
}

class PostureGuardApp extends StatelessWidget {
  const PostureGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PostureGuard',
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
      // Ana ekran artık Dashboard - Buradan Posture Guard'a gidilecek
      home: const DashboardScreen(),
    );
  }
}

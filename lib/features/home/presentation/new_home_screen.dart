import 'package:flutter/material.dart';
import '../../../navigation/app_routes.dart';
import '../data/home_metrics_service.dart';
import '../domain/home_metrics.dart';
import '../../profile/data/profile_repository_impl.dart';

/// New Home screen based on Stitch design (Variant 2)
/// Clean, modern health dashboard with glassmorphism
class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final _metricsService = HomeMetricsService();
  final _profileRepository = ProfileRepositoryImpl();
  ScreenTimeDelta? _screenTimeDelta;

  @override
  void initState() {
    super.initState();
    _loadScreenTimeDelta();
  }

  Future<void> _loadScreenTimeDelta() async {
    final delta = await _metricsService.getScreenTimeDeltaVsYesterday();
    if (mounted) {
      setState(() {
        _screenTimeDelta = delta;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101F22), // background-dark
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Bar
            SliverToBoxAdapter(
              child: _buildTopBar(context),
            ),
            
            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero Card: Daily Focus
                  _buildDailyFocusCard(context),
                  const SizedBox(height: 20),
                  
                  // 2x2 Module Grid
                  _buildModuleGrid(context),
                  const SizedBox(height: 20),
                  
                  // Streak & XP Card
                  _buildStreakCard(context),
                  const SizedBox(height: 100), // Space for bottom nav
                ]),
              ),
            ),
          ],
        ),
      ),
      // Floating Bottom Nav
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User Avatar + Greeting (Tappable - opens Profile)
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[700],
                        border: Border.all(color: const Color(0xFF1C2527), width: 2),
                      ),
                      child: const Icon(Icons.person, color: Colors.white70, size: 24),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF111718), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                StreamBuilder(
                  stream: _profileRepository.watch(),
                  builder: (context, snapshot) {
                    final name = snapshot.data?.name ?? 'User';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
                        ),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Action Button - Notification only
          _buildGlassButton(Icons.notifications_outlined, () {}),
        ],
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildDailyFocusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2527).withOpacity(0.6),
            const Color(0xFF1C2527).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Focus',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overall wellness score',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
              Icon(Icons.more_vert, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Circular Progress
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: 0.85,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFF2A3639),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF13C8EC)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const Text(
                      '85%',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great job! You\'re crushing your goals today.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[300], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.focusDetails),
                      icon: const Text('View Details'),
                      label: const Icon(Icons.arrow_forward, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13C8EC),
                        foregroundColor: const Color(0xFF101F22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _buildPostureCard(context),
        _buildPedometerCard(context),
        _buildScreenTimeCard(context),
        _buildHydrationCard(context),
      ],
    );
  }

  Widget _buildPostureCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.posture),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF13C8EC).withOpacity(0.15),
              const Color(0xFF13C8EC).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF13C8EC).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF13C8EC).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.accessibility_new, color: Color(0xFF13C8EC), size: 24),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF13C8EC),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Posture Guard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPedometerCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.pedometer),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C2527).withOpacity(0.6),
              const Color(0xFF1C2527).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2A3639),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.directions_walk, color: Colors.grey[300], size: 24),
            ),
            const Spacer(),
            StreamBuilder<int>(
              stream: _metricsService.todayStepsStream,
              initialData: _metricsService.todayStepsSync,
              builder: (context, snapshot) {
                final steps = snapshot.data ?? 0;
                return Text(
                  _metricsService.formatSteps(steps),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                );
              },
            ),
            Text(
              'Steps today',
              style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.65,
                backgroundColor: const Color(0xFF2A3639),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF13C8EC)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTimeCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.screenTime),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C2527).withOpacity(0.6),
              const Color(0xFF1C2527).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3639),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.smartphone, color: Colors.grey[300], size: 24),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAppIcon('FB', Colors.grey[600]!),
                    const SizedBox(width: 4),
                    _buildAppIcon('YT', Colors.grey[500]!),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const Text(
              '1h 24m',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Screen time',
              style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _screenTimeDelta == null
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.grey),
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        _screenTimeDelta!.isIncrease ? Icons.trending_up : Icons.trending_down,
                        color: _screenTimeDelta!.isIncrease ? Colors.red : Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _screenTimeDelta!.hasData
                            ? '${_screenTimeDelta!.formattedPercent} vs yesterday'
                            : 'No data yesterday',
                        style: TextStyle(
                          fontSize: 12,
                          color: _screenTimeDelta!.isIncrease ? Colors.red[400] : Colors.green[400],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.hydration),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1C2527).withOpacity(0.6),
              const Color(0xFF1C2527).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            // Liquid background effect
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF13C8EC).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3639),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.water_drop, color: Color(0xFF13C8EC), size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3639),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '60%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '1,200',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '/ 2,000 ml',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.hydration),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Water'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF13C8EC),
                      side: BorderSide(color: const Color(0xFF13C8EC).withOpacity(0.2)),
                      backgroundColor: const Color(0xFF13C8EC).withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon(String label, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1C2527)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2527).withOpacity(0.6),
            const Color(0xFF1C2527).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '12 Day Streak',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Keep the flame alive!',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '450 XP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF13C8EC)),
              ),
              Text(
                'LEVEL 5',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2527).withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavItem(Icons.home, true, () {}),
          const SizedBox(width: 48),
          _buildNavItem(Icons.bar_chart_outlined, false, () {
            Navigator.pushNamed(context, AppRoutes.insights);
          }),
          const SizedBox(width: 48),
          _buildNavItem(Icons.settings_outlined, false, () {
            Navigator.pushNamed(context, AppRoutes.settings);
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? const Color(0xFF13C8EC) : Colors.grey[500],
          ),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF13C8EC) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

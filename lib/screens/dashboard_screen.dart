import 'package:flutter/material.dart';
import 'posture_monitor_screen.dart';
import 'steps_weekly_screen.dart'; // Haftalık adım ekranı
import 'screen_time/screen_time_screen.dart'; // Ekran süresi ekranı
import '../logic/step_service.dart'; // Adım sayar servisi
import '../logic/screen_time_service.dart'; // Ekran süresi servisi

/// Minimal Dashboard Tile - Large Icon + Label Only
class DashboardMiniTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isDark;

  const DashboardMiniTile({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C242E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ana Dashboard Ekranı - Health Companion
/// Stitch ile tasarılanmış HTML'den Flutter'a çevrildi
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StepService _stepService = StepService();

  @override
  void initState() {
    super.initState();
    // Adım saymayı başlat (yeni API: init)
    _stepService.init();
  }

  @override
  void dispose() {
    // Servisi temizle (opsiyonel - Singleton olduğu için diğer ekranlar kullanabilir)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark mode kontrolü
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Stack(
          children: [
            // Ana içerik
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(isDark),
                    const SizedBox(height: 24),
                    
                    // Hero Card - Daily Focus
                    _buildHeroCard(isDark),
                    const SizedBox(height: 32),
                    
                    // Grid Dashboard
                    _buildDashboardGrid(context, isDark),
                    
                    const SizedBox(height: 100), // Bottom nav için boşluk
                  ],
                ),
              ),
            ),
            
            // Floating Bottom Navigation
            _buildBottomNav(isDark),
          ],
        ),
      ),
    );
  }
  
  /// Header - Kullanıcı profili ve rozetler
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profil
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF137FEC).withOpacity(0.2),
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBI2LB5JmvIjf3-YRTv6ktgrPoUktQsZHtUYtO7MohWYeur0dXxShOEeAUtv-MqB4SEXO-y8JTG61xettaKeAz_ZByLa_44cRc1ypaLUTPatF1Zm6oajTZLRdjOvpRoycWeRHg2M6-3WHRXoUCCrMen3l1GVCUsJzknREZ-FpSLuXqtR9wWeEzz_KqyPMWW19Wu84feV4KJnOdusuy7_uK2uEihm7gCdjc0-MdqcZ7X5ZxfUybbrom54P45ZgZWd5UTA8YGJsvC5S0'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                        border: Border.all(
                          color: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Evening,',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'Alex',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Rozetler (Streak ve Stars)
          Row(
            children: [
              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.orange.withOpacity(0.2) 
                      : const Color(0xFFFED7AA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark 
                        ? Colors.orange.withOpacity(0.3)
                        : const Color(0xFFFECA8F),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '12',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.orange[400] : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Star Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.yellow.withOpacity(0.2) 
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark 
                        ? Colors.yellow.withOpacity(0.3)
                        : const Color(0xFFFEE68F),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '450',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.yellow[600] : Colors.yellow[800],
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
  
  /// Hero Card - Daily Focus (Posture Score)
  Widget _buildHeroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C242E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: isDark 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Focus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  Text(
                    'Posture Score',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 24),
          
          // İçerik
          Row(
            children: [
              // Circular Progress
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: 0.85,
                        strokeWidth: 8,
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                        color: const Color(0xFF137FEC),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '85',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.grey[900],
                              ),
                            ),
                            Text(
                              '%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              
              // Stats & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.green, size: 18),
                        const SizedBox(width: 4),
                        const Text(
                          '+5% vs yesterday',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You're in the top 5% of users today! Great job maintaining spinal health.",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF137FEC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'View Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF137FEC),
                        ),
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
  
  /// Dashboard Grid - Kartlar
  Widget _buildDashboardGrid(BuildContext context, bool isDark) {
    return Column(
      children: [
        // İlk satır - Posture Guard ve Steps
        Row(
          children: [
            // Posture Guard Card (TIKLANABİLİR - Navigator)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // PostureMonitorScreen'e git
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PostureMonitorScreen(),
                    ),
                  );
                },
                child: _buildPostureGuardCard(isDark),
              ),
            ),
            const SizedBox(width: 16),
            // Steps Card (TIKLANABİLİR - Haftalık ekrana git)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // StepsWeeklyScreen'e git
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StepsWeeklyScreen(),
                    ),
                  );
                },
                child: _buildStepsCard(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // İkinci satır - Screen Time ve Hydration
        Row(
          children: [
            // Screen Time Card (TIKLANABİLİR - Screen Time ekranına git)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // ScreenTimeScreen'e git
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScreenTimeScreen(),
                    ),
                  );
                },
                child: _buildScreenTimeCard(isDark),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildHydrationCard(isDark)),
          ],
        ),
        const SizedBox(height: 16),
        
        // Eco Impact Card (Wide)
        _buildEcoImpactCard(isDark),
      ],
    );
  }
  
  /// Posture Guard Card
  Widget _buildPostureGuardCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C242E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.accessibility_new,
                  color: Color(0xFF137FEC),
                  size: 18,
                ),
              ),
              // Toggle Switch
              Container(
                width: 36,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Posture Guard',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Active Monitoring',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // DEPRECATED - Old implementation, keeping for reference but unused
  Widget _buildLegacyStepsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C242E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: StreamBuilder<int>(
        // StepService'in stream'ini dinle
        stream: _stepService.stepCountStream,
        initialData: 0,
        builder: (context, snapshot) {
          // HATA DURUMU: Sensör yok veya izin verilmedi
          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.directions_walk,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                    Text(
                      'Sensör hatası',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '--',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'İzin gerekli',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // VERİ BEKLENİYOR
          if (!snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A65).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.directions_walk,
                    color: Color(0xFFFF8A65),
                    size: 18,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Veri bekleniyor...',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // VERİ VAR - Hesaplamaları yap
          final steps = snapshot.data!;
          final goal = _stepService.dailyGoal; // 7000
          final percent = ((steps / goal) * 100).clamp(0.0, 200.0);

          // Tudor-Locke Pedometre Sınıflandırması (Bilimsel)
          String activityLabel;
          if (steps < 5000) {
            activityLabel = "Bugünkü aktivite: Sedanter";
          } else if (steps < 7500) {
            activityLabel = "Bugünkü aktivite: Düşük aktif";
          } else if (steps < 10000) {
            activityLabel = "Bugünkü aktivite: Orta aktif";
          } else if (steps < 12500) {
            activityLabel = "Bugünkü aktivite: Aktif";
          } else {
            activityLabel = "Bugünkü aktivite: Çok aktif";
          }

          // Sadeleştirilmiş motivasyon mesajı
          String motivationMessage;
          if (percent < 30) {
            motivationMessage = 'Yavaş başlangıç.';
          } else if (percent < 70) {
            motivationMessage = 'Fena değil, devam.';
          } else if (percent < 100) {
            motivationMessage = 'Hedefe az kaldı.';
          } else {
            motivationMessage = 'Bugün Koala gururlu.';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ÜST KISIM: Başlık (Steps) + Hedef
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Steps',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    'Goal: ${(goal / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // ALT KISIM: Adım sayısı + Aktivite seviyesi + Motivasyon
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Adım sayısı (Büyük)
                  Text(
                    steps.toString().replaceAllMapped(
                      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    ),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Aktivite sınıfı (Tudor-Locke) - Overflow koruması
                  Text(
                    activityLabel,
                    maxLines: 1, // Overflow engelle
                    overflow: TextOverflow.ellipsis, // Taşarsa ... ekle
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  
                  // Motivasyon mesajı - Overflow koruması
                  Text(
                    motivationMessage,
                    maxLines: 1, // Overflow engelle
                    overflow: TextOverflow.ellipsis, // Taşarsa ... ekle
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// Screen Time Card - Minimal icon + label only
  Widget _buildScreenTimeCard(bool isDark) {
    return DashboardMiniTile(
      icon: Icons.smartphone,
      label: 'Screen Time',
      accentColor: Theme.of(context).colorScheme.primary,
      isDark: isDark,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScreenTimeScreen()),
        );
      },
    );
  }

  /// Steps Card - Minimal icon + label only
  Widget _buildStepsCard(bool isDark) {
    return DashboardMiniTile(
      icon: Icons.directions_walk,
      label: 'Adımsayar',
      accentColor: const Color(0xFF4CAF50), // Green
      isDark: isDark,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StepsWeeklyScreen()),
        );
      },
    );
  }
  
  Widget _buildMiniBar(bool isDark, double height, bool isActive) {
    return Container(
      width: 4,
      height: 32 * height,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFF137FEC) 
            : (isDark ? Colors.grey[700] : Colors.grey[300]),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
  
  // DEPRECATED - Old implementation, keeping for reference but unused
  Widget _buildLegacyScreenTimeCard(bool isDark) {
    final screenTimeService = ScreenTimeService();
    
    return FutureBuilder<ScreenTimeSummary>(
      future: screenTimeService.getTodayUsageSummary(),
      builder: (context, snapshot) {
        // Loading state
        if (!snapshot.hasData) {
          return _buildScreenTimeCardBody(
            isDark: isDark,
            mainText: '…',
            subtitle: 'Loading...',
            showButton: false,
          );
        }

        final data = snapshot.data!;

        // Platform desteklenmiyor (iOS vs.)
        if (!data.supported) {
          return _buildScreenTimeCardBody(
            isDark: isDark,
            mainText: '--',
            subtitle: 'Not supported',
            showButton: false,
          );
        }

        // İzin yok
        if (!data.permissionGranted) {
          return _buildScreenTimeCardBody(
            isDark: isDark,
            mainText: '0h 0m',
            subtitle: 'Permission required',
            showButton: true,
            onButtonPressed: () async {
              await screenTimeService.requestUsagePermission();
              // Refresh - setState trigger
              (context as Element).markNeedsBuild();
            },
          );
        }

        // Başarılı - Gerçek veri
        final totalLabel = _formatDuration(data.totalForegroundTime);
        
        // En çok kullanılan uygulama (sadece 1 tanesi, minimal format)
        final appsLabel = data.topApps.isEmpty
            ? 'No usage today'
            : 'Top: ${_getSimplifiedAppName(data.topApps[0].packageName)} • ${_formatDuration(data.topApps[0].foregroundTime)}';

        return _buildScreenTimeCardBody(
          isDark: isDark,
          mainText: totalLabel,
          subtitle: appsLabel,
          showButton: false,
        );
      },
    );
  }

  /// Screen Time Card UI Body - Minimal Professional Style
  Widget _buildScreenTimeCardBody({
    required bool isDark,
    required String mainText,
    required String subtitle,
    required bool showButton,
    VoidCallback? onButtonPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      height: 130,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C242E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.smartphone,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const Spacer(),
          // Title
          Text(
            'Screen Time',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          // Main value
          Text(
            mainText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Subtext or button
          if (showButton)
            TextButton(
              onPressed: onButtonPressed,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Grant Permission',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  /// Duration formatter helper
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
  
  /// App name simplifier helper
  String _getSimplifiedAppName(String packageName) {
    final parts = packageName.split('.');
    return parts.isNotEmpty ? parts.last : packageName;
  }
  
  /// Hydration Card
  Widget _buildHydrationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C242E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.cyan,
                  size: 18,
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 14, color: Colors.grey),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '1,200',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ml',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Water glasses
              Row(
                children: [
                  _buildWaterGlass(true),
                  _buildWaterGlass(true),
                  _buildWaterGlass(true),
                  _buildWaterGlass(false),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWaterGlass(bool filled) {
    return Expanded(
      child: Container(
        height: 32,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: filled ? Colors.cyan.withOpacity(0.2) : Colors.grey[300],
          borderRadius: BorderRadius.circular(6),
        ),
        child: filled 
            ? const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.cyan,
                  ),
                ),
              )
            : null,
      ),
    );
  }
  
  /// Eco Impact Card (Wide)
  Widget _buildEcoImpactCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.forest, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Eco Impact',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "You've saved 2.4kg of CO2 by walking today!",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[100],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Claim XP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Bottom Navigation
  Widget _buildBottomNav(bool isDark) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF1C242E).withOpacity(0.8)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.grey[700]!.withOpacity(0.5)
                  : Colors.white.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavItem(Icons.home, true),
              const SizedBox(width: 32),
              _buildNavItem(Icons.bar_chart, false),
              const SizedBox(width: 32),
              _buildNavItem(Icons.leaderboard, false),
              const SizedBox(width: 32),
              _buildNavItem(Icons.settings, false),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF137FEC) : Colors.grey[400],
          size: 24,
        ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF137FEC) : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: isActive 
                ? [
                    BoxShadow(
                      color: const Color(0xFF137FEC).withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

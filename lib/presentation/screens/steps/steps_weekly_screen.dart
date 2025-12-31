import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/steps/step_service.dart';
import '../../../data/services/steps/weekly_steps_service.dart';
import '../../../data/services/steps/monthly_steps_service.dart';
import 'dart:math' as math;

/// Daily goal constant (for day mode display)
const int kDefaultDailyGoal = 10000;

/// Görünüm modları: Gün / Hafta / Ay
enum StepsViewMode { day, week, month }

/// Haftalık adım detay ekranı
/// Stitch HTML/CSS tasarımından Flutter'a çevrildi
class StepsWeeklyScreen extends StatefulWidget {
  const StepsWeeklyScreen({super.key});

  @override
  State<StepsWeeklyScreen> createState() => _StepsWeeklyScreenState();
}

class _StepsWeeklyScreenState extends State<StepsWeeklyScreen> {
  // Görünüm modu
  StepsViewMode _viewMode = StepsViewMode.week;
  
  // Servisler
  late final StepService _stepService;
  late final WeeklyStepsService _weeklyService;
  late final MonthlyStepsService _monthlyStepsService;
  
  // Veri modelleri
  WeeklyStepsData? _weeklyData;
  MonthlyStepsData? _monthlyData;
  int _todaySteps = 0;
  
  // Se çili gün index'i
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Servisleri oluştur
    _stepService = StepService();
    _weeklyService = WeeklyStepsService(_stepService);
    _monthlyStepsService = MonthlyStepsService(_stepService);
    
    // İlk mod için veriyi yükle
    _onModeChanged();
    
    // Gerçek zamanlı güncelleme (bugünkü adım değiştiğinde)
    _stepService.stepCountStream.listen((_) {
      _onModeChanged();
    });
  }

  /// Mod değiştiğinde uygun veriyi yükle
  void _onModeChanged() {
    switch (_viewMode) {
      case StepsViewMode.day:
        _loadDayData();
        break;
      case StepsViewMode.week:
        _loadWeeklyData();
        break;
      case StepsViewMode.month:
        _loadMonthlyData();
        break;
    }
  }

  /// Günlük veriyi yükle
  void _loadDayData() {
    final steps = _stepService.getTodayStepsSync();
    setState(() {
      _todaySteps = steps;
      _selectedDayIndex = 0; // Day modunda tek "bar"
    });
  }

  /// Haftalık veriyi yükle ve bugünü seç
  void _loadWeeklyData() {
    final data = _weeklyService.getCurrentWeekData();
    setState(() {
      _weeklyData = data;
      
      // Bugünü otomatik seç
      final now = DateTime.now();
      _selectedDayIndex = data.days.indexWhere((d) =>
        d.date.year == now.year &&
        d.date.month == now.month &&
        d.date.day == now.day
      );
      if (_selectedDayIndex < 0) _selectedDayIndex = 0;
    });
  }

  /// Aylık veriyi yükle ve bugünü seç
  void _loadMonthlyData() {
    final data = _monthlyStepsService.getCurrentMonthData();
    setState(() {
      _monthlyData = data;
      
      // İlk haftayı seç (month modunda 4 bar var)
      _selectedDayIndex = 0;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Loading state - mode-dependent null check
    if (_viewMode == StepsViewMode.week && _weeklyData == null) {
      return _buildLoadingScaffold(isDark, 'Loading weekly data...');
    }
    if (_viewMode == StepsViewMode.month && _monthlyData == null) {
      return _buildLoadingScaffold(isDark, 'Loading monthly data...');
    }
    
    // Day mode her zaman hazır (sadece int)
    // Week ve Month modları için data'yı hazırla
    final WeeklyStepsData? weekData = _viewMode == StepsViewMode.week ? _weeklyData! : null;
    final MonthlyStepsData? monthData = _viewMode == StepsViewMode.month ? _monthlyData! : null;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0f1216) : const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tabs
            _buildTabs(),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    // Hero chart card (mode-dependent)
                    _buildHeroChartCard(isDark, weekData, monthData),
                    const SizedBox(height: 20),
                    
                    // Statistics grid (mode-dependent)
                    _buildStatisticsGrid(isDark, weekData, monthData),
                    const SizedBox(height: 20),
                    
                    // Day detail panel (mode-dependent)
                    _buildDayDetailPanel(isDark, weekData, monthData),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Loading scaffold helper
  Widget _buildLoadingScaffold(bool isDark, String message) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0f1216) : const Color(0xFFF6F7F8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF30e87a)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Header (back, title, settings)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          // Title
          const Text(
            'Steps',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          
          // Settings button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Tab bar (Day, Week, Month)
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1e24),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            _buildTab('Day', StepsViewMode.day),
            _buildTab('Week', StepsViewMode.week),
            _buildTab('Month', StepsViewMode.month),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, StepsViewMode mode) {
    final isActive = _viewMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _viewMode = mode;
            _onModeChanged();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF30e87a).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: isActive ? Border.all(color: const Color(0xFF30e87a).withOpacity(0.1)) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF30e87a) : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  /// Hero chart card (mode-dependent: today/week/month + chart)
  Widget _buildHeroChartCard(bool isDark, WeeklyStepsData? weekData, MonthlyStepsData? monthData) {
    // Mode-dependent title and total
    String title;
    int totalSteps;
    
    switch (_viewMode) {
      case StepsViewMode.day:
        title = 'Today';
        totalSteps = _todaySteps;
        break;
      case StepsViewMode.week:
        title = 'This week';
        totalSteps = weekData?.totalSteps ?? 0;
        break;
      case StepsViewMode.month:
        title = 'This month';
        totalSteps = monthData?.totalSteps ?? 0;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1e24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Title and total - DYNAMIC
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                totalSteps.toString().replaceAllMapped(
                  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                  (m) => '${m[1]},',
                ),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'steps',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF30e87a),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Bar chart (mode-dependent)
          _buildBarChart(weekData, monthData),
        ],
      ),
    );
  }

  /// Bar chart - DAY: 1 progress bar, WEEK: 7 bars, MONTH: 4 weekly bars
  Widget _buildBarChart(WeeklyStepsData? weekData, MonthlyStepsData? monthData) {
    if (_viewMode == StepsViewMode.day) {
      // DAY MODE: Single progress bar
      final goal = kDefaultDailyGoal;
      final progress = goal > 0 ? (_todaySteps / goal).clamp(0.0, 1.0) : 0.0;
      
      return Column(
        children: [
          // Goal label
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Goal: ${goal.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} steps',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
          ),
          SizedBox(
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% of goal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF232930),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF30e87a), Color(0xFF30e87a)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_viewMode == StepsViewMode.week && weekData != null) {
      // WEEK MODE: 7 bars (Mon-Sun)
      const dayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
      final maxSteps = weekData.maxSteps;
      
      return SizedBox(
        height: 200,
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final day = weekData.days[index];
                  final isSelected = index == _selectedDayIndex;
                  final heightRatio = maxSteps > 0 ? (day.steps / maxSteps) : 0.0;
                  final barHeight = (heightRatio * 150).clamp(20.0, 150.0);
                  
                  return _buildBar(index, barHeight, isSelected);
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final isSelected = index == _selectedDayIndex;
                return SizedBox(
                  width: 32,
                  child: Text(
                    dayLabels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    } else if (_viewMode == StepsViewMode.month && monthData != null) {
      // MONTH MODE: 4 weekly bars (1-7, 8-14, 15-21, 22-end)
      final weeklyTotals = monthData.weeklyTotals;
      final maxWeekly = monthData.maxWeeklyTotal;
      const weekLabels = ["W1", "W2", "W3", "W4"];
      
      return SizedBox(
        height: 200,
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(4, (index) {
                  final weekTotal = weeklyTotals[index];
                  final isSelected = index == _selectedDayIndex; // Reuse for week selection
                  final heightRatio = maxWeekly > 0 ? (weekTotal / maxWeekly) : 0.0;
                  final barHeight = (heightRatio * 150).clamp(20.0, 150.0);
                  
                  return _buildBar(index, barHeight, isSelected);
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final isSelected = index == _selectedDayIndex;
                return SizedBox(
                  width: 60,
                  child: Text(
                    weekLabels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    } else {
      // Fallback
      return const SizedBox(height: 200, child: Center(child: Text('Loading...', style: TextStyle(color: Colors.grey))));
    }
  }

  /// Tek bir bar (gün/hafta çubuğu)
  Widget _buildBar(int index, double height, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDayIndex = index;
        });
      },
      child: Container(
        width: 24,
        height: 150,
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF30e87a), Color(0xFF30e87a)],
                  )
                : LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF30e87a).withOpacity(0.3),
                      const Color(0xFF30e87a).withOpacity(0.3),
                    ],
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF30e87a).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: -3,
                    ),
                  ]
                : null,
            border: isSelected
                ? Border.all(
                    color: const Color(0xFF30e87a).withOpacity(0.2),
                    width: 1,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// Statistics grid (2x2 cards) - mode-dependent
  Widget _buildStatisticsGrid(bool isDark, WeeklyStepsData? weekData, MonthlyStepsData? monthData) {
    // Mode-dependent calculations
    int totalSteps;
    int avgSteps;
    
    switch (_viewMode) {
      case StepsViewMode.day:
        totalSteps = _todaySteps;
        avgSteps = _todaySteps;
        break;
      case StepsViewMode.week:
        totalSteps = weekData?.totalSteps ?? 0;
        avgSteps = (weekData?.averageSteps ?? 0).round();
        break;
      case StepsViewMode.month:
        totalSteps = monthData?.totalSteps ?? 0;
        avgSteps = (monthData?.averageSteps ?? 0).round();
        break;
    }
    final distance = _weeklyService.estimateDistanceKm(totalSteps);
    final calories = _weeklyService.estimateCaloriesFromSteps(totalSteps).round();
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('TOTAL', Icons.directions_walk, totalSteps.toString(), 'steps'),
        _buildStatCard('AVERAGE', Icons.equalizer, avgSteps.toString(), 'steps/day'),
        _buildStatCard('DISTANCE', Icons.social_distance, distance.toStringAsFixed(1), 'km'),
        _buildStatCard('BURNED', Icons.local_fire_department_outlined, calories.toString(), 'kcal'),
      ],
    );
  }

  Widget _buildStatCard(String title, IconData icon, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1e24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF30e87a),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Day detail panel - DAY: today, WEEK: selected day, MONTH: selected week
  Widget _buildDayDetailPanel(bool isDark, WeeklyStepsData? weekData, MonthlyStepsData? monthData) {
    // Mode-dependent data
    DateTime selectedDate;
    int selectedSteps;
    String panelTitle;
    
    switch (_viewMode) {
      case StepsViewMode.day:
        selectedDate = DateTime.now();
        selectedSteps = _todaySteps;
        panelTitle = _formatDateTurkish(selectedDate);
        break;
      case StepsViewMode.week:
        final day = weekData!.days[_selectedDayIndex];
        selectedDate = day.date;
        selectedSteps = day.steps;
        panelTitle = _formatDateTurkish(selectedDate);
        break;
      case StepsViewMode.month:
        // Month mode shows weekly summary
        final weeklyTotals = monthData!.weeklyTotals;
        selectedSteps = weeklyTotals[_selectedDayIndex];
        selectedDate = DateTime.now(); // Not used in month mode
        final weekNames = ['1. Hafta (1-7)', '2. Hafta (8-14)', '3. Hafta (15-21)', '4. Hafta (22-sonu)'];
        panelTitle = weekNames[_selectedDayIndex];
        break;
    }
    
    final steps = selectedSteps;
    final activityLabel = _activityLabelFor(steps);
    final motivation = _motivationFor(steps, StepService().dailyGoal);
    final goalPercent = ((steps / StepService().dailyGoal) * 100).clamp(0, 200).round();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1e24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: date/week title + avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date/week and steps
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      panelTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          steps.toString().replaceAllMapped(
                            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]},',
                          ),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF30e87a),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'adım',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Koala avatar
              Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF30e87a).withOpacity(0.2),
                        width: 2,
                      ),
                      color: const Color(0xFF232930),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/happy_koala.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_circle,
                          size: 40,
                          color: Color(0xFF30e87a),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF30e87a).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF30e87a),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Activity and motivation
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt,
                    color: Color(0xFF30e87a),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activityLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    color: Color(0xFF30e87a),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    motivation,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Goal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$goalPercent%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF232930),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (goalPercent / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF30e87a),
                          Color(0xFF30e87a),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tarihi Türkçe formatta göster (Perşembe 18 Mart)
  String _formatDateTurkish(DateTime date) {
    const dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    const monthNames = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
                        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    
    final dayName = dayNames[date.weekday - 1];
    final monthName = monthNames[date.month - 1];
    
    return '$dayName ${date.day} $monthName';
  }

  /// Tudor-Locke aktivite sınıflandırması
  String _activityLabelFor(int steps) {
    if (steps < 5000) return "Bugünkü aktivite: Sedanter";
    if (steps < 7500) return "Bugünkü aktivite: Düşük aktif";
    if (steps < 10000) return "Bugünkü aktivite: Orta aktif";
    if (steps < 12500) return "Bugünkü aktivite: Aktif";
    return "Bugünkü aktivite: Çok aktif";
  }

  /// Hedefe göre motivasyon mesajı
  String _motivationFor(int steps, int goal) {
    final ratio = goal <= 0 ? 0 : steps / goal;
    if (ratio < 0.3) return "Yavaş başlangıç.";
    if (ratio < 0.7) return "Fena değil, devam.";
    if (ratio < 1.0) return "Hedefe az kaldı.";
    return "Bugün Koala gururlu.";
  }
}

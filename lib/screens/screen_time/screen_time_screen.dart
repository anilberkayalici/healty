import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';
import '../../logic/screen_time_service.dart';

/// Screen Time ekranı - Android ekran kullanım istatistikleri
/// Stitch UI tasarımından uyarlanmıştır
class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  final ScreenTimeService _service = ScreenTimeService();
  
  // SharedPreferences keys
  static const String _prefSortMostUsed = 'screen_time_sort_most_used';
  static const String _prefPeriodDay = 'screen_time_period_day';
  
  // State
  bool _isLoading = true;
  ScreenTimeSummary? _data; // Day data
  ScreenTimeSummary? _weekData; // Week data
  String? _errorMessage;
  
  // UI Toggles
  bool _sortMostUsed = true; // true: Most Used, false: Least Used
  bool _periodDay = true; // true: Day, false: Week
  
  // Icon cache for real app icons
  final Map<String, Uint8List> _iconCache = {};
  final Set<String> _iconRequested = {};
  
  @override
  void initState() {
    super.initState();
    _loadPreferences().then((_) => _loadData());
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortMostUsed = prefs.getBool(_prefSortMostUsed) ?? true;
      _periodDay = prefs.getBool(_prefPeriodDay) ?? true;
    });
  }
  
  Future<void> _saveSortPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSortMostUsed, value);
  }
  
  Future<void> _savePeriodPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefPeriodDay, value);
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_periodDay) {
        final data = await _service.getTodayUsageSummary();
        setState(() {
          _data = data;
          _isLoading = false;
        });
        // Load icons for all apps
        if (_data != null) {
          await _ensureIconsLoaded(_data!.topApps.map((e) => e.packageName));
        }
      } else {
        final data = await _service.getWeekUsageSummary();
        setState(() {
          _weekData = data;
          _isLoading = false;
        });
        // Load icons for all apps
        if (_weekData != null) {
          await _ensureIconsLoaded(_weekData!.topApps.map((e) => e.packageName));
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Header
              _buildHeader(isDark),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildContent(isDark),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Header - Title + Refresh + Filters
  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark 
          ? const Color(0xFF000000).withOpacity(0.95)
          : const Color(0xFFF2F2F7).withOpacity(0.95),
      title: const Text(
        'Screen Time',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              const Spacer(),
              
              // Period Toggle (Day/Week)
              _buildPeriodToggle(isDark),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Sort Button (compact version for Apps header)
  Widget _buildSortDropdown(bool isDark) {
    return GestureDetector(
      onTap: () {
        final newValue = !_sortMostUsed;
        setState(() {
          _sortMostUsed = newValue;
        });
        _saveSortPreference(newValue);
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _sortMostUsed ? 'Most Used' : 'Least Used',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.swap_vert,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
  
  /// OLD Sort Button (kept for Day/Week if needed elsewhere, but currently unused)
  Widget _buildOldSortButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        final newValue = !_sortMostUsed;
        setState(() {
          _sortMostUsed = newValue;
        });
        _saveSortPreference(newValue);
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, color: Color(0xFF137FEC), size: 18),
            const SizedBox(width: 6),
            Text(
              _sortMostUsed ? 'Most Used' : 'Least Used',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[200] : Colors.grey[900],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Period Toggle (Day / Week)
  Widget _buildPeriodToggle(bool isDark) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton('Day', _periodDay, isDark),
          _buildPeriodButton('Week', !_periodDay, isDark),
        ],
      ),
    );
  }
  
  Widget _buildPeriodButton(String label, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        final newValue = label == 'Day';
        setState(() {
          _periodDay = newValue;
        });
        _savePeriodPreference(newValue);
        _loadData(); // Reload appropriate period
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.grey[700] : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : Colors.grey[500],
          ),
        ),
      ),
    );
  }
  
  /// Main Content - State Switch
  Widget _buildContent(bool isDark) {
    // Loading
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Error
    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }
    
    // Determine which data to check based on period
    final currentData = _periodDay ? _data : _weekData;
    
    // No data
    if (currentData == null) {
      return _buildNoDataState(isDark);
    }
    
    // Platform not supported (iOS)
    if (!currentData.supported) {
      return _buildUnsupportedState(isDark);
    }
    
    // Permission not granted
    if (!currentData.permissionGranted) {
      return _buildPermissionDeniedState(isDark);
    }
    
    // No usage data
    if (currentData.topApps.isEmpty) {
      return _buildNoUsageState(isDark);
    }
    
    // Success - Show data (Day or Week)
    return _periodDay ? _buildSuccessState(isDark) : _buildWeekSuccessState(isDark);
  }
  
  /// Success State - Data visualization
  Widget _buildSuccessState(bool isDark) {
    // Null-safe: return empty if data is null
    if (_data == null) {
      return _buildNoDataState(isDark);
    }
    
    final total = _data?.totalForegroundTime ?? Duration.zero;
    final apps = _getSortedApps();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circular Chart
        _buildCircularChart(isDark, total),
        const SizedBox(height: 16),
        
        // Top 2 Apps Grid
        if (apps.isNotEmpty) _buildTopAppsGrid(isDark, apps),
        if (apps.isNotEmpty) const SizedBox(height: 24),
        
        // Apps List Header with Sort Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Apps (Today)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ),
              // Sort dropdown on the right
              _buildSortDropdown(isDark),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Apps List
        ...apps.map((app) => _buildAppListItem(isDark, app, total)),
      ],
    );
  }
  
  /// Week Success State - Data visualization for 7 days
  Widget _buildWeekSuccessState(bool isDark) {
    // Null-safe: return empty if data is null
    if (_weekData == null) {
      return _buildNoDataState(isDark);
    }
    
    final total = _weekData?.totalForegroundTime ?? Duration.zero;
    final apps = _getSortedApps(isWeek: true);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circular Chart
        _buildCircularChart(isDark, total, isWeek: true),
        const SizedBox(height: 16),
        
        // Top 2 Apps Grid
        if (apps.isNotEmpty) _buildTopAppsGrid(isDark, apps),
        if (apps.isNotEmpty) const SizedBox(height: 24),
        
        // Apps List Header with Sort Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Apps (This Week)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
              ),
              // Sort dropdown on the right
              _buildSortDropdown(isDark),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Apps List
        ...apps.map((app) => _buildAppListItem(isDark, app, total)),
      ],
    );
  }
  
  /// Circular Progress Chart
  Widget _buildCircularChart(bool isDark, Duration total, {bool isWeek = false}) {
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    // For week: decorative 75% ring; for day: actual percentage
    final percentage = isWeek ? 0.75 : (total.inMinutes / (24 * 60)).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 12,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    color: const Color(0xFF137FEC),
                  ),
                ),
                // Center text - PIXEL-PERFECT centering with RichText
                _buildCenteredTotalLabel(
                  isDark: isDark,
                  isWeek: isWeek,
                  hours: total.inHours,
                  minutes: total.inMinutes.remainder(60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Top 2 Apps Grid
  Widget _buildTopAppsGrid(bool isDark, List<AppUsageEntry> apps) {
    return Row(
      children: [
        if (apps.isNotEmpty)
          Expanded(
            child: _buildTopAppCard(isDark, apps[0], 1),
          ),
        if (apps.length > 1) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildTopAppCard(isDark, apps[1], 2),
          ),
        ],
      ],
    );
  }
  
  /// Top App Card
  Widget _buildTopAppCard(bool isDark, AppUsageEntry app, int rank) {
    final appName = _getSimplifiedAppName(app.packageName);
    final duration = _formatDuration(app.foregroundTime);
    
    // Null-safe: use current data or fallback to zero
    final currentData = _periodDay ? _data : _weekData;
    final totalMinutes = currentData?.totalForegroundTime.inMinutes ?? 1;
    final percentage = (totalMinutes > 0
        ? (app.foregroundTime.inMinutes / totalMinutes) * 100
        : 0.0)
        .clamp(0.0, 100.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Real app icon from device
              _buildAppIcon(app.packageName, size: 44),
              const SizedBox(width: 8),
              Text(
                '#$rank Used',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            appName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            duration,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            color: const Color(0xFF137FEC),
          ),
        ],
      ),
    );
  }
  
  /// App List Item
  Widget _buildAppListItem(bool isDark, AppUsageEntry app, Duration total) {
    final appName = _getSimplifiedAppName(app.packageName);
    final duration = _formatDuration(app.foregroundTime);
    final percentage = (total.inMinutes == 0 
        ? 0.0 
        : (app.foregroundTime.inMinutes / total.inMinutes) * 100)
        .clamp(0.0, 100.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Real app icon from device
              _buildAppIcon(app.packageName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'App',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            color: const Color(0xFF137FEC),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
  
  /// Permission Denied State
  Widget _buildPermissionDeniedState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFF137FEC).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF137FEC).withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.lock_person,
              color: Color(0xFF137FEC),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Usage access required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To analyze your screen time and provide insights, PostureGuard needs permission to view your usage stats.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _service.requestUsagePermission();
                await Future.delayed(const Duration(milliseconds: 500));
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// No Usage Data State
  Widget _buildNoUsageState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_outlined,
              color: Colors.grey[400],
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No usage data yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use your phone for a bit and check back later to see your insights.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Unsupported Platform State (iOS)
  Widget _buildUnsupportedState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1C1C1E)
            : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.red[900]!.withOpacity(0.3)
              : Colors.red[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Platform.isIOS ? Icons.apple : Icons.phone_android,
            color: isDark ? Colors.red[400] : Colors.red[500],
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'iOS Not Supported Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full screen time API integration is currently restricted on this iOS version. Basic features remain available.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Error State
  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// No Data State
  Widget _buildNoDataState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.data_usage_outlined, color: Colors.grey[400], size: 48),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Week Placeholder
  Widget _buildWeekPlaceholder(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Weekly view coming soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weekly usage statistics will be available in a future update.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Helper: Get sorted apps based on toggle
  List<AppUsageEntry> _getSortedApps({bool isWeek = false}) {
    final source = isWeek ? _weekData : _data;
    if (source == null) return [];
    
    final apps = List<AppUsageEntry>.from(source.topApps);
    
    if (_sortMostUsed) {
      // Most used first (already sorted by service)
      apps.sort((a, b) => b.foregroundTime.compareTo(a.foregroundTime));
    } else {
      // Least used first
      apps.sort((a, b) => a.foregroundTime.compareTo(b.foregroundTime));
    }
    
    return apps;
  }
  
  /// Helper: Simplify package name
  String _getSimplifiedAppName(String packageName) {
    // com.instagram.android → instagram
    final parts = packageName.split('.');
    return parts.isNotEmpty ? parts.last : packageName;
  }
  
  /// Helper: Format duration
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
  
  /// Build center text for circular chart - PIXEL-PERFECT centering with TextPainter
  Widget _buildPerfectCenteredTotalText({
    required bool isDark,
    required String labelTop,
    required int hours,
    required int minutes,
  }) {
    final topStyle = TextStyle(
      fontSize: 12,
      letterSpacing: 1.6,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white70 : Colors.black54,
    );

    final numStyle = TextStyle(
      fontSize: 54,
      fontWeight: FontWeight.w800,
      height: 1.0,
      color: isDark ? Colors.white : Colors.black,
    );

    final unitStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.0,
      color: isDark ? Colors.white70 : Colors.black54,
    );

    final span = TextSpan(
      children: [
        TextSpan(text: '$hours', style: numStyle),
        TextSpan(text: 'h', style: unitStyle),
        const TextSpan(text: '  '),
        TextSpan(text: '$minutes', style: numStyle),
        TextSpan(text: 'm', style: unitStyle),
      ],
    );

    // Measure the span width precisely
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(); // no maxWidth => intrinsic width

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(labelTop, style: topStyle, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: tp.width, // critical: measured width prevents visual drift
            child: RichText(
              textAlign: TextAlign.center,
              text: span,
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _ensureIconsLoaded(Iterable<String> packageNames) async {
    if (!defaultTargetPlatform.toString().toLowerCase().contains('android')) return;
    final toFetch = <String>[];
    for (final p in packageNames) {
      if (p.isEmpty || _iconCache.containsKey(p) || _iconRequested.contains(p)) continue;
      _iconRequested.add(p);
      toFetch.add(p);
    }
    if (toFetch.isEmpty) return;
    for (final pkg in toFetch) {
      try {
        final app = await DeviceApps.getApp(pkg, true);
        if (app is ApplicationWithIcon) _iconCache[pkg] = app.icon;
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }
  
  Widget _buildAppIcon(String packageName, {double size = 40}) {
    final bytes = _iconCache[packageName];
    if (bytes != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true));
    }
    return Container(width: size, height: size, decoration: BoxDecoration(color: const Color(0xFF0F2A3A), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.grid_view_rounded, color: Color(0xFF2D8CFF), size: 20));
  }
  
  Widget _buildCenteredTotalLabel({required bool isDark, required bool isWeek, required int hours, required int minutes}) {
    final title = isWeek ? 'WEEK TOTAL' : 'TODAY TOTAL';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          RichText(textAlign: TextAlign.center, text: TextSpan(children: [
            TextSpan(text: '$hours', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 54, fontWeight: FontWeight.w800, height: 1.0)),
            TextSpan(text: 'h ', style: TextStyle(color: isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.7), fontSize: 22, fontWeight: FontWeight.w700, height: 1.0)),
            TextSpan(text: '$minutes', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 54, fontWeight: FontWeight.w800, height: 1.0)),
            TextSpan(text: 'm', style: TextStyle(color: isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.7), fontSize: 22, fontWeight: FontWeight.w700, height: 1.0)),
          ])),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/screen_time_service.dart';
import '../../../data/services/app_icon_service.dart';

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

  // App display names cache
  final Map<String, String> _appNames = {};

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
      } else {
        final data = await _service.getWeekUsageSummary();
        setState(() {
          _weekData = data;
          _isLoading = false;
        });
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
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          'Screen Time',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Spacer(),
                _buildPeriodToggle(isDark),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _buildContent(isDark),
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
    } else {
      // Success state: show data
      return _periodDay
        ? _buildDaySuccessState(isDark)
        : _buildWeekSuccessState(isDark);
    }
  }

  /// Day Success State UI - Optimized for smooth scrolling
  Widget _buildDaySuccessState(bool isDark) {
    if (_data == null) {
      return _buildNoDataState(isDark);
    }

    final total = _data!.totalForegroundTime;
    final apps = _getSortedApps();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Circular Chart
              RepaintBoundary(
                child: _buildCircularChart(isDark, total),
              ),
              const SizedBox(height: 24),

              // Top 2 Apps Grid
              if (apps.length >= 2) ...[
                RepaintBoundary(
                  child: _buildTopAppsGrid(isDark, apps),
                ),
                const SizedBox(height: 24),
              ],

              // Apps List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apps (Today)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  _buildSortDropdown(isDark),
                ],
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),

        // App List Items
        if (apps.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return RepaintBoundary(
                    key: ValueKey(apps[index].packageName),
                    child: _buildAppListItem(isDark, apps[index], total),
                  );
                },
                childCount: apps.length,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
              ),
            ),
          )
        else
          const SliverPadding(
            padding: EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Center(child: Text('No app usage data')),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  /// Week Success State UI - Optimized for smooth scrolling
  Widget _buildWeekSuccessState(bool isDark) {
    if (_weekData == null) {
      return _buildNoDataState(isDark);
    }

    final total = _weekData!.totalForegroundTime;
    final apps = _getSortedApps(isWeek: true);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Circular Chart
              RepaintBoundary(
                child: _buildCircularChart(isDark, total, isWeek: true),
              ),
              const SizedBox(height: 24),

              // Top 2 Apps Grid
              if (apps.length >= 2) ...[
                RepaintBoundary(
                  child: _buildTopAppsGrid(isDark, apps),
                ),
                const SizedBox(height: 24),
              ],

              // Apps List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apps (This Week)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  _buildSortDropdown(isDark),
                ],
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),

        // App List Items
        if (apps.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return RepaintBoundary(
                    key: ValueKey(apps[index].packageName),
                    child: _buildAppListItem(isDark, apps[index], total),
                  );
                },
                childCount: apps.length,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
              ),
            ),
          )
        else
          const SliverPadding(
            padding: EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Center(child: Text('No app usage data')),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  /// Circular Progress Chart
  Widget _buildCircularChart(bool isDark, Duration total,
      {bool isWeek = false}) {
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    // For week: decorative 75% ring; for day: actual percentage
    final percentage =
        isWeek ? 0.75 : (total.inMinutes / (24 * 60)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
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
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[200],
                    color: const Color(0xFF137FEC),
                  ),
                ),
                // Center text - EXACTLY AS SPEC - PERFECTLY CENTERED
                buildTotalCenterText(
                    isWeek, total.inHours, total.inMinutes.remainder(60)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get app display name (with caching)
  Future<String> _getAppDisplayName(String packageName) async {
    if (_appNames.containsKey(packageName)) {
      return _appNames[packageName]!;
    }

    try {
      final appInfo = await AppIconService.getAppInfo(packageName);
      final displayName = appInfo.displayName ?? _getSimplifiedAppName(packageName);
      _appNames[packageName] = displayName;
      return displayName;
    } catch (e) {
      final fallback = _getSimplifiedAppName(packageName);
      _appNames[packageName] = fallback;
      return fallback;
    }
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

  /// Top App Card - Premium Compact Design
  Widget _buildTopAppCard(bool isDark, AppUsageEntry app, int rank) {
    final duration = _formatDuration(app.foregroundTime);

    final currentData = _periodDay ? _data : _weekData;
    final totalMinutes = currentData?.totalForegroundTime.inMinutes ?? 1;
    final percentage = (totalMinutes > 0
            ? (app.foregroundTime.inMinutes / totalMinutes) * 100
            : 0.0)
        .clamp(0.0, 100.0);

    return FutureBuilder<String>(
      future: _getAppDisplayName(app.packageName),
      builder: (context, snapshot) {
        final appName = snapshot.data ?? _getSimplifiedAppName(app.packageName);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildLeadingIcon(app.packageName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          duration,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white.withOpacity(0.95)
                                : const Color(0xFF0A0A0A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 3,
                  backgroundColor: isDark
                      ? Colors.grey.shade800.withOpacity(0.3)
                      : Colors.grey.shade200,
                  color: const Color(0xFF2D8CFF),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// App List Item - Minimal Premium Design
  Widget _buildAppListItem(bool isDark, AppUsageEntry app, Duration total) {
    final duration = _formatDuration(app.foregroundTime);
    final percentage = (total.inMinutes == 0
            ? 0.0
            : (app.foregroundTime.inMinutes / total.inMinutes) * 100)
        .clamp(0.0, 100.0);

    return FutureBuilder<String>(
      future: _getAppDisplayName(app.packageName),
      builder: (context, snapshot) {
        final appName = snapshot.data ?? _getSimplifiedAppName(app.packageName);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.2)
                  : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              _buildLeadingIcon(app.packageName),
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
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 2.5,
                        backgroundColor: isDark
                            ? Colors.grey.shade800.withOpacity(0.2)
                            : Colors.grey.shade200,
                        color: const Color(0xFF2D8CFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withOpacity(0.95)
                          : const Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
        color: isDark ? const Color(0xFF1C1C1E) : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.red[900]!.withOpacity(0.3) : Colors.red[200]!,
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

  /// Real App Icon Widget with FutureBuilder - Optimized for scroll
  Widget _buildLeadingIcon(String packageName) {
    return FutureBuilder<Uint8List?>(
      future: AppIconService.getIcon(packageName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
          // Real icon loaded - use gaplessPlayback for smoother scroll
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              snapshot.data!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              cacheWidth: 120, // Cache at 3x for smooth scaling
              filterQuality: FilterQuality.medium,
            ),
          );
        }
        
        // Fallback icon - const for performance
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0x1F2D8CFF),
          child: Icon(
            Icons.apps_rounded,
            color: Color(0xFF2D8CFF),
            size: 20,
          ),
        );
      },
    );
  }

  // Removed icon loading logic that depended on device_apps package
  void _loadAppIconsSync(List<String> packageNames) {
    // TODO: Implement icon loading when device_apps is properly configured
    // For now, this is a no-op stub to prevent compile errors
  }

  // CENTER TEXT (EXACTLY AS SPEC)
  Widget buildTotalCenterText(bool isWeek, int hours, int minutes) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isWeek ? 'WEEK TOTAL' : 'TODAY TOTAL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          // Responsive time text with FittedBox
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 150, // Fit inside 180px circle with margin
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$hours',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'h ',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    TextSpan(
                      text: '$minutes',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'm',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

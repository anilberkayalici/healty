  /// Screen Time Card - Gerçek ekran kullanım verisiyle
  Widget _buildScreenTimeCard(bool isDark) {
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
            subtitle: 'This platform is not supported yet',
            showButton: false,
          );
        }

        // İzin yok
        if (!data.permissionGranted) {
          return _buildScreenTimeCardBody(
            isDark: isDark,
            mainText: '0h 0m',
            subtitle: 'Usage access permission required',
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
        
        // En çok kullanılan uygulamalar (top 3 göster)
        final appsLabel = data.topApps.isEmpty
            ? 'No usage today'
            : data.topApps
                .take(3)
                .map((a) {
                  // Package name'i kısalt (ör: com.instagram.android → instagram)
                  final shortName = a.packageName.split('.').last;
                  return '$shortName: ${_formatDuration(a.foregroundTime)}';
                })
                .join(' • ');

        return _buildScreenTimeCardBody(
          isDark: isDark,
          mainText: totalLabel,
          subtitle: appsLabel,
          showButton: false,
        );
      },
    );
  }

  /// Screen Time Card UI Body
  Widget _buildScreenTimeCardBody({
    required bool isDark,
    required String mainText,
    required String subtitle,
    required bool showButton,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: showButton ? 160 : 140,
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.smartphone,
              color: Colors.purple,
              size: 18,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
              ),
              Text(
                'Screen Time',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle (apps or message)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showButton) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.withOpacity(0.2),
                      foregroundColor: Colors.purple,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Grant Permission',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
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

package com.example.posture_guard

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class ScreenTimeMonitoringService : Service() {
    
    companion object {
        const val CHANNEL_ID = "screen_time_monitoring"
        const val NOTIFICATION_ID = 9999
        const val POLL_INTERVAL_MS = 2000L // 2 seconds
        
        const val PREFS_NAME = "screen_time_monitor"
        const val PREFS_DAILY_USAGE = "daily_usage_"
        const val PREFS_LAST_RESET = "last_reset_date"
        const val PREFS_NOTIFIED_APPS = "notified_apps_"
        
        // Method channel name for Flutter communication
        const val CHANNEL_NAME = "com.example.posture_guard/screen_time_monitor"
        
        @Volatile
        var isServiceRunning = false
        
        @Volatile
        var methodChannel: MethodChannel? = null
    }
    
    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var sharedPrefs: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private var lastForegroundApp: String? = null
    private var lastCheckTime = System.currentTimeMillis()
    
    // In-memory cache of daily usage (milliseconds)
    private val dailyUsage = mutableMapOf<String, Long>()
    
    // Track which thresholds have been notified for each app
    // Key: packageName, Value: Set of threshold minutes
    private val notifiedThresholds = mutableMapOf<String, MutableSet<Int>>()
    
    private val monitoringRunnable = object : Runnable {
        override fun run() {
            try {
                checkAndResetForNewDay()
                updateForegroundAppUsage()
                checkThresholds()
            } catch (e: Exception) {
                // Silent fail
            }
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        sharedPrefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        loadDailyUsageFromPrefs()
        loadNotifiedThresholdsFromPrefs()
        
        // Create notification channels for alerts
        createAlertNotificationChannel()
        
        // Start monitoring WITHOUT foreground notification
        isServiceRunning = true
        handler.post(monitoringRunnable)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(monitoringRunnable)
        saveDailyUsageToPrefs()
        saveNotifiedThresholdsToPrefs()
        isServiceRunning = false
    }
    
    private fun createAlertNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // High-priority channel for threshold alerts
            val alertChannel = NotificationChannel(
                "screen_time_alerts",
                "Screen Time Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts when app usage exceeds time limits"
                setShowBadge(true)
                enableVibration(true)
                enableLights(true)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(alertChannel)
        }
    }
    
    private fun getForegroundApp(): String? {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 5000 // Last 5 seconds
        
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        return stats?.maxByOrNull { it.lastTimeUsed }?.packageName
    }
    
    private fun updateForegroundAppUsage() {
        val currentTime = System.currentTimeMillis()
        val elapsed = currentTime - lastCheckTime
        lastCheckTime = currentTime
        
        val foregroundApp = getForegroundApp()
        
        // Only track if we have a foreground app and it's the same as before
        // This ensures accurate tracking between polls
        if (foregroundApp != null && foregroundApp == lastForegroundApp) {
            val currentUsage = dailyUsage.getOrDefault(foregroundApp, 0L)
            dailyUsage[foregroundApp] = currentUsage + elapsed
        }
        
        lastForegroundApp = foregroundApp
    }
    
    private fun checkThresholds() {
        val thresholds = listOf(
            5 to 5 * 60 * 1000L,      // 5 minutes
            10 to 10 * 60 * 1000L,    // 10 minutes  
            30 to 30 * 60 * 1000L,    // 30 minutes
            60 to 60 * 60 * 1000L     // 60 minutes
        )
        
        for ((packageName, usage) in dailyUsage) {
            // Skip system apps
            if (isSystemApp(packageName)) continue
            
            for ((thresholdMinutes, thresholdMs) in thresholds) {
                if (usage >= thresholdMs) {
                    val notified = notifiedThresholds
                        .getOrPut(packageName) { mutableSetOf() }
                    
                    if (!notified.contains(thresholdMinutes)) {
                        // Send notification via Flutter
                        sendThresholdNotification(packageName, thresholdMinutes)
                        notified.add(thresholdMinutes)
                    }
                }
            }
        }
    }
    
    private fun sendThresholdNotification(packageName: String, minutes: Int) {
        handler.post {
            methodChannel?.invokeMethod("onThresholdExceeded", mapOf(
                "packageName" to packageName,
                "thresholdMinutes" to minutes,
                "usage" to dailyUsage[packageName]
            ))
        }
    }
    
    private fun isSystemApp(packageName: String): Boolean {
        val systemApps = setOf(
            "com.android.systemui",
            "com.android.launcher",
            "com.google.android.apps.nexuslauncher",
            "com.android.settings",
            "com.example.posture_guard" // Our own app
        )
        return systemApps.contains(packageName) || packageName.startsWith("com.android.")
    }
    
    private fun checkAndResetForNewDay() {
        val lastReset = sharedPrefs.getLong(PREFS_LAST_RESET, 0L)
        val now = System.currentTimeMillis()
        
        val lastResetDay = TimeUnit.MILLISECONDS.toDays(lastReset)
        val currentDay = TimeUnit.MILLISECONDS.toDays(now)
        
        if (currentDay > lastResetDay) {
            // New day detected - reset everything
            dailyUsage.clear()
            notifiedThresholds.clear()
            sharedPrefs.edit()
                .putLong(PREFS_LAST_RESET, now)
                .apply()
        }
    }
    
    private fun loadDailyUsageFromPrefs() {
        val allPrefs = sharedPrefs.all
        for ((key, value) in allPrefs) {
            if (key.startsWith(PREFS_DAILY_USAGE) && value is Long) {
                val packageName = key.removePrefix(PREFS_DAILY_USAGE)
                dailyUsage[packageName] = value
            }
        }
    }
    
    private fun saveDailyUsageToPrefs() {
        val editor = sharedPrefs.edit()
        for ((packageName, usage) in dailyUsage) {
            editor.putLong(PREFS_DAILY_USAGE + packageName, usage)
        }
        editor.apply()
    }
    
    private fun loadNotifiedThresholdsFromPrefs() {
        val allPrefs = sharedPrefs.all
        for ((key, value) in allPrefs) {
            if (key.startsWith(PREFS_NOTIFIED_APPS) && value is Set<*>) {
                val packageName = key.removePrefix(PREFS_NOTIFIED_APPS)
                @Suppress("UNCHECKED_CAST")
                val thresholds = (value as? Set<String>)?.mapNotNull { it.toIntOrNull() }?.toMutableSet()
                if (thresholds != null) {
                    notifiedThresholds[packageName] = thresholds
                }
            }
        }
    }
    
    private fun saveNotifiedThresholdsToPrefs() {
        val editor = sharedPrefs.edit()
        for ((packageName, thresholds) in notifiedThresholds) {
            val stringSet = thresholds.map { it.toString() }.toSet()
            editor.putStringSet(PREFS_NOTIFIED_APPS + packageName, stringSet)
        }
        editor.apply()
    }
}

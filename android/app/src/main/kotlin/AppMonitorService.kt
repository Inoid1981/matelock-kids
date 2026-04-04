package com.example.matelock_kids

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class AppMonitorService : Service() {

    companion object {
        private const val CHANNEL_ID = "matelock_monitor"
        private const val NOTIFICATION_ID = 1001
        private const val PREFS_NAME = "matelock_native"
        private const val BLOCKED_APPS_KEY = "blocked_app_ids"
        private const val UNLOCK_UNTIL_PACKAGE_PREFIX = "unlock_until_pkg_"
    }

    private val handler = Handler(Looper.getMainLooper())

    private var lastOpenedApp: String? = null
    private var lastLaunchTime: Long = 0

    private val checkRunnable = object : Runnable {
        override fun run() {
            try {
                checkForegroundApp()
            } catch (e: Exception) {
                e.printStackTrace()
            }
            handler.postDelayed(this, 1500)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("MateLock Kids")
            .setContentText("Protección activa")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)
        handler.post(checkRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private fun loadBlockedAppIds(): Set<String> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(BLOCKED_APPS_KEY, emptySet()) ?: emptySet()
    }

    private fun getUnlockUntilForPackage(pkg: String): Long {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getLong("$UNLOCK_UNTIL_PACKAGE_PREFIX$pkg", 0L)
    }

    private fun clearUnlockForPackage(pkg: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove("$UNLOCK_UNTIL_PACKAGE_PREFIX$pkg").apply()
    }

    private fun resolveBlockedPackageMap(blockedIds: Set<String>): Map<String, String> {
        val result = mutableMapOf<String, String>()

        for (id in blockedIds) {
            when (id) {
                "youtube" -> {
                    result["com.google.android.youtube"] = id
                }

                "instagram" -> {
                    result["com.instagram.android"] = id
                }

                "tiktok" -> {
                    result["com.zhiliaoapp.musically"] = id
                }

                "chrome" -> {
                    result["com.android.chrome"] = id
                }

                "whatsapp" -> {
                    result["com.whatsapp"] = id
                }

                "calculator" -> {
                    result["com.google.android.calculator"] = id
                    result["com.android.calculator2"] = id
                    result["com.miui.calculator"] = id
                    result["com.samsung.android.calculator"] = id
                    result["com.coloros.calculator"] = id
                }

                else -> {
                    if (id.contains(".")) {
                        result[id] = id
                    }
                }
            }
        }

        return result
    }

    private fun checkForegroundApp() {
        val blockedPackageMap = resolveBlockedPackageMap(loadBlockedAppIds())
        if (blockedPackageMap.isEmpty()) return

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            time - 1000 * 10,
            time
        )

        if (stats.isNullOrEmpty()) return

        val recentApp = stats.maxByOrNull { it.lastTimeUsed } ?: return
        val currentPackageName = recentApp.packageName

        if (currentPackageName == this.packageName) return
        if (!blockedPackageMap.containsKey(currentPackageName)) return

        val now = System.currentTimeMillis()
        val unlockUntil = getUnlockUntilForPackage(currentPackageName)

        if (unlockUntil > now) {
            return
        }

        if (unlockUntil in 1 until now) {
            clearUnlockForPackage(currentPackageName)
        }

        if (currentPackageName != lastOpenedApp || now - lastLaunchTime > 3000) {
            lastOpenedApp = currentPackageName
            lastLaunchTime = now

            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            startActivity(intent)
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(checkRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "MateLock Monitor",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
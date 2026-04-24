package com.example.matelock_kids

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

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

            handler.postDelayed(this, 1000)
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

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        handler.post(checkRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private fun loadBlockedAppIds(): Set<String> {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val savedApps = prefs.getStringSet(BLOCKED_APPS_KEY, emptySet()) ?: emptySet()

        val protectedApps = savedApps.toMutableSet()

        // Ajustes queda siempre protegido para evitar que el niño quite permisos,
        // fuerce cierre, borre datos o desinstale la app.
        protectedApps.add("settings")

        return protectedApps
    }

    private fun getUnlockUntilForPackage(pkg: String): Long {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getLong("$UNLOCK_UNTIL_PACKAGE_PREFIX$pkg", 0L)
    }

    private fun clearUnlockForPackage(pkg: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove("$UNLOCK_UNTIL_PACKAGE_PREFIX$pkg").apply()
    }

    @Suppress("DEPRECATION")
    private fun getForegroundPackageName(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()

        val events = usm.queryEvents(now - 30_000, now)
        val event = UsageEvents.Event()

        var lastForegroundPackage: String? = null

        while (events.hasNextEvent()) {
            events.getNextEvent(event)

            val isForegroundEvent =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    event.eventType == UsageEvents.Event.ACTIVITY_RESUMED
                } else {
                    event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
                }

            if (!event.packageName.isNullOrBlank() && isForegroundEvent) {
                lastForegroundPackage = event.packageName
            }
        }

        if (!lastForegroundPackage.isNullOrBlank()) {
            return lastForegroundPackage
        }

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            now - 5 * 60 * 1000,
            now
        )

        if (stats.isNullOrEmpty()) {
            return null
        }

        return stats.maxByOrNull { it.lastTimeUsed }?.packageName
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

                "settings" -> {
                    result["com.android.settings"] = id
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

        val currentPackageName = getForegroundPackageName() ?: return

        if (currentPackageName == this.packageName) return

        val appId = blockedPackageMap[currentPackageName] ?: return
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
            intent.putExtra("blocked_app_id", appId)
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
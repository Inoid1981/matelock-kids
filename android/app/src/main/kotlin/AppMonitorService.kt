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

    private fun resolveBlockedPackages(blockedIds: Set<String>): Set<String> {
        val result = mutableSetOf<String>()

        for (id in blockedIds) {
            when (id) {
                "youtube" -> {
                    result.add("com.google.android.youtube")
                }

                "instagram" -> {
                    result.add("com.instagram.android")
                }

                "tiktok" -> {
                    result.add("com.zhiliaoapp.musically")
                }

                "chrome" -> {
                    result.add("com.android.chrome")
                }

                "whatsapp" -> {
                    result.add("com.whatsapp")
                }

                "calculator" -> {
                    result.add("com.google.android.calculator")
                    result.add("com.android.calculator2")
                    result.add("com.miui.calculator")
                    result.add("com.samsung.android.calculator")
                    result.add("com.coloros.calculator")
                }

                else -> {
                    if (id.contains(".")) {
                        result.add(id)
                    }
                }
            }
        }

        return result
    }

    private fun checkForegroundApp() {
        val blockedPackages = resolveBlockedPackages(loadBlockedAppIds())
        if (blockedPackages.isEmpty()) return

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()

        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            time - 1000 * 10,
            time
        )

        if (stats.isNullOrEmpty()) return

        val recentApp = stats.maxByOrNull { it.lastTimeUsed } ?: return

        if (recentApp.packageName == packageName) return

        if (blockedPackages.contains(recentApp.packageName)) {
            val now = System.currentTimeMillis()

            if (recentApp.packageName != lastOpenedApp || now - lastLaunchTime > 3000) {
                lastOpenedApp = recentApp.packageName
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
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
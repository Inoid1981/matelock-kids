package com.example.matelock_kids

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "matelock_kids/android"
    private val PREFS_NAME = "matelock_native"
    private val BLOCKED_APPS_KEY = "blocked_app_ids"
    private val UNLOCK_UNTIL_PACKAGE_PREFIX = "unlock_until_pkg_"
    private val PENDING_BLOCKED_APP_KEY = "pending_blocked_app"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        savePendingBlockedAppFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        savePendingBlockedAppFromIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canDrawOverlays" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }

                    "hasUsageAccess" -> {
                        result.success(hasUsageStatsPermission())
                    }

                    "openOverlaySettings" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }

                    "openUsageAccessSettings" -> {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }

                    "setBlockedApps" -> {
                        val appIds = call.argument<List<String>>("appIds") ?: emptyList()
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit().putStringSet(BLOCKED_APPS_KEY, appIds.toSet()).apply()
                        result.success(true)
                    }

                    "setTemporaryUnlock" -> {
                        val appId = call.argument<String>("appId")
                        val unlockUntil = call.argument<Long>("unlockUntil") ?: 0L

                        if (appId.isNullOrBlank()) {
                            result.success(false)
                        } else {
                            val packages = resolvePackagesForAppId(appId)
                            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            val editor = prefs.edit()

                            for (pkg in packages) {
                                editor.putLong("$UNLOCK_UNTIL_PACKAGE_PREFIX$pkg", unlockUntil)
                            }

                            result.success(editor.commit())
                        }
                    }

                    "getTemporaryUnlockForPackage" -> {
                        val packageName = call.argument<String>("packageName")

                        if (packageName.isNullOrBlank()) {
                            result.success(0L)
                        } else {
                            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            val value = prefs.getLong(
                                "$UNLOCK_UNTIL_PACKAGE_PREFIX$packageName",
                                0L
                            )
                            result.success(value)
                        }
                    }

                    "clearTemporaryUnlock" -> {
                        val appId = call.argument<String>("appId")

                        if (appId.isNullOrBlank()) {
                            result.success(false)
                        } else {
                            val packages = resolvePackagesForAppId(appId)
                            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            val editor = prefs.edit()

                            for (pkg in packages) {
                                editor.remove("$UNLOCK_UNTIL_PACKAGE_PREFIX$pkg")
                            }

                            result.success(editor.commit())
                        }
                    }

                    "consumePendingBlockedApp" -> {
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        val value = prefs.getString(PENDING_BLOCKED_APP_KEY, null)
                        prefs.edit().remove(PENDING_BLOCKED_APP_KEY).apply()
                        result.success(value)
                    }

                    "clearPendingBlockedApp" -> {
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit().remove(PENDING_BLOCKED_APP_KEY).apply()
                        result.success(true)
                    }

                    "startMonitorService" -> {
                        val intent = Intent(this, AppMonitorService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }

                    "stopMonitorService" -> {
                        val intent = Intent(this, AppMonitorService::class.java)
                        stopService(intent)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun savePendingBlockedAppFromIntent(intent: Intent?) {
        val blockedAppId = intent?.getStringExtra("blocked_app_id")
        if (blockedAppId.isNullOrBlank()) return

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(PENDING_BLOCKED_APP_KEY, blockedAppId).apply()
    }

    private fun resolvePackagesForAppId(appId: String): Set<String> {
        return when (appId) {
            "youtube" -> setOf("com.google.android.youtube")
            "instagram" -> setOf("com.instagram.android")
            "tiktok" -> setOf("com.zhiliaoapp.musically")
            "chrome" -> setOf("com.android.chrome")
            "whatsapp" -> setOf("com.whatsapp")
            "calculator" -> setOf(
                "com.google.android.calculator",
                "com.android.calculator2",
                "com.miui.calculator",
                "com.samsung.android.calculator",
                "com.coloros.calculator"
            )
            else -> {
                if (appId.contains(".")) setOf(appId) else emptySet()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager

        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }

        return mode == AppOpsManager.MODE_ALLOWED
    }
}
package com.example.matelock_kids

import android.Manifest
import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "matelock_kids/android"
    private val PREFS_NAME = "matelock_native"
    private val BLOCKED_APPS_KEY = "blocked_app_ids"
    private val UNLOCK_UNTIL_PACKAGE_PREFIX = "unlock_until_pkg_"
    private val PENDING_BLOCKED_APP_KEY = "pending_blocked_app"

    private val NOTIFICATION_PERMISSION_REQUEST_CODE = 2001
    private val DEVICE_ADMIN_REQUEST_CODE = 3001

    private var channel: MethodChannel? = null   // <-- AÑADIDO

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        savePendingBlockedAppFromIntent(intent)
        requestNotificationPermissionIfNeeded()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        savePendingBlockedAppFromIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Guardamos el canal en la variable
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // 2. Handler vacío para habilitar comunicación nativo -> Flutter
        channel?.setMethodCallHandler { _, _ -> }

        // 3. Handler real con todos los métodos existentes
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "canDrawOverlays" -> {
                    result.success(Settings.canDrawOverlays(this))
                }

                "hasUsageAccess" -> {
                    result.success(hasUsageStatsPermission())
                }

                "hasNotificationPermission" -> {
                    result.success(hasNotificationPermission())
                }

                "requestNotificationPermission" -> {
                    requestNotificationPermissionIfNeeded()
                    result.success(true)
                }

                "isDeviceAdminActive" -> {
                    result.success(isDeviceAdminActive())
                }

                "requestDeviceAdmin" -> {
                    requestDeviceAdmin()
                    result.success(true)
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

                "openBatteryOptimizationSettings" -> {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                    result.success(true)
                }

                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    intent.data = Uri.parse("package:$packageName")
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
                    prefs.edit().remove(PENDING_BLOCKED_APP_KEY).commit()
                    result.success(value)
                }

                "peekPendingBlockedApp" -> {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val value = prefs.getString(PENDING_BLOCKED_APP_KEY, null)
                    result.success(value)
                }

                "clearPendingBlockedApp" -> {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit().remove(PENDING_BLOCKED_APP_KEY).commit()
                    result.success(true)
                }

                "openAppById" -> {
                    val appId = call.argument<String>("appId")
                    if (appId.isNullOrBlank()) {
                        result.success(false)
                    } else {
                        result.success(openAppById(appId))
                    }
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

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED

            if (!granted) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    private fun isDeviceAdminActive(): Boolean {
        val devicePolicyManager =
            getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

        val componentName = ComponentName(
            this,
            MateLockDeviceAdminReceiver::class.java
        )

        return devicePolicyManager.isAdminActive(componentName)
    }

    private fun requestDeviceAdmin() {
        val componentName = ComponentName(
            this,
            MateLockDeviceAdminReceiver::class.java
        )

        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
        intent.putExtra(
            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "Activa esta protección para evitar que MateLock Kids pueda ser desinstalado sin PIN parental."
        )

        startActivityForResult(intent, DEVICE_ADMIN_REQUEST_CODE)
    }

    private fun savePendingBlockedAppFromIntent(intent: Intent?) {
        val blockedAppId = intent?.getStringExtra("blocked_app_id")
        if (blockedAppId.isNullOrBlank()) return

        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(PENDING_BLOCKED_APP_KEY, blockedAppId).commit()

        // Notificar a Flutter inmediatamente
        //channel?.invokeMethod("onBlockedApp", mapOf("appId" to blockedAppId))
    }

    private fun openAppById(appId: String): Boolean {
        if (appId == "settings") {
            return try {
                val intent = Intent(Settings.ACTION_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }

        val packages = resolvePackagesForAppId(appId)

        for (pkg in packages) {
            try {
                val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                if (launchIntent != null) {
                    launchIntent.addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
                    )
                    startActivity(launchIntent)
                    return true
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        return false
    }

    private fun resolvePackagesForAppId(appId: String): Set<String> {
        return when (appId) {
            "youtube" -> setOf("com.google.android.youtube")
            "instagram" -> setOf("com.instagram.android")
            "tiktok" -> setOf("com.zhiliaoapp.musically")
            "chrome" -> setOf("com.android.chrome")
            "whatsapp" -> setOf("com.whatsapp")
            "settings" -> setOf("com.android.settings")
            "package_installer" -> setOf(
                "com.google.android.packageinstaller",
                "com.android.packageinstaller",
                "com.google.android.permissioncontroller",
                "com.android.permissioncontroller",
                "com.miui.packageinstaller",
                "com.samsung.android.packageinstaller"
            )
            "play_store" -> setOf("com.android.vending")
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
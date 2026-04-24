package com.example.matelock_kids

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val PREFS_NAME = "matelock_native"
        private const val BLOCKED_APPS_KEY = "blocked_app_ids"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val blockedApps = prefs.getStringSet(BLOCKED_APPS_KEY, emptySet()) ?: emptySet()

        if (blockedApps.isEmpty()) return

        val serviceIntent = Intent(context, AppMonitorService::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
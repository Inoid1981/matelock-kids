package com.example.matelock_kids

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

class MateLockDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "MateLock Kids protege este dispositivo. Si desactivas esta protección, la app podrá ser desinstalada y el control parental dejará de funcionar."
    }
}
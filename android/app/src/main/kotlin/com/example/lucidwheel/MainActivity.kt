package com.example.lucidwheel

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            "high_importance_channel",
            "Emergency Alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "LucidWheels emergency and fleet safety alerts"
        }
        manager.createNotificationChannel(channel)
    }
}

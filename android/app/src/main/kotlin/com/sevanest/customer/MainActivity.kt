package com.sevanest.customer

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The backend sends every push with channel_id "sevanest_high_importance". If the channel
        // does not exist Android falls back to a quiet default one, so create it here (idempotent).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "sevanest_high_importance",
                "SevaNest alerts",
                NotificationManager.IMPORTANCE_HIGH,
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    // Dev "Push diagnostics" screen: notifications switch, channel importance (-1 = missing), device.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sevanest/push_diag")
            .setMethodCallHandler { call, result ->
                if (call.method != "state") return@setMethodCallHandler result.notImplemented()
                var importance = -1
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    importance = getSystemService(NotificationManager::class.java)
                        .getNotificationChannel("sevanest_high_importance")?.importance ?: -1
                }
                result.success(
                    mapOf(
                        "enabled" to NotificationManagerCompat.from(this).areNotificationsEnabled(),
                        "channelImportance" to importance,
                        "model" to "${Build.MANUFACTURER} ${Build.MODEL}",
                        "androidVersion" to "${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})",
                    ),
                )
            }
    }
}

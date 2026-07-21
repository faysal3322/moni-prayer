package com.example.moni_prayer

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// audio_service requires FlutterFragmentActivity (not the plain FlutterActivity)
// so it can host the media-session/notification integration.
class MainActivity: FlutterFragmentActivity() {

    private val BACKUP_CHANNEL = "com.example.moni_prayer/backup"

    private val tickReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, PrayerWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                val updateIntent = Intent(context, PrayerWidgetProvider::class.java)
                updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                context.sendBroadcast(updateIntent)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Saves a text file into the public Download folder.
                // Uses MediaStore on Android 10+ (required by scoped storage,
                // and avoids the raw-path write issues some MIUI/Xiaomi
                // devices hit with older approaches). Falls back to a direct
                // file write on Android 9 and below.
                "saveToDownloads" -> {
                    try {
                        val fileName = call.argument<String>("fileName")!!
                        val content = call.argument<String>("content")!!
                        val savedPath = saveTextToDownloads(fileName, content)
                        result.success(savedPath)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveTextToDownloads(fileName: String, content: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw Exception("MediaStore insert returned null")
            resolver.openOutputStream(uri)?.use { it.write(content.toByteArray()) }
                ?: throw Exception("Could not open output stream")
            return "Download/$fileName"
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) downloadsDir.mkdirs()
            val file = File(downloadsDir, fileName)
            file.writeText(content)
            return file.absolutePath
        }
    }

    override fun onStart() {
        super.onStart()
        registerReceiver(tickReceiver, IntentFilter(Intent.ACTION_TIME_TICK))
    }

    override fun onStop() {
        super.onStop()
        try {
            unregisterReceiver(tickReceiver)
        } catch (e: Exception) {
        }
    }
}

package com.example.posture_guard

import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.posture_guard/app_icons"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppIcon" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName == null) {
                            result.error("INVALID", "Package name is null", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val pm = applicationContext.packageManager
                            val drawable = pm.getApplicationIcon(packageName)
                            
                            // Get app label (display name)
                            val appInfo = pm.getApplicationInfo(packageName, 0)
                            val appLabel = pm.getApplicationLabel(appInfo).toString()

                            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
                            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96

                            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                            val canvas = Canvas(bitmap)
                            drawable.setBounds(0, 0, canvas.width, canvas.height)
                            drawable.draw(canvas)

                            val stream = ByteArrayOutputStream()
                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)

                            // Return both icon and label
                            val resultMap = mapOf(
                                "icon" to stream.toByteArray(),
                                "label" to appLabel
                            )
                            result.success(resultMap)
                        } catch (e: Exception) {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

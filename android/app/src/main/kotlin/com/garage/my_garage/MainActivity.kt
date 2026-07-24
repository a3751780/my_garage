package com.garage.my_garage

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "my_garage/home_widget"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateGarageStatusWidget" -> {
                    updateGarageStatusWidget()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun updateGarageStatusWidget() {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val componentName = ComponentName(this, GarageStatusWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        if (appWidgetIds.isNotEmpty()) {
            GarageStatusWidgetProvider.updateWidgets(
                context = this,
                appWidgetManager = appWidgetManager,
                appWidgetIds = appWidgetIds
            )
        }
    }
}

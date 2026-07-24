package com.garage.my_garage

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

class GarageStatusWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            val preferences = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )
            val vehicleName = preferences.getString(
                "flutter.garage_widget_vehicle_name",
                "My Garage"
            ) ?: "My Garage"
            val refuelTitle = preferences.getString(
                "flutter.garage_widget_refuel_title",
                "預估加油"
            ) ?: "預估加油"
            val refuelValue = preferences.getString(
                "flutter.garage_widget_refuel_value",
                "開啟 App 更新"
            ) ?: "開啟 App 更新"
            val refuelStatus = preferences.getString(
                "flutter.garage_widget_refuel_status",
                "unknown"
            ) ?: "unknown"
            val oilTitle = preferences.getString(
                "flutter.garage_widget_oil_title",
                "機油更換"
            ) ?: "機油更換"
            val oilValue = preferences.getString(
                "flutter.garage_widget_oil_value",
                "開啟 App 更新"
            ) ?: "開啟 App 更新"
            val oilStatus = preferences.getString(
                "flutter.garage_widget_oil_status",
                "unknown"
            ) ?: "unknown"
            val updatedAt = preferences.getString(
                "flutter.garage_widget_updated_at",
                ""
            ) ?: ""

            val launchIntent = context.packageManager.getLaunchIntentForPackage(
                context.packageName
            ) ?: Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(
                    context.packageName,
                    R.layout.garage_status_widget
                )
                views.setTextViewText(R.id.widget_vehicle_name, vehicleName)
                views.setTextViewText(R.id.widget_refuel_title, refuelTitle)
                views.setTextViewText(R.id.widget_refuel_value, refuelValue)
                views.setTextViewText(R.id.widget_oil_title, oilTitle)
                views.setTextViewText(R.id.widget_oil_value, oilValue)
                views.setTextViewText(R.id.widget_updated_at, updatedAt)
                applyMetricStatus(
                    views = views,
                    containerId = R.id.widget_refuel_container,
                    titleId = R.id.widget_refuel_title,
                    valueId = R.id.widget_refuel_value,
                    status = refuelStatus
                )
                applyMetricStatus(
                    views = views,
                    containerId = R.id.widget_oil_container,
                    titleId = R.id.widget_oil_title,
                    valueId = R.id.widget_oil_value,
                    status = oilStatus
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }

        private fun applyMetricStatus(
            views: RemoteViews,
            containerId: Int,
            titleId: Int,
            valueId: Int,
            status: String
        ) {
            val backgroundRes = when (status) {
                "danger" -> R.drawable.garage_widget_metric_danger_background
                "warning" -> R.drawable.garage_widget_metric_warning_background
                "normal" -> R.drawable.garage_widget_metric_normal_background
                else -> R.drawable.garage_widget_metric_background
            }
            val titleColor = when (status) {
                "danger" -> Color.parseColor("#7A1D1D")
                "warning" -> Color.parseColor("#73510A")
                "normal" -> Color.parseColor("#155F46")
                else -> Color.parseColor("#35657F")
            }
            val valueColor = when (status) {
                "danger" -> Color.parseColor("#B42318")
                "warning" -> Color.parseColor("#B7791F")
                "normal" -> Color.parseColor("#007A55")
                else -> Color.parseColor("#0072E3")
            }

            views.setInt(containerId, "setBackgroundResource", backgroundRes)
            views.setTextColor(titleId, titleColor)
            views.setTextColor(valueId, valueColor)
        }
    }
}

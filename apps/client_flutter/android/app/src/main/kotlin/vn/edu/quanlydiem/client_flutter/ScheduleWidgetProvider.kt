package vn.edu.quanlydiem.client_flutter

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import java.util.Calendar

class ScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) render(context, manager, id)
        scheduleNextRefresh(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_REFRESH,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> refreshAll(context)
        }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        alarmManager(context)?.cancel(refreshIntent(context))
    }

    companion object {
        const val ACTION_REFRESH = "vn.edu.quanlydiem.client_flutter.SCHEDULE_REFRESH"

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ScheduleWidgetProvider::class.java))
            if (ids.isEmpty()) return
            for (id in ids) render(context, manager, id)
            scheduleNextRefresh(context)
        }

        private fun alarmManager(context: Context): AlarmManager? =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

        private fun refreshIntent(context: Context): PendingIntent {
            val intent = Intent(context, ScheduleWidgetProvider::class.java).setAction(ACTION_REFRESH)
            return PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun scheduleNextRefresh(context: Context) {
            val at = ScheduleStore.nextRefreshAt(ScheduleStore.load(context), Calendar.getInstance())
            alarmManager(context)?.set(AlarmManager.RTC, at, refreshIntent(context))
        }

        private fun openAppIntent(context: Context): PendingIntent {
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent()
            return PendingIntent.getActivity(
                context,
                1,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun render(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.schedule_widget)
            val schedule = ScheduleStore.load(context)
            val open = openAppIntent(context)
            views.setOnClickPendingIntent(R.id.widget_header, open)
            views.setOnClickPendingIntent(R.id.widget_empty, open)
            views.setPendingIntentTemplate(R.id.widget_lessons, open)

            if (schedule == null) {
                views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_name))
                views.setTextViewText(R.id.widget_day, "")
                views.setTextViewText(R.id.widget_empty, context.getString(R.string.widget_signed_out))
            } else {
                val view = ScheduleStore.resolve(schedule, Calendar.getInstance(), ScheduleStore.savedAt(context))
                views.setTextViewText(R.id.widget_title, view.title)
                views.setTextViewText(R.id.widget_day, view.dayLabel)
                views.setTextViewText(R.id.widget_empty, view.emptyMessage)
            }

            val service = Intent(context, ScheduleWidgetService::class.java)
            service.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            service.data = Uri.parse(service.toUri(Intent.URI_INTENT_SCHEME))
            views.setRemoteAdapter(R.id.widget_lessons, service)
            views.setEmptyView(R.id.widget_lessons, R.id.widget_empty)

            manager.updateAppWidget(appWidgetId, views)
            manager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_lessons)
        }
    }
}

package vn.edu.quanlydiem.client_flutter

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.util.Calendar

class ScheduleWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    private class Factory(private val context: Context) : RemoteViewsFactory {
        private var view: DayView? = null

        override fun onCreate() {}

        override fun onDataSetChanged() {
            val schedule = ScheduleStore.load(context)
            view = if (schedule == null) null else ScheduleStore.resolve(schedule, Calendar.getInstance(), ScheduleStore.savedAt(context))
        }

        override fun onDestroy() {
            view = null
        }

        override fun getCount(): Int = view?.lessons?.size ?: 0

        override fun getViewAt(position: Int): RemoteViews {
            val current = view ?: return RemoteViews(context.packageName, R.layout.schedule_widget_item)
            val lesson = current.lessons[position]
            val isCurrent = lesson.tiet == current.currentTiet
            val row = RemoteViews(context.packageName, R.layout.schedule_widget_item)
            row.setTextViewText(R.id.item_time, lesson.start ?: "Tiết ${lesson.tiet}")
            row.setTextViewText(R.id.item_slot, "Tiết ${lesson.tiet}")
            row.setTextViewText(R.id.item_subject, lesson.subject)
            row.setTextViewText(R.id.item_detail, lesson.detail)
            row.setViewVisibility(
                R.id.item_detail,
                if (lesson.detail.isEmpty()) android.view.View.GONE else android.view.View.VISIBLE,
            )
            if (isCurrent) {
                row.setTextViewText(R.id.item_slot, "Tiết ${lesson.tiet} · Đang học")
                row.setInt(R.id.item_root, "setBackgroundResource", R.drawable.widget_current_bg)
            }
            row.setOnClickFillInIntent(R.id.item_root, Intent())
            return row
        }

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewTypeCount(): Int = 1

        override fun getItemId(position: Int): Long = position.toLong()

        override fun hasStableIds(): Boolean = true
    }
}

package vn.edu.quanlydiem.client_flutter

import android.content.Context
import org.json.JSONObject
import java.util.Calendar

data class Lesson(
    val thu: Int,
    val tiet: Int,
    val subject: String,
    val detail: String,
    val start: String?,
    val end: String?,
)

data class Schedule(
    val title: String,
    val semesterStart: String?,
    val semesterEnd: String?,
    val lessons: List<Lesson>,
)

data class DayView(
    val title: String,
    val dayLabel: String,
    val lessons: List<Lesson>,
    val currentTiet: Int?,
    val emptyMessage: String,
)

object ScheduleStore {
    const val CHANNEL = "vn.edu.quanlydiem/schedule_widget"
    private const val PREFS = "eduscore_schedule_widget"
    private const val KEY = "schedule"
    private const val KEY_SAVED_AT = "saved_at"
    private const val STALE_DAYS = 7
    private const val LOOKAHEAD_DAYS = 7
    private val DAY_NAMES = arrayOf("Chủ nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy")

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY, json)
            .putLong(KEY_SAVED_AT, System.currentTimeMillis())
            .apply()
    }

    fun savedAt(context: Context): Long =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong(KEY_SAVED_AT, 0L)

    fun clear(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(KEY).remove(KEY_SAVED_AT).apply()
    }

    fun load(context: Context): Schedule? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return null
        return try {
            parse(raw)
        } catch (e: Exception) {
            null
        }
    }

    fun parse(raw: String): Schedule {
        val root = JSONObject(raw)
        val semester = root.optJSONObject("semester")
        val array = root.optJSONArray("lessons")
        val lessons = ArrayList<Lesson>()
        if (array != null) {
            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)
                lessons.add(
                    Lesson(
                        thu = item.optInt("thu", 2),
                        tiet = item.optInt("tiet", 1),
                        subject = item.optString("subject", ""),
                        detail = item.optString("detail", ""),
                        start = item.optString("start", "").ifEmpty { null },
                        end = item.optString("end", "").ifEmpty { null },
                    ),
                )
            }
        }
        return Schedule(
            title = root.optString("title", "Thời khóa biểu"),
            semesterStart = semester?.optString("start", "")?.ifEmpty { null },
            semesterEnd = semester?.optString("end", "")?.ifEmpty { null },
            lessons = lessons,
        )
    }

    private fun thuOf(calendar: Calendar): Int {
        val dow = calendar.get(Calendar.DAY_OF_WEEK)
        return if (dow == Calendar.SUNDAY) 8 else dow
    }

    private fun isoDay(calendar: Calendar): String =
        String.format(
            "%04d-%02d-%02d",
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )

    private fun minutes(hhmm: String?): Int? {
        if (hhmm == null) return null
        val parts = hhmm.split(":")
        if (parts.size != 2) return null
        val h = parts[0].toIntOrNull() ?: return null
        val m = parts[1].toIntOrNull() ?: return null
        return h * 60 + m
    }

    fun endMinutes(lesson: Lesson): Int? = minutes(lesson.end)

    private fun dateLabel(calendar: Calendar): String =
        String.format(
            "%s %02d/%02d",
            DAY_NAMES[calendar.get(Calendar.DAY_OF_WEEK) - 1],
            calendar.get(Calendar.DAY_OF_MONTH),
            calendar.get(Calendar.MONTH) + 1,
        )

    fun resolve(schedule: Schedule, now: Calendar, savedAt: Long = 0L): DayView {
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        for (offset in 0..LOOKAHEAD_DAYS) {
            val day = now.clone() as Calendar
            day.add(Calendar.DAY_OF_YEAR, offset)
            val iso = isoDay(day)
            val start = schedule.semesterStart
            val end = schedule.semesterEnd
            if ((start != null && iso < start) || (end != null && iso > end)) continue
            val thu = thuOf(day)
            val lessons = schedule.lessons.filter { it.thu == thu }.sortedBy { it.tiet }
            if (lessons.isEmpty()) continue
            if (offset == 0) {
                val remaining = lessons.filter { (endMinutes(it) ?: Int.MAX_VALUE) > nowMinutes }
                if (remaining.isEmpty()) continue
                val current = remaining.firstOrNull {
                    val begin = minutes(it.start)
                    begin != null && begin <= nowMinutes
                }?.tiet
                return DayView(schedule.title, "Hôm nay · " + dateLabel(day), remaining, current, "")
            }
            val prefix = if (offset == 1) "Ngày mai · " else ""
            return DayView(schedule.title, prefix + dateLabel(day), lessons, null, "")
        }
        return DayView(schedule.title, "Hôm nay · " + dateLabel(now), emptyList(), null, emptyMessage(schedule, now, savedAt))
    }

    private fun viDate(iso: String): String =
        iso.substring(8, 10) + "/" + iso.substring(5, 7) + "/" + iso.substring(0, 4)

    private fun emptyMessage(schedule: Schedule, now: Calendar, savedAt: Long): String {
        val today = isoDay(now)
        val start = schedule.semesterStart
        val end = schedule.semesterEnd
        val ageDays = if (savedAt <= 0L) 0L else (now.timeInMillis - savedAt) / 86_400_000L
        return when {
            end != null && today > end -> "Học kỳ đã kết thúc. Mở EduScore để cập nhật lịch mới."
            start != null && today < start -> "Học kỳ bắt đầu ngày ${viDate(start)}."
            ageDays >= STALE_DAYS -> "Không có tiết nào trong $LOOKAHEAD_DAYS ngày tới. Mở EduScore để cập nhật lịch."
            else -> "Không có tiết nào trong $LOOKAHEAD_DAYS ngày tới."
        }
    }

    fun nextRefreshAt(schedule: Schedule?, now: Calendar): Long {
        val midnight = now.clone() as Calendar
        midnight.set(Calendar.HOUR_OF_DAY, 0)
        midnight.set(Calendar.MINUTE, 1)
        midnight.set(Calendar.SECOND, 0)
        midnight.set(Calendar.MILLISECOND, 0)
        midnight.add(Calendar.DAY_OF_YEAR, 1)
        var best = midnight.timeInMillis
        if (schedule == null) return best
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val thu = thuOf(now)
        val boundaries = schedule.lessons
            .filter { it.thu == thu }
            .flatMap { listOfNotNull(minutes(it.start), endMinutes(it)) }
            .filter { it > nowMinutes }
        val nextBoundary = boundaries.minOrNull()
        if (nextBoundary != null) {
            val at = now.clone() as Calendar
            at.set(Calendar.HOUR_OF_DAY, nextBoundary / 60)
            at.set(Calendar.MINUTE, nextBoundary % 60)
            at.set(Calendar.SECOND, 30)
            at.set(Calendar.MILLISECOND, 0)
            if (at.timeInMillis < best) best = at.timeInMillis
        }
        return best
    }
}

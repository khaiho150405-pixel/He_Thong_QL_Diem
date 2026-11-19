package vn.edu.quanlydiem.client_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ScheduleStore.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "save" -> {
                        val json = call.arguments as? String
                        if (json == null) {
                            result.error("bad_args", "Thiếu dữ liệu lịch.", null)
                        } else {
                            ScheduleStore.save(applicationContext, json)
                            ScheduleWidgetProvider.refreshAll(applicationContext)
                            result.success(null)
                        }
                    }
                    "clear" -> {
                        ScheduleStore.clear(applicationContext)
                        ScheduleWidgetProvider.refreshAll(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

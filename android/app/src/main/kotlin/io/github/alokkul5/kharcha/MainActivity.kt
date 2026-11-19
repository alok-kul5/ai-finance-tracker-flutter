package io.github.alokkul5.kharcha

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Reads the SMS inbox for the Dart parser. Only the sender, body and date
 * of each message cross the channel; nothing is stored or sent anywhere
 * from here. The READ_SMS permission is requested from Dart.
 */
class MainActivity : FlutterActivity() {
    private val io = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kharcha/sms").setMethodCallHandler { call, result ->
            if (call.method != "inbox") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (checkSelfPermission(Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
                result.error("permission", "READ_SMS not granted", null)
                return@setMethodCallHandler
            }
            val since = (call.argument<Number>("since") ?: 0).toLong()
            val limit = (call.argument<Number>("limit") ?: 2000).toInt()
            io.execute {
                try {
                    val out = ArrayList<Map<String, Any?>>()
                    contentResolver.query(
                        Uri.parse("content://sms/inbox"),
                        arrayOf("address", "body", "date"),
                        "date > ?",
                        arrayOf(since.toString()),
                        "date DESC",
                    )?.use { c ->
                        val a = c.getColumnIndexOrThrow("address")
                        val b = c.getColumnIndexOrThrow("body")
                        val d = c.getColumnIndexOrThrow("date")
                        while (c.moveToNext() && out.size < limit) {
                            out.add(mapOf("address" to c.getString(a), "body" to c.getString(b), "date" to c.getLong(d)))
                        }
                    }
                    runOnUiThread { result.success(out) }
                } catch (e: Exception) {
                    runOnUiThread { result.error("read", e.message, null) }
                }
            }
        }
    }
}

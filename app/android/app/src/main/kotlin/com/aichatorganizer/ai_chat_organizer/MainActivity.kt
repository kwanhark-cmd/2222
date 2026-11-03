package com.aichatorganizer.ai_chat_organizer

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * "공유하기 → 이 앱"으로 받은 파일을 앱 임시 폴더로 복사해 경로를 넘겨줍니다.
 * 원본 파일은 읽기만 하고 절대 바꾸거나 지우지 않습니다.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aico/share").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialFile") {
                    result.success(pendingPath)
                    pendingPath = null
                } else {
                    result.notImplemented()
                }
            }
        }
        pendingPath = copySharedFile(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val path = copySharedFile(intent) ?: return
        channel?.invokeMethod("sharedFile", path)
    }

    private fun uriFrom(intent: Intent?): Uri? {
        if (intent == null) return null
        return when (intent.action) {
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            Intent.ACTION_VIEW -> intent.data
            else -> null
        }
    }

    private fun copySharedFile(intent: Intent?): String? {
        val uri = uriFrom(intent) ?: return null
        return try {
            var name = "shared_file"
            contentResolver.query(uri, null, null, null, null)?.use { c ->
                val idx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0 && c.moveToFirst()) name = c.getString(idx) ?: name
            }
            val safe = name.replace(Regex("[\\\\/:*?\"<>|]"), "_")
            val dir = File(cacheDir, "shared").apply { mkdirs() }
            val out = File(dir, safe)
            contentResolver.openInputStream(uri)?.use { input ->
                out.outputStream().use { output -> input.copyTo(output) }
            } ?: return null
            out.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}

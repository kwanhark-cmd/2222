package com.aichatorganizer.ai_chat_organizer

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
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
        // 앱 꾸미기: 홈 화면 아이콘·이름 바꾸기(미리 준비한 별칭 중 하나만 켬)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aico/launcher").setMethodCallHandler { call, result ->
            if (call.method == "setAlias") {
                val chosen = call.arguments as String
                val aliases = listOf("LauncherDefault", "LauncherSpeech", "LauncherBooks")
                if (chosen !in aliases) {
                    result.error("alias", "unknown alias", null)
                    return@setMethodCallHandler
                }
                try {
                    // 새 것을 먼저 켜고 나머지를 꺼서 아이콘이 사라지는 순간이 없게
                    val ordered = listOf(chosen) + aliases.filter { it != chosen }
                    for (a in ordered) {
                        val state = if (a == chosen) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                        packageManager.setComponentEnabledSetting(ComponentName(this, "$packageName.$a"), state, PackageManager.DONT_KILL_APP)
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("alias", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
        // 업데이트: 내려받은 APK의 설치 화면 열기(설치는 사용자가 확인)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aico/update").setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                try {
                    val file = File(call.arguments as String)
                    val uri = FileProvider.getUriForFile(this, "$packageName.updates", file)
                    val install = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(install)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("install", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
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

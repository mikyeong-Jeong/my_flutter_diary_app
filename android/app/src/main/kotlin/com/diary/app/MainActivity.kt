package com.diary.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.diary.app/import"
    private val DEEPLINK_CHANNEL = "com.diary.app/deeplink"
    private var sharedData: String? = null
    private var pendingDeeplink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 콜드 스타트: 딥링크를 보관만 하고, Flutter가 첫 화면을 그리기 전에 getDeeplink로 가져감
        handleIntent(intent, isNewIntent = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 앱 실행 중: Flutter로 바로 전달
        handleIntent(intent, isNewIntent = true)
    }

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedData" -> {
                    result.success(sharedData)
                    sharedData = null // Clear after reading
                }
                else -> result.notImplemented()
            }
        }
        
        // 딥링크 처리를 위한 새로운 채널
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEPLINK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeeplink" -> {
                    result.success(pendingDeeplink)
                    pendingDeeplink = null // Clear after reading
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleIntent(intent: Intent?, isNewIntent: Boolean) {
        // 위젯에서 전달된 딥링크 처리
        intent?.data?.let { uri ->
            if (uri.scheme == "diaryapp") {
                val engine = flutterEngine
                if (isNewIntent && engine != null) {
                    // 실행 중인 앱에 바로 전달 (보관하지 않아 중복 이동 방지)
                    pendingDeeplink = null
                    MethodChannel(engine.dartExecutor.binaryMessenger, DEEPLINK_CHANNEL)
                        .invokeMethod("onDeeplink", uri.toString())
                } else {
                    pendingDeeplink = uri.toString()
                }
                return
            }
        }
        
        when (intent?.action) {
            Intent.ACTION_SEND -> {
                if ("text/plain" == intent.type) {
                    handleSendText(intent)
                } else if (intent.type?.startsWith("application/") == true) {
                    handleSendFile(intent)
                }
            }
            Intent.ACTION_VIEW -> {
                intent.data?.let { uri ->
                    handleFileUri(uri)
                }
            }
        }
    }

    private fun handleSendText(intent: Intent) {
        intent.getStringExtra(Intent.EXTRA_TEXT)?.let {
            sharedData = it
        }
    }

    private fun handleSendFile(intent: Intent) {
        (intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM))?.let { uri ->
            handleFileUri(uri)
        }
    }

    private fun handleFileUri(uri: Uri) {
        try {
            contentResolver.openInputStream(uri)?.use { inputStream ->
                // 백업 파일은 UTF-8(BOM 포함)로 저장되므로 인코딩을 명시하고 BOM 제거
                BufferedReader(InputStreamReader(inputStream, Charsets.UTF_8)).use { reader ->
                    sharedData = reader.readText().removePrefix("\uFEFF")
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

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
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
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

    private fun handleIntent(intent: Intent?) {
        // 위젯에서 전달된 딥링크 처리
        intent?.data?.let { uri ->
            if (uri.scheme == "diary") {
                pendingDeeplink = uri.toString()
                // Flutter 엔진이 준비되면 딥링크 전달
                flutterEngine?.let { engine ->
                    MethodChannel(engine.dartExecutor.binaryMessenger, DEEPLINK_CHANNEL)
                        .invokeMethod("onDeeplink", pendingDeeplink)
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
                BufferedReader(InputStreamReader(inputStream)).use { reader ->
                    sharedData = reader.readText()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

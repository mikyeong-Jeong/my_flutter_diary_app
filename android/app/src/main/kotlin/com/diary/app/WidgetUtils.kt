package com.diary.app

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build

/**
 * 위젯 관련 공통 유틸리티 클래스
 * 
 * DiaryAppWidget과 MemoWidget에서 공통으로 사용되는 로직을 관리합니다.
 */
object WidgetUtils {
    
    /**
     * PendingIntent 생성을 위한 공통 플래그
     */
    val pendingIntentFlags: Int
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    
    /**
     * 딥링크 Intent 생성
     * 
     * @param context 컨텍스트
     * @param action 딥링크 액션 (예: "openapp", "newentry", "viewmemo", "editmemo", "write")
     * @param params 추가 파라미터 맵 (선택사항)
     * @return 생성된 Intent
     */
    fun createDeepLinkIntent(
        context: Context,
        action: String,
        params: Map<String, String>? = null
    ): Intent {
        return Intent(context, MainActivity::class.java).apply {
            val uriBuilder = Uri.parse("diary://$action").buildUpon()
            params?.forEach { (key, value) ->
                uriBuilder.appendQueryParameter(key, value)
            }
            data = uriBuilder.build()
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
    }
    
    /**
     * PendingIntent 생성 헬퍼
     * 
     * @param context 컨텍스트
     * @param requestCode 요청 코드
     * @param intent 인텐트
     * @return 생성된 PendingIntent
     */
    fun createPendingIntent(
        context: Context,
        requestCode: Int,
        intent: Intent
    ): PendingIntent {
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            pendingIntentFlags
        )
    }
    
    /**
     * 위젯 클릭 액션을 위한 PendingIntent 생성
     * 
     * @param context 컨텍스트
     * @param requestCode 요청 코드
     * @param action 딥링크 액션
     * @param params 추가 파라미터 (선택사항)
     * @return 생성된 PendingIntent
     */
    fun createWidgetClickIntent(
        context: Context,
        requestCode: Int,
        action: String,
        params: Map<String, String>? = null
    ): PendingIntent {
        val intent = createDeepLinkIntent(context, action, params)
        return createPendingIntent(context, requestCode, intent)
    }
    
    /**
     * 텍스트가 비어있을 때 기본값 제공
     * 
     * @param text 확인할 텍스트
     * @param default 기본값
     * @return 텍스트가 비어있지 않으면 원본, 비어있으면 기본값
     */
    fun getTextOrDefault(text: String?, default: String): String {
        return if (text.isNullOrEmpty()) default else text
    }
}
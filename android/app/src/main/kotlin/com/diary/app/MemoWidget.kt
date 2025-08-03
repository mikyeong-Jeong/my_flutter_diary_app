package com.diary.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.net.Uri
import android.view.View
import es.antonborri.home_widget.HomeWidgetPlugin

class MemoWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateMemoWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateMemoWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        
        // 위젯 크기에 따른 레이아웃 선택
        val layoutId = getLayoutForWidget(context, appWidgetManager, appWidgetId)
        val views = RemoteViews(context.packageName, layoutId)
        
        // 최근 메모 3개 표시
        var hasMemos = false
        
        for (i in 0..2) {
            val memoId = widgetData.getString("memo_${i}_id", "")
            
            if (!memoId.isNullOrEmpty()) {
                hasMemos = true
                val memoDate = widgetData.getString("memo_${i}_date", "")
                val memoTitle = widgetData.getString("memo_${i}_title", "제목 없음")
                val memoContent = widgetData.getString("memo_${i}_content", "")
                
                // 각 메모 항목에 데이터 설정
                when (i) {
                    0 -> {
                        views.setTextViewText(R.id.memo_0_date, memoDate)
                        views.setTextViewText(R.id.memo_0_title, memoTitle)
                        views.setTextViewText(R.id.memo_0_content, memoContent)
                        views.setViewVisibility(R.id.memo_0_container, View.VISIBLE)
                        
                        // 첫 번째 메모 클릭 시 해당 메모로 이동
                        val viewIntent = Intent(context, MainActivity::class.java).apply {
                            data = Uri.parse("diary://viewmemo?id=$memoId")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        val viewPendingIntent = PendingIntent.getActivity(
                            context,
                            appWidgetId * 10,
                            viewIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(R.id.memo_0_container, viewPendingIntent)
                    }
                    1 -> {
                        views.setTextViewText(R.id.memo_1_date, memoDate)
                        views.setTextViewText(R.id.memo_1_title, memoTitle)
                        views.setTextViewText(R.id.memo_1_content, memoContent)
                        views.setViewVisibility(R.id.memo_1_container, View.VISIBLE)
                        
                        val viewIntent = Intent(context, MainActivity::class.java).apply {
                            data = Uri.parse("diary://viewmemo?id=$memoId")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        val viewPendingIntent = PendingIntent.getActivity(
                            context,
                            appWidgetId * 10 + 1,
                            viewIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(R.id.memo_1_container, viewPendingIntent)
                    }
                    2 -> {
                        views.setTextViewText(R.id.memo_2_date, memoDate)
                        views.setTextViewText(R.id.memo_2_title, memoTitle)
                        views.setTextViewText(R.id.memo_2_content, memoContent)
                        views.setViewVisibility(R.id.memo_2_container, View.VISIBLE)
                        
                        val viewIntent = Intent(context, MainActivity::class.java).apply {
                            data = Uri.parse("diary://viewmemo?id=$memoId")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        val viewPendingIntent = PendingIntent.getActivity(
                            context,
                            appWidgetId * 10 + 2,
                            viewIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        views.setOnClickPendingIntent(R.id.memo_2_container, viewPendingIntent)
                    }
                }
            } else {
                // 빈 슬롯 숨기기
                when (i) {
                    0 -> views.setViewVisibility(R.id.memo_0_container, View.GONE)
                    1 -> views.setViewVisibility(R.id.memo_1_container, View.GONE)
                    2 -> views.setViewVisibility(R.id.memo_2_container, View.GONE)
                }
            }
        }
        
        if (!hasMemos) {
            // 메모가 없는 경우 안내 메시지 표시
            views.setViewVisibility(R.id.empty_message_container, View.VISIBLE)
            views.setTextViewText(R.id.empty_message, "작성된 메모가 없습니다")
            
            // 앱 열기
            val openIntent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("diary://write?type=general")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.empty_message_container, openPendingIntent)
        } else {
            views.setViewVisibility(R.id.empty_message_container, View.GONE)
        }
        
        // 새 메모 추가 버튼 설정
        val addIntent = Intent(context, MainActivity::class.java).apply {
            data = Uri.parse("diary://write?type=general")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId + 1000,
            addIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.add_memo_button, addPendingIntent)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getLayoutForWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ): Int {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        
        return when {
            minWidth >= 250 && minHeight >= 180 -> R.layout.memo_widget_large  // 대형
            minWidth >= 180 && minHeight >= 110 -> R.layout.memo_widget_medium // 중형
            else -> R.layout.memo_widget_small // 소형
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateMemoWidget(context, appWidgetManager, appWidgetId)
    }
}
package com.diary.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.net.Uri
import android.view.View

class SingleMemoWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        android.util.Log.d("SingleMemoWidget", "onUpdate called for widgets: ${appWidgetIds.joinToString()}")
        for (appWidgetId in appWidgetIds) {
            updateSingleMemoWidget(context, appWidgetManager, appWidgetId)
        }
    }

    internal fun updateSingleMemoWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        try {
            // home_widget SharedPreferences에서 직접 읽기
            val prefs = context.getSharedPreferences("home_widget", Context.MODE_PRIVATE)
            
            // 디버깅: 위젯 데이터 확인
            android.util.Log.d("SingleMemoWidget", "Widget ID: $appWidgetId")
            android.util.Log.d("SingleMemoWidget", "SharedPreferences keys: ${prefs.all.keys}")
            
            // 위젯 크기에 따른 레이아웃 선택
            val layoutId = getLayoutForWidget(context, appWidgetManager, appWidgetId)
            val views = RemoteViews(context.packageName, layoutId)
        
        // 디버깅을 위해 레이아웃 이름 로그
        val layoutName = when(layoutId) {
            R.layout.single_memo_widget_large -> "large"
            R.layout.single_memo_widget_medium -> "medium"
            R.layout.single_memo_widget_small -> "small"
            else -> "unknown"
        }
        android.util.Log.d("SingleMemoWidget", "Using layout: $layoutName")
        
        // 위젯별 선택된 메모 ID 가져오기
        val selectedMemoId = prefs.getString("single_memo_widget_${appWidgetId}_id", "")
        android.util.Log.d("SingleMemoWidget", "Selected memo ID: $selectedMemoId")
        
        if (!selectedMemoId.isNullOrEmpty()) {
            // 선택된 메모 데이터 표시
            val memoDate = prefs.getString("single_memo_widget_${appWidgetId}_date", "") ?: ""
            val memoTitle = prefs.getString("single_memo_widget_${appWidgetId}_title", "제목 없음") ?: "제목 없음"
            val memoContent = prefs.getString("single_memo_widget_${appWidgetId}_content", "") ?: ""
            val memoIcons = prefs.getString("single_memo_widget_${appWidgetId}_icons", "") ?: ""
            val memoType = prefs.getString("single_memo_widget_${appWidgetId}_type", "general") ?: "general"
            
            // 디버깅: 메모 데이터 확인
            android.util.Log.d("SingleMemoWidget", "Loading memo data:")
            android.util.Log.d("SingleMemoWidget", "  Date: $memoDate")
            android.util.Log.d("SingleMemoWidget", "  Title: $memoTitle")
            android.util.Log.d("SingleMemoWidget", "  Content length: ${memoContent.length}")
            android.util.Log.d("SingleMemoWidget", "  Type: $memoType")
            
            // 텍스트 설정을 안전하게 처리
            try {
                views.setTextViewText(R.id.memo_date, memoDate)
            } catch (e: Exception) {
                android.util.Log.e("SingleMemoWidget", "Error setting date", e)
            }
            
            try {
                views.setTextViewText(R.id.memo_title, memoTitle)
            } catch (e: Exception) {
                android.util.Log.e("SingleMemoWidget", "Error setting title", e)
            }
            
            try {
                views.setTextViewText(R.id.memo_content, memoContent)
            } catch (e: Exception) {
                android.util.Log.e("SingleMemoWidget", "Error setting content", e)
            }
            
            // 아이콘 표시 (일반 메모는 아이콘 없음)
            if (memoType == "general" || memoIcons.isNullOrEmpty()) {
                views.setViewVisibility(R.id.memo_icons, View.GONE)
            } else {
                views.setViewVisibility(R.id.memo_icons, View.VISIBLE)
                views.setTextViewText(R.id.memo_icons, memoIcons)
            }
            
            // 메모 컨테이너 표시 (명시적으로 설정)
            views.setViewVisibility(R.id.memo_container, View.VISIBLE)
            views.setViewVisibility(R.id.empty_container, View.GONE)
            
            // 대형 레이아웃에서는 더 많은 내용을 표시할 수 있음
            // (ScrollView가 제거되었으므로 특별한 처리 불필요)
            
            // 메모 클릭 시 해당 메모로 이동
            val viewIntent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("diary://viewmemo?id=$selectedMemoId")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val viewPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                viewIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.memo_container, viewPendingIntent)
        } else {
            // 선택된 메모가 없는 경우 (명시적으로 설정)
            android.util.Log.d("SingleMemoWidget", "No memo selected for widget $appWidgetId")
            views.setViewVisibility(R.id.memo_container, View.GONE)
            views.setViewVisibility(R.id.empty_container, View.VISIBLE)
            
            // 설정 버튼 클릭 시 설정 화면으로 이동
            val configIntent = Intent(context, SingleMemoWidgetConfigureActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val configPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId + 10000,
                configIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.empty_container, configPendingIntent)
        }
        
        // 설정 버튼 (항상 표시)
        val settingsIntent = Intent(context, SingleMemoWidgetConfigureActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val settingsPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId + 20000,
            settingsIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.settings_button, settingsPendingIntent)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            android.util.Log.e("SingleMemoWidget", "Error updating widget $appWidgetId", e)
            
            // 오류 발생 시 기본 레이아웃으로 에러 메시지 표시
            try {
                val errorViews = RemoteViews(context.packageName, R.layout.single_memo_widget_small)
                errorViews.setTextViewText(R.id.memo_title, "위젯 오류")
                errorViews.setTextViewText(R.id.memo_content, "위젯을 다시 설정해주세요")
                errorViews.setViewVisibility(R.id.memo_container, View.VISIBLE)
                errorViews.setViewVisibility(R.id.empty_container, View.GONE)
                appWidgetManager.updateAppWidget(appWidgetId, errorViews)
            } catch (fallbackError: Exception) {
                android.util.Log.e("SingleMemoWidget", "Fallback error", fallbackError)
            }
        }
    }

    private fun getLayoutForWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ): Int {
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val maxWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
        val maxHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        
        // 디버깅 로그
        android.util.Log.d("SingleMemoWidget", "Widget size - MinWidth: $minWidth, MinHeight: $minHeight, MaxWidth: $maxWidth, MaxHeight: $maxHeight")
        
        // 위젯 크기 판단 기준을 조정 (더 넉넉하게)
        return when {
            minWidth >= 200 || minHeight >= 150 -> R.layout.single_memo_widget_large  // 대형
            minWidth >= 150 || minHeight >= 100 -> R.layout.single_memo_widget_medium // 중형
            else -> R.layout.single_memo_widget_small // 소형
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle?
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateSingleMemoWidget(context, appWidgetManager, appWidgetId)
    }
    
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        // 위젯이 삭제될 때 처리
        // HomeWidgetPlugin은 데이터 삭제 기능을 제공하지 않으므로
        // 실제 데이터 정리는 Flutter 앱에서 처리해야 합니다
        super.onDeleted(context, appWidgetIds)
    }
}
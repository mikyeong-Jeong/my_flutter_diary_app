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

class DiaryAppWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_diary_app).apply {
                val widgetData = HomeWidgetPlugin.getData(context)
                
                // 오늘 날짜 표시
                val todayDate = widgetData.getString("today_date", "")
                setTextViewText(R.id.widget_date, todayDate)
                
                // 전체 일기 개수
                val entryCount = widgetData.getString("entry_count", "0개의 일기")
                setTextViewText(R.id.widget_entry_count, entryCount)
                
                // 최근 일기 3개 표시
                for (i in 0..2) {
                    val containerId = context.resources.getIdentifier("entry_container_$i", "id", context.packageName)
                    val dateId = context.resources.getIdentifier("entry_date_$i", "id", context.packageName)
                    val titleId = context.resources.getIdentifier("entry_title_$i", "id", context.packageName)
                    val iconsId = context.resources.getIdentifier("entry_icons_$i", "id", context.packageName)
                    
                    val entryId = widgetData.getString("entry_${i}_id", "")
                    val date = widgetData.getString("entry_${i}_date", "")
                    val title = widgetData.getString("entry_${i}_title", "")
                    val icons = widgetData.getString("entry_${i}_icons", "")
                    
                    if (!date.isNullOrEmpty() && !entryId.isNullOrEmpty()) {
                        setTextViewText(dateId, date)
                        setTextViewText(titleId, title)
                        setTextViewText(iconsId, icons)
                        setViewVisibility(containerId, View.VISIBLE)
                        
                        // 각 항목에 대한 클릭 이벤트 설정
                        val entryIntent = Intent(context, MainActivity::class.java).apply {
                            data = Uri.parse("diary://viewmemo?id=$entryId")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        }
                        val entryPendingIntent = PendingIntent.getActivity(
                            context,
                            100 + i,  // 각 항목마다 고유한 request code
                            entryIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        setOnClickPendingIntent(containerId, entryPendingIntent)
                    } else {
                        setViewVisibility(containerId, View.GONE)
                    }
                }
                
                // 위젯 클릭 시 앱 열기
                val intent = Intent(context, MainActivity::class.java).apply {
                    data = Uri.parse("diary://openapp")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 
                    0, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                
                // 새 일기 작성 버튼
                val newEntryIntent = Intent(context, MainActivity::class.java).apply {
                    data = Uri.parse("diary://newentry")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val newEntryPendingIntent = PendingIntent.getActivity(
                    context, 
                    1, 
                    newEntryIntent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_new_entry_button, newEntryPendingIntent)
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
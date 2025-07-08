package com.diary.app

// 위젯 기능은 home_widget 패키지가 필요하므로 임시로 비활성화
// TODO: 위젯 기능이 필요한 경우 home_widget 패키지를 다시 추가하고 이 파일을 활성화

/*
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import android.view.View
import com.diary.app.R

class DiaryAppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.diary_widget_layout).apply {
                
                // 오늘 날짜 설정
                val todayDate = widgetData.getString("today_date", "")
                setTextViewText(R.id.today_date, todayDate)
                
                // 일기 개수 설정
                val entryCount = widgetData.getString("entry_count", "0개의 일기")
                setTextViewText(R.id.entry_count, entryCount)
                
                // 최근 일기 3개 설정
                for (i in 0..2) {
                    val date = widgetData.getString("entry_${i}_date", "")
                    val title = widgetData.getString("entry_${i}_title", "")
                    val icons = widgetData.getString("entry_${i}_icons", "")
                    
                    val containerId = context.resources.getIdentifier("entry_${i}_container", "id", context.packageName)
                    val dateId = context.resources.getIdentifier("entry_${i}_date", "id", context.packageName)
                    val titleId = context.resources.getIdentifier("entry_${i}_title", "id", context.packageName)
                    val iconsId = context.resources.getIdentifier("entry_${i}_icons", "id", context.packageName)
                    
                    if (date.isNotEmpty() && containerId != 0) {
                        setViewVisibility(containerId, View.VISIBLE)
                        if (dateId != 0) setTextViewText(dateId, date)
                        if (titleId != 0) setTextViewText(titleId, title)
                        if (iconsId != 0) setTextViewText(iconsId, icons)
                    } else if (containerId != 0) {
                        setViewVisibility(containerId, View.GONE)
                    }
                }
                
                // 위젯 클릭시 앱 열기
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("diaryapp://openapp")
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                
                // 새 일기 버튼 클릭
                val newEntryIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("diaryapp://write")
                )
                setOnClickPendingIntent(R.id.new_entry_button, newEntryIntent)
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
*/

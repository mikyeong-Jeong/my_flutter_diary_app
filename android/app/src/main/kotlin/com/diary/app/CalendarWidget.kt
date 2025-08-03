package com.diary.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.net.Uri
import android.view.View
import java.text.SimpleDateFormat
import java.util.*
import org.json.JSONArray
import org.json.JSONObject

class CalendarWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateCalendarWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateCalendarWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
        val layoutId = getLayoutForWidget(context, appWidgetManager, appWidgetId)
        val views = RemoteViews(context.packageName, layoutId)
        
        // SharedPreferences에서 현재 월 정보 가져오기
        val prefs = context.getSharedPreferences("calendar_widget", Context.MODE_PRIVATE)
        val currentTimeMillis = prefs.getLong("widget_${appWidgetId}_month", System.currentTimeMillis())
        
        // 현재 날짜 정보
        val calendar = Calendar.getInstance()
        calendar.timeInMillis = currentTimeMillis
        val dateFormat = SimpleDateFormat("yyyy년 M월", Locale.KOREAN)
        val currentMonth = dateFormat.format(calendar.time)
        
        // 헤더 설정
        views.setTextViewText(R.id.month_title, currentMonth)
        
        // 일기 데이터 가져오기 (소형 위젯에서 사용하기 위해 먼저 로드)
        val entriesJson = widgetData.getString("entries", "[]") ?: "[]"
        val datedEntries = mutableListOf<String>()
        val entryIdsByDate = mutableMapOf<String, String>()
        
        try {
            val entriesArray = JSONArray(entriesJson)
            for (i in 0 until entriesArray.length()) {
                val entry = entriesArray.getJSONObject(i)
                if (entry.getString("type") == "dated") {
                    entry.optString("date", "")?.let { date ->
                        if (date.isNotEmpty()) {
                            datedEntries.add(date)
                            // 날짜와 ID 매핑 저장
                            entry.optString("id", "")?.let { id ->
                                if (id.isNotEmpty()) {
                                    entryIdsByDate[date] = id
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // 에러 처리
        }
        
        // 소형 위젯용 추가 정보
        if (layoutId == R.layout.calendar_widget_small) {
            val today = Calendar.getInstance()
            val todayFormat = SimpleDateFormat("M월 d일", Locale.KOREAN)
            views.setTextViewText(R.id.today_date, todayFormat.format(today.time))
            
            // 이번 달 일기 개수
            val currentYear = calendar.get(Calendar.YEAR)
            val currentMonthNum = calendar.get(Calendar.MONTH) + 1
            val monthDiaryCount = datedEntries.count { date ->
                date.startsWith("$currentYear-${String.format("%02d", currentMonthNum)}")
            }
            views.setTextViewText(R.id.diary_count, "이번 달 일기: ${monthDiaryCount}개")
        }
        
        // 이전/다음 월 버튼 설정
        val prevIntent = Intent(context, CalendarWidget::class.java).apply {
            action = "PREV_MONTH"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val prevPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 100,
            prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.prev_month_button, prevPendingIntent)
        
        val nextIntent = Intent(context, CalendarWidget::class.java).apply {
            action = "NEXT_MONTH"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val nextPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId * 100 + 1,
            nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.next_month_button, nextPendingIntent)
        
        // 캘린더 그리드 업데이트
        updateCalendarGrid(context, views, calendar, datedEntries, entryIdsByDate, appWidgetId)
        
        // 탭 버튼 설정 (소형 위젯이 아닌 경우만)
        if (layoutId != R.layout.calendar_widget_small) {
            // 달력 탭 (현재 선택됨)
            val calendarIntent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("diary://home?tab=0")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val calendarPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 10000,
                calendarIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.tab_calendar, calendarPendingIntent)
            
            // 일기 탭
            val diaryIntent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("diary://home?tab=1")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val diaryPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 10000 + 1,
                diaryIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.tab_diary, diaryPendingIntent)
            
            // 메모 탭
            val memoIntent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("diary://home?tab=2")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val memoPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 10000 + 2,
                memoIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.tab_memo, memoPendingIntent)
            
            // 계산기 탭
            val calculatorIntent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("diary://home?tab=3")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val calculatorPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId * 10000 + 3,
                calculatorIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.tab_calculator, calculatorPendingIntent)
        }
        
        // 앱 열기 버튼
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.open_app_button, openAppPendingIntent)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun updateCalendarGrid(
        context: Context,
        views: RemoteViews,
        calendar: Calendar,
        datedEntries: List<String>,
        entryIdsByDate: Map<String, String>,
        appWidgetId: Int
    ) {
        // 캘린더 설정
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        val firstDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK) - 1
        val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        val currentYear = calendar.get(Calendar.YEAR)
        val currentMonth = calendar.get(Calendar.MONTH) + 1
        
        // 오늘 날짜
        val today = Calendar.getInstance()
        val todayDay = if (today.get(Calendar.YEAR) == currentYear && 
                           today.get(Calendar.MONTH) + 1 == currentMonth) {
            today.get(Calendar.DAY_OF_MONTH)
        } else {
            -1
        }
        
        // 캘린더 셀 업데이트 (6주 x 7일 = 42개)
        for (i in 0 until 42) {
            val dayNumber = i - firstDayOfWeek + 1
            val cellId = context.resources.getIdentifier("day_$i", "id", context.packageName)
            
            if (dayNumber in 1..daysInMonth) {
                views.setTextViewText(cellId, dayNumber.toString())
                views.setViewVisibility(cellId, View.VISIBLE)
                
                // 날짜 포맷
                val dateString = String.format("%d-%02d-%02d", currentYear, currentMonth, dayNumber)
                
                // 일기가 있는 날 표시
                if (datedEntries.contains(dateString)) {
                    views.setTextColor(cellId, context.getColor(android.R.color.holo_blue_dark))
                    views.setTextViewCompoundDrawables(cellId, 0, 0, 0, R.drawable.ic_dot)
                } else {
                    views.setTextViewCompoundDrawables(cellId, 0, 0, 0, 0)
                }
                
                // 오늘 날짜 강조
                if (dayNumber == todayDay) {
                    views.setInt(cellId, "setBackgroundResource", R.drawable.today_background)
                } else {
                    views.setInt(cellId, "setBackgroundResource", 0)
                }
                
                // 주말 색상
                val dayOfWeek = (i % 7)
                if (dayOfWeek == 0) { // 일요일
                    views.setTextColor(cellId, context.getColor(android.R.color.holo_red_dark))
                } else if (dayOfWeek == 6) { // 토요일
                    views.setTextColor(cellId, context.getColor(android.R.color.holo_blue_light))
                }
                
                // 날짜 클릭 시 해당 날짜의 일기 작성/보기
                val dayIntent = Intent(context, MainActivity::class.java).apply {
                    // 일기가 있으면 보기, 없으면 작성
                    if (datedEntries.contains(dateString)) {
                        val entryId = entryIdsByDate[dateString]
                        if (entryId != null) {
                            // ID가 있으면 직접 해당 일기로 이동
                            data = Uri.parse("diary://viewmemo?id=$entryId")
                        } else {
                            // ID가 없으면 날짜로 검색
                            data = Uri.parse("diary://viewdate?date=$dateString")
                        }
                    } else {
                        data = Uri.parse("diary://write?date=$dateString")
                    }
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val dayPendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId * 1000 + dayNumber,
                    dayIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(cellId, dayPendingIntent)
            } else {
                views.setViewVisibility(cellId, View.INVISIBLE)
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
        
        return when {
            minWidth >= 300 && minHeight >= 300 -> R.layout.calendar_widget_large
            minWidth >= 250 && minHeight >= 250 -> R.layout.calendar_widget_medium
            else -> R.layout.calendar_widget_small
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "PREV_MONTH", "NEXT_MONTH" -> {
                val appWidgetId = intent.getIntExtra(
                    AppWidgetManager.EXTRA_APPWIDGET_ID,
                    AppWidgetManager.INVALID_APPWIDGET_ID
                )
                if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                    // SharedPreferences에서 현재 월 정보 가져오기
                    val prefs = context.getSharedPreferences("calendar_widget", Context.MODE_PRIVATE)
                    val currentTimeMillis = prefs.getLong("widget_${appWidgetId}_month", System.currentTimeMillis())
                    
                    // 월 이동
                    val calendar = Calendar.getInstance()
                    calendar.timeInMillis = currentTimeMillis
                    
                    if (intent.action == "PREV_MONTH") {
                        calendar.add(Calendar.MONTH, -1)
                    } else {
                        calendar.add(Calendar.MONTH, 1)
                    }
                    
                    // 새로운 월 정보 저장
                    prefs.edit().putLong("widget_${appWidgetId}_month", calendar.timeInMillis).apply()
                    
                    // 위젯 업데이트
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    updateCalendarWidget(context, appWidgetManager, appWidgetId)
                }
            }
        }
    }
}
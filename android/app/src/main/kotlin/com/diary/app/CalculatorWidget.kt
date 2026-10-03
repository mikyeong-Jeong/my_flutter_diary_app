package com.diary.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.text.DecimalFormat

/**
 * 계산기 위젯 (계산 1개 표시)
 *
 * 위젯을 놓을 때 고른 계산의 제목, 지출 총액, 남은 금액을 표시합니다.
 * 계산 데이터는 Flutter 앱(WidgetService.updateCalculatorWidgets)이 'calculator_sheets'로 저장하며,
 * 위젯은 선택된 계산 id로 이 목록에서 찾아 최신 금액을 표시합니다.
 */
class CalculatorWidget : AppWidgetProvider() {

    companion object {
        /** 위젯별 선택된 계산 id 저장 키 */
        fun sheetIdKey(appWidgetId: Int) = "calculator_widget_${appWidgetId}_sheet_id"

        /** Flutter 앱이 저장한 계산 목록 */
        fun loadSheets(context: Context): JSONArray {
            return try {
                val json = HomeWidgetPlugin.getData(context).getString("calculator_sheets", "[]") ?: "[]"
                JSONArray(json)
            } catch (e: Exception) {
                JSONArray()
            }
        }

        /** id로 계산 찾기 (없으면 null) */
        fun findSheet(context: Context, sheetId: String?): JSONObject? {
            if (sheetId.isNullOrEmpty()) return null
            val sheets = loadSheets(context)
            for (i in 0 until sheets.length()) {
                val sheet = sheets.getJSONObject(i)
                if (sheet.optString("id") == sheetId) return sheet
            }
            return null
        }

        /** 금액 표시 (천 단위 콤마, 음수는 앞에 '-') */
        fun formatAmount(amount: Long): String {
            val formatted = DecimalFormat("#,###").format(kotlin.math.abs(amount))
            return if (amount < 0) "-${formatted}원" else "${formatted}원"
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateCalculatorWidget(context, appWidgetManager, appWidgetId)
        }
    }

    internal fun updateCalculatorWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.calculator_widget)
        val prefs = HomeWidgetPlugin.getData(context)
        val sheetId = prefs.getString(sheetIdKey(appWidgetId), null)
        val sheet = findSheet(context, sheetId)

        if (sheet != null) {
            // 선택된 계산 표시
            val title = sheet.optString("title", "")
            val total = sheet.optLong("total", 0L)
            val budget = sheet.optLong("budget", 0L)
            val remaining = sheet.optLong("remaining", 0L)

            views.setTextViewText(R.id.calc_title, if (title.isEmpty()) "제목 없음" else title)
            views.setTextViewText(R.id.calc_total, formatAmount(total))
            if (budget > 0) {
                views.setTextViewText(R.id.calc_remaining, formatAmount(remaining))
                // 예산 초과 시 빨간색
                views.setTextColor(
                    R.id.calc_remaining,
                    if (remaining < 0) Color.parseColor("#D32F2F") else Color.parseColor("#1976D2")
                )
            } else {
                views.setTextViewText(R.id.calc_remaining, "-")
                views.setTextColor(R.id.calc_remaining, Color.parseColor("#757575"))
            }

            views.setViewVisibility(R.id.calc_container, View.VISIBLE)
            views.setViewVisibility(R.id.empty_container, View.GONE)

            // 누르면 앱에서 해당 계산 화면을 바로 열기
            val viewIntent = Intent(context, MainActivity::class.java).apply {
                data = Uri.parse("diaryapp://viewcalc?id=${Uri.encode(sheet.optString("id"))}")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val viewPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId + 30000,
                viewIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.calc_container, viewPendingIntent)
        } else {
            // 선택된 계산이 없거나 삭제된 경우: 누르면 계산 선택 화면
            views.setViewVisibility(R.id.calc_container, View.GONE)
            views.setViewVisibility(R.id.empty_container, View.VISIBLE)
            views.setOnClickPendingIntent(R.id.empty_container, configPendingIntent(context, appWidgetId, 40000))
        }

        // 설정 버튼: 표시할 계산 다시 선택
        views.setOnClickPendingIntent(R.id.settings_button, configPendingIntent(context, appWidgetId, 50000))

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun configPendingIntent(context: Context, appWidgetId: Int, requestOffset: Int): PendingIntent {
        val configIntent = Intent(context, CalculatorWidgetConfigureActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        return PendingIntent.getActivity(
            context,
            appWidgetId + requestOffset,
            configIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        // 삭제된 위젯의 선택 정보 정리
        val editor = HomeWidgetPlugin.getData(context).edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove(sheetIdKey(appWidgetId))
        }
        editor.apply()
        super.onDeleted(context, appWidgetIds)
    }
}

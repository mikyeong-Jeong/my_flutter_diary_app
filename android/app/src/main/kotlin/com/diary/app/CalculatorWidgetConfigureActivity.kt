package com.diary.app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ListView
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * 계산기 위젯 설정 화면
 *
 * 위젯에 표시할 계산을 목록에서 선택합니다.
 */
class CalculatorWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var listView: ListView
    private lateinit var saveButton: Button
    private var selectedSheetId: String? = null
    private val sheets = mutableListOf<SheetItem>()

    data class SheetItem(
        val id: String,
        val title: String,
        val total: Long,
        val budget: Long,
        val remaining: Long
    ) {
        override fun toString(): String {
            val displayTitle = if (title.isEmpty()) "제목 없음" else title
            val summary = if (budget > 0) {
                "지출 ${CalculatorWidget.formatAmount(total)} · 남은 ${CalculatorWidget.formatAmount(remaining)}"
            } else {
                "지출 ${CalculatorWidget.formatAmount(total)}"
            }
            return "$displayTitle\n$summary"
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 선택하지 않고 닫으면 위젯 추가 취소
        setResult(RESULT_CANCELED)
        setContentView(R.layout.calculator_widget_configure)

        appWidgetId = intent.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        listView = findViewById(R.id.sheet_list)
        saveButton = findViewById(R.id.save_button)

        loadSheets()

        listView.setOnItemClickListener { _, _, position, _ ->
            selectedSheetId = sheets[position].id
            saveButton.isEnabled = true
        }

        saveButton.setOnClickListener { saveSelection() }
    }

    private fun loadSheets() {
        val array = CalculatorWidget.loadSheets(this)
        sheets.clear()
        for (i in 0 until array.length()) {
            val sheet = array.getJSONObject(i)
            sheets.add(
                SheetItem(
                    id = sheet.optString("id"),
                    title = sheet.optString("title", ""),
                    total = sheet.optLong("total", 0L),
                    budget = sheet.optLong("budget", 0L),
                    remaining = sheet.optLong("remaining", 0L)
                )
            )
        }

        if (sheets.isEmpty()) {
            // 계산이 없으면 안내 문구 표시
            listView.adapter = ArrayAdapter(
                this,
                android.R.layout.simple_list_item_1,
                arrayOf("작성된 계산이 없습니다.\n앱의 계산기 탭에서 계산을 추가해주세요.")
            )
            listView.isEnabled = false
            saveButton.isEnabled = false
            return
        }

        listView.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_single_choice, sheets)
        listView.choiceMode = ListView.CHOICE_MODE_SINGLE

        // 이미 선택된 계산이 있으면 체크 표시
        val currentId = HomeWidgetPlugin.getData(this).getString(CalculatorWidget.sheetIdKey(appWidgetId), null)
        val index = sheets.indexOfFirst { it.id == currentId }
        if (index >= 0) {
            listView.setItemChecked(index, true)
            selectedSheetId = currentId
            saveButton.isEnabled = true
        }
    }

    private fun saveSelection() {
        val sheetId = selectedSheetId
        if (sheetId == null) {
            Toast.makeText(this, "계산을 선택해주세요.", Toast.LENGTH_SHORT).show()
            return
        }

        HomeWidgetPlugin.getData(this).edit()
            .putString(CalculatorWidget.sheetIdKey(appWidgetId), sheetId)
            .apply()

        // 위젯 즉시 갱신
        val appWidgetManager = AppWidgetManager.getInstance(this)
        CalculatorWidget().updateCalculatorWidget(this, appWidgetManager, appWidgetId)

        val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }
}

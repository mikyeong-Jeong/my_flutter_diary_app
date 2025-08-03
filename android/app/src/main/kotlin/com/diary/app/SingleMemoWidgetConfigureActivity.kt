package com.diary.app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ListView
import android.widget.TextView
import android.widget.Toast
import android.view.Gravity
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

class SingleMemoWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var listView: ListView
    private lateinit var saveButton: Button
    private var selectedMemoId: String? = null
    private val memos = mutableListOf<MemoItem>()
    
    data class MemoItem(
        val id: String,
        val title: String,
        val content: String,
        val date: String,
        val type: String,
        val updatedAt: String
    ) {
        override fun toString(): String {
            val displayTitle = if (title.isEmpty()) "제목 없음" else title
            val displayContent = if (content.length > 50) 
                content.substring(0, 50) + "..." else content
            val displayDate = date.ifEmpty { updatedAt }
            return "$displayTitle\n$displayContent\n$displayDate"
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 결과를 취소로 설정
        setResult(RESULT_CANCELED)
        
        // 레이아웃 설정
        setContentView(R.layout.single_memo_widget_configure)
        
        // 인텐트에서 위젯 ID 가져오기
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }
        
        // 잘못된 위젯 ID인 경우 종료
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        
        // UI 초기화
        listView = findViewById(R.id.memo_list)
        saveButton = findViewById(R.id.save_button)
        
        // 메모 목록 로드
        loadMemos()
        
        // 리스트 아이템 클릭 리스너
        listView.setOnItemClickListener { _, _, position, _ ->
            selectedMemoId = memos[position].id
            saveButton.isEnabled = true
        }
        
        // 저장 버튼 클릭 리스너
        saveButton.setOnClickListener {
            saveMemoSelection()
        }
    }
    
    private fun loadMemos() {
        try {
            // SharedPreferences에서 메모 데이터 가져오기
            // home_widget 패키지가 사용하는 SharedPreferences
            val prefs = getSharedPreferences("home_widget", MODE_PRIVATE)
            
            // 디버깅: 모든 SharedPreferences 파일 확인
            android.util.Log.d("SingleMemoWidget", "=== SharedPreferences Debug ===")
            
            // home_widget SharedPreferences의 모든 키 출력
            android.util.Log.d("SingleMemoWidget", "home_widget keys: ${prefs.all.keys}")
            
            // FlutterSharedPreferences도 확인
            val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            android.util.Log.d("SingleMemoWidget", "FlutterSharedPreferences keys: ${flutterPrefs.all.keys}")
            
            // 다양한 키로 시도
            var entriesJson = prefs.getString("entries", null)
            if (entriesJson == null) {
                entriesJson = prefs.getString("flutter.entries", null)
            }
            if (entriesJson == null) {
                entriesJson = flutterPrefs.getString("flutter.entries", null)
            }
            if (entriesJson == null) {
                // Flutter의 SharedPreferences 키 형식 확인
                val entriesKey = flutterPrefs.all.keys.find { it.contains("entries") }
                if (entriesKey != null) {
                    entriesJson = flutterPrefs.getString(entriesKey, null)
                    android.util.Log.d("SingleMemoWidget", "Found entries with key: $entriesKey")
                }
            }
            if (entriesJson == null) {
                entriesJson = "[]"
            }
            
            // 디버깅: 데이터 확인
            android.util.Log.d("SingleMemoWidget", "Entries JSON: $entriesJson")
            android.util.Log.d("SingleMemoWidget", "JSON length: ${entriesJson.length}")
            
            // 메모가 없는 경우 처리를 나중에 함
            
            val entriesArray = JSONArray(entriesJson)
            
            memos.clear()
            
            // JSON 배열을 MemoItem 리스트로 변환
            for (i in 0 until entriesArray.length()) {
                val entry = entriesArray.getJSONObject(i)
                val type = entry.optString("type", "dated")
                
                // 모든 메모 타입 포함 (날짜별 메모와 일반 메모)
                val memoItem = MemoItem(
                    id = entry.getString("id"),
                    title = entry.optString("title", ""),
                    content = entry.optString("content", ""),
                    date = entry.optString("date", ""),
                    type = type,
                    updatedAt = entry.optString("updatedAt", "")
                )
                memos.add(memoItem)
            }
            
            // 최신 메모가 위에 오도록 정렬
            memos.sortByDescending { 
                if (it.date.isNotEmpty()) it.date else it.updatedAt 
            }
            
            // 메모가 없는 경우 안내 메시지 표시
            if (memos.isEmpty()) {
                // 어댑터에 안내 메시지 추가
                val noDataMessage = MemoItem(
                    id = "",
                    title = "작성된 메모가 없습니다",
                    content = "앱을 실행하여 메모를 작성해주세요.",
                    date = "",
                    type = "",
                    updatedAt = ""
                )
                memos.add(noDataMessage)
                
                // 어댑터 설정
                val adapter = ArrayAdapter(
                    this,
                    android.R.layout.simple_list_item_1,
                    arrayOf("작성된 메모가 없습니다.\n앱을 실행하여 메모를 작성해주세요.")
                )
                listView.adapter = adapter
                listView.isEnabled = false
                saveButton.isEnabled = false
            } else {
                // 어댑터 설정
                val adapter = ArrayAdapter(
                    this,
                    android.R.layout.simple_list_item_single_choice,
                    memos
                )
                listView.adapter = adapter
                listView.choiceMode = ListView.CHOICE_MODE_SINGLE
            }
            
            // 현재 선택된 메모가 있는지 확인
            val currentMemoId = prefs.getString("single_memo_widget_${appWidgetId}_id", null)
            if (currentMemoId != null) {
                val index = memos.indexOfFirst { it.id == currentMemoId }
                if (index >= 0) {
                    listView.setItemChecked(index, true)
                    selectedMemoId = currentMemoId
                    saveButton.isEnabled = true
                }
            }
            
        } catch (e: Exception) {
            Toast.makeText(this, "메모를 불러오는 중 오류가 발생했습니다.", Toast.LENGTH_SHORT).show()
            finish()
        }
    }
    
    private fun saveMemoSelection() {
        if (selectedMemoId == null) {
            Toast.makeText(this, "메모를 선택해주세요.", Toast.LENGTH_SHORT).show()
            return
        }
        
        val selectedMemo = memos.find { it.id == selectedMemoId }
        if (selectedMemo == null) {
            Toast.makeText(this, "선택한 메모를 찾을 수 없습니다.", Toast.LENGTH_SHORT).show()
            return
        }
        
        // 선택한 메모 데이터 저장
        // home_widget 패키지가 사용하는 SharedPreferences
        val prefs = getSharedPreferences("home_widget", MODE_PRIVATE)
        val editor = prefs.edit()
        
        // 날짜 포맷팅
        val displayDate = if (selectedMemo.type == "dated" && selectedMemo.date.isNotEmpty()) {
            try {
                val parts = selectedMemo.date.split("-")
                "${parts[0]}년 ${parts[1].toInt()}월 ${parts[2].toInt()}일"
            } catch (e: Exception) {
                selectedMemo.date
            }
        } else {
            try {
                val parts = selectedMemo.updatedAt.split("T")[0].split("-")
                "${parts[0]}년 ${parts[1].toInt()}월 ${parts[2].toInt()}일"
            } catch (e: Exception) {
                selectedMemo.updatedAt
            }
        }
        
        editor.putString("single_memo_widget_${appWidgetId}_id", selectedMemo.id)
        editor.putString("single_memo_widget_${appWidgetId}_date", displayDate)
        editor.putString("single_memo_widget_${appWidgetId}_title", selectedMemo.title)
        editor.putString("single_memo_widget_${appWidgetId}_content", selectedMemo.content)
        editor.putString("single_memo_widget_${appWidgetId}_icons", "") // 일반 메모는 아이콘 없음
        editor.putString("single_memo_widget_${appWidgetId}_type", selectedMemo.type)
        editor.apply()
        
        // 디버깅 로그
        android.util.Log.d("SingleMemoWidget", "Saving memo for widget $appWidgetId")
        android.util.Log.d("SingleMemoWidget", "Memo ID: ${selectedMemo.id}")
        android.util.Log.d("SingleMemoWidget", "Memo Title: ${selectedMemo.title}")
        
        // 위젯 업데이트
        val appWidgetManager = AppWidgetManager.getInstance(this)
        SingleMemoWidget().updateSingleMemoWidget(this, appWidgetManager, appWidgetId)
        
        // 위젯 프로바이더에 업데이트 요청
        val updateIntent = Intent(this, SingleMemoWidget::class.java)
        updateIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        updateIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        sendBroadcast(updateIntent)
        
        // 결과 반환
        val resultValue = Intent()
        resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }
}
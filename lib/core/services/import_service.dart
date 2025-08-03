import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// 외부 앱에서 공유된 백업 데이터를 처리하는 서비스
/// 
/// 다른 앱에서 공유 기능을 통해 전달된 JSON 백업 파일을
/// 가져와서 복원할 수 있도록 합니다.
class ImportService {
  static const platform = MethodChannel('com.diary.app/import');
  
  /// 앱이 시작될 때 공유된 데이터 확인
  /// 
  /// 다른 앱에서 Intent를 통해 전달된 데이터가 있는지 확인합니다.
  /// 웹 플랫폼에서는 지원하지 않습니다.
  static Future<String?> checkSharedData() async {
    // 웹 플랫폼에서는 지원하지 않음
    if (kIsWeb) {
      return null;
    }
    
    try {
      final String? data = await platform.invokeMethod('getSharedData');
      return data;
    } on PlatformException {
      // 공유 데이터 가져오기 실패 - 정상적인 상황일 수 있음
      return null;
    }
  }
  
  /// 공유된 데이터가 백업 데이터인지 확인
  /// 
  /// JSON 형식이고 'entries'와 'settings' 필드를 모두 포함하고 있는지 검사합니다.
  /// 
  /// @param data : 검사할 JSON 문자열
  /// @return bool : 유효한 백업 데이터면 true
  static bool isValidBackupData(String? data) {
    if (data == null || data.isEmpty) return false;
    
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return false;

      final hasEntries  = decoded.containsKey('entries');
      final hasSettings = decoded.containsKey('settings');
      // entries와 settings 모두 있어야 유효한 백업으로 간주
      return hasEntries && hasSettings;
      } catch (e) {
      return false;
    }
  }
}

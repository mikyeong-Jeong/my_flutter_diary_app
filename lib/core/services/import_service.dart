import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class ImportService {
  static const platform = MethodChannel('com.diary.app/import');
  
  // 앱이 시작될 때 공유된 데이터 확인
  static Future<String?> checkSharedData() async {
    // 웹 플랫폼에서는 지원하지 않음
    if (kIsWeb) {
      return null;
    }
    
    try {
      final String? data = await platform.invokeMethod('getSharedData');
      return data;
    } on PlatformException catch (e) {
      print('Failed to get shared data: ${e.message}');
      return null;
    }
  }
  
  // 공유된 데이터가 백업 데이터인지 확인
  static bool isValidBackupData(String? data) {
    if (data == null || data.isEmpty) return false;
    
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) return false;

      final hasEntries  = decoded.containsKey('entries');
      final hasSettings = decoded.containsKey('settings');
      // 둘 다 있어야 할 때:
      return hasEntries && hasSettings;
      // 어느 하나만으로 충분하면:
      // return hasEntries || hasSettings;
      } catch (e) {
      return false;
    }
  }
}

// 조건부 import를 사용하여 플랫폼별 구현 선택
export 'storage_service_mobile.dart' 
    if (dart.library.html) 'storage_service_web.dart';

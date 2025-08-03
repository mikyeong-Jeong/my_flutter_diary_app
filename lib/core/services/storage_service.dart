/**
 * 스토리지 서비스 플랫폼 선택 파일
 * 
 * 조건부 export를 사용하여 플랫폼에 따라 적절한 스토리지 구현체를 자동으로 선택합니다.
 * 
 * 플랫폼별 구현:
 * - 모바일 (Android/iOS): storage_service_mobile.dart - 파일 시스템 사용
 * - 웹 (Web): storage_service_web.dart - localStorage 사용
 * 
 * 이 방식을 통해 클라이언트 코드는 플랫폼을 신경 쓰지 않고 
 * 동일한 인터페이스로 스토리지 기능을 사용할 수 있습니다.
 */

// 조건부 import를 사용하여 플랫폼별 구현 선택
// dart.library.html이 있으면 웹 환경으로 판단하여 웹용 구현체 사용
// 그렇지 않으면 모바일 환경으로 판단하여 모바일용 구현체 사용
export 'storage_service_mobile.dart' 
    if (dart.library.html) 'storage_service_web.dart';

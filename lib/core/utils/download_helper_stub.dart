/// 웹이 아닌 플랫폼을 위한 다운로드 헬퍼 (stub)
/// 
/// 모바일 플랫폼에서는 share_plus 패키지를 사용하므로
/// 이 함수는 호출되지 않아야 합니다. 예외를 발생시켜 개발자에게 알림.
void downloadFile(String fileName, String content) {
  // 모바일에서는 share_plus를 사용해야 함
  // 이 함수가 호출되었다면 코드에 문제가 있음
  throw UnsupportedError('모바일 플랫폼에서는 share_plus 패키지를 사용해주세요.');
}

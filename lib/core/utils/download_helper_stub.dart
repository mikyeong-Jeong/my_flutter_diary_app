import 'dart:typed_data';

void downloadFile(String fileName, String content) {
  // 웹이 아닌 플랫폼에서는 아무것도 하지 않음
  throw UnsupportedError('Download is not supported on this platform');
}

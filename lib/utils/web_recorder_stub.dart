import 'dart:typed_data';

class WebRecording {
  final Uint8List bytes;
  final String mimeType;
  final String downloadUrl;

  WebRecording({
    required this.bytes,
    required this.mimeType,
    required this.downloadUrl,
  });
}

class WebRecorder {
  Future<void> start() async {
    throw UnsupportedError('Web recording is not supported on this platform.');
  }

  Future<WebRecording?> stop() async {
    return null;
  }

  void dispose() {}
}

void downloadRecording(String url, {String filename = 'recording.webm'}) {}

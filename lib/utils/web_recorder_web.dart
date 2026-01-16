import 'dart:async';
import 'dart:html' as html;
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
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];

  Future<void> start() async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw StateError('MediaDevices not available.');
    }

    _stream = await mediaDevices.getUserMedia({'audio': true});
    _chunks.clear();

    final recorder = html.MediaRecorder(_stream!);
    _recorder = recorder;

    recorder.addEventListener('dataavailable', (event) {
      final e = event as html.BlobEvent;
      if (e.data != null) {
        _chunks.add(e.data!);
      }
    });

    recorder.start();
  }

  Future<WebRecording?> stop() async {
    final recorder = _recorder;
    if (recorder == null) return null;

    final completer = Completer<WebRecording?>();
    void onStop(html.Event _) async {
      recorder.removeEventListener('stop', onStop);

      final blob = html.Blob(_chunks, 'audio/webm');
      final url = html.Url.createObjectUrl(blob);

      _chunks.clear();
      _recorder = null;

      final stream = _stream;
      _stream = null;
      if (stream != null) {
        for (final track in stream.getTracks()) {
          track.stop();
        }
      }

      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        await reader.onLoad.first;
        final buffer = reader.result as ByteBuffer;
        final bytes = Uint8List.view(buffer);
        completer.complete(
          WebRecording(bytes: bytes, mimeType: 'audio/webm', downloadUrl: url),
        );
      } catch (_) {
        completer.complete(null);
      }
    }

    recorder.addEventListener('stop', onStop);
    recorder.stop();

    return completer.future;
  }

  void dispose() {
    final stream = _stream;
    _stream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }
    _recorder = null;
    _chunks.clear();
  }
}

void downloadRecording(String url, {String filename = 'recording.webm'}) {
  final anchor = html.AnchorElement(href: url)
    ..download = filename
    ..click();
}

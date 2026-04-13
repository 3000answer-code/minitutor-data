// Stub for non-web platforms
class WebSpeechAPI {
  static dynamic createRecognition() {
    throw UnsupportedError('Speech recognition is only supported on web');
  }
}

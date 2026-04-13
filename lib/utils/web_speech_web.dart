// Web Speech API implementation for web platform
import 'dart:html' as html;
import 'dart:js' as js;

class WebSpeechAPI {
  static dynamic createRecognition() {
    return js.JsObject(
      js.context['webkitSpeechRecognition'] ?? js.context['SpeechRecognition'],
    );
  }
}

// drive_web_player.dart
// 조건부 export: 웹이면 _drive_web_player_web.dart, 그 외 _drive_web_player_stub.dart
export 'drive_web_player_stub.dart'
    if (dart.library.html) 'drive_web_player_web.dart';

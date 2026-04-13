// drive_web_player_stub.dart
// 모바일/데스크탑용 stub (실제로는 호출되지 않음)
import 'package:flutter/material.dart';

/// 모바일에서는 이 위젯을 렌더링하지 않음
/// DriveWebPlayer는 kIsWeb == true 일 때만 호출해야 함
class DriveWebPlayer extends StatelessWidget {
  final String fileId;
  final bool isShortsStyle;

  const DriveWebPlayer({
    super.key,
    required this.fileId,
    this.isShortsStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    // 모바일에서는 렌더링 안 됨 (kIsWeb 체크 후 호출하므로 여기 도달 X)
    return const SizedBox.shrink();
  }
}

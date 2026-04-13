// drive_web_player_web.dart
// 웹 전용 Drive iframe 임베드 위젯
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// 웹에서 Google Drive 영상을 iframe으로 직접 임베드하는 위젯
class DriveWebPlayer extends StatefulWidget {
  final String fileId;
  final bool isShortsStyle;

  const DriveWebPlayer({
    super.key,
    required this.fileId,
    this.isShortsStyle = false,
  });

  @override
  State<DriveWebPlayer> createState() => _DriveWebPlayerState();
}

class _DriveWebPlayerState extends State<DriveWebPlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'drive-iframe-${widget.fileId}-${DateTime.now().millisecondsSinceEpoch}';
    _registerView();
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'https://drive.google.com/file/d/${widget.fileId}/preview?rm=minimal'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.background = '#000'
          ..setAttribute('allow', 'autoplay; encrypted-media; fullscreen; picture-in-picture')
          ..allowFullscreen = true;
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: HtmlElementView(viewType: _viewType),
    );
  }
}

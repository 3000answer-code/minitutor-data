import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lecture.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DriveVideoPlayerScreen
// Google Drive MP4를 video_player + chewie로 직접 인앱 재생
// 스트리밍 불가 시 브라우저 fallback
// ─────────────────────────────────────────────────────────────────────────────
class DriveVideoPlayerScreen extends StatefulWidget {
  final Lecture lecture;
  final bool isShortsStyle;

  const DriveVideoPlayerScreen({
    super.key,
    required this.lecture,
    this.isShortsStyle = false,
  });

  @override
  State<DriveVideoPlayerScreen> createState() => _DriveVideoPlayerScreenState();
}

class _DriveVideoPlayerScreenState extends State<DriveVideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMsg = '';

  // ── Drive 파일 ID 추출
  static String? _extractDriveFileId(String url) {
    final patterns = [
      RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'drive\.google\.com/(?:open|uc)\?(?:.*&)?id=([a-zA-Z0-9_-]+)'),
      RegExp(r'id=([a-zA-Z0-9_-]+)'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  // ── 스트리밍 URL 생성
  // confirm=t : 대용량 파일(100MB+)의 바이러스 스캔 경고 페이지를 건너뜀
  String _getStreamUrl(String fileId) {
    return 'https://drive.usercontent.google.com/download?id=$fileId&export=download&confirm=t';
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isShortsStyle) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    _initPlayer();
  }

  // ── 스트리밍 가능 여부 사전 확인
  Future<bool> _checkStreamable(String url) async {
    try {
      final resp = await http.head(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      final ct = resp.headers['content-type'] ?? '';
      return ct.contains('video/');
    } catch (_) {
      return false;
    }
  }

  Future<void> _initPlayer() async {
    final fileId = _extractDriveFileId(widget.lecture.videoUrl);
    if (fileId == null) {
      setState(() {
        _hasError = true;
        _errorMsg = '올바르지 않은 영상 주소입니다.';
        _isLoading = false;
      });
      return;
    }

    final streamUrl = _getStreamUrl(fileId);

    // 사전 확인: 스트리밍 가능한지 체크
    final streamable = await _checkStreamable(streamUrl);
    if (!streamable) {
      // 공유 설정 문제 → 에러 표시 (브라우저 버튼 제공)
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMsg = 'Google Drive 공유 설정으로 인해 직접 재생할 수 없습니다.';
        _isLoading = false;
      });
      return;
    }

    try {
      final videoCtrl = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
        },
      );
      await videoCtrl.initialize();

      if (!mounted) {
        videoCtrl.dispose();
        return;
      }

      final chewieCtrl = ChewieController(
        videoPlayerController: videoCtrl,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        aspectRatio: widget.isShortsStyle
            ? (9 / 16)
            : videoCtrl.value.aspectRatio,
        // placeholder 제거: 썸네일+Chewie UI 동시 노출로 2중 화면 되는 문제 수정
        errorBuilder: (ctx, msg) => _buildErrorWidget(msg),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );

      if (!mounted) {
        chewieCtrl.dispose();
        videoCtrl.dispose();
        return;
      }
      setState(() {
        _videoController = videoCtrl;
        _chewieController = chewieCtrl;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMsg = '영상 초기화 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── 썸네일 플레이스홀더
  Widget _buildPlaceholder() {
    final thumbUrl = widget.lecture.effectiveThumbnailUrl;
    return Container(
      color: Colors.black,
      child: thumbUrl.isNotEmpty && thumbUrl != 'nas_default'
          ? Image.network(thumbUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientBg())
          : _buildGradientBg(),
    );
  }

  Widget _buildGradientBg() {
    final subject = widget.lecture.subject;
    final color = subject == '수학'
        ? AppColors.math
        : subject == '과학'
            ? AppColors.science
            : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.8), Colors.black87],
        ),
      ),
    );
  }

  // ── 에러 위젯
  Widget _buildErrorWidget(String msg) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Colors.white60, size: 44),
            ),
            const SizedBox(height: 16),
            const Text('직접 재생을 할 수 없습니다',
                style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Google Drive 공유 설정을 확인해 주세요.\n(링크 공유: 뷰어)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // 브라우저로 열기 버튼
            ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              label: const Text('브라우저에서 재생'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 10),
            // 재시도 버튼
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _initPlayer();
              },
              icon: Icon(Icons.refresh_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.6)),
              label: Text('다시 시도',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final fileId = _extractDriveFileId(widget.lecture.videoUrl);
    if (fileId == null) return;
    final uri = Uri.parse('https://drive.google.com/file/d/$fileId/preview');
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(),
          Expanded(child: _buildBody()),
          if (!widget.isShortsStyle) _buildInfoBar(),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 50,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        // 뒤로가기
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 4),
        // 제목
        Expanded(
          child: Text(
            widget.lecture.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 브라우저로 열기
        IconButton(
          icon: const Icon(Icons.open_in_new_rounded,
              color: Colors.white54, size: 20),
          onPressed: _openInBrowser,
          tooltip: '브라우저에서 열기',
          padding: EdgeInsets.zero,
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      // 순수 검은 배경: Drive iframe 수준의 이상한 판넷 참조화면 보이지 않도록
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 46, height: 46,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text('영상 연결 중...',
                style: TextStyle(color: Colors.white70, fontSize: 14,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 6),
            Text('처음 로딩은 10~20초 걸릴 수 있습니다',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorWidget(_errorMsg);
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return _buildErrorWidget('플레이어 초기화 실패');
  }

  Widget _buildInfoBar() {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.lecture.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w700),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.person_outline_rounded,
                size: 13, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(widget.lecture.instructor,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
            const SizedBox(width: 14),
            Icon(Icons.school_outlined,
                size: 13, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(widget.lecture.subject,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          ]),
          if (widget.lecture.hashtags.isNotEmpty) ...[
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final tags = widget.lecture.hashtags;
                double estimateW(String t) => t.length * 7.0 + 16;
                final avail = constraints.maxWidth;
                double w = 0;
                final row1 = <String>[], row2 = <String>[];
                bool useRow2 = false;
                for (final t in tags) {
                  final tw = estimateW(t);
                  if (!useRow2) {
                    if (w + tw <= avail) { row1.add(t); w += tw + 6; }
                    else { useRow2 = true; row2.add(t); }
                  } else { row2.add(t); }
                }
                Widget chip(String tag) => Container(
                  margin: const EdgeInsets.only(right: 5, bottom: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC3D4F0), width: 0.8),
                  ),
                  child: Text('#$tag',
                    style: const TextStyle(
                      color: Color(0xFF5E8ED6),
                      fontSize: 10, fontWeight: FontWeight.w600)),
                );
                Widget buildRow(List<String> ts) => Wrap(spacing: 6, children: ts.map(chip).toList());
                if (row2.isEmpty) return buildRow(row1);
                double row2W = row2.fold(0.0, (s, t) => s + estimateW(t) + 6);
                Widget rows() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  buildRow(row1), const SizedBox(height: 4), buildRow(row2),
                ]);
                if (row2W > avail) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: rows());
                }
                return rows();
              },
            ),
          ],
        ],
      ),
    );
  }
}

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

  // ── A-B 구간반복 ────────────────────────────────
  Duration? _pointA;
  Duration? _pointB;
  bool _abActive = false;     // A-B 반복 활성 여부
  Timer? _abTimer;
  Timer? _positionTimer;       // 현재 위치 표시용 타이머
  Duration _currentPosition = Duration.zero;

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
      // 위치 추적 타이머 시작
      _positionTimer?.cancel();
      _positionTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        if (!mounted || _videoController == null) return;
        final pos = _videoController!.value.position;
        if (pos != _currentPosition) {
          setState(() => _currentPosition = pos);
        }
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
    _abTimer?.cancel();
    _positionTimer?.cancel();
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // 시스템 UI를 일반 모드로 복원 (네비게이션 바 겹침 방지)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
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
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // 1행: 뒤로가기 + 제목 + 브라우저
        SizedBox(
          height: 44,
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40),
            ),
            const SizedBox(width: 4),
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
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded,
                  color: Colors.white54, size: 20),
              onPressed: _openInBrowser,
              tooltip: '브라우저에서 열기',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40),
            ),
          ]),
        ),
        // 2행: A-B 구간반복 컨트롤 바 (플레이어 로딩 완료 후)
        if (_chewieController != null) _buildABControlBar(),
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

  // ── A-B 구간반복 컨트롤 바 (상단바 내부) ──────────────
  Widget _buildABControlBar() {
    final bool hasA = _pointA != null;
    final bool hasB = _pointB != null;
    final pos = _currentPosition;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: _abActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        // 구간반복 아이콘
        Icon(Icons.repeat_rounded,
            size: 16,
            color: _abActive ? AppColors.primary : Colors.white38),
        const SizedBox(width: 6),

        // 현재 위치 표시
        Text(
          _formatDuration(pos),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11, fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),

        // [A] 버튼
        _abChip(
          label: hasA ? 'A ${_formatDuration(_pointA!)}' : 'A 설정',
          color: hasA
              ? (hasA && !hasB ? const Color(0xFF3B82F6) : const Color(0xFF22C55E))
              : Colors.white24,
          textColor: hasA ? Colors.white : Colors.white54,
          onTap: () {
            if (_abActive) return;   // 반복 중에는 A 변경 불가
            if (!hasA) {
              setState(() => _pointA = pos);
            } else if (!hasB) {
              setState(() => _pointA = null);  // A만 설정 → 재탭으로 해제
            }
          },
        ),
        const SizedBox(width: 6),

        // [B] 버튼
        _abChip(
          label: hasB ? 'B ${_formatDuration(_pointB!)}' : 'B 설정',
          color: hasB ? const Color(0xFFEF4444) : Colors.white24,
          textColor: (hasA && !hasB) ? Colors.white : Colors.white54,
          onTap: () {
            if (_abActive) return;   // 반복 중에는 B 변경 불가
            if (hasA && !hasB) {
              if (pos > _pointA!) {
                setState(() {
                  _pointB = pos;
                  _abActive = true;
                });
                _startABLoop();
                _videoController?.seekTo(_pointA!);
              }
            }
          },
        ),

        const Spacer(),

        // 반복 활성 시 상태 표시 + 해제 버튼
        if (_abActive) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.loop_rounded, size: 12, color: AppColors.primary),
              const SizedBox(width: 3),
              Text('반복 중',
                style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(width: 4),
        ],

        // 해제(X) 버튼 - A가 설정되어 있으면 항상 표시
        if (hasA)
          GestureDetector(
            onTap: _clearABRepeat,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 14),
            ),
          ),
      ]),
    );
  }

  Widget _abChip({required String label, required Color color, required Color textColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
          style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startABLoop() {
    _abTimer?.cancel();
    // 200ms 간격으로 현재 위치 확인, B 지점 도달 시 A로 되돌림
    _abTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_abActive || _pointA == null || _pointB == null) {
        _abTimer?.cancel();
        return;
      }
      final ctrl = _videoController;
      if (ctrl == null || !ctrl.value.isInitialized) return;
      final pos = ctrl.value.position;
      if (pos >= _pointB!) {
        ctrl.seekTo(_pointA!);
      }
    });
  }

  void _clearABRepeat() {
    _abTimer?.cancel();
    setState(() {
      _pointA = null;
      _pointB = null;
      _abActive = false;
    });
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

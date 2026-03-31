import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lecture.dart';
import '../../services/app_state.dart';
import '../../services/data_service.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lecture_card.dart';

class LecturePlayerScreen extends StatefulWidget {
  final Lecture lecture;
  const LecturePlayerScreen({super.key, required this.lecture});

  @override
  State<LecturePlayerScreen> createState() => _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends State<LecturePlayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPlaying = false;
  bool _showSubtitle = true;
  double _playbackSpeed = 1.0;
  bool _isFullScreen = false;   // 전체보기 (33p)
  bool _isLandscape = false;     // 가로보기 감지 (32p)
  bool _landscapeInfoVisible = true; // 가로모드 강의정보 패널 표시
  int _currentTime = 0;
  late int _totalTime;
  bool _showControls = true;
  double _userRating = 0;

  // YouTube
  bool _isYouTubeVideo = false;

  // 노트 텍스트 관련
  final TextEditingController _noteController = TextEditingController();
  final List<Map<String, String>> _notes = [];

  // 교재 필기 관련
  bool _isDrawingMode = false;
  Color _penColor = Colors.blue;
  double _strokeWidth = 3.0;
  List<_DrawingStroke> _strokes = [];
  List<Offset?> _currentStroke = [];
  int _currentNotePageIndex = 0;
  // 교안 페이지별 필기 저장
  final Map<int, List<_DrawingStroke>> _pageStrokes = {};

  final List<Color> _penColors = [Colors.blue, Colors.red, Colors.black];
  bool _isEraser = false;

  // 자막
  final List<Map<String, dynamic>> _subtitles = [
    {'start': 0, 'end': 20, 'text': '안녕하세요! 오늘은 2분 안에 핵심 개념을 완벽하게 정리해드릴게요.'},
    {'start': 20, 'end': 45, 'text': '먼저 기본 개념부터 살펴볼까요? 핵심 포인트는 세 가지입니다.'},
    {'start': 45, 'end': 70, 'text': '첫 번째! 개념의 정의를 명확히 이해하는 것이 중요합니다.'},
    {'start': 70, 'end': 95, 'text': '두 번째! 예시를 통해 실제로 어떻게 적용되는지 확인하세요.'},
    {'start': 95, 'end': 118, 'text': '마지막으로 실전 문제에서 어떻게 활용할지 기억해두세요! 수고하셨습니다!'},
  ];

  // 교안 페이지 (샘플 - 실제는 강의별 이미지)
  List<String> get _notePages => [
    'https://picsum.photos/seed/${widget.lecture.id}1/800/600',
    'https://picsum.photos/seed/${widget.lecture.id}2/800/600',
    'https://picsum.photos/seed/${widget.lecture.id}3/800/600',
  ];

  String get _currentSubtitle {
    for (final sub in _subtitles) {
      if (_currentTime >= sub['start'] && _currentTime < sub['end']) {
        return sub['text'] as String;
      }
    }
    return '';
  }

  // YouTube URL에서 영상 ID 추출
  String? _extractYouTubeId(String url) {
    final regexps = [
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    ];
    for (final re in regexps) {
      final match = re.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _totalTime = widget.lecture.duration;
    _tabController = TabController(length: 4, vsync: this);
    _strokes = _pageStrokes[_currentNotePageIndex] ?? [];

    // YouTube 영상 감지
    final videoUrl = widget.lecture.videoUrl;
    final ytId = videoUrl.isNotEmpty ? _extractYouTubeId(videoUrl) : null;
    if (ytId != null) {
      _isYouTubeVideo = true;
      _isPlaying = false;
      // YouTube 앱으로 바로 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchYouTube();
      });
    } else {
      _simulatePlayback();
    }
    // 화면 회전 허용 (가로보기 32p)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 가로모드 진입 시 강의정보 탭 자동 선택 - 스토리보드 32p
    // orientation은 빌드 후에 알 수 있으므로 addPostFrameCallback 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final orientation = MediaQuery.of(context).orientation;
        if (orientation == Orientation.landscape) {
          _tabController.animateTo(3); // 강의정보 탭 자동 선택
        }
      }
    });
  }

  Future<void> _launchYouTube() async {
    final url = widget.lecture.videoUrl;
    final ytId = _extractYouTubeId(url);

    // YouTube ID가 없으면 원본 URL 그대로 열기
    final bool isShorts = url.contains('/shorts/');

    // 시도할 URL 목록 (우선순위 순)
    final List<Uri> candidates = [];

    if (ytId != null) {
      if (isShorts) {
        // Shorts: YouTube 앱 스킴 → 웹 URL 순서
        candidates.add(Uri.parse('vnd.youtube://shorts/$ytId'));
        candidates.add(Uri.parse('https://www.youtube.com/shorts/$ytId'));
      } else {
        // 일반 영상
        candidates.add(Uri.parse('vnd.youtube://$ytId'));
        candidates.add(Uri.parse('https://youtu.be/$ytId'));
        candidates.add(Uri.parse('https://www.youtube.com/watch?v=$ytId'));
      }
    }
    // 원본 URL 항상 마지막 fallback으로 추가
    candidates.add(Uri.parse(url));

    // canLaunchUrl 체크 없이 순서대로 시도 (Android 11+ 호환)
    for (final uri in candidates) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return; // 성공하면 종료
      } catch (_) {
        // 실패 시 다음 URL 시도
        continue;
      }
    }

    // 모두 실패 시 사용자에게 알림
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('YouTube 앱 또는 브라우저를 열 수 없습니다.\n아래 "직접 열기" 버튼을 사용해주세요.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _simulatePlayback() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_isPlaying && _currentTime < _totalTime) {
        setState(() => _currentTime++);
      }
      _simulatePlayback();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    // 화면 회전 다시 세로 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // 전체화면 해제 시 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Color _subjectColor(String subject) {
    switch (subject) {
      case '국어': return AppColors.korean;
      case '영어': return AppColors.english;
      case '수학': return AppColors.math;
      case '과학': return AppColors.science;
      case '사회': return AppColors.social;
      default: return AppColors.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final isFav = appState.isFavorite(widget.lecture.id);
    // 현재 방향 감지 (32p 가로보기)
    final orientation = MediaQuery.of(context).orientation;
    final wasLandscape = _isLandscape;
    _isLandscape = orientation == Orientation.landscape;
    // 세로 → 가로 전환 시 강의정보 탭 자동 선택 (스토리보드 32p)
    if (!wasLandscape && _isLandscape) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.animateTo(3);
      });
    }

    // ── 전체화면 (33p): 시스템 UI 숨김 ──
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isFullScreen
          // ── 전체화면 모드 (33p) ──
          ? SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildVideoPlayer(isFav, appState),
                          // 전체화면 해제 버튼 (우측 하단 - 스토리보드 18p/33p)
                  Positioned(
                    bottom: 20, right: 16,
                    child: _buildViewModeBtn(
                      icon: Icons.fullscreen_exit_rounded,
                      label: T('player_exit_fullscreen'),
                      onTap: () => setState(() => _isFullScreen = false),
                    ),
                  ),
                ],
              ),
            )
          : _isLandscape
              // ── 가로보기 모드 (32p): 영상+강의정보 나란히 ──
              ? SafeArea(
                  child: Row(
                    children: [
                      // 영상 영역 (좌측 55%)
                      Expanded(
                        flex: 55,
                        child: Stack(
                          children: [
                            _buildVideoPlayer(isFav, appState),
                            // 가로모드 전체화면 버튼 (우상단)
                            Positioned(
                              top: 8, right: 8,
                              child: _buildViewModeBtn(
                                icon: Icons.fullscreen_rounded,
                                label: T('player_fullscreen'),
                                onTap: () => setState(() => _isFullScreen = true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 강의정보 패널 항상 표시 (우측 45% - 32p 스펙)
                      Expanded(
                        flex: 45,
                        child: Container(
                          color: AppColors.background,
                          child: Column(
                            children: [
                              // 탭바 헤더
                              Container(
                                color: Colors.white,
                                child: TabBar(
                                  controller: _tabController,
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                  tabs: [
                                    Tab(text: T('tab_note')),
                                    Tab(text: T('tab_qa')),
                                    Tab(text: T('tab_playlist')),
                                    Tab(text: T('tab_info')),
                                  ],
                                  labelColor: AppColors.primary,
                                  unselectedLabelColor: AppColors.textSecondary,
                                  indicatorColor: AppColors.primary,
                                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  dividerColor: AppColors.divider,
                                ),
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildNoteTab(),
                                    _buildQATab(),
                                    _buildPlaylistTab(),
                                    _buildLectureInfoTab(isFav, appState),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              // ── 세로보기 모드 (기본) ──
              : SafeArea(
                  child: Column(
                    children: [
                      // 영상 영역
                      // 세로화면 비디오 영역 + 가로/전체 전환 아이콘 오버레이
                      _buildPortraitVideoWithButtons(isFav, appState),
                      Expanded(
                        child: Container(
                          color: AppColors.background,
                          child: Column(
                            children: [
                              Container(
                                color: Colors.white,
                                child: TabBar(
                                  controller: _tabController,
                                  isScrollable: true,
                                  tabAlignment: TabAlignment.start,
                                  tabs: [
                                    Tab(text: T('tab_note')),
                                    Tab(text: T('tab_qa')),
                                    Tab(text: T('tab_playlist')),
                                    Tab(text: T('tab_info')),
                                  ],
                                  labelColor: AppColors.primary,
                                  unselectedLabelColor: AppColors.textSecondary,
                                  indicatorColor: AppColors.primary,
                                  dividerColor: AppColors.divider,
                                ),
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildNoteTab(),
                                    _buildQATab(),
                                    _buildPlaylistTab(),
                                    _buildLectureInfoTab(isFav, appState),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ── 세로화면 비디오 + 가로/전체 전환 버튼 오버레이 ──
  Widget _buildPortraitVideoWithButtons(bool isFav, AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Stack(
      children: [
        _buildVideoPlayer(isFav, appState),
        // 우측 하단 - 가로보기 / 전체보기 버튼 (스토리보드 32-33p 요구사항)
        Positioned(
          bottom: 10, right: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 가로보기 안내 버튼 (폰 회전 유도)
              _buildViewModeBtn(
                icon: Icons.screen_rotation_alt_rounded,
                label: T('player_landscape'),
                onTap: _showLandscapeGuide,
              ),
              const SizedBox(height: 6),
              // 전체보기 버튼 (스토리보드 18p/33p - 우측 하단)
              _buildViewModeBtn(
                icon: Icons.fullscreen_rounded,
                label: T('player_portrait'),
                onTap: () => setState(() => _isFullScreen = true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 뷰 모드 전환 버튼 공통 위젯
  Widget _buildViewModeBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // 가로보기 안내 팝업 (세로 고정 해제 방법)
  void _showLandscapeGuide() {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.screen_rotation_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(T('player_landscape'), style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(T('landscape_guide_body'),
                style: const TextStyle(fontSize: 14, height: 1.6)),
            const SizedBox(height: 12),
            Row(children: const [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Expanded(child: Text(
                '',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              )),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(T('confirm')),
          ),
        ],
      ),
    );
  }

  // ── 비디오 플레이어 ──────────────────────────────
  Widget _buildVideoPlayer(bool isFav, AppState appState) {
    // 전체화면 또는 가로모드이면 AspectRatio 해제하고 전체 채우기
    final useFullArea = _isFullScreen || _isLandscape;
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: useFullArea
          ? SizedBox.expand(child: _buildPlayerContent(isFav, appState))
          : AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildPlayerContent(isFav, appState),
      ),
    );
  }

  // 플레이어 내용 (전체화면/가로모드 공용)
  Widget _buildPlayerContent(bool isFav, AppState appState) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // YouTube 모드: 썸네일 + 재생 안내
        if (_isYouTubeVideo)
          Positioned.fill(
            child: Builder(builder: (context) {
              final lang = context.read<AppState>().selectedLanguage;
              final T = (String key) => AppTranslations.tLang(lang, key);
              final ytId = _extractYouTubeId(widget.lecture.videoUrl);
              // 썸네일 URL 목록 (순서대로 시도)
              final thumbUrls = <String>[];
              if (ytId != null) {
                thumbUrls.addAll([
                  'https://i.ytimg.com/vi/$ytId/hqdefault.jpg',
                  'https://i.ytimg.com/vi/$ytId/mqdefault.jpg',
                  'https://i.ytimg.com/vi/$ytId/sddefault.jpg',
                  'https://i.ytimg.com/vi/$ytId/default.jpg',
                ]);
              }
              if (widget.lecture.thumbnailUrl.isNotEmpty) {
                thumbUrls.add(widget.lecture.thumbnailUrl);
              }
              return Stack(children: [
                // 썸네일 배경
                Positioned.fill(
                  child: _PlayerThumbWidget(
                    urls: thumbUrls,
                    subject: widget.lecture.subject,
                  ),
                ),
                Container(color: Colors.black.withValues(alpha: 0.50)),
                // 중앙 재생 버튼
                Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // 큼직한 재생 버튼
                    ElevatedButton(
                      onPressed: _launchYouTube,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(22),
                        elevation: 8,
                        shadowColor: Colors.red.withValues(alpha: 0.6),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: 18),
                    // YouTube로 열기 버튼
                    ElevatedButton.icon(
                      onPressed: _launchYouTube,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('YouTube에서 보기',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('터치하면 YouTube 앱이 열립니다',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                  ]),
                ),
              ]);
            }),
          )
        else ...[
          Image.network(
            widget.lecture.thumbnailUrl,
            width: double.infinity, height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: _subjectColor(widget.lecture.subject).withValues(alpha: 0.3),
              child: Icon(Icons.play_circle_outline, size: 80,
                  color: _subjectColor(widget.lecture.subject)),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.4)),
          if (_showControls)
            GestureDetector(
              onTap: () => setState(() => _isPlaying = !_isPlaying),
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 36),
              ),
            ),
        ],
        if (!_isYouTubeVideo && _showSubtitle && _currentSubtitle.isNotEmpty)
          Positioned(
            bottom: 36, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_currentSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
            ),
          ),
        // YouTube 모드: 상단에 뒤로가기 + YouTube 앱 열기 + 전체화면 버튼
        if (_isYouTubeVideo)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Builder(builder: (ctx) {
              final lang = ctx.read<AppState>().selectedLanguage;
              final T = (String key) => AppTranslations.tLang(lang, key);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent]),
                ),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(child: Text(widget.lecture.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  // YouTube 앱으로 직접 열기
                  GestureDetector(
                    onTap: _launchYouTube,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 3),
                        Text(T('player_open_youtube'),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isFullScreen
                        ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                        color: Colors.white, size: 20),
                    tooltip: _isFullScreen ? T('player_exit_fullscreen') : T('player_fullscreen'),
                    onPressed: () => setState(() => _isFullScreen = !_isFullScreen),
                  ),
                ]),
              );
            }),
          ),
        // YouTube 하단 열기 버튼 (다국어)
        if (_isYouTubeVideo)
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: Center(
              child: Builder(builder: (ctx) {
                final lang = ctx.read<AppState>().selectedLanguage;
                final T = (String key) => AppTranslations.tLang(lang, key);
                return GestureDetector(
                  onTap: _launchYouTube,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(T('player_tap_hint'),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              }),
            ),
          ),
        if (!_isYouTubeVideo && _showControls)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent]),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(child: Text(widget.lecture.title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                IconButton(
                  icon: Icon(_showSubtitle
                      ? Icons.closed_caption_rounded
                      : Icons.closed_caption_disabled_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => setState(() => _showSubtitle = !_showSubtitle),
                ),
                // 전체화면 토글 버튼 (스토리보드 18p - 컨트롤 상단)
                IconButton(
                  icon: Icon(_isFullScreen
                      ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                      color: Colors.white, size: 20),
                  tooltip: _isFullScreen ? '전체화면 해제' : '전체화면',
                  onPressed: () => setState(() => _isFullScreen = !_isFullScreen),
                ),
              ]),
            ),
          ),
        if (!_isYouTubeVideo && _showControls)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent]),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SliderTheme(
                  data: SliderThemeData(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    trackHeight: 2,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: _currentTime.toDouble(),
                    max: _totalTime.toDouble(),
                    onChanged: (v) => setState(() => _currentTime = v.toInt()),
                  ),
                ),
                Row(children: [
                  Text(_formatTime(_currentTime),
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 22),
                      onPressed: () => setState(
                          () => _currentTime = (_currentTime - 10).clamp(0, _totalTime))),
                  IconButton(
                      icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 22),
                      onPressed: () => setState(
                          () => _currentTime = (_currentTime + 10).clamp(0, _totalTime))),
                  Text(_formatTime(_totalTime),
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ]),
              ]),
            ),
          ),
      ],
    );
  }

  // ── 탭1: 노트 (교안 필기) ────────────────────────
  Widget _buildNoteTab() {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Column(children: [
      // 교안 페이지 네비게이션 헤더
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(children: [
          Text('${T("tab_note")} ${_currentNotePageIndex + 1} / ${_notePages.length}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          // 필기 도구 버튼
          if (_isDrawingMode) ...[
            // 색상 버튼들
            ..._penColors.map((c) => GestureDetector(
              onTap: () => setState(() { _penColor = c; _isEraser = false; }),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (_penColor == c && !_isEraser) ? AppColors.primary : Colors.transparent,
                    width: 2.5),
                ),
              ),
            )),
            // 지우개
            GestureDetector(
              onTap: () => setState(() => _isEraser = true),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _isEraser ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _isEraser ? AppColors.primary : AppColors.divider),
                ),
                child: const Icon(Icons.auto_fix_normal_rounded, size: 18, color: AppColors.textSecondary),
              ),
            ),
            // 전체 지우기
            GestureDetector(
              onTap: () => setState(() {
                _strokes.clear();
                _pageStrokes[_currentNotePageIndex] = [];
              }),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(width: 8),
          // 필기 모드 토글
          GestureDetector(
            onTap: () {
              setState(() {
                _isDrawingMode = !_isDrawingMode;
                if (_isDrawingMode) _isEraser = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isDrawingMode ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isDrawingMode ? AppColors.primary : AppColors.divider),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_rounded, size: 14,
                    color: _isDrawingMode ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(T('drawing_mode'),
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _isDrawingMode ? Colors.white : AppColors.textSecondary)),
              ]),
            ),
          ),
          if (_isDrawingMode) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _saveDrawing,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.save_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(T('save_note'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ],
        ]),
      ),
      // 교안 + 필기 영역
      Expanded(
        child: Stack(children: [
          // 교안 이미지 (좌우 스와이프로 페이지 전환)
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (!_isDrawingMode) {
                if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
                  // 왼쪽 스와이프 → 다음 페이지
                  if (_currentNotePageIndex < _notePages.length - 1) {
                    _changePage(_currentNotePageIndex + 1);
                  }
                } else if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                  // 오른쪽 스와이프 → 이전 페이지
                  if (_currentNotePageIndex > 0) {
                    _changePage(_currentNotePageIndex - 1);
                  }
                }
              }
            },
            child: Container(
              color: Colors.white,
              child: Image.network(
                _notePages[_currentNotePageIndex],
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF8F9FA),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.menu_book_rounded, size: 64,
                        color: _subjectColor(widget.lecture.subject).withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('교안 ${_currentNotePageIndex + 1}페이지',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(widget.lecture.title,
                        style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
                  ])),
                ),
              ),
            ),
          ),

          // 필기 캔버스 오버레이
          if (_isDrawingMode)
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (d) => setState(() => _currentStroke = [d.localPosition]),
                onPanUpdate: (d) {
                  setState(() => _currentStroke.add(d.localPosition));
                },
                onPanEnd: (_) {
                  if (_currentStroke.isNotEmpty) {
                    setState(() {
                      if (_isEraser) {
                        // 지우개: 근처 스트로크 제거
                        final erasePos = _currentStroke.last;
                        if (erasePos != null) {
                          _strokes.removeWhere((s) => s.points.any((p) =>
                              p != null && (p - erasePos).distance < 20));
                        }
                      } else {
                        _strokes.add(_DrawingStroke(
                          points: List.from(_currentStroke),
                          color: _penColor,
                          width: _strokeWidth,
                        ));
                      }
                      _currentStroke = [];
                      _pageStrokes[_currentNotePageIndex] = List.from(_strokes);
                    });
                  }
                },
                child: CustomPaint(
                  painter: _DrawingPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    currentColor: _isEraser ? Colors.transparent : _penColor,
                    currentWidth: _isEraser ? 20 : _strokeWidth,
                    isEraser: _isEraser,
                  ),
                ),
              ),
            ),

          // 필기 모드 비활성화 시에도 기존 필기 표시
          if (!_isDrawingMode && _strokes.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: _DrawingPainter(
                  strokes: _strokes,
                  currentStroke: const [],
                  currentColor: Colors.transparent,
                  currentWidth: 3,
                  isEraser: false,
                ),
              ),
            ),

          // 페이지 인디케이터 (하단)
          Positioned(
            bottom: 8, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_notePages.length, (i) => GestureDetector(
                onTap: () => _changePage(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentNotePageIndex ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentNotePageIndex
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )),
            ),
          ),
        ]),
      ),

      // 텍스트 메모 영역 (하단)
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Divider(height: 0),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: T('note_hint'),
                  border: InputBorder.none,
                  isDense: true,
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_formatTime(_currentTime),
                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero),
                onPressed: _saveNote,
                child: Text(T('save_note'), style: const TextStyle(fontSize: 12)),
              ),
            ]),
          ]),
          // 저장된 메모 최신 1개 미리보기
          if (_notes.isNotEmpty) ...[
            const Divider(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(_notes.last['time']!,
                    style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(_notes.last['content']!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('+${_notes.length}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            ]),
          ],
        ]),
      ),
    ]);
  }

  void _changePage(int index) {
    setState(() {
      // 현재 페이지 필기 저장
      _pageStrokes[_currentNotePageIndex] = List.from(_strokes);
      _currentNotePageIndex = index;
      // 새 페이지 필기 로드
      _strokes = List.from(_pageStrokes[_currentNotePageIndex] ?? []);
    });
  }

  void _saveDrawing() {
    _pageStrokes[_currentNotePageIndex] = List.from(_strokes);
    setState(() => _isDrawingMode = false);
    final lang2 = context.read<AppState>().selectedLanguage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppTranslations.tLang(lang2, 'save_note')),
          backgroundColor: AppColors.success));
  }

  // ── 탭2: 강의 Q&A ────────────────────────────────
  Widget _buildQATab() {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final qaList = [
      {'q': '이 개념이 시험에 자주 나오나요?', 'nick': '공부왕민준', 'a': '네! 매년 시험에 출제되는 핵심 개념입니다. 반드시 숙지하세요.', 'answerer': '김민준 강사', 'time': '2일 전', 'answered': true},
      {'q': '예시에서 두 번째 방법도 유효한가요?', 'nick': '열공소율', 'a': '', 'answerer': '', 'time': '5시간 전', 'answered': false},
      {'q': '다음 강의는 언제 업로드되나요?', 'nick': '수학왕', 'a': '다음 주 월요일 업로드 예정입니다!', 'answerer': '운영자', 'time': '1주 전', 'answered': true},
    ];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_comment_outlined, size: 18),
          label: Text(T('ask_question')),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          onPressed: _showQADialog,
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          itemCount: qaList.length,
          itemBuilder: (_, i) {
            final qa = qaList[i];
            final answered = qa['answered'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // 질문 (오른쪽 정렬 - 스토리보드 23p)
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4)),
                    child: Text('Q. ${qa['nick']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: answered
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4)),
                    child: Text(answered ? T('answer_complete') : T('answer_pending'),
                        style: TextStyle(
                          fontSize: 10,
                          color: answered ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(qa['q'] as String,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (answered && (qa['a'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('A. ${qa['answerer']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(qa['a'] as String,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                    ]),
                  ),
                ],
                const SizedBox(height: 4),
                Text(qa['time'] as String,
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  // ── 탭3: 재생목록 ────────────────────────────────
  Widget _buildPlaylistTab() {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    final dataService = DataService();
    final series = dataService.getAllLectures()
        .where((l) => l.series == widget.lecture.series)
        .toList();
    final total = series.length;
    final currentIdx = series.indexWhere((l) => l.id == widget.lecture.id);

    return Column(children: [
      // 재생목록 헤더 (스토리보드 24p - 순서/전체 강의수)
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          Text('${currentIdx + 1} / $total강',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(width: 8),
          Text(widget.lecture.series,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(children: [
            const Icon(Icons.autorenew_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(T('section_recommend'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            Switch(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
        ]),
      ),
      // 해시태그 (스토리보드 24p)
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Wrap(
          spacing: 6,
          children: widget.lecture.hashtags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('#$tag',
                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
          )).toList(),
        ),
      ),
      const Divider(height: 0),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          itemCount: series.length,
          itemBuilder: (_, i) {
            final l = series[i];
            final isCurrent = l.id == widget.lecture.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.divider),
              ),
              child: LectureCard(
                lecture: l,
                isHorizontal: true,
                onTap: isCurrent
                    ? null
                    : () => Navigator.pushReplacement(context,
                        MaterialPageRoute(
                            builder: (_) => LecturePlayerScreen(lecture: l))),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── 탭4: 강의정보 (스토리보드 26p) ───────────────
  Widget _buildLectureInfoTab(bool isFav, AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    // 썸네일 URL 구성 (YouTube 강의는 ytimg, 일반은 thumbnailUrl)
    final ytId = _extractYouTubeId(widget.lecture.videoUrl);
    final thumbUrls = <String>[];
    if (ytId != null) {
      thumbUrls.addAll([
        'https://i.ytimg.com/vi/$ytId/hqdefault.jpg',
        'https://i.ytimg.com/vi/$ytId/mqdefault.jpg',
        'https://i.ytimg.com/vi/$ytId/default.jpg',
      ]);
    }
    if (widget.lecture.thumbnailUrl.isNotEmpty) {
      thumbUrls.add(widget.lecture.thumbnailUrl);
    }

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 썸네일 섹션 ──
        if (thumbUrls.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(children: [
                _PlayerThumbWidget(
                  urls: thumbUrls,
                  subject: widget.lecture.subject,
                ),
                // 재생 아이콘 오버레이
                Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.2))),
                Center(
                  child: GestureDetector(
                    onTap: _isYouTubeVideo ? _launchYouTube : () => setState(() => _isPlaying = !_isPlaying),
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: (_isYouTubeVideo ? Colors.red : AppColors.primary).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                ),
                if (_isYouTubeVideo)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.play_circle_filled, color: Colors.white, size: 10),
                        SizedBox(width: 3),
                        Text('YouTube', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
        // 기본 정보 섹션
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 과목 + 학제 배지
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _subjectColor(widget.lecture.subject),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(widget.lecture.subject,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider)),
                child: Text(widget.lecture.gradeText,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(widget.lecture.lectureTypeText,
                    style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),
            // 강의명
            Text(widget.lecture.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            // 강사 정보
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.background,
                backgroundImage: NetworkImage(
                    'https://picsum.photos/seed/${widget.lecture.instructor}/80/80'),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.lecture.instructor,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text('${widget.lecture.subject} ${T('instructor_label')}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
              const Spacer(),
              Row(children: [
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                const SizedBox(width: 2),
                Text(widget.lecture.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(' (${widget.lecture.ratingCount})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
            const SizedBox(height: 14),
            // 전체 해시태그 (좌우 스크롤 - 스토리보드 26p)
            Text(T('hashtags_label'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textHint)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.lecture.hashtags.map((tag) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('#$tag 검색 결과로 이동합니다')));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text('#$tag',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ),
                )).toList(),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 8),

        // 퀵 액션 버튼 5개 (스토리보드 26p: 즐겨찾기/평점/공유/관련시리즈/문제풀이)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoActionBtn(
                icon: isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                label: T('favorites'),
                color: isFav ? AppColors.primary : AppColors.textSecondary,
                onTap: () => appState.toggleFavorite(widget.lecture.id),
              ),
              _buildInfoActionBtn(
                icon: Icons.star_half_rounded,
                label: T('rating_label'),
                color: const Color(0xFFFBBF24),
                onTap: _showRatingDialog,
                badge: widget.lecture.rating.toStringAsFixed(1),
              ),
              _buildInfoActionBtn(
                icon: Icons.share_rounded,
                label: T('series_label'),
                color: AppColors.textSecondary,
                onTap: _share,
              ),
              _buildInfoActionBtn(
                icon: Icons.playlist_play_rounded,
                label: T('related_lectures'),
                color: AppColors.textSecondary,
                onTap: () => _tabController.animateTo(2),
              ),
              _buildInfoActionBtn(
                icon: Icons.quiz_rounded,
                label: T('rate_lecture'),
                color: AppColors.accent,
                onTap: _openRelatedLecture,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 강의 상세 정보
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(T('lecture_info'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.schedule_rounded, T('duration_label'), _formatTime(widget.lecture.duration)),
            _buildInfoRow(Icons.school_rounded, T('grade_middle'), widget.lecture.gradeText),
            _buildInfoRow(Icons.category_rounded, T('instructor_lecture_count'), widget.lecture.lectureTypeText),
            _buildInfoRow(Icons.playlist_play_rounded, T('series_label'), widget.lecture.series),
            _buildInfoRow(Icons.visibility_rounded, T('views_count'), '${widget.lecture.viewCount}'),
            _buildInfoRow(Icons.people_rounded, T('rating_label'), '${widget.lecture.ratingCount}'),
          ]),
        ),

        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildInfoActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            if (badge != null)
              Positioned(
                right: -4, top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(badge,
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }

  void _saveNote() {
    if (_noteController.text.isEmpty) return;
    setState(() {
      _notes.add({'time': _formatTime(_currentTime), 'content': _noteController.text});
      _noteController.clear();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('노트가 저장되었습니다!')));
  }

  void _showQADialog() {
    final controller = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('질문 작성'),
              content: TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: '질문 내용을 입력하세요...')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context), child: const Text('취소')),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('질문이 등록되었습니다!')));
                    },
                    child: const Text('등록')),
              ],
            ));
  }

  void _showRatingDialog() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('강의 평점 남기기'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('이 강의는 어떠셨나요?'),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        5,
                        (i) => IconButton(
                              icon: Icon(
                                  i < _userRating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: const Color(0xFFFBBF24),
                                  size: 36),
                              onPressed: () => setState(() {
                                _userRating = (i + 1).toDouble();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('평점이 등록되었습니다!')));
                              }),
                            ))),
              ]),
            ));
  }

  void _share() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('공유 링크가 복사되었습니다!')));
  }

  void _openRelatedLecture() {
    final dataService = DataService();
    final related = dataService
        .getAllLectures()
        .where((l) => l.id == widget.lecture.relatedLectureId)
        .firstOrNull;
    if (related != null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => LecturePlayerScreen(lecture: related)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('연결된 문제풀이 강의가 없습니다')));
    }
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

// ── 필기 스트로크 모델 ────────────────────────────
class _DrawingStroke {
  final List<Offset?> points;
  final Color color;
  final double width;
  _DrawingStroke({required this.points, required this.color, required this.width});
}

// ── 필기 CustomPainter ───────────────────────────
class _DrawingPainter extends CustomPainter {
  final List<_DrawingStroke> strokes;
  final List<Offset?> currentStroke;
  final Color currentColor;
  final double currentWidth;
  final bool isEraser;

  const _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
    required this.isEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 저장된 스트로크 그리기
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: 0.85)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool started = false;
      for (final point in stroke.points) {
        if (point == null) { started = false; continue; }
        if (!started) { path.moveTo(point.dx, point.dy); started = true; }
        else { path.lineTo(point.dx, point.dy); }
      }
      canvas.drawPath(path, paint);
    }

    // 현재 그리는 스트로크
    if (currentStroke.isNotEmpty && !isEraser) {
      final paint = Paint()
        ..color = currentColor.withValues(alpha: 0.85)
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool started = false;
      for (final point in currentStroke) {
        if (point == null) { started = false; continue; }
        if (!started) { path.moveTo(point.dx, point.dy); started = true; }
        else { path.lineTo(point.dx, point.dy); }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

// ─── 플레이어용 YouTube 썸네일 (여러 URL 순서대로 시도) ───
class _PlayerThumbWidget extends StatefulWidget {
  final List<String> urls;
  final String subject;
  const _PlayerThumbWidget({required this.urls, required this.subject});

  @override
  State<_PlayerThumbWidget> createState() => _PlayerThumbWidgetState();
}

class _PlayerThumbWidgetState extends State<_PlayerThumbWidget> {
  int _idx = 0;

  Color get _color {
    switch (widget.subject) {
      case '수학': return AppColors.math;
      case '영어': return AppColors.english;
      case '국어': return AppColors.korean;
      case '과학': return AppColors.science;
      default: return AppColors.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_idx >= widget.urls.length) {
      return Container(
        color: _color.withValues(alpha: 0.3),
        child: Icon(Icons.play_circle_outline, size: 80, color: _color),
      );
    }
    return Image.network(
      widget.urls[_idx],
      width: double.infinity, height: double.infinity,
      fit: BoxFit.cover,
      headers: const {
        'User-Agent': 'Mozilla/5.0',
        'Referer': 'https://www.youtube.com/',
      },
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _idx++);
        });
        return Container(color: Colors.black87);
      },
    );
  }
}

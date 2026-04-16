import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Conditional import for web speech API
import 'package:asometutor/utils/web_speech_web.dart' if (dart.library.io) 'package:asometutor/utils/web_speech_stub.dart';
import '../../models/lecture.dart';
import '../../services/app_state.dart';
import '../../services/auth_service.dart';
import '../../services/note_repository.dart';
import '../../services/problem_bank.dart';
import '../../theme/app_theme.dart';
import '../../config.dart';
import '../../widgets/drive_web_player.dart';
import '../../widgets/eraser_widgets.dart';
import '../profile/my_activity_screen.dart';
import '../profile/my_note_viewer_screen.dart';

const Color _kOrange = Color(0xFFF97316);
const String _kOrangeHex = '#F97316';

// ─────────────────────────────────────────────────────────────────────────────
// LecturePlayerScreen — Asome Tutor 스타일 동영상 플레이어
// ─────────────────────────────────────────────────────────────────────────────
class LecturePlayerScreen extends StatefulWidget {
  final Lecture lecture;
  /// 자동재생용 강의 목록 (null이면 자동재생 비활성)
  final List<Lecture>? autoPlayList;
  /// 현재 강의의 목록 내 인덱스
  final int autoPlayIndex;

  const LecturePlayerScreen({
    super.key,
    required this.lecture,
    this.autoPlayList,
    this.autoPlayIndex = 0,
  });

  @override
  State<LecturePlayerScreen> createState() => _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends State<LecturePlayerScreen>
    with TickerProviderStateMixin {

  // ── 탭 컨트롤러 (노트 보기 / 강의 Q&A / 재생 목록)
  late TabController _tabController;

  // ── 플레이어 상태
  bool _isPlaying = false;
  bool _showControls = true;
  bool _showSubtitle = true;
  double _playbackSpeed = 1.0;
  bool _isFullScreen = false;
  int _currentTime = 0;
  late int _totalTime;
  Timer? _controlsTimer;
  Timer? _playbackTimer;

  // ── 미니 플레이어 (하단 고정)
  bool _isMiniPlayer = false;

  // ── 가로화면 + 사이드패널 모드
  bool _isLandscape = false;
  bool _isLandscapeInfoExpanded = false; // 가로화면 강의정보 확장/축소

  // ── 세로화면 메타바 접힘/펼침
  bool _isMetaBarCollapsed = false; // true = 접힘(영상 정보 숨김)

  // ── 자동 재생 (재생 목록)
  bool _autoPlay = false;

  // ── WebView (Android NAS MP4 재생)
  WebViewController? _webViewController;
  bool _webViewLoading = true;

  // ── Drive/YouTube 인라인 플레이어
  VideoPlayerController? _driveVideoCtrl;
  ChewieController? _driveChewieCtrl;
  bool _drivePlayerLoading = false;
  bool _drivePlayerError = false;
  bool _drivePlayerActive = false; // 인라인 재생 활성화 여부

  // ── 노트 필기
  bool _isDrawingMode = false;
  Color _penColor = const Color(0xFF2563EB);
  double _strokeWidth = 3.0;
  List<_DrawingStroke> _strokes = [];
  List<Offset?> _currentStroke = [];
  int _currentNotePageIndex = 0;
  final Map<int, List<_DrawingStroke>> _pageStrokes = {};
  bool _isEraser = false;
  bool _strokesSaved = true; // 필기 저장 상태 (false = 미저장 변경사항 있음)
  // 지우개 커서
  Offset? _eraserPosition;
  bool _showEraserCursor = false;

  // ── 교안 슬라이드
  List<String> _notePages = [];
  bool _slidesLoading = true;

  // ── 메모
  final TextEditingController _noteController = TextEditingController();
  final List<Map<String, String>> _savedNotes = [];

  // ── 진도 추적
  final AuthService _authService = AuthService();
  final Set<String> _savedProgressCheckpoints = {};

  // ── Q&A 목록 (더미)
  final List<Map<String, String>> _qaList = [
    {'q': '공식을 외우는 좋은 방법이 있나요?', 'a': '반복 연습이 가장 효과적입니다. 문제를 많이 풀어보세요!', 'time': '1일 전'},
    {'q': '예제 문제를 더 풀어볼 수 있나요?', 'a': '교재 p.45~50의 연습 문제를 추천드립니다.', 'time': '3일 전'},
    {'q': '이 개념이 수능에 자주 나오나요?', 'a': '네, 매년 출제되는 핵심 개념입니다. 꼭 숙지하세요!', 'time': '5일 전'},
  ];

  // ── 자막 (비활성화 - 더미 문구 제거)
  final List<Map<String, dynamic>> _subtitles = [];

  // ── 문제풀이 상태
  int _currentProblemIndex = 0;
  int? _selectedAnswer;
  bool _showExplanation = false;
  List<_ProblemData>? _problems;

  // ── 파생 게터
  double get _watchProgress =>
      _totalTime > 0 ? (_currentTime / _totalTime).clamp(0.0, 1.0) : 0.0;

  String get _currentSubtitle => '';

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─────────────────────────────────────────────
  // 라이프사이클
  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _totalTime = widget.lecture.duration;
    // autoPlayList가 제공되면 자동재생 활성화
    _autoPlay = widget.autoPlayList != null && widget.autoPlayList!.length > 1;
    // 모든 강의는 4개 탭 (노트보기, Q&A, 재생목록, 문제풀이)
    _tabController = TabController(length: 4, vsync: this);
    
    // 탭 변경 리스너 추가 (문제풀이 탭으로 돌아올 때 초기화)
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // 문제풀이 탭(인덱스 3)으로 진입 시 초기화
        if (_tabController.index == 3) {
          setState(() {
            _currentProblemIndex = 0;
            _selectedAnswer = null;
            _showExplanation = false;
          });
        }
      }
    });

    // 새 강의 플레이어 열릴 때: PIP와 동일 강의면 PIP 종료, 다른 강의면 PIP 그대로 유지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final appState = context.read<AppState>();
        if (appState.pipActive &&
            appState.pipLecture != null &&
            appState.pipLecture!.id == widget.lecture.id) {
          // PIP 강의와 같은 강의 → PIP 종료
          appState.deactivatePip();
        }
        // PIP 강의와 다른 강의 D → PIP(A)는 그대로 재생 유지 (아무것도 안 함)
      }
    });
    
    _initPlayer();
    _loadSlidePages();
    _scheduleHideControls();
    _loadSavedStrokes(); // 저장된 필기 불러오기
  }

  // ── 강의별 SharedPreferences 키
  String get _strokesKey => 'strokes_${widget.lecture.id}';
  String get _notesKey => 'notes_${widget.lecture.id}';

  // ── 필기 데이터 불러오기
  Future<void> _loadSavedStrokes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 필기 데이터 복원
      final strokesJson = prefs.getString(_strokesKey);
      if (strokesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(strokesJson);
        final Map<int, List<_DrawingStroke>> loaded = {};
        decoded.forEach((pageKey, strokeList) {
          final pageIdx = int.tryParse(pageKey) ?? 0;
          final strokes = (strokeList as List).map((s) {
            final points = (s['points'] as List).map<Offset?>((p) =>
              Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())
            ).toList();
            return _DrawingStroke(
              points: points,
              color: Color(s['color'] as int),
              width: (s['width'] as num).toDouble(),
            );
          }).toList();
          loaded[pageIdx] = strokes;
        });
        setState(() => _pageStrokes.addAll(loaded));
      }
      // 메모 복원
      final notesJson = prefs.getString(_notesKey);
      if (notesJson != null) {
        final List decoded = jsonDecode(notesJson);
        setState(() {
          _savedNotes.addAll(decoded.map((n) =>
            Map<String, String>.from(n as Map)));
        });
      }
    } catch (_) {}
  }

  // ── 필기 데이터 저장 + NoteRepository 메타데이터 갱신
  Future<void> _saveStrokes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toSave = {};
      _pageStrokes.forEach((pageIdx, strokes) {
        toSave[pageIdx.toString()] = strokes.map((s) => {
          'points': s.points
              .whereType<Offset>()
              .map((p) => {'x': p.dx, 'y': p.dy})
              .toList(),
          'color': s.color.toARGB32(),
          'width': s.width,
        }).toList();
      });
      await prefs.setString(_strokesKey, jsonEncode(toSave));
      setState(() => _strokesSaved = true);

      // NoteRepository에 메타데이터 저장 → 나의활동 > 노트 목록에 표시
      final totalStrokes = _pageStrokes.values
          .fold<int>(0, (sum, list) => sum + list.length);
      final now = DateTime.now();
      final savedAt =
          '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} '
          '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
      await NoteRepository().saveNoteMeta(NoteMetaData(
        lectureId:      widget.lecture.id,
        lectureTitle:   widget.lecture.title,
        subject:        widget.lecture.subject,
        instructorName: widget.lecture.instructor,
        savedAt:        savedAt,
        strokeCount:    totalStrokes,
        memoCount:      _savedNotes.length,
        handoutUrls:    widget.lecture.handoutUrls,
        thumbnailUrl:   widget.lecture.thumbnailUrl,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('필기가 저장되었습니다'),
            ]),
            backgroundColor: Color(0xFF2563EB),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  // ── 메모 데이터 저장
  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notesKey, jsonEncode(_savedNotes));
    } catch (_) {}
  }

  // ── 현재 페이지 필기 전체 삭제
  Future<void> _clearCurrentPageStrokes() async {
    setState(() {
      _pageStrokes[_currentNotePageIndex]?.clear();
      _pageStrokes.remove(_currentNotePageIndex);
      _strokesSaved = false;
    });
    await _saveStrokes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controlsTimer?.cancel();
    _playbackTimer?.cancel();
    _noteController.dispose();
    _driveChewieCtrl?.dispose();
    _driveVideoCtrl?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // 플레이어 초기화
  // ─── 구글 드라이브 파일 ID 추출 ───
  static String? _extractDriveFileId(String url) {
    // https://drive.google.com/file/d/FILE_ID/view
    // https://drive.google.com/open?id=FILE_ID
    // https://drive.google.com/uc?id=FILE_ID
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

  // ─────────────────────────────────────────────
  // ✅ 통합 비디오 플레이어 초기화
  // YouTube → WebView IFrame API 인앱 재생 (모든 YouTube 로고/브랜딩 숨김)
  // Drive  → uc?export=download 스트림 URL을 <video> 태그로 직접 재생
  // MP4    → WebView HTML5 video 직접 재생
  // ─────────────────────────────────────────────
  void _initPlayer() {
    final videoUrl = widget.lecture.videoUrl;
    if (videoUrl.isEmpty) return;

    final ytId = _extractYoutubeId(videoUrl);
    final driveId = _extractDriveFileId(videoUrl);

    String html;
    String baseUrl;
    String userAgent = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36';

    if (ytId != null) {
      html = _buildYoutubeHtml(ytId, 0);
      baseUrl = 'https://www.youtube.com';
    } else if (driveId != null) {
      // Drive: uc?export=download URL로 <video> 직접 재생 (인증 불필요)
      final streamUrl = 'https://drive.usercontent.google.com/download?id=$driveId&export=download&confirm=t';
      html = _buildDriveVideoHtml(streamUrl);
      baseUrl = 'https://drive.usercontent.google.com';
    } else {
      html = _buildMp4Html(videoUrl, _playbackSpeed);
      baseUrl = AppConfig.baseUrl.isNotEmpty ? AppConfig.baseUrl : 'about:blank';
    }

    final controller = WebViewController();

    // Android: 자동재생 허용 - 컨트롤러 설정 전에 먼저 적용 (로딩 속도 향상)
    if (!kIsWeb) {
      try {
        final androidCtrl = controller.platform;
        if (androidCtrl is AndroidWebViewController) {
          androidCtrl.setMediaPlaybackRequiresUserGesture(false);
          // 미디어 캐시 활성화 (재방문 시 빠른 로딩)
          AndroidWebViewController.enableDebugging(false);
        }
      } catch (_) {}
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(userAgent)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) => _onWebMessage(msg.message),
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) {
            setState(() => _webViewLoading = false);
            _scheduleHideControls();
          }
        },
        onWebResourceError: (err) {
          if (mounted) setState(() => _webViewLoading = false);
        },
        onNavigationRequest: (req) => NavigationDecision.navigate,
      ))
      ..loadHtmlString(html, baseUrl: baseUrl);

    if (kDebugMode) {
      controller.setOnConsoleMessage(
          (m) => debugPrint('VideoPlayer: ${m.message}'));
    }

    setState(() {
      _webViewController = controller;
      _webViewLoading = true;
    });
  }

  /// ── YouTube IFrame API HTML (인앱 재생, YouTube 브랜딩 완전 숨김)
  String _buildYoutubeHtml(String videoId, int startSec) => '''
<!DOCTYPE html><html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box;}
html,body{width:100%;height:100%;background:#000;overflow:hidden;}
#player{width:100%;height:100%;}
/* YouTube 로고/워터마크/버튼/점3개/전체화면 등 완전 숨김 */
.ytp-watermark,.ytp-youtube-button,.ytp-share-button,.ytp-pause-overlay,
.ytp-gradient-top,.ytp-chrome-top,.ytp-show-cards-title,
.ytp-overflow-button,.ytp-more-videos-button,.ytp-contextmenu,
.ytp-settings-button,.ytp-fullscreen-button,.ytp-size-button,
[class*="ytp-logo"],[class*="watermark"]{
  display:none!important;opacity:0!important;visibility:hidden!important;
}
</style>
</head>
<body>
<div id="player"></div>
<script src="https://www.youtube.com/iframe_api"></script>
<script>
var player;
var timeTimer=null;
var lastTime=-1;
function onYouTubeIframeAPIReady(){
  player=new YT.Player("player",{
    videoId:"$videoId",
    playerVars:{autoplay:1,mute:1,start:$startSec,controls:1,playsinline:1,
      rel:0,modestbranding:1,iv_load_policy:3,enablejsapi:1,
      disablekb:0,fs:1,cc_load_policy:0},
    events:{
      onReady:function(e){
        e.target.playVideo();
        setTimeout(function(){
          try{player.unMute();player.setVolume(100);}catch(ex){}
          // YouTube 로고 DOM에서 제거
          try{
            var iframe=document.querySelector('#player iframe');
            if(iframe&&iframe.contentDocument){
              var els=iframe.contentDocument.querySelectorAll('.ytp-watermark,.ytp-youtube-button');
              els.forEach(function(el){el.style.display='none';});
            }
          }catch(ex){}
        },800);
      },
      onStateChange:function(e){
        if(e.data===1){
          if(window.FlutterBridge) FlutterBridge.postMessage("play");
          startTimeTracking();
        }
        if(e.data===2){
          if(window.FlutterBridge) FlutterBridge.postMessage("pause");
          stopTimeTracking();
        }
        if(e.data===0){
          if(window.FlutterBridge) FlutterBridge.postMessage("ended");
          stopTimeTracking();
        }
        if(e.data===-1||e.data===5){
          try{
            var d=player.getDuration();
            if(d>0&&window.FlutterBridge) FlutterBridge.postMessage("dur:"+d.toFixed(0));
          }catch(ex){}
        }
      }
    }
  });
}
function startTimeTracking(){
  if(timeTimer) clearInterval(timeTimer);
  timeTimer=setInterval(function(){
    try{
      var t=player.getCurrentTime();
      if(Math.abs(t-lastTime)>=0.5){
        lastTime=t;
        if(window.FlutterBridge) FlutterBridge.postMessage("time:"+t.toFixed(1));
      }
    }catch(e){}
  },500);
}
function stopTimeTracking(){
  if(timeTimer){clearInterval(timeTimer);timeTimer=null;}
}
function setSpeed(s){try{player.setPlaybackRate(s);}catch(e){}}
function seekTo(t){try{player.seekTo(t,true);}catch(e){}}
function playVid(){try{player.playVideo();}catch(e){}}
function pauseVid(){try{player.pauseVideo();}catch(e){}}
</script>
</body></html>''';

  /// ── Google Drive 영상 HTML (uc?export=download 스트림 직접 <video> 재생)
  /// Drive /preview iframe 방식 대신 직접 스트림 URL로 재생
  String _buildDriveVideoHtml(String streamUrl) => '''
<!DOCTYPE html><html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box;}
html,body{width:100%;height:100%;background:#000;overflow:hidden;}
video{width:100%;height:100%;object-fit:contain;background:#000;display:block;}
/* 자막/자동자막 오버레이 완전 제거 */
::cue{display:none!important;visibility:hidden!important;opacity:0!important;}
video::cue{display:none!important;visibility:hidden!important;opacity:0!important;}
.vtt-cue,.caption-window,.caption-text,
[class*="caption"],[class*="subtitle"],[class*="cue"]{
  display:none!important;visibility:hidden!important;opacity:0!important;
}
#load{display:flex;position:absolute;inset:0;background:#000;
  flex-direction:column;align-items:center;justify-content:center;z-index:10;}
#load.hide{display:none;}
.spin{width:44px;height:44px;border:3px solid #333;border-top:3px solid #F97316;
  border-radius:50%;animation:sp 0.8s linear infinite;}
@keyframes sp{to{transform:rotate(360deg);}}
#load p{color:#777;font-size:12px;margin-top:12px;font-family:sans-serif;}
#err{display:none;position:absolute;inset:0;background:#111;
  color:#fff;flex-direction:column;align-items:center;
  justify-content:center;font-family:sans-serif;text-align:center;
  padding:20px;z-index:20;}
#err.show{display:flex;}
#err .icon{font-size:40px;margin-bottom:8px;}
#err p{font-size:13px;color:#aaa;line-height:1.6;}
#err button{margin-top:16px;padding:10px 28px;background:#F97316;color:#fff;
  border:none;border-radius:24px;font-size:14px;font-weight:bold;cursor:pointer;}
</style>
</head>
<body>
<div id="load"><div class="spin"></div><p>영상 불러오는 중...</p></div>
<video id="vid" playsinline preload="auto" x-webkit-airplay="allow"></video>
<div id="err">
  <div class="icon">⚠️</div>
  <p>영상을 불러올 수 없습니다.<br><small>파일이 공개 설정인지 확인해주세요.</small></p>
  <button onclick="retry()">다시 시도</button>
</div>
<script>
var vid=document.getElementById("vid");
var load=document.getElementById("load");
var err=document.getElementById("err");
var lastTime=-1;
var retryCount=0;
vid.src="$streamUrl";
// 메타데이터 로드 즉시 재생 (canplay 대기 시간 단축)
vid.onloadedmetadata=function(){
  load.classList.add("hide");
  vid.play().catch(function(){});
  if(window.FlutterBridge) FlutterBridge.postMessage("dur:"+vid.duration.toFixed(0));
}
vid.oncanplay=function(){ load.classList.add("hide"); vid.play().catch(function(){}); }
vid.oncanplaythrough=function(){ load.classList.add("hide"); }
vid.onerror=function(){
  if(retryCount<2){
    retryCount++;
    setTimeout(function(){ vid.load(); }, 1000);
  }else{
    load.classList.add("hide");
    err.classList.add("show");
  }
}
vid.onwaiting=function(){ /* 버퍼링 중 깜빡임 방지 - 로딩 표시 생략 */ }
vid.onplaying=function(){
  load.classList.add("hide");
  if(window.FlutterBridge) FlutterBridge.postMessage("play");
}
vid.onpause=function(){if(window.FlutterBridge) FlutterBridge.postMessage("pause");}
vid.onended=function(){if(window.FlutterBridge) FlutterBridge.postMessage("ended");}
vid.ontimeupdate=function(){
  var t=vid.currentTime;
  if(Math.abs(t-lastTime)>=0.5){
    lastTime=t;
    if(window.FlutterBridge) FlutterBridge.postMessage("time:"+t.toFixed(1));
  }
}
function retry(){retryCount=0;err.classList.remove("show");load.classList.remove("hide");vid.load();vid.play().catch(function(){});}
function setSpeed(s){vid.playbackRate=s;}
function seekTo(t){vid.currentTime=t;}
function playVid(){vid.play().catch(function(){});}
function pauseVid(){vid.pause();}
</script>
</body></html>''';

  /// WebView → Flutter 메시지 수신 (재생 시간 등)
  void _onWebMessage(String msg) {
    if (msg.startsWith('time:')) {
      final t = double.tryParse(msg.substring(5));
      if (t != null && mounted) {
        setState(() => _currentTime = t.toInt());
      }
    } else if (msg == 'ended') {
      setState(() { _isPlaying = false; _currentTime = _totalTime; });
      _playbackTimer?.cancel();
      if (_autoPlay) _playNextLecture();
    } else if (msg == 'play') {
      if (!mounted) return;
      setState(() => _isPlaying = true);
      _startSimulation();
    } else if (msg == 'pause') {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      _playbackTimer?.cancel();
    } else if (msg.startsWith('dur:')) {
      // HTML에서 영상 길이 전달 시 업데이트
      final d = double.tryParse(msg.substring(4));
      if (d != null && d > 0 && mounted) {
        setState(() => _totalTime = d.toInt());
      }
    }
  }

  // 다음 강의 자동재생
  void _playNextLecture() {
    final list = widget.autoPlayList;
    if (list == null || list.isEmpty) return;
    final nextIndex = widget.autoPlayIndex + 1;
    if (nextIndex >= list.length) {
      // 목록 끝 - 안내 스낵바
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('마지막 강의입니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    final nextLecture = list[nextIndex];
    if (!mounted) return;
    // 현재 화면을 대체(replace)해 다음 강의로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LecturePlayerScreen(
          lecture: nextLecture,
          autoPlayList: list,
          autoPlayIndex: nextIndex,
        ),
      ),
    );
  }

  // ─── 유튜브 영상 ID 추출 ───
  static String? _extractYoutubeId(String url) {
    // 두번설명: youtube.com/shorts/VIDEOID
    final shortsMatch = RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (shortsMatch != null) return shortsMatch.group(1);
    // 일반: youtu.be/VIDEOID 또는 youtube.com/watch?v=VIDEOID
    final normalMatch = RegExp(r'(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|v/))([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (normalMatch != null) return normalMatch.group(1);
    return null;
  }

  // ─── MP4/NAS 플레이어 HTML ───
  String _buildMp4Html(String videoUrl, double speedVal) {
    return '''<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box;}
html,body{width:100%;height:100%;background:#000;overflow:hidden;}
video{width:100%;height:100%;object-fit:contain;background:#000;display:block;}
/* 자막/자동자막 오버레이 완전 제거 */
::cue{display:none!important;visibility:hidden!important;opacity:0!important;}
video::cue{display:none!important;visibility:hidden!important;opacity:0!important;}
.vtt-cue,.caption-window,.caption-text,
[class*="caption"],[class*="subtitle"],[class*="cue"]{
  display:none!important;visibility:hidden!important;opacity:0!important;
}
#load{display:flex;position:absolute;inset:0;background:#000;
  flex-direction:column;align-items:center;justify-content:center;z-index:10;}
#load.hide{display:none;}
.spin{width:44px;height:44px;border:3px solid #333;border-top:3px solid $_kOrangeHex;
  border-radius:50%;animation:sp 0.8s linear infinite;}
@keyframes sp{to{transform:rotate(360deg);}}
#load p{color:#777;font-size:12px;margin-top:12px;font-family:sans-serif;}
#err{display:none;position:absolute;inset:0;background:#111;
  color:#fff;flex-direction:column;align-items:center;
  justify-content:center;font-family:sans-serif;text-align:center;
  padding:20px;z-index:20;}
#err.show{display:flex;}
#err .icon{font-size:40px;margin-bottom:8px;}
#err p{font-size:13px;color:#aaa;line-height:1.6;}
#err small{font-size:11px;color:#555;}
#err button{margin-top:16px;padding:10px 28px;background:$_kOrangeHex;color:#fff;
  border:none;border-radius:24px;font-size:14px;font-weight:bold;cursor:pointer;}
</style>
</head>
<body>
<div id="load"><div class="spin"></div><p>영상 불러오는 중...</p></div>
<video id="vid" playsinline preload="auto" src="$videoUrl" x-webkit-airplay="allow"></video>
<div id="err">
  <div class="icon">⚠️</div>
  <p>영상을 불러올 수 없습니다.<br><small>네트워크를 확인하거나 잠시 후 다시 시도해주세요.</small></p>
  <button onclick="retry()">다시 시도</button>
</div>
<script>
var vid=document.getElementById("vid");
var load=document.getElementById("load");
var err=document.getElementById("err");
var lastTime=-1;
vid.playbackRate=$speedVal;

// 재생 준비 완료 시 자동 재생 시도
// 메타데이터 로드되면 즉시 재생 시도 (canplay 대기 불필요)
vid.onloadedmetadata=function(){
  load.classList.add("hide");
  vid.play().catch(function(){});
  if(window.FlutterBridge) FlutterBridge.postMessage("dur:"+vid.duration.toFixed(0));
  try{ for(var i=0;i<vid.textTracks.length;i++) vid.textTracks[i].mode='disabled'; }catch(e){}
}
vid.oncanplay=function(){ load.classList.add("hide"); vid.play().catch(function(){}); }
vid.oncanplaythrough=function(){ load.classList.add("hide"); }
vid.onerror=function(){ load.classList.add("hide"); err.classList.add("show"); }
vid.onwaiting=function(){ /* 버퍼링 중 로딩 표시 생략 - 깜빡임 방지 */ }
vid.onstalled=function(){
  setTimeout(function(){ vid.load(); vid.play().catch(function(){}); }, 800);
}
vid.onplaying=function(){
  load.classList.add("hide");
  if(window.FlutterBridge) FlutterBridge.postMessage("play");
}
vid.onpause=function(){
  if(window.FlutterBridge) FlutterBridge.postMessage("pause");
}
vid.onended=function(){
  if(window.FlutterBridge) FlutterBridge.postMessage("ended");
}
vid.ontimeupdate=function(){
  var t=vid.currentTime;
  if(Math.abs(t-lastTime)>=0.5){
    lastTime=t;
    if(window.FlutterBridge) FlutterBridge.postMessage("time:"+t.toFixed(1));
  }
}
vid.onloadedmetadata=function(){
  load.classList.add("hide");
  vid.play().catch(function(){});
  if(window.FlutterBridge) FlutterBridge.postMessage("dur:"+vid.duration.toFixed(0));
  try{ for(var i=0;i<vid.textTracks.length;i++) vid.textTracks[i].mode='disabled'; }catch(e){}
}
function retry(){err.classList.remove("show");load.classList.remove("hide");vid.load();vid.play().catch(function(){});}
// 외부에서 제어할 수 있는 함수들
function setSpeed(s){vid.playbackRate=s;}
function seekTo(t){vid.currentTime=t;}
function playVid(){vid.play().catch(function(){});}
function pauseVid(){vid.pause();}
</script>
</body>
</html>''';
  }

  // ─────────────────────────────────────────────
  // 교안 슬라이드 로드
  // ─────────────────────────────────────────────
  Future<void> _loadSlidePages() async {
    // 1순위: Lecture 모델에 handoutUrls가 있으면 바로 사용
    if (widget.lecture.handoutUrls.isNotEmpty) {
      if (mounted) {
        setState(() {
          _notePages = List.from(widget.lecture.handoutUrls);
          _slidesLoading = false;
        });
      }
      return;
    }
    // 2순위: NAS 서버에서 슬라이드 자동 탐색
    final lectureId = widget.lecture.id;
    final baseUrl = AppConfig.baseUrl;
    final List<String> pages = [];
    for (int total = 1; total <= 20; total++) {
      final url = '$baseUrl/slides/$lectureId/${lectureId}_1$total.png';
      try {
        final res = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          for (int page = 1; page <= total; page++) {
            pages.add('$baseUrl/slides/$lectureId/${lectureId}_$page$total.png');
          }
          break;
        }
      } catch (_) { break; }
    }
    if (mounted) setState(() { _notePages = pages; _slidesLoading = false; });
  }

  // ─────────────────────────────────────────────
  // 타이머/플레이어 컨트롤
  // ─────────────────────────────────────────────
  void _scheduleHideControls() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      // 재생 중이든 아니든 일정 시간 후 컨트롤 오버레이를 숨김
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onTapPlayer() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startSimulation();
    } else {
      _playbackTimer?.cancel();
    }
    // 재생/정지 모두 컨트롤 표시 후 자동 숨김
    setState(() => _showControls = true);
    _scheduleHideControls();
    // YouTube IFrame API / HTML5 video 통합 제어
    _webViewController?.runJavaScript(
      _isPlaying ? 'try{playVid();}catch(e){}' : 'try{pauseVid();}catch(e){}',
    );
  }

  void _startSimulation() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_currentTime < _totalTime) {
        setState(() {
          _currentTime++;
          _saveProgressIfNeeded();
        });
      } else {
        _playbackTimer?.cancel();
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _saveProgressIfNeeded() async {
    if (!mounted) return;
    final appState = context.read<AppState>();
    if (!appState.isLoggedIn) return;
    final userId = appState.userId;
    if (userId.isEmpty) return;
    await _authService.saveLectureProgress(userId, widget.lecture.id, _watchProgress);
    for (final cp in [0.25, 0.5, 0.75, 0.9]) {
      final key = '${widget.lecture.id}_${(cp * 100).toInt()}';
      if (_watchProgress >= cp && !_savedProgressCheckpoints.contains(key)) {
        _savedProgressCheckpoints.add(key);
      }
    }
  }

  void _seekRelative(int seconds) {
    setState(() => _currentTime = (_currentTime + seconds).clamp(0, _totalTime));
    // YouTube IFrame API / HTML5 video 통합 탐색
    _webViewController?.runJavaScript('try{seekTo($_currentTime);}catch(e){}');
    _scheduleHideControls();
  }

  void _seekTo(double ratio) {
    setState(() => _currentTime = (ratio * _totalTime).toInt().clamp(0, _totalTime));
    _webViewController?.runJavaScript('try{seekTo($_currentTime);}catch(e){}');
  }

  void _setPlaybackSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    _webViewController?.runJavaScript('try{setSpeed($speed);}catch(e){}');
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      // 전체화면 → 이전 모드로 복귀
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() { _isFullScreen = false; _isLandscape = false; });
      });
    } else {
      // 세로 → 전체화면
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() { _isFullScreen = true; _isLandscape = false; });
      });
    }
  }

  // 가로화면+사이드패널 모드 토글
  void _toggleLandscapeMode() {
    if (_isLandscape) {
      // 가로 → 세로 복귀
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // 방향 전환 후 setState (딜레이로 블랙아웃 방지)
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _isLandscape = false);
      });
    } else {
      // 세로 → 가로 전환
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _isLandscape = true);
      });
    }
  }

  void _toggleMiniPlayer() {
    setState(() => _isMiniPlayer = !_isMiniPlayer);
  }

  void _changePage(int index) {
    _pageStrokes[_currentNotePageIndex] = List.from(_strokes);
    setState(() {
      _currentNotePageIndex = index;
      _strokes = List.from(_pageStrokes[index] ?? []);
      _currentStroke = [];
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) return _buildFullScreenScaffold();
    if (_isLandscape) return _buildLandscapeWithSidePanel();
    if (_isMiniPlayer) return _buildMiniPlayerLayout();
    // 모든 강의는 동일한 일반 레이아웃 사용 (탭 포함)
    return _buildNormalLayout();
  }

  // ─────────────────────────────────────────────
  // 📱 두번설명 레이아웃 (유튜브 쇼츠 스타일)
  // ─────────────────────────────────────────────
  Widget _buildShortsLayout() {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ① 전체 화면 영상 영역 (화면 크기에 딱 맞춤)
          Positioned(
            top: 0, left: 0, right: 0, bottom: 0,
            child: _buildShortsVideoArea(),
          ),

          // ② 상단 뒤로가기 버튼 (영상 위에 오버레이)
          Positioned(
            top: topPad + 4,
            left: 4,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ③ 하단 정보 오버레이 (제목 + 해시태그)
          // Drive 두번설명: bottom 패딩을 줄여서 재생 버튼과 안 겹치도록
          Positioned(
            bottom: botPad + 12,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 32, 80, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lecture.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: widget.lecture.hashtags.take(4).map((tag) => GestureDetector(
                        onTap: () {
                          final appState = context.read<AppState>();
                          // 이미 다른 강의가 PIP로 재생 중이면 activatePip 호출 안 함 (PIP 유지)
                          if (!appState.pipActive ||
                              appState.pipLecture == null ||
                              appState.pipLecture!.id == widget.lecture.id) {
                            appState.activatePip(widget.lecture, startSeconds: _currentTime);
                          }
                          appState.setSearchQuery(tag);
                          appState.setNavIndex(3);
                          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ④ 우측 하단: Drive인 경우 '재생' 안내 배지 (인라인 재생으로 대체 - 제거)
        ],
      ),
    );
  }

  // ✅ Shorts 통합 비디오 영역 (동일한 WebView 방식)
  Widget _buildShortsVideoArea() {
    if (kIsWeb) return _buildWebPreviewPlayer();

    if (_webViewController == null) {
      return _buildVideoLoadingPlaceholder();
    }

    return Stack(fit: StackFit.expand, children: [
      ClipRect(child: WebViewWidget(controller: _webViewController!)),
      if (_webViewLoading) _buildLoadingOverlay(),
    ]);
  }

  /// 웹 미리보기 전용: Drive iframe을 HtmlElementView로 직접 임베드
  /// kIsWeb == true 일 때만 호출됨
  Widget _buildWebDriveIframe(String fileId, {bool isShortsStyle = false}) {
    return DriveWebPlayer(fileId: fileId, isShortsStyle: isShortsStyle);
  }

  /// Drive 영상 탭-투-플레이 UI
  /// Drive thumbnail은 영상 첫 프레임(자막/마케팅 텍스트)을 반환해 지저분하므로
  /// 깔끔한 그라디언트 배경 + 제목 + 재생버튼으로 대체
  /// Drive 영상 인라인 플레이어 (별도 화면 이동 없이 현재 화면에서 재생)
  Widget _buildDriveTapToPlay(String fileId, {bool isShortsStyle = false}) {
    // ── 이미 인라인 플레이어가 활성화된 경우 → Chewie 위젯 반환
    if (_drivePlayerActive) {
      if (_drivePlayerLoading) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: _kOrange, strokeWidth: 2.5),
              SizedBox(height: 12),
              Text('영상 불러오는 중...', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
        );
      }
      if (_drivePlayerError) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 40),
              const SizedBox(height: 12),
              const Text('직접 재생 불가 — 브라우저로 열기', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = 'https://drive.google.com/file/d/$fileId/view';
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Google Drive에서 열기'),
                style: ElevatedButton.styleFrom(backgroundColor: _kOrange),
              ),
            ]),
          ),
        );
      }
      if (_driveChewieCtrl != null) {
        return Container(
          color: Colors.black,
          child: Chewie(controller: _driveChewieCtrl!),
        );
      }
    }

    // ── 재생 전: 로딩 스피너만 표시 (탭-투-플레이 버튼 없음)
    // Drive 영상은 자동으로 _startDriveInlinePlayer가 호출됨
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_drivePlayerActive) {
        _startDriveInlinePlayer(fileId);
      }
    });
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2.5)),
          SizedBox(height: 12),
          Text('영상 불러오는 중...', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ),
    );
  }

  /// Drive 영상 인라인 초기화 (video_player + chewie)
  Future<void> _startDriveInlinePlayer(String fileId) async {
    setState(() {
      _drivePlayerActive = true;
      _drivePlayerLoading = true;
      _drivePlayerError = false;
    });

    final streamUrl = 'https://drive.usercontent.google.com/download?id=$fileId&export=download&confirm=t';

    try {
      // 스트리밍 가능 여부 확인
      final resp = await http.head(Uri.parse(streamUrl))
          .timeout(const Duration(seconds: 8));
      final ct = resp.headers['content-type'] ?? '';
      if (!ct.contains('video/')) {
        throw Exception('스트리밍 불가');
      }

      final videoCtrl = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        httpHeaders: {'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36'},
      );
      await videoCtrl.initialize();

      if (!mounted) { videoCtrl.dispose(); return; }

      final chewieCtrl = ChewieController(
        videoPlayerController: videoCtrl,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );

      if (!mounted) { chewieCtrl.dispose(); videoCtrl.dispose(); return; }

      setState(() {
        _driveVideoCtrl = videoCtrl;
        _driveChewieCtrl = chewieCtrl;
        _drivePlayerLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _drivePlayerError = true;
        _drivePlayerLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  // 일반 레이아웃 (세로)
  // ─────────────────────────────────────────────
  Widget _buildNormalLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      // ── (교안) 내 노트 플로팅 버튼 ──
      floatingActionButton: _buildNoteViewerFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(children: [
          // ① 플레이어 영역 (상단 바 + 영상 + 진행바)
          _buildPlayerSection(),
          // ② 탭바
          _buildTabBar(),
          // ③ 탭 컨텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildNoteTab(),
                _buildQATab(),
                _buildPlaylistTab(),
                _buildProblemTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  /// 교안 내 노트 플로팅 버튼 (작고 샤프한 스타일)
  Widget _buildNoteViewerFAB() {
    if (widget.lecture.handoutUrls.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _openInlineNoteViewer,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0EA5E9),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.menu_book_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text('내 노트',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2)),
        ]),
      ),
    );
  }

  /// 교안 인라인 뷰어 (DraggableScrollableSheet)
  void _openInlineNoteViewer() {
    final allLectures = widget.autoPlayList;
    final lecturesWithHandouts = allLectures != null
        ? allLectures.where((l) => l.handoutUrls.isNotEmpty).toList()
        : <Lecture>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: MyNoteViewerScreen(
              lecture: widget.lecture,
              lectureList: lecturesWithHandouts.isNotEmpty ? lecturesWithHandouts : null,
              fromPlayer: true,          // 플레이어에서 열린 경우
              scrollController: scrollController,
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🎬 플레이어 섹션
  // ─────────────────────────────────────────────
  Widget _buildPlayerSection() {
    // ── 영상 비율: Drive/MP4 모두 16:9, Shorts는 9:16 ──
    final videoUrl = widget.lecture.videoUrl;
    final isShortsStyle = videoUrl.contains('/shorts/');
    // 정확한 16:9 비율
    const aspectRatio = 16.0 / 9.0;

    return Container(
      color: Colors.black,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildPlayerTopBar(),
        // ── AspectRatio로 영상 크기 정확히 맞춤 ──
        LayoutBuilder(
          builder: (ctx, constraints) {
            final maxW = constraints.maxWidth;
            final sz = MediaQuery.of(ctx).size;
            // 최대 높이를 화면의 35%로 제한 (너무 크지 않게)
            final maxH = sz.height * (isShortsStyle ? 0.55 : 0.35);
            // 16:9 비율로 높이 계산, 최대치 초과하지 않도록
            final h = (maxW / aspectRatio).clamp(0.0, maxH);
            return SizedBox(
              width: maxW,
              height: h,
              child: GestureDetector(
                onTap: _onTapPlayer,
                child: Stack(fit: StackFit.expand, children: [
                  _buildVideoArea(),
                  // 로딩 중에는 컨트롤 오버레이(플레이 버튼) 숨김
                  if (_showControls && !_webViewLoading) _buildControlOverlay(),
                  if (_showSubtitle && _currentSubtitle.isNotEmpty) _buildSubtitle(),
                  // 영상 우하단 전체화면 버튼 (항상 표시) + 가로화면 전환 버튼
                  Positioned(
                    right: 8, bottom: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 가로화면 전환 버튼 (전체화면 버튼 위)
                        GestureDetector(
                          onTap: _toggleLandscapeMode,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.screen_rotation_rounded,
                              color: Colors.white, size: 18),
                          ),
                        ),
                        // 전체화면 버튼
                        GestureDetector(
                          onTap: _toggleFullScreen,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.fullscreen_rounded,
                              color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
        _buildProgressBar(),
      ]),
    );
  }

  // ── 상단 바
  Widget _buildPlayerTopBar() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white,
      child: Row(children: [
        // 뒤로가기
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF333333), size: 26),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        // 제목
        Expanded(
          child: Text(
            widget.lecture.title,
            style: const TextStyle(
              color: Color(0xFF222222), fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        // 재생속도 칩 (세로화면 - 주황 테두리로 눈에 띄게)
        _buildSpeedChip(highlighted: true),
        const SizedBox(width: 6),
        // 점 3개(더보기) 삭제
      ]),
    );
  }

  Widget _buildCCButton() {
    return GestureDetector(
      onTap: () => setState(() => _showSubtitle = !_showSubtitle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: _showSubtitle ? _kOrange : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('CC',
          style: TextStyle(
            color: _showSubtitle ? Colors.white : const Color(0xFF444444),
            fontSize: 10, fontWeight: FontWeight.w800,
            letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildSpeedChip({bool onDark = false, bool highlighted = false}) {
    final label = _playbackSpeed == 1.0 ? '1x'
        : _playbackSpeed == 1.5 ? '1.5x'
        : _playbackSpeed == 2.0 ? '2x'
        : '${_playbackSpeed}x';
    final isNonDefault = _playbackSpeed != 1.0;
    // highlighted=true(세로화면 상단): 기본속도라도 주황 테두리로 눈에 띄게
    final bgColor = isNonDefault
        ? _kOrange
        : highlighted
            ? const Color(0xFFFFF3E0)  // 연한 주황 배경
            : onDark
                ? Colors.white.withValues(alpha: 0.18)
                : const Color(0xFFE8E8E8);
    final borderColor = isNonDefault
        ? _kOrange
        : highlighted
            ? _kOrange  // 주황 테두리
            : onDark ? Colors.white30 : const Color(0xFFCCCCCC);
    final textColor = isNonDefault
        ? Colors.white
        : highlighted
            ? _kOrange  // 주황 텍스트
            : onDark ? Colors.white : const Color(0xFF333333);
    return GestureDetector(
      onTap: _showSpeedSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: isNonDefault ? 0 : 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded,
              size: 12,
              color: textColor),
            const SizedBox(width: 3),
            Text(label,
              style: TextStyle(
                color: textColor,
                fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ✅ 통합 비디오 영역: YouTube / Drive / MP4 모두 WebView로 처리
  Widget _buildVideoArea() {
    if (kIsWeb) return _buildWebPreviewPlayer();

    if (_webViewController == null) {
      // 초기화 전: 썸네일 + 로딩 표시
      return _buildVideoLoadingPlaceholder();
    }

    return Stack(fit: StackFit.expand, children: [
      // WebView 영상 (contain으로 비율 유지)
      ClipRect(child: WebViewWidget(controller: _webViewController!)),
      if (_webViewLoading) _buildLoadingOverlay(),
    ]);
  }

  /// 초기 로딩 플레이스홀더 (WebView 초기화 전 표시)
  Widget _buildVideoLoadingPlaceholder() {
    final thumbUrl = widget.lecture.effectiveThumbnailUrl;
    return Container(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        // 썸네일 (contain으로 비율 유지, 너무 크지 않게)
        if (thumbUrl.isNotEmpty && thumbUrl != 'nas_default')
          Image.network(
            thumbUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildGradientPlaceholder(),
          )
        else
          _buildGradientPlaceholder(),
        Container(color: Colors.black.withValues(alpha: 0.3)),
        _buildLoadingOverlay(),
      ]),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2.5)),
          SizedBox(height: 12),
          Text('영상 불러오는 중...',
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ),
    );
  }

  /// YouTube 외부 실행 UI (앱/브라우저로 열기)
  /// Google Drive 외부 실행 UI (Chrome으로 열기)
  // _buildDriveLauncherUI 는 _buildDriveThumbnailPlayer 로 통합됨

  /// 웹 미리보기 전용 플레이어 (시뮬레이션)
  Widget _buildWebPreviewPlayer() {
    // 웹 환경에서도 WebViewController가 있으면 바로 사용
    if (_webViewController != null) {
      return Stack(fit: StackFit.expand, children: [
        WebViewWidget(controller: _webViewController!),
        if (_webViewLoading) _buildLoadingOverlay(),
      ]);
    }

    final thumbUrl = widget.lecture.effectiveThumbnailUrl;
    return Container(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        // 썸네일 배경 - contain으로 원본 비율 유지
        if (thumbUrl != 'nas_default' && thumbUrl.isNotEmpty)
          Image.network(thumbUrl, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildGradientPlaceholder())
        else
          _buildGradientPlaceholder(),
        // 어두운 오버레이 (약하게)
        Container(color: Colors.black.withValues(alpha: 0.35)),
        // 재생 버튼
        Center(
          child: GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _kOrange,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: _kOrange.withValues(alpha: 0.4),
                  blurRadius: 16, spreadRadius: 2)],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 36),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(Icons.play_circle_outline_rounded,
          size: 72, color: _kOrange.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildGradientPlaceholder() {
    Color subjectColor;
    switch (widget.lecture.subject) {
      case '수학': subjectColor = AppColors.math; break;
      case '과학': subjectColor = AppColors.science; break;
      case '공통과학': subjectColor = AppColors.commonScience; break;
      case '물리': subjectColor = AppColors.physics; break;
      case '화학': subjectColor = AppColors.chemistry; break;
      case '생명과학': subjectColor = AppColors.biology; break;
      case '지구과학': subjectColor = AppColors.earth; break;
      case '국어': subjectColor = AppColors.korean; break;
      case '영어': subjectColor = AppColors.english; break;
      default: subjectColor = _kOrange;
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            subjectColor.withValues(alpha: 0.8),
            subjectColor.withValues(alpha: 0.4),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.movie_outlined, size: 48, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(widget.lecture.subject,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── 컨트롤 오버레이 (터치 투명도 처리 포함)
  Widget _buildControlOverlay() {
    // _showControls=false면 포인터 무시 + 투명으로 처리
    return IgnorePointer(
      ignoring: !_showControls,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        // 배경 탭 → 오버레이 닫기 (GestureDetector로 전체 영역 커버)
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTapPlayer, // 배경 탭 시 오버레이 닫기
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
            child: Center(
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: _kOrange,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: _kOrange.withValues(alpha: 0.45),
                      blurRadius: 16, spreadRadius: 2)],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeekButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(icon, color: Colors.white, size: 28),
          Positioned(
            bottom: 6,
            child: Text(label,
              style: const TextStyle(
                color: Colors.white70, fontSize: 7, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  // ── 자막
  Widget _buildSubtitle() {
    return Positioned(
      bottom: 8, left: 16, right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            _currentSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white, fontSize: 13, height: 1.5,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }

  // ── 진행바
  Widget _buildProgressBar() {
    final progress = _totalTime > 0 ? _currentTime / _totalTime : 0.0;
    // 아이보리/연노란 배경에 맞는 어두운 텍스트/아이콘 색상
    const timeTextColor = Color(0xFF4A4A4A);
    const iconColor = Color(0xFF5A5A5A);
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      child: Row(children: [
        // 슬라이더
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: _kOrange,
              inactiveTrackColor: const Color(0xFFCCCCCC),
              thumbColor: _kOrange,
              overlayColor: _kOrange.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: _seekTo,
              onChangeStart: (_) {
                _controlsTimer?.cancel();
                setState(() => _showControls = true);
              },
              onChangeEnd: (_) => _scheduleHideControls(),
            ),
          ),
        ),
        // 시간 텍스트
        Text(_formatTime(_currentTime),
          style: const TextStyle(color: timeTextColor, fontSize: 10,
            fontWeight: FontWeight.w600)),
        const Text(' / ', style: TextStyle(color: Color(0xFF999999), fontSize: 10)),
        Text(_formatTime(_totalTime),
          style: const TextStyle(color: Color(0xFF999999), fontSize: 10)),
        const SizedBox(width: 4),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  // 🗂️ 탭바
  // ─────────────────────────────────────────────
  Widget _buildTabBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 탭 바 (자동재생 토글 제거됨) ──
        Container(
          color: Colors.white,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: _kOrange,
            unselectedLabelColor: const Color(0xFF888888),
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            indicatorColor: _kOrange,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: '노트 보기'),
              Tab(text: '강의 Q&A'),
              Tab(text: '재생 목록'),
              Tab(text: '문제풀이'),
            ],
          ),
        ),
        // ── 강의 메타 정보 영역 (터치 시 접힘/펼침) ──
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _isMetaBarCollapsed = !_isMetaBarCollapsed),
          onVerticalDragEnd: (details) {
            // 위로 슬라이드 → 접힘(영상 공간 확보), 아래로 슬라이드 → 펼침
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -50) {
                setState(() => _isMetaBarCollapsed = true);
              } else if (details.primaryVelocity! > 50) {
                setState(() => _isMetaBarCollapsed = false);
              }
            }
          },
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstChild: _buildLectureMetaBar(),
            secondChild: _buildCollapsedMetaBar(),
            crossFadeState: _isMetaBarCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ),
      ],
    );
  }

  /// 접힌 상태 메타바 (제목 한 줄 + 펼침 화살표)
  Widget _buildCollapsedMetaBar() {
    final lec = widget.lecture;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(children: [
        Expanded(
          child: Text(
            lec.title,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        // 펼침 힌트
        const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF9CA3AF), size: 18),
        const SizedBox(width: 2),
        const Text('강의 정보',
            style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
      ]),
    );
  }

  /// 탭바 아래 강의 정보 요약 바 (LectureCard와 동일한 형식으로 통일)
  Widget _buildLectureMetaBar() {
    final lec = widget.lecture;
    // 과목 색상
    Color subjectColor;
    Color gradeColor;
    switch (lec.subject) {
      case '수학':     subjectColor = const Color(0xFF2563EB); break;
      case '과학':     subjectColor = const Color(0xFF16A34A); break;
      case '공통과학': subjectColor = const Color(0xFF7C3AED); break;
      case '물리':     subjectColor = const Color(0xFF0EA5E9); break;
      case '화학':     subjectColor = const Color(0xFFFF6B35); break;
      case '생명과학': subjectColor = const Color(0xFF22C55E); break;
      case '지구과학': subjectColor = const Color(0xFF6366F1); break;
      case '국어':     subjectColor = const Color(0xFFDC2626); break;
      case '영어':     subjectColor = const Color(0xFF0891B2); break;
      default:          subjectColor = _kOrange;
    }
    switch (lec.grade) {
      case 'elementary': gradeColor = const Color(0xFFFF6B35); break;  // 주황
      case 'middle':     gradeColor = const Color(0xFF059669); break;  // 에메랄드 (해시태그 파랑과 구분)
      default:           gradeColor = const Color(0xFF7C3AED);          // 보라 (고등)
    }

    Widget badge(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );

    final gradeLabel = lec.gradeText;
    final yearLabel = lec.gradeYear.isEmpty || lec.gradeYear == 'All'
        ? 'All' : '${lec.gradeYear}학년';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 행 1: 강의명
          Text(
            lec.title,
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827), height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // 행 2: 시리즈명
          if (lec.series.isNotEmpty) ...[
            Row(children: [
              const Icon(Icons.playlist_play_rounded, size: 13, color: Color(0xFF6B7280)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(lec.series,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 4),
          ],
          // 행 3: 학제 + 학년 + 과목 + 강사명
          Row(children: [
            badge(gradeLabel, gradeColor),
            const SizedBox(width: 4),
            badge(yearLabel, yearLabel == 'All' ? const Color(0xFFF97316) : gradeColor.withValues(alpha: 0.65)),
            const SizedBox(width: 4),
            badge(lec.subject, subjectColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(lec.instructor,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          // 행 4: 해시태그 (1줄이면 스크롤 없음, 2줄 이상이면 좌우 스크롤)
          if (lec.hashtags.isNotEmpty) ...[
            const SizedBox(height: 5),
            _buildMetaHashtags(lec.hashtags, subjectColor),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 📝 탭1: 노트 보기
  // ─────────────────────────────────────────────
  Widget _buildNoteTab() {
    if (_slidesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kOrange, strokeWidth: 2));
    }
    if (_notePages.isEmpty) return _buildTextNote();
    return Stack(children: [
      _buildSlideNote(),
    ]);
  }

  Widget _buildSlideNote() {
    return Column(children: [
      // ── 상단 툴바 행 1: 모드 전환 + 저장/메모 ──
      Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(children: [
          // 줌 모드 버튼
          _buildModeBtn(
            icon: Icons.zoom_in_rounded,
            label: '확대/축소',
            active: !_isDrawingMode,
            onTap: () => setState(() => _isDrawingMode = false),
          ),
          const SizedBox(width: 6),
          // 필기 모드 버튼
          _buildModeBtn(
            icon: Icons.edit_rounded,
            label: '필기',
            active: _isDrawingMode,
            onTap: () => setState(() => _isDrawingMode = true),
          ),
          const Spacer(),
          // 필기 저장 버튼 (미저장 시 강조)
          if (_isDrawingMode)
            GestureDetector(
              onTap: _saveStrokes,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _strokesSaved
                      ? Colors.grey.shade100
                      : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _strokesSaved
                        ? Colors.grey.shade300
                        : const Color(0xFF2563EB)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _strokesSaved ? Icons.check_rounded : Icons.save_outlined,
                    size: 14,
                    color: _strokesSaved ? AppColors.textSecondary : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _strokesSaved ? '저장됨' : '저장',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: _strokesSaved ? AppColors.textSecondary : Colors.white,
                    ),
                  ),
                ]),
              ),
            ),
          if (_isDrawingMode) const SizedBox(width: 6),
          // 메모 추가 버튼
          GestureDetector(
            onTap: _showNoteInput,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.sticky_note_2_outlined, size: 14, color: _kOrange),
                const SizedBox(width: 4),
                const Text('메모', style: TextStyle(
                  fontSize: 11, color: _kOrange, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ),
      // ── 상단 툴바 행 2: 필기 도구 (필기 모드일 때만) ──
      if (_isDrawingMode)
        Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          color: const Color(0xFFFAFAFA),
          child: Row(children: [
            const Text('색상:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 6),
            for (final c in [
              const Color(0xFF2563EB), Colors.red, Colors.green, const Color(0xFFF97316), Colors.black,
            ])
              GestureDetector(
                onTap: () => setState(() {
                  _penColor = c;
                  _isEraser = false;
                  // 색상 선택 시 자동으로 필기 모드 전환 (교안 고정)
                  _isDrawingMode = true;
                }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: _penColor == c && !_isEraser
                        ? Border.all(
                            // 빨간색 계열이면 흰색 테두리, 아니면 주황색 테두리
                            color: (c.red > 180 && c.green < 100 && c.blue < 100)
                                ? Colors.white
                                : _kOrange,
                            width: 2.5)
                        : null,
                    boxShadow: _penColor == c && !_isEraser
                        ? [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4, spreadRadius: 1)]
                        : null,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            // 지우개
            GestureDetector(
              onTap: () => setState(() => _isEraser = !_isEraser),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isEraser ? _kOrange.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isEraser ? _kOrange : Colors.grey.shade300),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  EraserIcon(isActive: _isEraser, size: 18),
                  const SizedBox(width: 3),
                  Text('지우개', style: TextStyle(
                    fontSize: 10, color: _isEraser ? _kOrange : AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const Spacer(),
            // 현재 페이지 필기 전체 삭제
            GestureDetector(
              onTap: _clearCurrentPageStrokes,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red.shade400),
                  const SizedBox(width: 3),
                  Text('이 페이지 삭제', style: TextStyle(
                    fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
      // ── 교안 페이지 스크롤 영역 ──
      // ★ 필기 모드일 때 NeverScrollableScrollPhysics로 전환 → 스크롤 충돌(떨림) 완전 제거
      Expanded(
        child: SingleChildScrollView(
          physics: _isDrawingMode
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          child: Column(
            children: List.generate(_notePages.length, (pageIdx) {
              final pageUrl = _notePages[pageIdx];
              final isAsset = pageUrl.startsWith('assets/');
              final pageStrokesForPage = _pageStrokes[pageIdx] ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                color: Colors.white,
                child: Column(children: [
                  // 페이지 번호 헤더
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: const Color(0xFFF5F7FA),
                    child: Row(children: [
                      Text('${pageIdx + 1} / ${_notePages.length}페이지',
                        style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  // 이미지 + 필기 레이어
                  // ★ Listener 사용: GestureDetector 대신 Listener로 교체하여
                  //   PageView/ScrollView와의 터치 이벤트 충돌(떨림)을 완전 제거
                  Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _isDrawingMode
                        ? (e) => setState(() {
                            _currentNotePageIndex = pageIdx;
                            _currentStroke = [e.localPosition];
                          })
                        : null,
                    onPointerMove: _isDrawingMode
                        ? (e) {
                            setState(() {
                              _currentStroke.add(e.localPosition);
                              if (_isEraser) {
                                _eraserPosition = e.localPosition;
                                _showEraserCursor = true;
                                final strokes = List<_DrawingStroke>.from(
                                    _pageStrokes[pageIdx] ?? []);
                                const eraseRadius = 20.0;
                                final idx = strokes.indexWhere((s) =>
                                    s.points.whereType<Offset>().any(
                                        (p) => (p - e.localPosition).distance < eraseRadius));
                                if (idx != -1) {
                                  strokes.removeAt(idx);
                                  _pageStrokes[pageIdx] = strokes;
                                  _strokesSaved = false;
                                }
                              }
                            });
                          }
                        : null,
                    onPointerUp: _isDrawingMode
                        ? (_) {
                            if (!_isEraser && _currentStroke.isNotEmpty) {
                              final strokes = List<_DrawingStroke>.from(
                                  _pageStrokes[pageIdx] ?? []);
                              strokes.add(_DrawingStroke(
                                points: List.from(_currentStroke),
                                color: _penColor, width: _strokeWidth));
                              setState(() {
                                _pageStrokes[pageIdx] = strokes;
                                _strokesSaved = false;
                              });
                            }
                            setState(() {
                              _currentStroke = [];
                              _showEraserCursor = false;
                              _eraserPosition = null;
                            });
                          }
                        : null,
                    onPointerCancel: _isDrawingMode
                        ? (_) => setState(() {
                            _currentStroke = [];
                            _showEraserCursor = false;
                            _eraserPosition = null;
                          })
                        : null,
                    child: Stack(children: [
                      // 교안 이미지
                      // 필기 모드 or 지우개 모드: 교안 완전 고정 (InteractiveViewer 비활성)
                      // 확대/축소 모드: InteractiveViewer 활성
                      (_isDrawingMode)
                          ? SizedBox(
                              width: double.infinity,
                              child: _buildHandoutImage(pageUrl, pageIdx, isAsset),
                            )
                          : InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 5.0,
                              constrained: true,
                              clipBehavior: Clip.none,
                              child: SizedBox(
                                width: double.infinity,
                                child: _buildHandoutImage(pageUrl, pageIdx, isAsset),
                              ),
                            ),
                      // 필기 레이어 (항상 표시)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: !_isDrawingMode,
                          child: CustomPaint(
                            painter: _DrawingPainter(
                              strokes: _isDrawingMode && _currentNotePageIndex == pageIdx
                                  ? [
                                      ...pageStrokesForPage,
                                      if (_currentStroke.isNotEmpty && !_isEraser)
                                        _DrawingStroke(
                                          points: List.from(_currentStroke),
                                          color: _penColor, width: _strokeWidth),
                                    ]
                                  : pageStrokesForPage,
                              currentStroke: [],
                              currentColor: _penColor,
                              currentWidth: _strokeWidth,
                              isEraser: _isEraser,
                            ),
                          ),
                        ),
                      ),
                      // 지우개 커서: 각 페이지 Stack 내부에 배치 → 스크롤 좌표와 정확히 일치
                      if (_isEraser && _showEraserCursor &&
                          _eraserPosition != null &&
                          _currentNotePageIndex == pageIdx)
                        Positioned(
                          left: _eraserPosition!.dx - 16,
                          top: _eraserPosition!.dy - 16,
                          child: IgnorePointer(
                            child: EraserCursor(position: _eraserPosition!),
                          ),
                        ),
                    ]),
                  ),
                ]),
              );
            }),
          ),
        ),
      ),
      // ── 저장된 메모 목록 ──
      if (_savedNotes.isNotEmpty)
        Container(
          constraints: const BoxConstraints(maxHeight: 160),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8F3),
            border: Border(top: BorderSide(color: Color(0xFFFFE0CC))),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Row(children: [
                const Icon(Icons.sticky_note_2_outlined, size: 14, color: _kOrange),
                const SizedBox(width: 6),
                Text('저장된 메모 ${_savedNotes.length}개',
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _kOrange)),
              ]),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                itemCount: _savedNotes.length,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD0B0)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_savedNotes[i]['time'] ?? '',
                        style: const TextStyle(
                          fontSize: 10, color: _kOrange, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_savedNotes[i]['text'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    // 휴지통 버튼
                    GestureDetector(
                      onTap: () {
                        setState(() => _savedNotes.removeAt(i));
                        _saveNotes();
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppColors.textHint),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
    ]);
  }

  Widget _buildModeBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: active ? Colors.white : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildHandoutImage(String pageUrl, int pageIdx, bool isAsset) {
    if (isAsset) {
      return Image.asset(
        pageUrl,
        fit: BoxFit.fitWidth,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _buildHandoutError(pageIdx),
      );
    }
    // genspark 단축 URL → 직접 접근 가능한 URL로 변환
    String resolvedUrl = pageUrl;
    if (pageUrl.contains('genspark.ai/api/files/s/')) {
      // 단축 URL을 직접 다운로드 URL로 변환
      final shortId = pageUrl.split('/').last;
      resolvedUrl = 'https://www.genspark.ai/api/files/v1/$shortId';
    }
    return Image.network(
      resolvedUrl,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      headers: pageUrl.contains('genspark.ai')
          ? const {'Referer': 'https://www.genspark.ai/'}
          : const {},
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: _kOrange, strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _buildHandoutError(pageIdx),
    );
  }

  // 교안 이미지 에러 위젯
  Widget _buildHandoutError(int pageIdx) {
    return Container(
      height: 200,
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.description_outlined, size: 40, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text('교안 ${pageIdx + 1}페이지',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
      ),
    );
  }

  Widget _buildTextNote() {
    return Column(children: [
      // 강의 정보 헤더
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 3, height: 18,
              decoration: BoxDecoration(
                color: _kOrange, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.lecture.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
            ),
            // 즐겨찾기
            Icon(Icons.bookmark_border_rounded,
              size: 20, color: AppColors.textHint),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _buildInfoBadge(Icons.person_outline_rounded, widget.lecture.instructor),
            _buildInfoBadge(Icons.timer_outlined, widget.lecture.durationText),
            _buildInfoBadge(Icons.school_outlined, _gradeLabel(widget.lecture.grade)),
            _buildInfoBadge(Icons.category_outlined, widget.lecture.lectureTypeText),
          ]),
        ]),
      ),
      // 강의 설명 + 해시태그 + 저장된 메모
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // 강의 설명
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Text(
                widget.lecture.description.isNotEmpty
                    ? widget.lecture.description
                    : '${widget.lecture.title}\n\n강사: ${widget.lecture.instructor}\n\n이 강의에 대한 교안을 불러오는 중입니다.',
                style: const TextStyle(
                  fontSize: 14, height: 1.7, color: AppColors.textPrimary),
              ),
            ),
            if (widget.lecture.hashtags.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('관련 태그',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              _buildDetailHashtags(widget.lecture.hashtags),
            ],
            // 저장된 메모
            if (_savedNotes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 3, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                const Text('내 메모',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
                const Spacer(),
                Text('${_savedNotes.length}개',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ]),
              const SizedBox(height: 8),
              ..._savedNotes.map((note) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kOrange.withValues(alpha: 0.2))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4)),
                    child: Text(note['time']!,
                      style: const TextStyle(
                        fontSize: 10, color: _kOrange, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(note['text']!,
                      style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary, height: 1.5))),
                ]),
              )).toList(),
            ],
            const SizedBox(height: 8),
            // 메모 추가 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('메모 추가'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kOrange,
                  side: BorderSide(color: _kOrange.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: _showNoteInput,
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.textHint),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }

  /// 메타바 해시태그: 터치 → PIP 전환 + 검색화면 이동 (2줄 이내 + 좌우 스크롤)
  Widget _buildMetaHashtags(List<String> tags, Color accentColor) {
    if (tags.isEmpty) return const SizedBox.shrink();
    // 해시태그 색상 고정 (앱 전체 통일: 890 화면 기준)
    const tagBg     = Color(0xFFEEF4FF);
    const tagBorder = Color(0xFFC3D4F0);
    const tagText   = Color(0xFF5E8ED6);
    final appState = context.read<AppState>();

    Widget tagChip(String tag) => GestureDetector(
      onTap: () {
        // 이미 다른 강의가 PIP로 재생 중이면 activatePip 호출 안 함 (PIP 유지)
        if (!appState.pipActive ||
            appState.pipLecture == null ||
            appState.pipLecture!.id == widget.lecture.id) {
          appState.activatePip(widget.lecture, startSeconds: _currentTime);
        }
        // 검색어 설정 후 검색 탭으로 이동
        appState.setSearchQuery(tag);
        appState.setNavIndex(3);
        // 강의 플레이어 화면 닫기
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 4, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: tagBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tagBorder, width: 0.8),
        ),
        child: Text(
          '#$tag',
          style: const TextStyle(
            fontSize: 10,
            color: tagText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        double estimateW(String t) => t.length * 7.0 + 18;
        final avail = constraints.maxWidth;

        // 1줄에 모두 들어가는지 먼저 확인
        double totalW = 0;
        for (final t in tags) {
          totalW += estimateW(t) + 4;
        }
        // 1줄로 충분 → 스크롤 없는 Row
        if (totalW <= avail) {
          return Row(children: tags.map(tagChip).toList());
        }

        // 2줄 분배
        double w = 0;
        final row1 = <String>[], row2 = <String>[];
        bool useRow2 = false;
        for (final t in tags) {
          final tw = estimateW(t);
          if (!useRow2) {
            if (w + tw <= avail) { row1.add(t); w += tw + 4; }
            else { useRow2 = true; row2.add(t); }
          } else { row2.add(t); }
        }
        double row2W = row2.fold(0.0, (s, t) => s + estimateW(t) + 4);
        Widget rows() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: row1.map(tagChip).toList()),
            const SizedBox(height: 2),
            Row(children: row2.map(tagChip).toList()),
          ],
        );
        if (row2W > avail) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: rows(),
          );
        }
        return rows();
      },
    );
  }

  /// 태그 수에 따라 1줄 / 2줄 / 2줄+좌우스크롤 자동 조절
  Widget _buildDetailHashtags(List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();
    // 해시태그 색상 고정 (앱 전체 통일: 890 화면 기준)
    const tagBg     = Color(0xFFEEF4FF);
    const tagBorder = Color(0xFFC3D4F0);
    const tagText   = Color(0xFF5E8ED6);
    final appState = context.read<AppState>();

    Widget tagChip(String tag) => GestureDetector(
      onTap: () {
        // 이미 다른 강의가 PIP로 재생 중이면 activatePip 호출 안 함 (PIP 유지)
        if (!appState.pipActive ||
            appState.pipLecture == null ||
            appState.pipLecture!.id == widget.lecture.id) {
          appState.activatePip(widget.lecture, startSeconds: _currentTime);
        }
        appState.setSearchQuery(tag);
        appState.setNavIndex(3);
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tagBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tagBorder, width: 0.8)),
        child: Text('#$tag',
          style: const TextStyle(
            fontSize: 12, color: tagText, fontWeight: FontWeight.w600)),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // 태그 너비 추정 (글자 수 × 7.5 + 패딩)
        double estimateTagWidth(String tag) => tag.length * 7.5 + 27;

        final availableWidth = constraints.maxWidth;
        double rowWidth = 0;
        final row1 = <String>[];
        final row2 = <String>[];
        bool useRow2 = false;

        for (final tag in tags) {
          final w = estimateTagWidth(tag);
          if (!useRow2) {
            if (rowWidth + w <= availableWidth) {
              row1.add(tag);
              rowWidth += w + 6;
            } else {
              useRow2 = true;
              row2.add(tag);
              rowWidth = w + 6;
            }
          } else {
            row2.add(tag);
          }
        }

        // 1줄로 충분
        if (row2.isEmpty) {
          return Row(children: row1.map(tagChip).toList());
        }

        // 2줄 필요 → row2가 넘치면 좌우 스크롤
        double row2Width = row2.fold(0.0, (s, t) => s + estimateTagWidth(t) + 6);
        bool needsScroll = row2Width > availableWidth;

        Widget rows() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: row1.map(tagChip).toList()),
            const SizedBox(height: 6),
            Row(children: row2.map(tagChip).toList()),
          ],
        );

        if (needsScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: rows(),
          );
        }
        return rows();
      },
    );
  }

  Widget _buildDrawingToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isDrawingMode = !_isDrawingMode),
      child: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _isDrawingMode ? _kOrange : Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6, offset: const Offset(2, 0))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.edit_rounded, size: 16,
            color: _isDrawingMode ? Colors.white : AppColors.textSecondary),
          const SizedBox(height: 2),
          Text('필기\n도구',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8, height: 1.2,
              color: _isDrawingMode ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _buildDrawingPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (final c in [
            const Color(0xFF2563EB),
            const Color(0xFFDC2626),
            const Color(0xFF16A34A),
            _kOrange,
            Colors.black,
          ])
            GestureDetector(
              onTap: () => setState(() { _penColor = c; _isEraser = false; }),
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: c, shape: BoxShape.circle,
                  border: _penColor == c && !_isEraser
                      ? Border.all(color: _kOrange, width: 2.5)
                      : null),
              ),
            ),
        ]),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _isEraser = !_isEraser),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isEraser ? _kOrange.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isEraser ? _kOrange : Colors.grey.shade300)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              EraserIcon(isActive: _isEraser, size: 18),
              const SizedBox(width: 4),
              Text('지우개',
                style: TextStyle(fontSize: 11,
                  color: _isEraser ? _kOrange : AppColors.textSecondary)),
            ]),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() {
            _pageStrokes[_currentNotePageIndex]?.clear();
            _pageStrokes.remove(_currentNotePageIndex);
          }),
          child: const Text('전체 지우기',
            style: TextStyle(fontSize: 10, color: AppColors.textHint)),
        ),
      ]),
    );
  }

  Widget _buildMemoButton() {
    return GestureDetector(
      onTap: _showNoteInput,
      child: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6, offset: const Offset(-2, 0))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.note_add_outlined, size: 16, color: AppColors.textSecondary),
          const SizedBox(height: 2),
          const Text('메모\n추가',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8, height: 1.2,
              color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  void _showNoteInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      builder: (ctx) {
        final isLandscape = MediaQuery.of(ctx).orientation == Orientation.landscape;
        final memoLines = isLandscape ? 2 : 4;
        final hPad = isLandscape ? 16.0 : 20.0;
        final vPad = isLandscape ? 10.0 : 20.0;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: hPad, right: hPad, top: vPad),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            SizedBox(height: isLandscape ? 8 : 14),
            Row(children: [
              const Text('메모 추가',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
                child: Text(_formatTime(_currentTime),
                  style: const TextStyle(
                    fontSize: 11, color: _kOrange, fontWeight: FontWeight.w700)),
              ),
            ]),
            SizedBox(height: isLandscape ? 8 : 12),
            TextField(
              controller: _noteController,
              maxLines: memoLines, autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '강의 내용을 메모하세요...',
                hintStyle: const TextStyle(fontSize: 13),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: isLandscape ? 8 : 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kOrange, width: 2)),
              ),
            ),
            SizedBox(height: isLandscape ? 8 : 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(vertical: isLandscape ? 8 : 12)),
                onPressed: () async {
                  if (_noteController.text.trim().isNotEmpty) {
                    setState(() {
                      _savedNotes.add({
                        'time': _formatTime(_currentTime),
                        'text': _noteController.text.trim(),
                      });
                      _noteController.clear();
                    });
                    await _saveNotes();
                    if (mounted) Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('메모가 저장되었습니다'),
                          ]),
                          backgroundColor: _kOrange,
                          duration: Duration(seconds: 2)));
                    }
                  }
                },
                child: const Text('저장', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            SizedBox(height: isLandscape ? 8 : 16),
          ]),
        );
      },
    );
  }

  String _gradeLabel(String grade) {
    switch (grade) {
      case 'elementary': return '예비중';
      case 'middle': return '중등';
      case 'high': return '고등';
      default: return '전체';
    }
  }

  // ─────────────────────────────────────────────
  // 💬 탭2: 강의 Q&A
  // ─────────────────────────────────────────────
  Widget _buildQATab() {
    return Column(children: [
      // 질문 작성 버튼
      Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
        child: GestureDetector(
          onTap: _showQADialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEEEEEE))),
            child: Row(children: [
              const Icon(Icons.edit_rounded, size: 15, color: AppColors.textHint),
              const SizedBox(width: 8),
              const Text('강의에 대해 질문해 보세요...',
                style: TextStyle(fontSize: 13, color: AppColors.textHint)),
            ]),
          ),
        ),
      ),
      // Q&A 개수
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text('총 ${_qaList.length}개',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
            fontWeight: FontWeight.w600)),
      ),
      // Q&A 목록
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _qaList.length,
          separatorBuilder: (_, __) => const Divider(height: 20),
          itemBuilder: (_, i) {
            final qa = _qaList[i];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4)),
                  child: const Text('Q',
                    style: TextStyle(fontSize: 11, color: _kOrange,
                      fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(qa['q']!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary))),
                Text(qa['time']!,
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                const SizedBox(width: 8),
                // 삭제 버튼
                GestureDetector(
                  onTap: () {
                    // 삭제 확인 다이얼로그
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('질문 삭제'),
                        content: const Text('이 질문을 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _qaList.removeAt(i);
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('질문이 삭제되었습니다'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4)),
                    child: const Text('A',
                      style: TextStyle(fontSize: 11, color: AppColors.primary,
                        fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(qa['a']!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary,
                        height: 1.5))),
                ]),
              ),
            ]);
          },
        ),
      ),
    ]);
  }

  // 음성 인식 함수 (Web Speech API)
  void _startSpeechRecognition(TextEditingController ctrl, Function(bool) setListening, Function setState) {
    if (!kIsWeb) {
      // 웹이 아닌 경우 알림만 표시
      _showVoiceDialog('음성 인식은 웹 브라우저에서만 지원됩니다', Colors.red);
      return;
    }

    // 웹 전용 코드
    if (kIsWeb) {
      try {
        // Web Speech API 사용
        final recognition = WebSpeechAPI.createRecognition();
        
        // 한국어 설정
        recognition['lang'] = 'ko-KR';
        recognition['continuous'] = false;
        recognition['interimResults'] = false;
        recognition['maxAlternatives'] = 1;

        // 음성 인식 시작
        recognition.callMethod('start', []);
        
        setListening(true);
        
        // 음성 인식 시작 알림 (다이얼로그)
        _showVoiceDialog('🎤 말씀하세요...', _kOrange, autoClose: 5);

        // 결과 받기
        recognition['onresult'] = (event) {
          final results = event['results'];
          if (results != null && results.length > 0) {
            final result = results[results.length - 1];
            if (result['isFinal']) {
              final transcript = result[0]['transcript'];
              
              setState(() {
                // 기존 텍스트에 공백 추가 후 인식된 텍스트 추가
                if (ctrl.text.isNotEmpty) {
                  ctrl.text += ' ';
                }
                ctrl.text += transcript;
                setListening(false);
              });

              _showVoiceDialog('✅ 음성이 텍스트로 변환되었습니다', Colors.green, autoClose: 2);
            }
          }
        };

        // 오류 처리
        recognition['onerror'] = (event) {
          setState(() {
            setListening(false);
          });
          
          final error = event['error'];
          String message = '음성 인식 오류';
          IconData icon = Icons.error_outline;
          
          if (error == 'no-speech') {
            message = '음성이 감지되지 않았습니다.\n조용한 곳에서 다시 시도해주세요.';
            icon = Icons.hearing_disabled_rounded;
          } else if (error == 'audio-capture') {
            message = '마이크를 찾을 수 없습니다.\n마이크가 연결되어 있는지 확인해주세요.';
            icon = Icons.mic_off_rounded;
          } else if (error == 'not-allowed') {
            message = '마이크 권한이 필요합니다.\n\n브라우저 주소창 옆의 🔒 자물쇠 아이콘을 클릭하여\n마이크 권한을 허용해주세요.';
            icon = Icons.mic_none_rounded;
          }
          
          _showVoiceErrorDialog(message, icon);
        };

        // 종료 처리
        recognition['onend'] = () {
          setState(() {
            setListening(false);
          });
        };
        
      } catch (e) {
        setListening(false);
        _showVoiceErrorDialog(
          '음성 인식을 지원하지 않는 브라우저입니다.\n\nChrome, Safari, Edge 브라우저를 사용해주세요.',
          Icons.browser_not_supported_rounded,
        );
      }
    }
  }

  // 음성 알림 다이얼로그 (자동 닫힘)
  void _showVoiceDialog(String message, Color color, {int autoClose = 0}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        if (autoClose > 0) {
          Future.delayed(Duration(seconds: autoClose), () {
            if (Navigator.canPop(ctx)) {
              Navigator.pop(ctx);
            }
          });
        }
        
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.contains('🎤'))
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                if (message.contains('🎤')) const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 음성 오류 다이얼로그 (수동 닫기)
  void _showVoiceErrorDialog(String message, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text(
              '음성 인식 오류',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: _kOrange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              '확인',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showQADialog() {
    final ctrl = TextEditingController();
    bool isListening = false;
    bool hasText = false;
    
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 텍스트 변경 리스너
          ctrl.addListener(() {
            setDialogState(() {
              hasText = ctrl.text.trim().isNotEmpty;
            });
          });
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('질문하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 텍스트 입력 필드 + 음성 입력 버튼
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isListening ? _kOrange : Colors.grey.shade300,
                    width: isListening ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: ctrl,
                      maxLines: 4,
                      autofocus: true,
                      onChanged: (text) {
                        setDialogState(() {
                          hasText = text.trim().isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: '궁금한 내용을 입력하세요...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    // 하단 툴바 (음성 입력 버튼)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 음성 입력 버튼
                          InkWell(
                            onTap: () async {
                              if (!isListening) {
                                // 웹 환경 체크
                                if (kIsWeb) {
                                  // 권한 안내 다이얼로그 표시
                                  final shouldProceed = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => AlertDialog(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.mic, color: _kOrange, size: 24),
                                          SizedBox(width: 8),
                                          Text('마이크 권한 필요'),
                                        ],
                                      ),
                                      content: const Text(
                                        '음성 입력을 사용하려면 마이크 권한이 필요합니다.\n\n'
                                        '브라우저에서 마이크 권한 요청이 표시되면 "허용"을 눌러주세요.',
                                        style: TextStyle(fontSize: 14, height: 1.6),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('취소'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _kOrange,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldProceed == true) {
                                    // 권한 확인 후 음성 인식 시작
                                    _startSpeechRecognition(
                                      ctrl,
                                      (listening) {
                                        setDialogState(() {
                                          isListening = listening;
                                        });
                                      },
                                      setDialogState,
                                    );
                                  }
                                } else {
                                  // 모바일 환경: 바로 음성 인식 시작
                                  _startSpeechRecognition(
                                    ctrl,
                                    (listening) {
                                      setDialogState(() {
                                        isListening = listening;
                                      });
                                    },
                                    setDialogState,
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isListening 
                                    ? _kOrange.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                    size: 20,
                                    color: isListening ? _kOrange : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isListening ? '음성 인식 중...' : '음성 입력',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isListening ? _kOrange : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          // 글자 수 표시
                          Text(
                            '${ctrl.text.length} / 500',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 등록 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasText ? _kOrange : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: hasText ? () {
                    final question = ctrl.text.trim();
                    Navigator.pop(context);
                    
                    // 질문 추가 (실제로는 서버에 전송)
                    setState(() {
                      _qaList.insert(0, {
                        'q': question,
                        'a': '답변 대기 중입니다. 강사가 곧 답변해 드릴 예정입니다.',
                        'time': '방금 전',
                      });
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 질문이 등록되었습니다'),
                        backgroundColor: _kOrange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } : null,
                  child: Text(
                    hasText ? '질문 등록' : '내용을 입력하세요',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: hasText ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 📋 탭3: 재생 목록
  // ─────────────────────────────────────────────
  Widget _buildPlaylistTab() {
    final appState = context.watch<AppState>();
    final lectures = appState.getLecturesBySubject(widget.lecture.subject);
    if (lectures.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.playlist_play_rounded, size: 48,
            color: Colors.grey.shade300),
          const SizedBox(height: 8),
          const Text('재생 목록이 없습니다',
            style: TextStyle(color: AppColors.textHint, fontSize: 14)),
        ]),
      );
    }
    return Column(children: [
      // 총 개수
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.centerLeft,
        child: Text('총 ${lectures.length}개',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
            fontWeight: FontWeight.w600)),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: lectures.length,
          itemBuilder: (_, i) {
            final lec = lectures[i];
            final isCurrent = lec.id == widget.lecture.id;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
              decoration: BoxDecoration(
                color: isCurrent ? _kOrange.withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent ? _kOrange.withValues(alpha: 0.3) : Colors.transparent,
                  width: isCurrent ? 1.5 : 0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                leading: Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: _buildThumbSmall(lec)),
                  if (isCurrent)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(7)),
                        child: const Center(
                          child: Icon(Icons.play_arrow_rounded,
                            color: _kOrange, size: 22)),
                      ),
                    ),
                ]),
                title: Text(lec.title,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isCurrent ? _kOrange : AppColors.textPrimary),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 줄1: 시리즈명 (있을 때만)
                      if (lec.series.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(children: [
                            const Icon(Icons.playlist_play_rounded,
                              size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(lec.series,
                                style: const TextStyle(fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        ),
                      // 줄2: 학년 배지 + 과목 배지 + 강사명
                      Row(children: [
                        _buildMiniGradeBadge(lec.gradeText),
                        const SizedBox(width: 4),
                        _buildMiniSubjectBadge(lec.subject),
                        if (lec.gradeYear.isNotEmpty && lec.gradeYear != 'All') ...[
                          const SizedBox(width: 4),
                          _buildMiniChip(lec.gradeYear),
                        ],
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(lec.instructor,
                            style: const TextStyle(fontSize: 10.5,
                              color: AppColors.textSecondary),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(3)),
                          child: Text(lec.durationText,
                            style: const TextStyle(fontSize: 10, color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ],
                  ),
                ),
                onTap: isCurrent ? null : () {
                  // 재생목록 탭에서 강의 선택 → 자동재생 목록 유지
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LecturePlayerScreen(
                        lecture: lec,
                        autoPlayList: lectures,
                        autoPlayIndex: i,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── 재생목록/홈 카드용 미니 배지 헬퍼 ──────────────
  static Color _subjectBadgeColor(String subject) {
    switch (subject) {
      case '수학':     return const Color(0xFF2563EB);
      case '과학':     return const Color(0xFF16A34A);
      case '공통과학': return const Color(0xFF7C3AED);
      case '물리':     return const Color(0xFF0EA5E9);
      case '화학':     return const Color(0xFFFF6B35);
      case '생명과학': return const Color(0xFF22C55E);
      case '지구과학': return const Color(0xFF6366F1);
      case '국어':     return const Color(0xFFDC2626);
      case '영어':     return const Color(0xFF0891B2);
      default:         return const Color(0xFFF97316);
    }
  }

  static Color _gradeBadgeColor(String grade) {
    switch (grade) {
      case 'elementary': return const Color(0xFFFF6B35);
      case 'middle':     return const Color(0xFF059669);
      default:           return const Color(0xFF7C3AED);
    }
  }

  Widget _buildMiniSubjectBadge(String subject) {
    final color = _subjectBadgeColor(subject);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.7),
      ),
      child: Text(subject,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildMiniGradeBadge(String gradeText) {
    final color = gradeText.contains('고') ? const Color(0xFF7C3AED)
        : gradeText.contains('중') ? const Color(0xFF059669)
        : const Color(0xFFFF6B35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.7),
      ),
      child: Text(gradeText,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMiniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B),
            fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildThumbSmall(Lecture lec) {
    final url = lec.effectiveThumbnailUrl;
    Widget img;
    if (url != 'nas_default' && url.isNotEmpty) {
      img = Image.network(url, width: 72, height: 52, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbFallback(lec.subject));
    } else {
      img = _thumbFallback(lec.subject);
    }
    // 재생시간 배지를 우상단에 통일 표시
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        children: [
          img,
          Positioned(
            top: 4, right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                lec.durationText,
                style: const TextStyle(
                  color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback(String subject) {
    Color c;
    switch (subject) {
      case '수학': c = AppColors.math; break;
      case '과학': c = AppColors.science; break;
      case '공통과학': c = AppColors.commonScience; break;
      case '물리': c = AppColors.physics; break;
      case '화학': c = AppColors.chemistry; break;
      case '생명과학': c = AppColors.biology; break;
      case '지구과학': c = AppColors.earth; break;
      case '국어': c = AppColors.korean; break;
      case '영어': c = AppColors.english; break;
      default: c = _kOrange;
    }
    return Container(
      width: 72, height: 52,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7)),
      child: Icon(Icons.play_circle_outline_rounded,
        size: 24, color: c.withValues(alpha: 0.7)));
  }

  // ─────────────────────────────────────────────
  // 📝 탭4: 문제풀이
  // ─────────────────────────────────────────────
  Widget _buildProblemTab() {
    // 문제 생성 (최초 1회만)
    _problems ??= _generateProblems();

    if (_problems == null || _problems!.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          const Text('문제를 생성할 수 없습니다',
              style: TextStyle(color: AppColors.textHint, fontSize: 14)),
        ]),
      );
    }

    final problem = _problems![_currentProblemIndex];
    final isCorrect = _selectedAnswer == problem.correctAnswer;

    return Column(
      children: [
        // 진행 표시
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFFF8FAFC),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '문제 ${_currentProblemIndex + 1} / ${_problems!.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: problem.level == '기본'
                      ? Colors.green.withValues(alpha: 0.1)
                      : problem.level == '중급'
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  problem.level,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: problem.level == '기본'
                        ? Colors.green.shade700
                        : problem.level == '중급'
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 문제
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    problem.question,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 선택지
                ...List.generate(problem.options.length, (index) {
                  final isSelected = _selectedAnswer == index;
                  final showResult = _showExplanation;
                  final isCorrectOption = index == problem.correctAnswer;

                  Color borderColor = const Color(0xFFE2E8F0);
                  Color bgColor = Colors.white;

                  if (showResult) {
                    if (isCorrectOption) {
                      borderColor = Colors.green;
                      bgColor = Colors.green.withValues(alpha: 0.05);
                    } else if (isSelected && !isCorrect) {
                      borderColor = Colors.red;
                      bgColor = Colors.red.withValues(alpha: 0.05);
                    }
                  } else if (isSelected) {
                    borderColor = _kOrange;
                    bgColor = _kOrange.withValues(alpha: 0.05);
                  }

                  return GestureDetector(
                    onTap: _showExplanation
                        ? null
                        : () {
                            setState(() {
                              _selectedAnswer = index;
                            });
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: showResult && isCorrectOption
                                  ? Colors.green
                                  : showResult && isSelected && !isCorrect
                                      ? Colors.red
                                      : isSelected
                                          ? _kOrange
                                          : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected || (showResult && isCorrectOption)
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              problem.options[index],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (showResult && isCorrectOption)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                          if (showResult && isSelected && !isCorrect)
                            const Icon(Icons.cancel, color: Colors.red, size: 18),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // 채점 버튼 (정답 확인 전)
                if (!_showExplanation)
                  ElevatedButton(
                    onPressed: _selectedAnswer == null
                        ? null
                        : () {
                            setState(() {
                              _showExplanation = true;
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text(
                      '정답 확인',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                // 정답 확인 없이 문제 이동 버튼 (정답 확인 전)
                if (!_showExplanation && (_currentProblemIndex > 0 || _currentProblemIndex < _problems!.length - 1))
                  const SizedBox(height: 8),
                
                if (!_showExplanation)
                  Row(
                    children: [
                      // 이전 문제 (정답 확인 전)
                      if (_currentProblemIndex > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentProblemIndex--;
                                _selectedAnswer = null;
                                _showExplanation = false;
                              });
                            },
                            icon: const Icon(Icons.arrow_back_rounded, size: 14),
                            label: const Text('이전', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      if (_currentProblemIndex > 0 && _currentProblemIndex < _problems!.length - 1)
                        const SizedBox(width: 10),
                      // 다음 문제 (정답 확인 전)
                      if (_currentProblemIndex < _problems!.length - 1)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentProblemIndex++;
                                _selectedAnswer = null;
                                _showExplanation = false;
                              });
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                            label: const Text('다음', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                // 해설
                if (_showExplanation) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withValues(alpha: 0.05)
                          : Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCorrect ? '정답입니다!' : '오답입니다',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '해설',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          problem.explanation,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 이전/다음 문제 버튼
                  Row(
                    children: [
                      // 이전 문제 버튼
                      if (_currentProblemIndex > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentProblemIndex--;
                                _selectedAnswer = null;
                                _showExplanation = false;
                              });
                            },
                            icon: const Icon(Icons.arrow_back_rounded, size: 14),
                            label: const Text('이전 문제', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kOrange,
                              side: BorderSide(color: _kOrange, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (_currentProblemIndex > 0 && _currentProblemIndex < _problems!.length - 1)
                        const SizedBox(width: 8),
                      // 다음 문제 버튼
                      if (_currentProblemIndex < _problems!.length - 1)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentProblemIndex++;
                                _selectedAnswer = null;
                                _showExplanation = false;
                              });
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                            label: const Text('다음 문제', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      // 마지막 문제에서는 완료 메시지만
                      if (_currentProblemIndex == _problems!.length - 1)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green, width: 1.5),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  '모든 문제 완료',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 문제 은행에서 강의 ID 기반 문제 로드
  List<_ProblemData> _generateProblems() {
    final lectureId = widget.lecture.id;
    final problems = ProblemBank.getProblems(lectureId);
    if (problems.isNotEmpty) {
      return problems.map((p) => _ProblemData(
        question: p.question,
        options: p.options,
        correctAnswer: p.correctAnswer,
        explanation: p.explanation,
        level: p.level,
      )).toList();
    }

    // ProblemBank에 없는 강의는 빈 리스트 반환
    return [];

  }


  // ─────────────────────────────────────────────
  // ⚙️ 옵션 시트
  // ─────────────────────────────────────────────
  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,   // 키보드/시스템UI 겹침 방지
      useSafeArea: true,          // 안전영역 자동 처리
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // 드래그 핸들
              Container(width: 32, height: 3,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              // 타이틀 행
              Row(children: [
                const Text('옵션',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.black54),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              // 자막
              _buildOptionTile(
                icon: Icons.closed_caption_rounded,
                title: '자막 표시',
                trailing: _buildToggleSwitch(
                  value: _showSubtitle,
                  onTap: () {
                    setState(() => _showSubtitle = !_showSubtitle);
                    setS(() {});
                  },
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 2),
              // 재생속도 - 탭으로 속도 선택 시트 열기
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Future.microtask(() => _showSpeedSheet());
                },
                child: _buildOptionTile(
                  icon: Icons.speed_rounded,
                  title: '재생 속도',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _playbackSpeed == 1.0 ? '기본'
                              : _playbackSpeed == 0.5 ? '0.5x'
                              : _playbackSpeed == 0.75 ? '0.75x'
                              : _playbackSpeed == 1.25 ? '1.25x'
                              : _playbackSpeed == 1.5 ? '1.5x'
                              : '2.0x',
                          style: const TextStyle(
                            fontSize: 13, color: _kOrange,
                            fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                          size: 16, color: _kOrange),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 2),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch({required bool value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 26,
        decoration: BoxDecoration(
          color: value ? _kOrange : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(13)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 20, height: 20,
            decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)]),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return SizedBox(
      height: 44,
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
        const Spacer(),
        trailing,
      ]),
    );
  }

  // ── 재생속도 전용 시트
  void _showSpeedSheet() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final labels = ['0.5x', '0.75x', '기본', '1.25x', '1.5x', '2.0x'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // 시스템 네비게이션 바 위로 팝업 띄우기
      useRootNavigator: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          // 하단 시스템 바 높이만큼 추가 패딩
          final bottomPad = MediaQuery.of(ctx).viewPadding.bottom + 12;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // 드래그 핸들
              Container(width: 32, height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 10),
              // 제목
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('재생 속도',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
              const SizedBox(height: 10),
              // 버튼 2행
              ...List.generate(2, (row) {
                final rowSpeeds = speeds.sublist(row * 3, row * 3 + 3);
                final rowLabels = labels.sublist(row * 3, row * 3 + 3);
                return Padding(
                  padding: EdgeInsets.only(bottom: row == 0 ? 8 : 0),
                  child: Row(
                    children: List.generate(3, (col) {
                      final speed = rowSpeeds[col];
                      final label = rowLabels[col];
                      final selected = _playbackSpeed == speed;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: col > 0 ? 6 : 0),
                          child: GestureDetector(
                            onTap: () {
                              _setPlaybackSpeed(speed);
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: selected ? _kOrange : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                                border: selected
                                    ? null
                                    : Border.all(color: const Color(0xFFE8E8E8))),
                              child: Center(
                                child: Text(label,
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : AppColors.textPrimary)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ]),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 🌄 가로화면 + 사이드패널 모드
  // ─────────────────────────────────────────────
  Widget _buildLandscapeWithSidePanel() {
    final lec = widget.lecture;
    // 블랙아웃 방지: 가로화면에서 WebView를 직접 사용
    Widget videoWidget;
    if (!kIsWeb && _webViewController != null) {
      videoWidget = WebViewWidget(controller: _webViewController!);
    } else {
      videoWidget = _buildGradientPlaceholder();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // ── 왼쪽: 영상 + 진행바 + 강의안내 (LayoutBuilder로 비율 계산)
            Expanded(
              flex: 52,
              child: Container(
                color: Colors.white,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final totalH = constraints.maxHeight;
                    final totalW = constraints.maxWidth;
                    // 영상: 16:9 비율, 최대 높이 72%
                    final videoH = (totalW * 9 / 16).clamp(0.0, totalH * 0.72);

                    return Column(
                      children: [
                        // ① 영상
                        SizedBox(
                          width: totalW, height: videoH,
                          child: Stack(fit: StackFit.expand, children: [
                            videoWidget,
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: _showControls,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _onTapPlayer,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                            _buildControlOverlay(),
                            Positioned(
                              top: 6, right: 6,
                              child: _buildSpeedChip(onDark: true),
                            ),
                          ]),
                        ),
                        // ② 진행바
                        _buildProgressBar(),
                        // ② - 스크롤 힌트 문구 (가로화면)
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 13, color: Colors.grey[400]),
                              const SizedBox(width: 3),
                              Text(
                                '아래로 스크롤하여 강의 정보를 확인하세요',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 13, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                        // ③ 강의정보 (항상 표시 / 탭하면 세로모드로 전환하여 상세 탭 영역 확인)
                        Expanded(
                          child: Container(
                            color: const Color(0xFFF8F9FA),
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 강의 제목
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 7, 10, 3),
                                    child: Text(lec.title,
                                      style: const TextStyle(color: Color(0xFF1A1A2E),
                                          fontSize: 12, fontWeight: FontWeight.w700),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ),
                                  // 배지 + 강사
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                                    child: Row(children: [
                                      _buildLandscapeBadge(lec.gradeText),
                                      const SizedBox(width: 3),
                                      _buildLandscapeBadge(lec.subject),
                                      const SizedBox(width: 5),
                                      Expanded(child: Text(lec.instructor,
                                        style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
                                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    ]),
                                  ),
                                  // 시리즈 (있는 경우)
                                  if (lec.series.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                                      child: Row(children: [
                                        const Icon(Icons.list_rounded, color: Color(0xFF999999), size: 11),
                                        const SizedBox(width: 3),
                                        Expanded(child: Text(lec.series,
                                          style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
                                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ]),
                                    ),
                                  // 해시태그 (있는 경우)
                                  if (lec.hashtags.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                                      child: Wrap(
                                        spacing: 4,
                                        runSpacing: 3,
                                        children: lec.hashtags.map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF4FF),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFFC3D4F0), width: 0.8)),
                                          child: Text('#$tag', style: const TextStyle(
                                              color: Color(0xFF5E8ED6), fontSize: 9, fontWeight: FontWeight.w600)),
                                        )).toList(),
                                      ),
                                    ),
                                  const Divider(color: Color(0xFFEEEEEE), height: 1),
                                  // 하단 버튼 행: 세로화면 전환 버튼 + 전체화면 버튼
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                                    child: Row(
                                      children: [
                                        // ★ 세로화면 전환 버튼
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _toggleLandscapeMode,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color(0xFFCCCCCC), width: 1.0)),
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.stay_primary_portrait_rounded,
                                                    color: Color(0xFF444444), size: 14),
                                                  SizedBox(width: 5),
                                                  Text('세로화면',
                                                    style: TextStyle(
                                                      color: Color(0xFF333333),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    )),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // 전체화면 버튼
                                        GestureDetector(
                                          onTap: _toggleFullScreen,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _kOrange,
                                              borderRadius: BorderRadius.circular(8)),
                                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                                              SizedBox(width: 4),
                                              Text('전체화면', style: TextStyle(
                                                color: Colors.white, fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                            ]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // ── 오른쪽: 사이드 패널
            Expanded(
              flex: 48,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // 탭바 (균등 간격)
                    Container(
                      color: Colors.white,
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFEEEEEE), width: 1)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: _kOrange,
                        unselectedLabelColor: const Color(0xFF888888),
                        isScrollable: false,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        labelStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500),
                        indicatorColor: _kOrange,
                        indicatorWeight: 2.5,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(height: 36, child: Text('노트 보기', textAlign: TextAlign.center)),
                          Tab(height: 36, child: Text('강의 Q&A', textAlign: TextAlign.center)),
                          Tab(height: 36, child: Text('재생 목록', textAlign: TextAlign.center)),
                          Tab(height: 36, child: Text('문제풀이', textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    // 탭 컨텐츠
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildNoteTab(),
                          _buildQATab(),
                          _buildPlaylistTab(),
                          _buildProblemTab(),
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

  // 가로화면 강의 안내용 배지
  Widget _buildLandscapeBadge(String label) {
    Color color;
    switch (label) {
      case '수학':     color = const Color(0xFF2563EB); break;
      case '과학':     color = const Color(0xFF16A34A); break;
      case '공통과학': color = const Color(0xFF7C3AED); break;
      case '물리':     color = const Color(0xFF0EA5E9); break;
      case '화학':     color = const Color(0xFFFF6B35); break;
      case '생명과학': color = const Color(0xFF22C55E); break;
      case '지구과학': color = const Color(0xFF6366F1); break;
      case '국어':     color = const Color(0xFFDC2626); break;
      case '영어':     color = const Color(0xFF0891B2); break;
      default:          color = _kOrange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.7),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  // ─────────────────────────────────────────────
  // 📺 전체화면 모드
  // ─────────────────────────────────────────────
  Widget _buildFullScreenScaffold() {
    // 블랙아웃 방지: WebView를 직접 사용
    Widget videoWidget;
    if (!kIsWeb && _webViewController != null) {
      videoWidget = WebViewWidget(controller: _webViewController!);
    } else {
      videoWidget = _buildGradientPlaceholder();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
          // 영상 (전체화면)
          Positioned.fill(child: videoWidget),
          // 투명 터치 레이어: 컨트롤 숨겨진 상태에서 탭 → 컨트롤 표시
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _showControls, // 컨트롤 표시 중엔 overlay가 처리
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTapPlayer,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // 컨트롤 오버레이 (배경 그라데이션 + 중앙 play 버튼)
          _buildControlOverlay(),
          // 상단바·중앙컨트롤·하단바: _showControls에 따라 표시/숨김
          IgnorePointer(
            ignoring: !_showControls,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(children: [
            // 상단 바: 전체화면 종료 + 제목
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 32, 8, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent])),
                child: Row(children: [
                  // 세로화면 복귀
                  IconButton(
                    icon: const Icon(Icons.fullscreen_exit_rounded,
                      color: Colors.white, size: 26),
                    onPressed: _toggleFullScreen,
                    tooltip: '전체화면 종료',
                  ),
                  Expanded(
                    child: Text(widget.lecture.title,
                      style: const TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  // CC 버튼 제거 (모든 강의에 자막 있어 불필요)
                  // 속도 버튼 (전체화면)
                  _buildSpeedChip(onDark: true),
                  const SizedBox(width: 6),
                  // 가로화면+사이드패널로 전환
                  GestureDetector(
                    onTap: () {
                      // 전체화면 종료 후 가로화면+사이드패널로
                      setState(() {
                        _isFullScreen = false;
                        _isLandscape = true;
                      });
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white30, width: 0.8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.view_sidebar_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('사이드패널',
                          style: TextStyle(color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                  // 세로화면 복귀
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFullScreen = false;
                        _isLandscape = false;
                      });
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.portraitDown,
                      ]);
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white30, width: 0.8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.stay_current_portrait_rounded,
                          color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('세로화면',
                          style: TextStyle(color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
            // 중앙 재생 컨트롤
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSeekButton(Icons.replay_10_rounded, '-10', () => _seekRelative(-10)),
                  const SizedBox(width: 28),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        color: _kOrange, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: _kOrange.withValues(alpha: 0.4),
                          blurRadius: 16, spreadRadius: 2)]),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(width: 28),
                  _buildSeekButton(Icons.forward_10_rounded, '+10', () => _seekRelative(10)),
                ],
              ),
            ),
            // 하단 진행바
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent])),
                child: _buildProgressBar(),
              ),
            ),
          ]),
            ),
          ),
          if (_showSubtitle && _currentSubtitle.isNotEmpty)
            Positioned(
              bottom: 60, left: 24, right: 24,
              child: Center(child: _buildSubtitle()),
            ),
        ]),
    );
  }

  // ─────────────────────────────────────────────
  // 🪟 미니 플레이어 레이아웃
  // ─────────────────────────────────────────────
  Widget _buildMiniPlayerLayout() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        // 반투명 배경
        GestureDetector(
          onTap: _toggleMiniPlayer,
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),
        // 미니 플레이어 (하단)
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildMiniPlayerBar(),
        ),
      ]),
    );
  }

  Widget _buildMiniPlayerBar() {
    return Container(
      height: 70,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        // 썸네일
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 52, height: 40,
            child: _buildThumbSmall(widget.lecture),
          ),
        ),
        const SizedBox(width: 10),
        // 제목 + 강사
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.lecture.title,
                style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(widget.lecture.instructor,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
        // 재생/정지
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white, size: 26),
          onPressed: _togglePlay,
        ),
        // 닫기
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 필기 스트로크 모델
// ─────────────────────────────────────────────────────────────────────────────
class _DrawingStroke {
  final List<Offset?> points;
  final Color color;
  final double width;
  _DrawingStroke({required this.points, required this.color, required this.width});
}

// ─────────────────────────────────────────────────────────────────────────────
// 필기 CustomPainter
// ─────────────────────────────────────────────────────────────────────────────
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
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color.withValues(alpha: 0.85)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      bool started = false;
      for (final p in stroke.points) {
        if (p == null) { started = false; continue; }
        if (!started) { path.moveTo(p.dx, p.dy); started = true; }
        else path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
    if (currentStroke.isNotEmpty && !isEraser) {
      final paint = Paint()
        ..color = currentColor.withValues(alpha: 0.85)
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      bool started = false;
      for (final p in currentStroke) {
        if (p == null) { started = false; continue; }
        if (!started) { path.moveTo(p.dx, p.dy); started = true; }
        else path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 문제풀이 관련 클래스
// ─────────────────────────────────────────────────────────────────────────────
class _ProblemData {
  final String question;
  final List<String> options;
  final int correctAnswer; // 0-based index
  final String explanation;
  final String level; // '기본', '중급', '심화'

  _ProblemData({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.level,
  });
}

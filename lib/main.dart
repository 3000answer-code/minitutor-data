import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'services/app_state.dart';
import 'services/api_service.dart';
import 'services/translations.dart';
import 'theme/app_theme.dart';
import 'models/lecture.dart';
import 'screens/language/language_select_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/consultation/consultation_screen.dart';
import 'screens/instructor/instructor_screen.dart';
import 'screens/curriculum/curriculum_screen.dart';
import 'screens/profile/profile_drawer.dart';
import 'screens/storyboard/storyboard_viewer_screen.dart';
import 'screens/lecture/lecture_player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // NAS 터널 URL 동적 업데이트 (백그라운드)
  ApiService.fetchTunnelUrl();
  runApp(const App2Gong());
}

class App2Gong extends StatelessWidget {
  const App2Gong({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) => MaterialApp(
          title: 'miniTutor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const _AppRootScreen(),
        ),
      ),
    );
  }
}

/// 앱 루트: 초기화 → 언어선택 → 로그인 → 메인 순서로 화면 결정
class _AppRootScreen extends StatefulWidget {
  const _AppRootScreen();

  @override
  State<_AppRootScreen> createState() => _AppRootScreenState();
}

class _AppRootScreenState extends State<_AppRootScreen> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 세션 복원 (비동기)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 1. 아직 초기화 안됨 → 스플래시
    if (!appState.initialized) {
      return const _SplashScreen();
    }

    // 2. 언어 미선택 → 언어 선택 화면
    if (!appState.languageSelected) {
      return const LanguageSelectScreen();
    }

    // 3. 로그인 안됨 → 로그인 화면
    if (!appState.isLoggedIn) {
      return const LoginScreen();
    }

    // 4. 메인 화면
    return const MainShell();
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
          ),
        ),
        child: Stack(
          children: [
            // 배경 원형 장식
            Positioned(top: -80, right: -60,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(bottom: 60, left: -80,
              child: Container(
                width: 320, height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // 중앙 콘텐츠
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 앱 아이콘 (빛나는 효과)
                      Container(
                        width: 116, height: 116,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset('assets/icons/app_icon.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 브랜드명
                      const Text(
                        'miniTutor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '매일 2분, 쌓이는 실력',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 56),
                      SizedBox(
                        width: 28, height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white.withValues(alpha: 0.8),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 하단 버전 표시
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Text(
                'v3.60',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    ProgressScreen(),
    CurriculumScreen(),
    SearchScreen(),
    ConsultationScreen(),
    InstructorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isHome = appState.currentNavIndex == 0;

    // ─── 안드로이드 뒤로가기 버튼 처리 ───
    // 홈 탭이 아닌 경우 → 홈 탭으로 이동
    // 홈 탭인 경우 → 앱 종료 확인 다이얼로그
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (appState.currentNavIndex != 0) {
          // 홈 탭으로 이동 (로그아웃 없음!)
          appState.setNavIndex(0);
        } else {
          // 홈 탭에서 뒤로가기 → 앱 종료 확인
          final shouldExit = await _showExitDialog(context);
          if (shouldExit == true && context.mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: isHome ? _buildHomeAppBar(context) : null,
        endDrawer: const ProfileDrawer(),
        body: Stack(
          children: [
            IndexedStack(
              index: appState.currentNavIndex,
              children: _screens,
            ),
            // ── PIP 오버레이 ──
            if (appState.pipActive && appState.pipLecture != null)
              _PipOverlay(lecture: appState.pipLecture!),
          ],
        ),
        bottomNavigationBar: _buildBottomNavTranslated(context, appState),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('앱 종료', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  // ── 홈 AppBar ──
  PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    final appState = context.read<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(children: [
        // miniTutor 아이콘
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(T('app_name'),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text(T('app_slogan'),
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          tooltip: '강의 새로고침',
          onPressed: () async {
            final appState = context.read<AppState>();
            await appState.refreshApiLectures();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ 최신 강의 목록을 불러왔습니다'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.slideshow_rounded, color: AppColors.primary),
          tooltip: T('storyboard_tooltip'),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StoryboardViewerScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.textPrimary),
          tooltip: T('notification_tooltip'),
          onPressed: () => _showNotifications(context, lang),
        ),
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            tooltip: T('menu_tooltip'),
            onPressed: () => Scaffold.of(ctx).openEndDrawer(),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showNotifications(BuildContext context, String lang) {
    final T = (String key) => AppTranslations.tLang(lang, key);
    // 딤(dim) 처리로 배경 콘텐츠와 완전히 분리
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55), // 딤 처리
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          // 상단 padding 고정, 하단은 시스템 내비게이션 바 높이 + 24 확보
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들바
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text(T('notification_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('3', style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
              ]),
              const SizedBox(height: 4),
              const Divider(),
              const SizedBox(height: 8),
              _notifItem('🎉', T('notif_new_lecture'), '삼각함수 시리즈 3편이 업로드되었습니다.', '방금'),
              _notifItem('✅', T('notif_answer'), '이차방정식 질문에 답변이 달렸습니다.', '1시간 전'),
              _notifItem('🔥', T('notif_goal'), '오늘 학습 목표를 달성했어요!', '3시간 전'),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _notifItem(String emoji, String title, String body, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text(body,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ])),
        Text(time,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ]),
    );
  }

  Widget _buildBottomNavTranslated(BuildContext context, AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(children: [
            _buildNavItem(context, appState, 0, Icons.home_rounded,
                Icons.home_outlined, T('nav_home')),
            _buildNavItem(context, appState, 1, Icons.trending_up_rounded,
                Icons.trending_up_outlined, T('nav_progress')),
            _buildNavItem(context, appState, 2, Icons.auto_stories_rounded,
                Icons.auto_stories_outlined, T('nav_curriculum')),
            _buildNavItem(context, appState, 3, Icons.search_rounded,
                Icons.search_outlined, T('nav_search')),
            _buildNavItem(context, appState, 4, Icons.chat_bubble_rounded,
                Icons.chat_bubble_outline_rounded, T('nav_consultation')),
            _buildNavItem(context, appState, 5, Icons.school_rounded,
                Icons.school_outlined, T('nav_instructor')),
          ]),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, AppState appState, int index,
      IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = appState.currentNavIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => appState.setNavIndex(index),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 21,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color:
                    isSelected ? AppColors.primary : AppColors.textHint,
              )),
        ]),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PIP (Picture-in-Picture) 오버레이 위젯
//  - 강의 재생 중 해시태그 터치 → 검색화면 이동 시 표시
//  - 우하단에 드래그 가능한 미니 플레이어
//  - 터치 시 본 화면으로 복귀
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  PIP (Picture-in-Picture) 오버레이 위젯
//  ✅ YouTube: iframe embed + autoplay (muted → unmute)
//  ✅ Drive: uc?export=download 스트리밍 URL → <video> 태그
//  ✅ MP4/NAS: <video> 태그 직접 재생
//  ✅ 드래그 가능, 터치 시 본 화면 복귀
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PipOverlay extends StatefulWidget {
  final Lecture lecture;
  const _PipOverlay({required this.lecture});

  @override
  State<_PipOverlay> createState() => _PipOverlayState();
}

class _PipOverlayState extends State<_PipOverlay>
    with SingleTickerProviderStateMixin {
  double _right = 12;
  double _bottom = 88;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  WebViewController? _webCtrl;
  bool _webReady = false;
  bool _webError = false;
  bool _isPaused = false;      // PIP 일시정지 상태

  // ── YouTube ID 추출
  static String? _ytId(String url) {
    final m1 = RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (m1 != null) return m1.group(1);
    final m2 = RegExp(
            r'(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|v/))([a-zA-Z0-9_-]{11})')
        .firstMatch(url);
    if (m2 != null) return m2.group(1);
    return null;
  }

  // ── Drive ID 추출
  static String? _driveId(String url) {
    final patterns = [
      RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'drive\.google\.com/(?:open|uc)\?(?:.*&)?id=([a-zA-Z0-9_-]+)'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  // ━━ YouTube embed HTML (로고/브랜딩 완전 숨김) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  String _buildYoutubeHtml(String videoId, int startSec) => '''
<!DOCTYPE html><html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box;}
html,body{width:100%;height:100%;background:#000;overflow:hidden;}
#player{width:100%;height:100%;}
.ytp-watermark,.ytp-youtube-button,.ytp-share-button,.ytp-pause-overlay,
.ytp-gradient-top,.ytp-chrome-top,.ytp-show-cards-title,
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
function onYouTubeIframeAPIReady(){
  player=new YT.Player("player",{
    videoId:"$videoId",
    playerVars:{autoplay:1,mute:1,start:$startSec,controls:1,playsinline:1,rel:0,modestbranding:1,iv_load_policy:3},
    events:{
      onReady:function(e){
        e.target.playVideo();
        setTimeout(function(){
          try{player.unMute();player.setVolume(100);}catch(ex){}
        },1500);
      }
    }
  });
}
function playVid(){try{player.playVideo();}catch(e){}}
function pauseVid(){try{player.pauseVideo();}catch(e){}}
function seekTo(t){try{player.seekTo(t,true);}catch(e){}}
function setSpeed(s){try{player.setPlaybackRate(s);}catch(e){}}
</script>
</body></html>''';

  // ━━ Drive 스트림 비디오 HTML (PIP용 - uc?export=download 직접 재생) ━━━━━━━━━━━━━━━━━━
  // Drive /preview iframe 대신 직접 스트림 URL로 <video> 재생 (인증 불필요)
  String _buildDriveStreamHtml(String fileId, int startSec) {
    final streamUrl = 'https://drive.usercontent.google.com/download?id=$fileId&export=download&confirm=t';
    return '''
<!DOCTYPE html><html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box;}
html,body{width:100%;height:100%;background:#000;overflow:hidden;}
video{width:100%;height:100%;object-fit:contain;background:#000;}
#ld{position:absolute;inset:0;background:#000;display:flex;align-items:center;justify-content:center;z-index:5;}
#ld.h{display:none;}
.sp{width:24px;height:24px;border:2px solid #333;border-top:2px solid #F97316;border-radius:50%;animation:spin .8s linear infinite;}
@keyframes spin{to{transform:rotate(360deg);}}
</style>
</head>
<body>
<div id="ld"><div class="sp"></div></div>
<video id="v" playsinline autoplay preload="auto"></video>
<script>
(function(){
  var v=document.getElementById("v");
  var ld=document.getElementById("ld");
  var r=0;
  v.src="$streamUrl";
  v.onloadedmetadata=function(){
    if($startSec>0)v.currentTime=$startSec;
    if(window.FlutterBridge)FlutterBridge.postMessage("dur:"+v.duration.toFixed(0));
  };
  v.oncanplay=function(){ld.classList.add("h");v.play().catch(function(){});};
  v.onplaying=function(){
    ld.classList.add("h");
    if(window.FlutterBridge)FlutterBridge.postMessage("play");
  };
  v.onpause=function(){if(window.FlutterBridge)FlutterBridge.postMessage("pause");};
  v.onended=function(){if(window.FlutterBridge)FlutterBridge.postMessage("ended");};
  v.onwaiting=function(){ld.classList.remove("h");};
  v.onerror=function(){
    if(r<2){r++;setTimeout(function(){v.load();v.play().catch(function(){});},1200);}
    else{ld.classList.add("h");}
  };
  v.ontimeupdate=function(){
    if(window.FlutterBridge)FlutterBridge.postMessage("time:"+v.currentTime.toFixed(1));
  };
  v.load();
  v.play().catch(function(){});
})();
function playVid(){document.getElementById("v").play().catch(function(){});}
function pauseVid(){document.getElementById("v").pause();}
function seekTo(t){document.getElementById("v").currentTime=t;}
function setSpeed(s){document.getElementById("v").playbackRate=s;}
</script>
</body></html>''';
  }

  // ━━ MP4/NAS video HTML (<video> 태그 직접 재생) ━━━━━━━━
  String _buildVideoHtml(String videoUrl, int startSec) => '''
<!DOCTYPE html><html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
*{margin:0;padding:0;box-sizing:border-box;}
html,body{width:100%;height:100%;background:#000;overflow:hidden;}
video{width:100%;height:100%;object-fit:contain;background:#000;}
#load{display:flex;position:absolute;inset:0;background:#000;align-items:center;justify-content:center;z-index:5;}
#load.h{display:none;}
.sp{width:28px;height:28px;border:2.5px solid #333;border-top:2.5px solid #FF6B35;border-radius:50%;animation:spin .8s linear infinite;}
@keyframes spin{to{transform:rotate(360deg);}}
</style>
</head>
<body>
<div id="load"><div class="sp"></div></div>
<video id="v" playsinline autoplay preload="auto"></video>
<script>
(function(){
  var v=document.getElementById("v");
  var ld=document.getElementById("load");
  var retries=0;
  function tryPlay(){
    var p=v.play();
    if(p!==undefined){
      p.catch(function(e){
        if(retries<4){retries++;setTimeout(tryPlay,500);}
      });
    }
  }
  v.src="$videoUrl";
  v.onloadedmetadata=function(){
    if($startSec>0) v.currentTime=$startSec;
  };
  v.oncanplay=function(){
    ld.classList.add("h");
    tryPlay();
  };
  v.onplaying=function(){ld.classList.add("h");};
  v.onwaiting=function(){ld.classList.remove("h");};
  v.onerror=function(){
    ld.classList.add("h");
    if(retries<3){retries++;setTimeout(function(){v.load();tryPlay();},1000);}
  };
  v.onstalled=function(){
    if(retries<3){retries++;setTimeout(function(){v.load();tryPlay();},800);}
  };
  v.load();
  tryPlay();
})();
</script>
</body></html>''';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
    // WebView 초기화는 첫 frame 이후 실행
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWebView());
  }

  void _initWebView() {
    if (!mounted) return;
    final url = widget.lecture.videoUrl;
    if (url.isEmpty) return;

    final appState = context.read<AppState>();
    final startSec = appState.pipStartSeconds;

    final ytId = _ytId(url);
    final driveId = _driveId(url);

    String html;
    String baseUrl;

    if (ytId != null) {
      // YouTube: IFrame API (로고 숨김)
      html = _buildYoutubeHtml(ytId, startSec);
      baseUrl = 'https://www.youtube.com';
    } else if (driveId != null) {
      // Drive: uc?export=download 스트림으로 <video> 직접 재생
      // /preview iframe 방식 제거 - Android WebView에서 인증 요구로 재생 불가
      html = _buildDriveStreamHtml(driveId, startSec);
      baseUrl = 'https://drive.usercontent.google.com';
    } else {
      // MP4 / NAS 직접 재생
      html = _buildVideoHtml(url, startSec);
      baseUrl = url.startsWith('http') ? url : 'about:blank';
    }

    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..addJavaScriptChannel('FlutterBridge',
          onMessageReceived: (msg) => _onPipMessage(msg.message))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _webReady = false; _webError = false; });
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _webReady = true);
        },
        onWebResourceError: (err) {
          if (kDebugMode) debugPrint('PIP err[${err.errorCode}]: ${err.description}');
          if (mounted && err.isForMainFrame == true &&
              err.errorCode != -1 && err.errorCode != -2 &&
              err.errorCode != -6 && err.errorCode != -12) {
            setState(() => _webError = true);
          }
        },
      ))
      ..loadHtmlString(html, baseUrl: baseUrl);

    // ── Android 전용: 미디어 자동재생 허용 설정 (핵심!)
    if (ctrl.platform is AndroidWebViewController) {
      (ctrl.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    if (kDebugMode) {
      ctrl.setOnConsoleMessage(
          (m) => debugPrint('PIP console: ${m.message}'));
    }

    setState(() => _webCtrl = ctrl);
  }

  /// PIP WebView 메시지 수신 처리
  void _onPipMessage(String msg) {
    if (!mounted) return;
    if (msg == 'play') {
      setState(() => _isPaused = false);
    } else if (msg == 'pause') {
      setState(() => _isPaused = true);
    } else if (msg == 'ended') {
      setState(() => _isPaused = true);
    }
    // time:/dur: 메시지는 PIP에서 무시
  }

  // ── PIP 일시정지 / 재생 토글
  void _togglePause() {
    if (_webCtrl == null) return;
    if (_isPaused) {
      _webCtrl!.runJavaScript('try{playVid();}catch(e){}');
    } else {
      _webCtrl!.runJavaScript('try{pauseVid();}catch(e){}');
    }
    setState(() => _isPaused = !_isPaused);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _subjectColor(String s) {
    switch (s) {
      case '수학': return const Color(0xFF2563EB);
      case '과학': return const Color(0xFF16A34A);
      case '화학': return const Color(0xFF7C3AED);
      case '국어': return const Color(0xFFDC2626);
      case '영어': return const Color(0xFF0891B2);
      default:    return const Color(0xFFEA580C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final screenSize = MediaQuery.of(context).size;
    final subjectColor = _subjectColor(widget.lecture.subject);
    // PIP 크기: 폭 220, 영상 높이 124 (16:9 비율), 정보바 40
    const pipW = 220.0;
    const pipVideoH = 124.0;
    const pipInfoH = 40.0;

    // AppState에서 외부 일시정지 요청이 오면 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && appState.pipPaused && !_isPaused) {
        _togglePause();
      }
    });

    return Positioned(
      right: _right,
      bottom: _bottom,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          // 드래그 (단순 pan - onTap과 구분)
          onPanUpdate: (d) {
            setState(() {
              _right -= d.delta.dx;
              _bottom -= d.delta.dy;
              _right = _right.clamp(8.0, screenSize.width - pipW - 8);
              _bottom = _bottom.clamp(
                  80.0, screenSize.height - pipVideoH - pipInfoH - 80);
            });
          },
          child: Container(
            width: pipW,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                  color: subjectColor.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ━━━━━━━━━━━━━━━━━━━━━━━
                // ── 영상 영역
                // ━━━━━━━━━━━━━━━━━━━━━━━
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: SizedBox(
                    width: pipW,
                    height: pipVideoH,
                    child: Stack(fit: StackFit.expand, children: [

                      // ① WebView (영상) - Drive는 클리핑 오프셋 적용
                      if (_webCtrl != null && !_webError)
                        _buildPipVideoWidget()
                      else
                        _buildFallbackThumbnail(subjectColor),

                      // ② 로딩 스피너
                      if (_webCtrl != null && !_webReady && !_webError)
                        Container(
                          color: Colors.black87,
                          child: Center(
                            child: SizedBox(
                              width: 26, height: 26,
                              child: CircularProgressIndicator(
                                color: subjectColor, strokeWidth: 2.5),
                            ),
                          ),
                        ),

                      // ③ 일시정지 시 반투명 오버레이
                      if (_isPaused)
                        Container(color: Colors.black.withValues(alpha: 0.35)),

                      // ④ 중앙 일시정지/재생 버튼
                      Center(
                        child: GestureDetector(
                          onTap: _togglePause,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                  alpha: _isPaused ? 0.75 : 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                      // ⑤ 좌하단: 재생중 / 일시정지 뱃지
                      Positioned(
                        left: 6, bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: (_isPaused ? Colors.grey[700] : Colors.red)!
                                .withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPaused
                                    ? Icons.pause_circle_outline_rounded
                                    : Icons.fiber_manual_record,
                                color: Colors.white,
                                size: _isPaused ? 8 : 6,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _isPaused ? '일시정지' : '재생중',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ⑥ 우상단: 닫기 버튼
                      Positioned(
                        right: 4, top: 4,
                        child: GestureDetector(
                          onTap: () => appState.deactivatePip(),
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 13),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),

                // ━━━━━━━━━━━━━━━━━━━━━━━
                // ── 강의 정보 + 본 화면 이동
                // ━━━━━━━━━━━━━━━━━━━━━━━
                GestureDetector(
                  onTap: () {
                    // PIP → 본 화면 복귀: deactivate 후 push
                    // (Navigator stack 최상단에서 새로 열어야 기존 플레이어와 충돌 없음)
                    appState.deactivatePip();
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LecturePlayerScreen(lecture: widget.lecture),
                      ),
                    );
                  },
                  child: Container(
                    width: pipW,
                    height: pipInfoH,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      border: Border(
                        top: BorderSide(
                            color: subjectColor.withValues(alpha: 0.3),
                            width: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 과목 컬러 도트
                        Container(
                          width: 6, height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: subjectColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.lecture.title,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.lecture.instructor,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white.withValues(alpha: 0.6)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_full_rounded,
                            size: 12, color: subjectColor.withValues(alpha: 0.8)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ PIP 비디오 위젯 - Drive/YouTube/MP4 모두 일반 WebView로 처리
  // Drive를 스트림 방식으로 전환했으므로 iframe 클리핑 불필요
  Widget _buildPipVideoWidget() {
    if (_webCtrl == null) return const SizedBox.shrink();
    return WebViewWidget(controller: _webCtrl!);
  }

  Widget _buildFallbackThumbnail(Color subjectColor) {
    final thumb = widget.lecture.effectiveThumbnailUrl;
    return Stack(fit: StackFit.expand, children: [
      if (thumb.isNotEmpty && !thumb.contains('default'))
        Image.network(
          thumb,
          fit: BoxFit.contain,  // contain으로 원본 비율 유지
          errorBuilder: (_, __, ___) => _buildGradient(subjectColor),
        )
      else
        _buildGradient(subjectColor),
      Container(color: Colors.black.withValues(alpha: 0.25)),
      Center(
        child: Icon(Icons.play_circle_outline_rounded,
            color: subjectColor.withValues(alpha: 0.9), size: 36),
      ),
    ]);
  }

  Widget _buildGradient(Color c) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.withValues(alpha: 0.7),
              c.withValues(alpha: 0.3),
            ],
          ),
        ),
      );
}

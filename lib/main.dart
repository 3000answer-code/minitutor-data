import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/translations.dart';
import 'theme/app_theme.dart';
import 'screens/language/language_select_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/consultation/consultation_screen.dart';
import 'screens/instructor/instructor_screen.dart';
import 'screens/curriculum/curriculum_screen.dart';
import 'screens/profile/profile_drawer.dart';
import 'screens/storyboard/storyboard_viewer_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const App2Gong());
}

class App2Gong extends StatelessWidget {
  const App2Gong({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..loadApiLectures(),
      child: Consumer<AppState>(
        builder: (context, appState, _) => MaterialApp(
          title: '이공 - 2분공부',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: appState.languageSelected
              ? const MainShell()
              : const LanguageSelectScreen(),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── 홈 탭일 때만 AppBar 표시 (메뉴 버튼 포함) ──
      appBar: isHome ? _buildHomeAppBar(context) : null,
      endDrawer: const ProfileDrawer(),
      body: IndexedStack(
        index: appState.currentNavIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavTranslated(context, appState),
    );
  }

  // ── 홈 AppBar (MainShell Scaffold 직속 → endDrawer 접근 가능) ──
  PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    final lang = context.read<AppState>().selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(children: [
        // 이공 로고 박스
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Text(T('app_name'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
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
      // ── actions: MainShell Scaffold 직속이라 endDrawer 정상 접근 ──
      actions: [
        // 강의 새로고침 버튼 (어드민 등록 콘텐츠 즉시 반영)
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
        // ☰ 메뉴 버튼 — Scaffold.of(context)가 MainShell Scaffold를 정확히 찾음
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(T('notification_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _notifItem('🎉', T('notif_new_lecture'), '삼각함수 시리즈 3편이 업로드되었습니다.', '방금'),
          _notifItem('✅', T('notif_answer'), '이차방정식 질문에 답변이 달렸습니다.', '1시간 전'),
          _notifItem('🔥', T('notif_goal'), '오늘 학습 목표를 달성했어요!', '3시간 전'),
        ]),
      ),
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
                  fontSize: 12, color: AppColors.textSecondary)),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';
import '../notice/notice_screen.dart';
import '../profile/my_activity_screen.dart';
import '../profile/settings_screen.dart';
import '../profile/store_screen.dart';
// schedule_screen은 my_activity_screen 내 탭으로 통합 (v115)
// storyboard_viewer_screen 삭제됨 (v112)
import '../support/support_screen.dart';
import '../curriculum/curriculum_screen.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(children: [
          // ─── 프로필 헤더 (57p) ───
          _buildProfileHeader(context, appState),
          // ─── 메뉴 스크롤 영역 ───
          Expanded(
            child: Column(children: [
              // 나의 활동
              _buildMenuSection(T('my_activity'), [
                _MenuItem(Icons.history_rounded, T('recent_lectures'), () => _openMyActivity(context, 0)),
                _MenuItem(Icons.note_alt_outlined, T('my_notes'), () => _openMyActivity(context, 1)),
                _MenuItem(Icons.question_answer_outlined, T('my_qa'), () => _openMyActivity(context, 2)),
                _MenuItem(Icons.calendar_month_outlined, T('my_schedule'), () => _openMyActivity(context, 3)),
              ]),
              const Divider(height: 1),
              // 이용권 / 스토어
              _buildMenuSection(T('subscription'), [
                _MenuItem(Icons.stars_rounded, T('extend_period'), () => _openStore(context)),
              ]),
              const Divider(height: 1),
              // Asome Tutor
              _buildMenuSection(T('app_info'), [
                _MenuItem(Icons.info_outline_rounded, T('about_app'), () => _showAbout(context)),
                _MenuItem(Icons.campaign_outlined, T('notice'), () => _openNotice(context)),
                _MenuItem(Icons.support_agent_outlined, T('support'), () => _openSupport(context)),
              ]),
              const Divider(height: 1),
              // 설정
              _buildMenuSection(T('settings'), [
                _MenuItem(Icons.settings_outlined, T('app_settings'), () => _openSettings(context)),
                _MenuItem(Icons.description_outlined, T('terms'), () => _openLegalPage(context, '이용약관')),
                _MenuItem(Icons.privacy_tip_outlined, T('privacy'), () => _openLegalPage(context, '개인정보처리방침')),
              ]),
              // 앱 버전
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('버전 v1.0.0',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ),
            ]),
          ),
          // ─── 로그아웃 ───
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            title: Text(T('logout'), style: const TextStyle(fontSize: 14, color: AppColors.error)),
            dense: true,
            visualDensity: const VisualDensity(vertical: -2),
            onTap: () => _showLogoutDialog(context),
          ),
        ]),
      ),
    );
  }

  // ─── 프로필 헤더 (57p 스펙) ──────────────────────
  Widget _buildProfileHeader(BuildContext context, AppState appState) {
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // 프로필 사진 (기본 로고)
          Stack(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: NetworkImage(appState.profileImageUrl),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: () => _showEditProfile(context, appState),
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.camera_alt, size: 12, color: AppColors.primary),
                ),
              ),
            ),
          ]),
          const Spacer(),
          // 프로필 수정 버튼 (58p)
          TextButton(
            onPressed: () => _showEditProfile(context, appState),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(T('edit_profile'), style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 4),
          // X (닫기) 버튼
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // 닉네임
        Text(appState.nickname,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        // 이메일 / 회원 등급
        Row(children: [
          Text(appState.email,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10)),
            child: Text(appState.isPremium ? T('premium_label') : T('regular_label'),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        // 이용권 잔여 일수 + 사용 기간 연장 버튼 (57p)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.stars_rounded, color: Colors.amber[300], size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              appState.isPremium
                  ? '${T('subscription_label')} ${appState.remainingDays}${T('days_left')}'
                  : T('no_subscription'),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            )),
            GestureDetector(
              onTap: () => _openStore(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10)),
                child: Text(appState.isPremium ? T('extend_btn') : T('buy_btn'),
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Text(title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.textHint, letterSpacing: 0.5)),
      ),
      ...items.map((item) => ListTile(
        leading: Icon(item.icon, size: 20, color: AppColors.textSecondary),
        title: Text(item.label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        onTap: item.onTap,
      )),
    ]);
  }

  // ─── 네비게이션 메서드들 ────────────────────────────

  /// 공통: Drawer 닫기 + 화면 이동을 동시에 처리 (깜빡임 방지)
  void _navigateAndReopenDrawer(BuildContext context, Widget screen) {
    // Drawer 닫기 전에 먼저 화면을 push → 메인화면 깜빡임 없음
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) {
      // 하위 화면에서 돌아오면 Drawer가 이미 열려있으므로 별도 처리 불필요
      // (Drawer 위에 push하면 pop 시 Drawer가 그대로 보임)
    });
  }

  void _openMyActivity(BuildContext context, int tab) {
    _navigateAndReopenDrawer(context, MyActivityScreen(initialTab: tab));
  }


  void _openCurriculum(BuildContext context) {
    _navigateAndReopenDrawer(context, const CurriculumScreen());
  }

  void _openStore(BuildContext context) {
    _navigateAndReopenDrawer(context, const StoreScreen());
  }

  void _openNotice(BuildContext context) {
    _navigateAndReopenDrawer(context, const NoticeScreen());
  }

  void _openSupport(BuildContext context) {
    _navigateAndReopenDrawer(context, const SupportScreen());
  }

  void _openSettings(BuildContext context) {
    _navigateAndReopenDrawer(context, const SettingsScreen());
  }

  void _openLegalPage(BuildContext context, String title) {
    final content = title == '이용약관' ? _termsContent : _privacyContent;
    _navigateAndReopenDrawer(context, Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(content,
          style: const TextStyle(fontSize: 14, height: 1.8, color: AppColors.textSecondary)),
      ),
    ));
  }

  void _showAbout(BuildContext context) {
    // Drawer 위에 바로 Dialog 표시 (Drawer 닫지 않음)
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(8)),
            child: const Text('AT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          const Text('Asome Tutor란?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        content: const Text(
          'Asome Tutor는 합격을 향한 키워드 학습 플랫폼입니다.\n\n핵심 개념만 쏙쏙 담은 강의로 공부 부담을 줄이고, 매일 꾸준히 학습하는 습관을 만들어드립니다.\n\n국내 최고 강사진의 강의로 공부의 혁신을 경험하세요!',
          style: TextStyle(fontSize: 14, height: 1.7, color: AppColors.textSecondary),
        ),
        actions: [TextButton(
          onPressed: () => Navigator.pop(dialogCtx), // Dialog만 닫기 → Drawer로 복귀
          child: const Text('확인'),
        )],
      ),
    );
  }

  // ─── 프로필 수정 (전체 화면 페이지) ──────────────────────
  void _showEditProfile(BuildContext context, AppState appState) {
    _navigateAndReopenDrawer(context, _EditProfilePage(appState: appState));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  static const String _termsContent = '''제1조 (목적)
본 약관은 Asome Tutor 서비스 이용에 관한 권리, 의무 및 책임 사항을 규정합니다.

제2조 (정의)
"서비스"란 Asome Tutor가 제공하는 모든 온라인 교육 콘텐츠 및 관련 서비스를 의미합니다.

제3조 (서비스 이용)
모든 콘텐츠는 저작권법에 의해 보호되며 무단 복제·배포를 금지합니다.

제4조 (이용권 및 결제)
이용권은 결제일로부터 해당 기간 동안 유효합니다.

제5조 (면책 조항)
천재지변, 네트워크 장애 등 불가항력적 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다.

부칙: 본 약관은 2025년 1월 1일부터 시행됩니다.''';

  static const String _privacyContent = '''개인정보처리방침

1. 수집 항목: 이메일, 닉네임, 비밀번호 (필수), 프로필 사진, 학년, 과목 설정 (선택)

2. 수집 목적
- 서비스 제공 및 회원 관리
- 맞춤형 학습 콘텐츠 추천
- 이용권 결제 및 환불 처리

3. 보유 기간: 회원 탈퇴 시까지 (관련 법령에 따라 일부 보존)

4. 제3자 제공: 원칙적으로 외부 제공 없음 (법령 예외 제외)

5. 개인정보 보호책임자
- 이메일: privacy@2gong.com
- 전화: 02-1234-5678

본 방침은 2025년 1월 1일부터 시행됩니다.''';
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.onTap);
}

// ─── 프로필 수정 전체 화면 ────────────────────────
class _EditProfilePage extends StatefulWidget {
  final AppState appState;
  const _EditProfilePage({required this.appState});
  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  late TextEditingController _nickCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nickCtrl = TextEditingController(text: widget.appState.nickname);
    _emailCtrl = TextEditingController(text: widget.appState.email);
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('프로필 수정', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          // 프로필 사진
          Center(
            child: Stack(children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage(widget.appState.profileImageUrl),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 28),
          // ID (수정 불가)
          _buildLabel('ID'),
          const SizedBox(height: 6),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: widget.appState.email.split('@').first,
              helperText: '아이디는 변경할 수 없습니다',
              helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),
          // 닉네임
          _buildLabel('닉네임'),
          const SizedBox(height: 6),
          TextField(
            controller: _nickCtrl,
            decoration: InputDecoration(
              hintText: '닉네임을 입력하세요',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 18),
          // 이메일
          _buildLabel('이메일'),
          const SizedBox(height: 6),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: '이메일을 입력하세요',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 32),
          // 수정 완료 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.appState.updateProfile(nickname: _nickCtrl.text, email: _emailCtrl.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('프로필이 수정되었습니다!'),
                    behavior: SnackBarBehavior.floating,
                  ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('수정 완료', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary));
  }
}

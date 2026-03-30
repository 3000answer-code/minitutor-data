import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 기본 학년
  String _defaultGrade = '중학교 2학년';
  // 기본 과목
  String _defaultSubject = '수학';
  // 자막
  bool _subtitleOn = true;
  // 모바일 데이터
  bool _mobileDataAllowed = false;
  // 푸시 알림 항목별
  bool _pushNewLecture = true;
  bool _pushQAAnswer = true;
  bool _pushEvent = false;
  bool _pushSchedule = true;

  final List<String> _grades = [
    '모든 학년',
    '초등 1학년', '초등 2학년', '초등 3학년',
    '초등 4학년', '초등 5학년', '초등 6학년',
    '중학교 1학년', '중학교 2학년', '중학교 3학년',
    '고등학교 1학년', '고등학교 2학년', '고등학교 3학년',
  ];

  final List<String> _subjects = ['국어', '영어', '수학', '과학', '사회', '역사', '지리'];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.selectedLanguage;
    final T = (String key) => AppTranslations.tLang(lang, key);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(T('settings_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // ─── 기본 학습 설정 ───
          _buildSectionHeader('기본 학습 설정'),
          Container(
            color: Colors.white,
            child: Column(children: [
              _buildPickerTile(
                icon: Icons.school_outlined,
                title: '기본 학년',
                value: _defaultGrade,
                onTap: () => _showPicker('학년 선택', _grades, _defaultGrade,
                    (v) => setState(() => _defaultGrade = v)),
              ),
              const Divider(height: 1, indent: 56),
              _buildPickerTile(
                icon: Icons.menu_book_outlined,
                title: '기본 과목',
                value: _defaultSubject,
                onTap: () => _showPicker('과목 선택', _subjects, _defaultSubject,
                    (v) => setState(() => _defaultSubject = v)),
              ),
            ]),
          ),

          // ─── 재생 설정 ───
          _buildSectionHeader('재생 설정'),
          Container(
            color: Colors.white,
            child: Column(children: [
              SwitchListTile(
                value: _subtitleOn,
                onChanged: (v) => setState(() => _subtitleOn = v),
                secondary: const Icon(Icons.closed_caption_outlined, color: AppColors.textSecondary),
                title: const Text('자막 기본 표시', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('강의 재생 시 자막을 기본으로 표시합니다', style: TextStyle(fontSize: 12)),
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                value: _mobileDataAllowed,
                onChanged: (v) => setState(() => _mobileDataAllowed = v),
                secondary: const Icon(Icons.signal_cellular_alt, color: AppColors.textSecondary),
                title: const Text('모바일 데이터 허용', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Wi-Fi 미연결 시 경고 없이 재생합니다', style: TextStyle(fontSize: 12)),
                activeColor: AppColors.primary,
              ),
            ]),
          ),

          // ─── 알림 설정 ───
          _buildSectionHeader('알림 설정'),
          Container(
            color: Colors.white,
            child: Column(children: [
              SwitchListTile(
                value: _pushNewLecture,
                onChanged: (v) => setState(() => _pushNewLecture = v),
                secondary: const Icon(Icons.play_circle_outline, color: AppColors.textSecondary),
                title: const Text('새 강의 업로드 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                value: _pushQAAnswer,
                onChanged: (v) => setState(() => _pushQAAnswer = v),
                secondary: const Icon(Icons.question_answer_outlined, color: AppColors.textSecondary),
                title: const Text('Q&A 답변 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                value: _pushEvent,
                onChanged: (v) => setState(() => _pushEvent = v),
                secondary: const Icon(Icons.campaign_outlined, color: AppColors.textSecondary),
                title: const Text('이벤트/공지 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                activeColor: AppColors.primary,
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                value: _pushSchedule,
                onChanged: (v) => setState(() => _pushSchedule = v),
                secondary: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
                title: const Text('일정 알림', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                activeColor: AppColors.primary,
              ),
            ]),
          ),

          // ─── 앱 정보 ───
          _buildSectionHeader('앱 정보'),
          Container(
            color: Colors.white,
            child: Column(children: [
              _buildInfoTile(Icons.info_outline, '앱 버전', 'v1.0.0'),
              const Divider(height: 1, indent: 56),
              _buildLinkTile(Icons.description_outlined, '이용약관',
                  () => _openLegalPage(context, '이용약관', _termsContent)),
              const Divider(height: 1, indent: 56),
              _buildLinkTile(Icons.privacy_tip_outlined, '개인정보처리방침',
                  () => _openLegalPage(context, '개인정보처리방침', _privacyContent)),
            ]),
          ),

          // ─── 저장 버튼 ───
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('설정이 저장되었습니다')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('저장', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textHint, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon, required String title,
    required String value, required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
      ]),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    );
  }

  Widget _buildLinkTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
      onTap: onTap,
    );
  }

  void _showPicker(String title, List<String> items, String current, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView(children: items.map((item) => ListTile(
              title: Text(item, style: TextStyle(
                fontSize: 14,
                fontWeight: current == item ? FontWeight.w700 : FontWeight.w400,
                color: current == item ? AppColors.primary : AppColors.textPrimary,
              )),
              trailing: current == item
                  ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () { onSelect(item); Navigator.pop(context); },
            )).toList()),
          ),
        ]),
      ),
    );
  }

  void _openLegalPage(BuildContext context, String title, String content) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(content, style: const TextStyle(fontSize: 14, height: 1.8, color: AppColors.textSecondary)),
        ),
      ),
    ));
  }

  static const String _termsContent = '''
제1조 (목적)
본 약관은 이공(2분공부) 서비스(이하 "서비스")를 이용함에 있어 서비스 제공자와 이용자 간의 권리, 의무 및 책임 사항을 규정함을 목적으로 합니다.

제2조 (정의)
① "서비스"란 이공(2분공부)이 제공하는 모든 온라인 교육 콘텐츠 및 관련 서비스를 의미합니다.
② "이용자"란 본 약관에 따라 서비스를 이용하는 회원 및 비회원을 의미합니다.

제3조 (서비스 이용)
① 이용자는 본 약관 및 관련 법령을 준수하여야 합니다.
② 서비스의 모든 콘텐츠는 저작권법에 의해 보호됩니다.
③ 이용자는 서비스를 통해 제공되는 콘텐츠를 무단으로 복제, 배포할 수 없습니다.

제4조 (이용권 및 결제)
① 이용권은 결제일로부터 해당 기간 동안 유효합니다.
② 결제 완료 후 환불은 이용약관에 따라 처리됩니다.
③ 이용권 기간 내 서비스 이용이 불가한 경우 고객센터로 문의하시기 바랍니다.

제5조 (개인정보 보호)
이공(2분공부)은 관련 법령에 따라 이용자의 개인정보를 보호합니다.

제6조 (면책 조항)
이공(2분공부)은 천재지변, 네트워크 장애 등 불가항력적 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다.

부칙
본 약관은 2025년 1월 1일부터 시행됩니다.
''';

  static const String _privacyContent = '''
개인정보처리방침

이공(2분공부)은 이용자의 개인정보를 소중히 여기며, 개인정보 보호법 및 관련 법령을 준수합니다.

1. 수집하는 개인정보 항목
- 필수: 이메일, 닉네임, 비밀번호
- 선택: 프로필 사진, 학년, 과목 설정

2. 개인정보 수집 목적
- 서비스 제공 및 회원 관리
- 학습 콘텐츠 추천 및 맞춤형 서비스 제공
- 이용권 결제 및 환불 처리

3. 개인정보 보유 및 이용기간
- 회원 탈퇴 시까지 보유
- 단, 관련 법령에 따라 일정 기간 보관이 필요한 경우 해당 기간 동안 보존

4. 개인정보의 제3자 제공
이공(2분공부)은 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다.
단, 법령에 의거하거나 이용자의 동의가 있는 경우 제외됩니다.

5. 개인정보 보호책임자
- 이름: 개인정보 보호팀
- 이메일: privacy@2gong.com
- 전화: 02-1234-5678

6. 개인정보 처리방침 변경
본 방침은 2025년 1월 1일부터 시행됩니다.
변경 사항은 서비스 내 공지사항을 통해 안내드립니다.
''';
}

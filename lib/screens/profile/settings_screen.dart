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
  String _defaultGrade = '모든 학년';
  // 기본 과목
  String _defaultSubject = '모든 과목';
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
    '예비중',
    '중학교 1학년', '중학교 2학년', '중학교 3학년',
    '고등학교 1학년', '고등학교 2학년', '고등학교 3학년',
  ];

  final List<String> _subjects = ['모든 과목', '수학', '과학'];

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
              Divider(height: 1, indent: 52, color: Colors.grey.shade200),
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
              _buildCompactSwitchTile(
                icon: Icons.closed_caption_outlined,
                title: '자막 기본 표시',
                subtitle: '강의 재생 시 자막을 기본으로 표시합니다',
                value: _subtitleOn,
                onChanged: (v) => setState(() => _subtitleOn = v),
              ),
              Divider(height: 1, indent: 52, color: Colors.grey.shade200),
              _buildCompactSwitchTile(
                icon: Icons.signal_cellular_alt,
                title: '모바일 데이터 허용',
                subtitle: 'Wi-Fi 미연결 시 경고 없이 재생합니다',
                value: _mobileDataAllowed,
                onChanged: (v) => setState(() => _mobileDataAllowed = v),
              ),
            ]),
          ),

          // ─── 알림 설정 ───
          _buildSectionHeader('알림 설정'),
          Container(
            color: Colors.white,
            child: Column(children: [
              _buildCompactSwitchTile(
                icon: Icons.play_circle_outline,
                title: '새 강의 업로드 알림',
                value: _pushNewLecture,
                onChanged: (v) => setState(() => _pushNewLecture = v),
              ),
              Divider(height: 1, indent: 52, color: Colors.grey.shade200),
              _buildCompactSwitchTile(
                icon: Icons.question_answer_outlined,
                title: 'Q&A 답변 알림',
                value: _pushQAAnswer,
                onChanged: (v) => setState(() => _pushQAAnswer = v),
              ),
              Divider(height: 1, indent: 52, color: Colors.grey.shade200),
              _buildCompactSwitchTile(
                icon: Icons.campaign_outlined,
                title: '이벤트/공지 알림',
                value: _pushEvent,
                onChanged: (v) => setState(() => _pushEvent = v),
              ),
              Divider(height: 1, indent: 52, color: Colors.grey.shade200),
              _buildCompactSwitchTile(
                icon: Icons.calendar_today_outlined,
                title: '일정 알림',
                value: _pushSchedule,
                onChanged: (v) => setState(() => _pushSchedule = v),
              ),
            ]),
          ),

          // ─── 앱 정보 ───
          _buildSectionHeader('앱 정보'),
          Container(
            color: Colors.white,
            child: Column(children: [
              _buildInfoTile(Icons.info_outline, '앱 버전', 'v1.0.0'),
            ]),
          ),

          // ─── 저장 버튼 ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: SizedBox(
              width: double.infinity,
              height: 46,
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
                child: const Text('저장', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.textHint, letterSpacing: 0.3)),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon, required String title,
    required String value, required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        const SizedBox(width: 3),
        const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textHint),
      ]),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  Widget _buildCompactSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.2))
          : null,
      trailing: SizedBox(
        width: 40, height: 22,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }

  void _showPicker(String title, List<String> items, String current, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 3,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: ListView(children: items.map((item) => ListTile(
              title: Text(item, style: TextStyle(
                fontSize: 13,
                fontWeight: current == item ? FontWeight.w700 : FontWeight.w400,
                color: current == item ? AppColors.primary : AppColors.textPrimary,
              )),
              trailing: current == item
                  ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20) : null,
              dense: true,
              visualDensity: const VisualDensity(vertical: -1),
              onTap: () { onSelect(item); Navigator.pop(context); },
            )).toList()),
          ),
        ]),
      ),
    );
  }

}

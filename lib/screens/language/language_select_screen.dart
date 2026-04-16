import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedLang;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'ko',
      'name': '한국어',
      'native': '한국어',
      'flag': '🇰🇷',
      'color': const Color(0xFF003478),
    },
    {
      'code': 'en',
      'name': 'English',
      'native': 'English',
      'flag': '🇺🇸',
      'color': const Color(0xFF3C3B6E),
    },
    {
      'code': 'ja',
      'name': '日本語',
      'native': '日本語',
      'flag': '🇯🇵',
      'color': const Color(0xFFBC002D),
    },
    {
      'code': 'zh',
      'name': '中文',
      'native': '中文(简体)',
      'flag': '🇨🇳',
      'color': const Color(0xFFDE2910),
    },
    {
      'code': 'es',
      'name': 'Español',
      'native': 'Español',
      'flag': '🇪🇸',
      'color': const Color(0xFFC60B1E),
    },
  ];

  static const Map<String, Map<String, String>> _i18n = {
    'ko': {
      'title': 'Asome Tutor',
      'subtitle': '합격을 향한 키워드 학습',
      'desc': '언어를 선택하세요',
      'btn': '시작하기',
    },
    'en': {
      'title': 'Asome Tutor',
      'subtitle': 'Keyword Learning to Pass',
      'desc': 'Select your language',
      'btn': 'Get Started',
    },
    'ja': {
      'title': 'Asome Tutor',
      'subtitle': '合格へのキーワード学習',
      'desc': '言語を選択してください',
      'btn': 'はじめる',
    },
    'zh': {
      'title': 'Asome Tutor',
      'subtitle': '关键词学习到通过',
      'desc': '请选择语言',
      'btn': '开始',
    },
    'es': {
      'title': 'Asome Tutor',
      'subtitle': 'Aprendizaje Clave para Pasar',
      'desc': 'Selecciona tu idioma',
      'btn': 'Comenzar',
    },
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _t(String key) {
    final lang = _selectedLang ?? 'ko';
    return _i18n[lang]?[key] ?? _i18n['ko']![key]!;
  }

  void _onSelectLang(String code) {
    setState(() => _selectedLang = code);
    context.read<AppState>().setLanguage(code);
  }

  void _onStart() {
    if (_selectedLang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('desc')),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final appState = context.read<AppState>();
    appState.setLanguage(_selectedLang!);
    appState.setLanguageSelected(true);
    appState.refreshApiLectures();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f1b35), Color(0xFF162040), Color(0xFF1a2d5a)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  // ── 상단 여백
                  const Spacer(flex: 2),

                  // ── 그룹1: 로고 + 안내 문구
                  _buildLogo(),
                  const SizedBox(height: 16),
                  _buildDesc(),

                  // ── 그룹1~2 사이 여백
                  const Spacer(flex: 2),

                  // ── 그룹2: 언어 버튼 목록
                  _buildLangBtn(_languages[0], fullWidth: true),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _buildLangBtn(_languages[1])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildLangBtn(_languages[2])),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _buildLangBtn(_languages[3])),
                    const SizedBox(width: 10),
                    Expanded(child: _buildLangBtn(_languages[4])),
                  ]),

                  // ── 그룹2~3 사이 여백
                  const Spacer(flex: 2),

                  // ── 그룹3: 시작 버튼
                  _buildStartButton(),

                  // ── 하단 여백
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘 (작게)
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.cover,
              width: 64,
              height: 64,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('MT',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 앱 이름
        const Text(
          'Asome Tutor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        // 서브 태그 (선택된 언어에 따라 다국어 변경)
        Text(
          _t('subtitle'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildDesc() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        _t('desc'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _onStart,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: _selectedLang != null
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: _selectedLang == null
              ? Colors.white.withValues(alpha: 0.12)
              : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _selectedLang != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            _t('btn'),
            style: TextStyle(
              color: _selectedLang != null
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangBtn(Map<String, dynamic> lang, {bool fullWidth = false}) {
    final isSelected = _selectedLang == lang['code'];
    return GestureDetector(
      onTap: () => _onSelectLang(lang['code'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: fullWidth ? double.infinity : null,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? (lang['color'] as Color).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (lang['color'] as Color).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lang['flag'] as String,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 9),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang['native'] as String,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (lang['name'] != lang['native'])
                  Text(
                    lang['name'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

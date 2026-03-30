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

  // 언어별 UI 텍스트
  static const Map<String, Map<String, String>> _i18n = {
    'ko': {
      'title': '이공',
      'subtitle': '2분 공부',
      'desc': '언어를 선택하세요',
      'btn': '시작하기',
    },
    'en': {
      'title': '2GONG',
      'subtitle': '2-Minute Study',
      'desc': 'Select your language',
      'btn': 'Get Started',
    },
    'ja': {
      'title': '2ゴング',
      'subtitle': '2分学習',
      'desc': '言語を選択してください',
      'btn': 'はじめる',
    },
    'zh': {
      'title': '2功',
      'subtitle': '2分钟学习',
      'desc': '请选择语言',
      'btn': '开始',
    },
    'es': {
      'title': '2GONG',
      'subtitle': 'Estudio de 2 Minutos',
      'desc': 'Selecciona tu idioma',
      'btn': 'Comenzar',
    },
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
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
        ),
      );
      return;
    }
    context.read<AppState>().setLanguageSelected(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // 로고 영역
                _buildLogo(),
                const SizedBox(height: 40),
                // 언어 선택 안내
                Text(
                  _t('desc'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                // 언어 버튼 목록
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 첫 줄: 한국어 (전체 너비)
                        _buildLangBtn(_languages[0], fullWidth: true),
                        const SizedBox(height: 12),
                        // 두 번째 줄: 영어 + 일본어
                        Row(children: [
                          Expanded(child: _buildLangBtn(_languages[1])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildLangBtn(_languages[2])),
                        ]),
                        const SizedBox(height: 12),
                        // 세 번째 줄: 중국어 + 스페인어
                        Row(children: [
                          Expanded(child: _buildLangBtn(_languages[3])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildLangBtn(_languages[4])),
                        ]),
                      ],
                    ),
                  ),
                ),
                // 시작 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: GestureDetector(
                    onTap: _onStart,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: _selectedLang != null
                            ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight])
                            : null,
                        color: _selectedLang == null
                            ? Colors.white.withValues(alpha: 0.15)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _selectedLang != null
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
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
                                : Colors.white.withValues(alpha: 0.4),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
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

  Widget _buildLogo() {
    return Column(children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _t('title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        _t('subtitle'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    ]);
  }

  Widget _buildLangBtn(Map<String, dynamic> lang, {bool fullWidth = false}) {
    final isSelected = _selectedLang == lang['code'];
    return GestureDetector(
      onTap: () => _onSelectLang(lang['code'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: fullWidth ? double.infinity : null,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected
              ? (lang['color'] as Color).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (lang['color'] as Color).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(lang['flag'] as String, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang['native'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (lang['name'] != lang['native'])
                  Text(
                    lang['name'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

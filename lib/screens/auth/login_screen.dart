import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // 로그인 컨트롤러
  final _loginEmailCtrl = TextEditingController();
  final _loginPwCtrl = TextEditingController();
  bool _loginPwVisible = false;

  // 회원가입 컨트롤러
  final _signupNicknameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPwCtrl = TextEditingController();
  final _signupPwConfirmCtrl = TextEditingController();
  String _signupGrade = 'middle';
  bool _signupPwVisible = false;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPwCtrl.dispose();
    _signupNicknameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPwCtrl.dispose();
    _signupPwConfirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── 상단 헤더 ───
            _buildHeader(),
            // ─── 탭 바 ───
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: '로그인'),
                  Tab(text: '회원가입'),
                ],
              ),
            ),
            // ─── 탭 콘텐츠 ───
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildSignUpTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로고
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('MT',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1)),
          ),
          const SizedBox(height: 12),
          const Text('Asome Tutor',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('합격을 향한 키워드 학습',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  // ─── 로그인 탭 ───
  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        const Text('이메일', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _loginEmailCtrl,
          hint: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        const Text('비밀번호', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _loginPwCtrl,
          hint: '비밀번호 입력',
          obscure: !_loginPwVisible,
          icon: Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(_loginPwVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _loginPwVisible = !_loginPwVisible),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _doLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('로그인', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: RichText(
              text: const TextSpan(
                text: '계정이 없으신가요? ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                children: [
                  TextSpan(text: '회원가입', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── 회원가입 탭 ───
  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        const Text('닉네임', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupNicknameCtrl,
          hint: '공부왕 (2~10자)',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        const Text('이메일', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupEmailCtrl,
          hint: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        const Text('비밀번호 (6자 이상)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupPwCtrl,
          hint: '비밀번호 입력',
          obscure: !_signupPwVisible,
          icon: Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(_signupPwVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: () => setState(() => _signupPwVisible = !_signupPwVisible),
          ),
        ),
        const SizedBox(height: 14),
        const Text('비밀번호 확인', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _signupPwConfirmCtrl,
          hint: '비밀번호 재입력',
          obscure: true,
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 14),
        const Text('학년', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        _buildGradeSelector(),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _doSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('회원가입', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(0),
            child: RichText(
              text: const TextSpan(
                text: '이미 계정이 있으신가요? ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                children: [
                  TextSpan(text: '로그인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildGradeSelector() {
    final grades = [
      {'key': 'elementary', 'label': '예비중'},
      {'key': 'middle', 'label': '중등'},
      {'key': 'high', 'label': '고등'},
    ];
    return Row(children: grades.map((g) {
      final isSelected = _signupGrade == g['key'];
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _signupGrade = g['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade200,
                ),
              ),
              child: Center(
                child: Text(g['label']!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  )),
              ),
            ),
          ),
        ),
      );
    }).toList());
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    IconData? icon,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.textHint) : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // ─── 로그인 처리 ───
  Future<void> _doLogin() async {
    final email = _loginEmailCtrl.text.trim();
    final password = _loginPwCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('이메일과 비밀번호를 입력하세요.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.signIn(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // AppState에 로그인 상태 업데이트
      final appState = context.read<AppState>();
      await appState.onLoginSuccess(
        userId: result.userId!,
        nickname: result.nickname!,
        email: email,
        grade: result.grade ?? 'middle',
      );
    } else {
      _showSnack(result.message ?? '로그인 실패');
    }
  }

  // ─── 회원가입 처리 ───
  Future<void> _doSignUp() async {
    final nickname = _signupNicknameCtrl.text.trim();
    final email = _signupEmailCtrl.text.trim();
    final password = _signupPwCtrl.text;
    final passwordConfirm = _signupPwConfirmCtrl.text;

    if (password != passwordConfirm) {
      _showSnack('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.signUp(
      nickname: nickname,
      email: email,
      password: password,
      grade: _signupGrade,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final appState = context.read<AppState>();
      await appState.onLoginSuccess(
        userId: result.userId!,
        nickname: result.nickname!,
        email: email,
        grade: _signupGrade,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 환영합니다, ${result.nickname}님!'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      _showSnack(result.message ?? '회원가입 실패');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }
}

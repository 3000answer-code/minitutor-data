import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';

/// 로컬 계정 인증 서비스 (SharedPreferences 기반)
class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyNickname = 'nickname';
  static const String _keyEmail = 'email';
  static const String _keyGrade = 'grade';
  static const String _keyAccountsJson = 'accounts_json';
  static const String _keyStreakDays = 'streakDays';
  static const String _keyLastStudyDate = 'lastStudyDate';
  static const String _keyTotalStudyMinutes = 'totalStudyMinutes';
  static const String _keyTodayStudyMinutes = 'todayStudyMinutes';
  static const String _keyCompletedLectures = 'completedLectures';
  static const String _keyFavoriteIds = 'favoriteIds';
  static const String _keyRecentViewedIds = 'recentViewedIds';
  static const String _keyRecentSearches = 'recentSearches';

  // ─── 계정 관리 ───

  /// 회원가입 - 계정 생성
  Future<AuthResult> signUp({
    required String nickname,
    required String email,
    required String password,
    required String grade,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 이메일 중복 확인
      final accounts = _loadAccounts(prefs);
      final exists = accounts.any((a) => a['email'] == email.trim().toLowerCase());
      if (exists) {
        return AuthResult(success: false, message: '이미 사용중인 이메일입니다.');
      }

      // 유효성 검사
      if (nickname.trim().isEmpty) return AuthResult(success: false, message: '닉네임을 입력하세요.');
      if (email.trim().isEmpty || !email.contains('@')) return AuthResult(success: false, message: '올바른 이메일을 입력하세요.');
      if (password.length < 6) return AuthResult(success: false, message: '비밀번호는 6자 이상이어야 합니다.');

      // 계정 생성
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final newAccount = {
        'userId': userId,
        'nickname': nickname.trim(),
        'email': email.trim().toLowerCase(),
        'password': _hashPassword(password), // 간단 해시
        'grade': grade,
        'createdAt': DateTime.now().toIso8601String(),
      };
      accounts.add(newAccount);
      await _saveAccounts(prefs, accounts);

      // 자동 로그인
      await _saveSession(prefs, userId, nickname.trim(), email.trim().toLowerCase(), grade);

      if (kDebugMode) debugPrint('[AuthService] ✅ 회원가입 성공: $email');
      return AuthResult(success: true, userId: userId, nickname: nickname.trim());
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] ❌ 회원가입 오류: $e');
      return AuthResult(success: false, message: '오류가 발생했습니다. 다시 시도하세요.');
    }
  }

  /// 로그인
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = _loadAccounts(prefs);

      final account = accounts.firstWhere(
        (a) => a['email'] == email.trim().toLowerCase() && a['password'] == _hashPassword(password),
        orElse: () => {},
      );

      if (account.isEmpty) {
        return AuthResult(success: false, message: '이메일 또는 비밀번호가 올바르지 않습니다.');
      }

      final userId = account['userId'] as String;
      final nickname = account['nickname'] as String;
      final grade = account['grade'] as String? ?? 'middle';

      await _saveSession(prefs, userId, nickname, email.trim().toLowerCase(), grade);

      if (kDebugMode) debugPrint('[AuthService] ✅ 로그인 성공: $email');
      return AuthResult(success: true, userId: userId, nickname: nickname, grade: grade);
    } catch (e) {
      if (kDebugMode) debugPrint('[AuthService] ❌ 로그인 오류: $e');
      return AuthResult(success: false, message: '오류가 발생했습니다. 다시 시도하세요.');
    }
  }

  /// 로그아웃 (학습 데이터는 유지, 세션만 삭제)
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    if (kDebugMode) debugPrint('[AuthService] ✅ 로그아웃 완료');
  }

  /// 현재 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// 저장된 세션 정보 불러오기
  Future<UserSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!loggedIn) return null;

    return UserSession(
      userId: prefs.getString(_keyUserId) ?? '',
      nickname: prefs.getString(_keyNickname) ?? '공부왕',
      email: prefs.getString(_keyEmail) ?? '',
      grade: prefs.getString(_keyGrade) ?? 'middle',
    );
  }

  // ─── 학습 통계 저장/불러오기 ───

  Future<UserStats> loadStats(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';

    final lastStudyDate = prefs.getString('$prefix$_keyLastStudyDate');
    int streakDays = prefs.getInt('$prefix$_keyStreakDays') ?? 0;

    // 연속학습 일수 계산: 오늘 공부했는지 확인
    final today = _dateKey(DateTime.now());
    if (lastStudyDate != null && lastStudyDate == today) {
      // 오늘 공부함 - 스트릭 유지
    } else if (lastStudyDate != null) {
      final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
      if (lastStudyDate == yesterday) {
        // 어제 마지막으로 공부함 - 스트릭 유지
      } else {
        // 하루 이상 공백 - 스트릭 리셋
        streakDays = 0;
        await prefs.setInt('$prefix$_keyStreakDays', 0);
      }
    }

    return UserStats(
      streakDays: streakDays,
      totalStudyMinutes: prefs.getInt('$prefix$_keyTotalStudyMinutes') ?? 0,
      todayStudyMinutes: _getTodayStudyMinutes(prefs, prefix),
      completedLectures: prefs.getInt('$prefix$_keyCompletedLectures') ?? 0,
    );
  }

  int _getTodayStudyMinutes(SharedPreferences prefs, String prefix) {
    final today = _dateKey(DateTime.now());
    final savedDate = prefs.getString('${prefix}todayDate');
    if (savedDate == today) {
      return prefs.getInt('$prefix$_keyTodayStudyMinutes') ?? 0;
    }
    return 0; // 날짜가 다르면 0으로 초기화
  }

  Future<void> addStudyTime(String userId, {int minutes = 2}) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${userId}_';
    final today = _dateKey(DateTime.now());

    // 오늘 공부 시간 업데이트
    final savedDate = prefs.getString('${prefix}todayDate');
    int todayMinutes = 0;
    if (savedDate == today) {
      todayMinutes = prefs.getInt('$prefix$_keyTodayStudyMinutes') ?? 0;
    }
    await prefs.setString('${prefix}todayDate', today);
    await prefs.setInt('$prefix$_keyTodayStudyMinutes', todayMinutes + minutes);

    // 총 공부 시간 업데이트
    final total = prefs.getInt('$prefix$_keyTotalStudyMinutes') ?? 0;
    await prefs.setInt('$prefix$_keyTotalStudyMinutes', total + minutes);

    // 연속학습 업데이트
    final lastDate = prefs.getString('$prefix$_keyLastStudyDate');
    if (lastDate != today) {
      final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
      int streakDays = prefs.getInt('$prefix$_keyStreakDays') ?? 0;
      if (lastDate == yesterday) {
        streakDays++; // 연속
      } else if (lastDate == null) {
        streakDays = 1; // 첫 공부
      } else {
        streakDays = 1; // 리셋 후 오늘부터
      }
      await prefs.setInt('$prefix$_keyStreakDays', streakDays);
      await prefs.setString('$prefix$_keyLastStudyDate', today);
    }
  }

  Future<void> incrementCompletedLectures(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${userId}_$_keyCompletedLectures';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  // ─── 개별 강의 시청 진도 ───

  /// 특정 강의의 시청 진도(0.0~1.0)를 저장
  Future<void> saveLectureProgress(String userId, String lectureId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${userId}_lp_$lectureId';
    await prefs.setDouble(key, progress.clamp(0.0, 1.0));
    // 마지막 시청 시간도 저장
    await prefs.setString('${userId}_lp_date_$lectureId', _dateKey(DateTime.now()));
  }

  /// 특정 강의의 시청 진도(0.0~1.0)를 불러옴
  double getLectureProgress(SharedPreferences prefs, String userId, String lectureId) {
    return prefs.getDouble('${userId}_lp_$lectureId') ?? 0.0;
  }

  /// 특정 강의의 시청 진도를 비동기로 불러옴
  Future<double> loadLectureProgress(String userId, String lectureId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('${userId}_lp_$lectureId') ?? 0.0;
  }

  /// 강의가 완료되었는지 확인 (80% 이상 시청 시 완료로 간주)
  Future<bool> isLectureCompleted(String userId, String lectureId) async {
    final progress = await loadLectureProgress(userId, lectureId);
    return progress >= 0.8;
  }

  /// 유저의 모든 강의 진도 맵을 반환 { lectureId: progress }
  Future<Map<String, double>> loadAllLectureProgress(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final prefix = '${userId}_lp_';
    final result = <String, double>{};
    for (final key in allKeys) {
      if (key.startsWith(prefix) && !key.contains('_lp_date_')) {
        final lectureId = key.substring(prefix.length);
        result[lectureId] = prefs.getDouble(key) ?? 0.0;
      }
    }
    return result;
  }

  /// 완료된 강의 ID 목록 반환 (진도 80% 이상)
  Future<List<String>> loadCompletedLectureIds(String userId) async {
    final allProgress = await loadAllLectureProgress(userId);
    return allProgress.entries
        .where((e) => e.value >= 0.8)
        .map((e) => e.key)
        .toList();
  }

  // ─── 즐겨찾기 / 최근 본 강의 / 검색어 ───

  Future<List<String>> loadFavoriteIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${userId}_$_keyFavoriteIds') ?? [];
  }

  Future<void> saveFavoriteIds(String userId, List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${userId}_$_keyFavoriteIds', ids);
  }

  Future<List<String>> loadRecentViewedIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${userId}_$_keyRecentViewedIds') ?? [];
  }

  Future<void> saveRecentViewedIds(String userId, List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${userId}_$_keyRecentViewedIds', ids);
  }

  Future<List<String>> loadRecentSearches(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${userId}_$_keyRecentSearches') ?? [];
  }

  Future<void> saveRecentSearches(String userId, List<String> queries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${userId}_$_keyRecentSearches', queries);
  }

  // ─── Private 헬퍼 ───

  List<Map<String, dynamic>> _loadAccounts(SharedPreferences prefs) {
    final raw = prefs.getString(_keyAccountsJson);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAccounts(SharedPreferences prefs, List<Map<String, dynamic>> accounts) async {
    await prefs.setString(_keyAccountsJson, jsonEncode(accounts));
  }

  Future<void> _saveSession(SharedPreferences prefs, String userId, String nickname, String email, String grade) async {
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyNickname, nickname);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyGrade, grade);
  }

  String _hashPassword(String password) {
    // 간단한 해시 (실제 서비스에서는 bcrypt 등 사용 권장)
    int hash = 0;
    for (int i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash + password.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return 'h_${hash.abs()}_${password.length}';
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class AuthResult {
  final bool success;
  final String? message;
  final String? userId;
  final String? nickname;
  final String? grade;

  const AuthResult({
    required this.success,
    this.message,
    this.userId,
    this.nickname,
    this.grade,
  });
}

class UserSession {
  final String userId;
  final String nickname;
  final String email;
  final String grade;

  const UserSession({
    required this.userId,
    required this.nickname,
    required this.email,
    required this.grade,
  });
}

class UserStats {
  final int streakDays;
  final int totalStudyMinutes;
  final int todayStudyMinutes;
  final int completedLectures;

  const UserStats({
    required this.streakDays,
    required this.totalStudyMinutes,
    required this.todayStudyMinutes,
    required this.completedLectures,
  });
}

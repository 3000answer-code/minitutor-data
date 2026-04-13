import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lecture.dart';
import '../models/instructor.dart';
import '../models/consultation.dart';
import 'data_service.dart';
import 'api_service.dart';
import 'instructor_service.dart';
import 'translations.dart';
import 'auth_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // ─── 초기화 완료 여부 ───
  bool _initialized = false;
  bool get initialized => _initialized;

  // ─── API 강의 캐시 ───
  List<Lecture> _apiLectures = ApiService.getBundledLecturesDirect();
  bool _apiLoaded = true;

  // apiLectures: 외부 노출 시 NAS/MP4 영상 자동 제거
  List<Lecture> get apiLectures => _apiLectures.where((l) => !l.isNasVideo).toList();
  bool get apiLoaded => _apiLoaded;

  // ─── 로그인 상태 ───
  bool _isLoggedIn = false;
  String _userId = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;

  // ─── 사용자 정보 ───
  String _nickname = '';
  String _email = '';
  String _grade = 'middle'; // elementary, middle, high
  final String _profileImageUrl = 'https://picsum.photos/seed/myprofile/150/150';
  bool _isPremium = false;
  int _remainingDays = 0;

  // ─── 학습 통계 (실제 저장/불러오기) ───
  int _totalStudyMinutes = 0;
  int _todayStudyMinutes = 0;
  int _streakDays = 0;
  int _completedLectures = 0;
  int _searchCount = 0;  // 검색수
  int _totalWatchMinutes = 0;  // 시청 시간(분)
  int _todayViewedCount = 0;  // 오늘 재생한 영상 수(완료 여부 무관)

  // ─── 현재 선택 상태 ───
  int _currentNavIndex = 0;
  String _selectedSubject = '전체';

  String _homeTabIndex = 'recommend';
  String _progressSubject = '수학';
  String _progressGrade = 'middle';
  String _instructorGrade = 'middle';
  String _consultationSort = '최신순';
  // 사용자가 등록한 질문 목록 (추가/삭제 가능)
  final List<Consultation> _userConsultations = [];

  // ─── 언어 설정 ───
  String _selectedLanguage = 'ko';
  bool _languageSelected = false;

  // ─── 검색 ───
  String _searchQuery = '';
  List<String> _recentSearches = [];
  final List<String> _popularSearches = ['이차방정식', '세포분열', '뉴턴법칙', '삼각함수', '화학반응', '유전과진화', '지구구조', '미적분'];

  // ─── PIP (Picture-in-Picture) 상태 ───
  Lecture? _pipLecture;        // 현재 PIP로 재생 중인 강의
  bool _pipActive = false;     // PIP 활성화 여부
  int _pipStartSeconds = 0;    // PIP 시작 시간(초)
  bool _pipPaused = false;     // PIP 외부 일시정지 요청 (새 영상 재생시)

  Lecture? get pipLecture => _pipLecture;
  bool get pipActive => _pipActive;
  int get pipStartSeconds => _pipStartSeconds;
  bool get pipPaused => _pipPaused;

  void activatePip(Lecture lecture, {int startSeconds = 0}) {
    _pipLecture = lecture;
    _pipActive = true;
    _pipStartSeconds = startSeconds;
    _pipPaused = false;  // 새 PIP 활성화 시 재생 상태로
    notifyListeners();
  }

  /// 새 강의 재생 시 기존 PIP를 일시정지 상태로 알림
  void pausePipForNewLecture() {
    if (_pipActive) {
      _pipPaused = true;
      notifyListeners();
    }
  }

  void resumePip() {
    _pipPaused = false;
    notifyListeners();
  }

  void deactivatePip() {
    _pipLecture = null;
    _pipActive = false;
    _pipStartSeconds = 0;
    notifyListeners();
  }

  void switchPipLecture(Lecture lecture, {int startSeconds = 0}) {
    _pipLecture = lecture;
    _pipActive = true;
    _pipStartSeconds = startSeconds;
    notifyListeners();
  }

  // ─── 즐겨찾기 / 최근 본 강의 ───
  List<String> _favoriteIds = [];
  List<String> _recentViewedIds = [];

  // ─── Getters ───
  String get selectedLanguage => _selectedLanguage;
  bool get languageSelected => _languageSelected;
  // 레거시 브랜드명(2분공부/이공/2공) → miniTutor로 자동 변환
  String get nickname {
    if (!_isLoggedIn) return '게스트';
    const legacyNames = ['2분공부', '이공', '2공', '2GONG', 'Minute Mentor'];
    if (legacyNames.contains(_nickname.trim())) return 'miniTutor';
    return _nickname;
  }
  String get email => _email;
  String get grade => _grade;
  String get profileImageUrl => _profileImageUrl;
  bool get isPremium => _isPremium;
  int get remainingDays => _remainingDays;

  // ─── 어드민 여부 (이메일 기반) ───
  bool get isAdmin {
    const adminEmails = [
      'admin@minitutor.com',
      'admin@2gong.com',
      'master@minitutor.com',
      'superadmin@minitutor.com',
    ];
    return adminEmails.contains(_email.trim().toLowerCase());
  }
  int get totalStudyMinutes => _totalStudyMinutes;
  int get todayStudyMinutes => _todayStudyMinutes;
  int get streakDays => _streakDays;
  int get completedLectures => _completedLectures;
  int get searchCount => _searchCount;
  int get totalWatchMinutes => _totalWatchMinutes;
  int get todayViewedCount => _todayViewedCount;  // 오늘 재생한 영상 수
  int get currentNavIndex => _currentNavIndex;
  String get selectedSubject => _selectedSubject;
  String get homeTabIndex => _homeTabIndex;
  String get progressSubject => _progressSubject;
  String get progressGrade => _progressGrade;
  String get instructorGrade => _instructorGrade;
  String get consultationSort => _consultationSort;
  String get searchQuery => _searchQuery;
  List<String> get recentSearches => _recentSearches;
  List<String> get popularSearches => _popularSearches;
  List<String> get favoriteIds => _favoriteIds;
  List<String> get recentViewedIds => _recentViewedIds;

  // ─── 앱 시작 시 초기화 ───
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. 로그인 세션 확인
    final session = await _authService.getSession();
    if (session != null && session.userId.isNotEmpty) {
      _isLoggedIn = true;
      _userId = session.userId;
      _nickname = session.nickname;
      _email = session.email;
      _grade = session.grade;
      _progressGrade = session.grade;

      // 2. 저장된 학습 통계 불러오기
      final stats = await _authService.loadStats(session.userId);
      _streakDays = stats.streakDays;
      _totalStudyMinutes = stats.totalStudyMinutes;
      _todayStudyMinutes = stats.todayStudyMinutes;
      _completedLectures = stats.completedLectures;

      // 3. 즐겨찾기 / 최근 본 강의 / 검색어
      _favoriteIds = await _authService.loadFavoriteIds(session.userId);
      _recentViewedIds = await _authService.loadRecentViewedIds(session.userId);
      _recentSearches = await _authService.loadRecentSearches(session.userId);

      if (kDebugMode) debugPrint('[AppState] ✅ 세션 복원: ${session.nickname} (스트릭: $_streakDays일)');
    }

    _initialized = true;
    await _loadTodayViewedCount();  // 오늘 재생 영상 수 복원
    notifyListeners();
  }

  // ─── 로그인 성공 후 호출 ───
  Future<void> onLoginSuccess({
    required String userId,
    required String nickname,
    required String email,
    required String grade,
  }) async {
    _isLoggedIn = true;
    _userId = userId;
    _nickname = nickname;
    _email = email;
    _grade = grade;
    _progressGrade = grade;

    // 저장된 학습 통계 불러오기
    final stats = await _authService.loadStats(userId);
    _streakDays = stats.streakDays;
    _totalStudyMinutes = stats.totalStudyMinutes;
    _todayStudyMinutes = stats.todayStudyMinutes;
    _completedLectures = stats.completedLectures;

    // 즐겨찾기 / 최근 본 강의 / 검색어 불러오기
    _favoriteIds = await _authService.loadFavoriteIds(userId);
    _recentViewedIds = await _authService.loadRecentViewedIds(userId);
    _recentSearches = await _authService.loadRecentSearches(userId);

    notifyListeners();
    if (kDebugMode) debugPrint('[AppState] ✅ 로그인 완료: $nickname');
  }

  // ─── 로그아웃 ───
  Future<void> logout() async {
    await _authService.signOut();
    _isLoggedIn = false;
    _userId = '';
    _nickname = '';
    _email = '';
    _grade = 'middle';
    _streakDays = 0;
    _totalStudyMinutes = 0;
    _todayStudyMinutes = 0;
    _completedLectures = 0;
    _favoriteIds = [];
    _recentViewedIds = [];
    _recentSearches = [];
    _currentNavIndex = 0;
    notifyListeners();
    if (kDebugMode) debugPrint('[AppState] ✅ 로그아웃 완료');
  }

  // ─── API 강의 로드 ───
  Future<void> loadApiLectures() async {
    if (kDebugMode) debugPrint('[AppState] loadApiLectures 시작');

    final bundled = ApiService.getBundledLecturesDirect();
    final bundledIds = bundled.map((l) => l.id).toSet();

    try {
      _apiService.clearCache();
      final apiLectures = await _apiService.fetchLectures(forceRefresh: true);
      // 쇼츠 강의 제외 (lectureType == 'shorts')
      final apiOnly = apiLectures
          .where((l) => !bundledIds.contains(l.id) && l.lectureType != 'shorts')
          .toList();
      _apiLectures = [...bundled, ...apiOnly];
      _apiLoaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[AppState] ❌ 예외 발생: $e');
      _apiLectures = bundled;
      _apiLoaded = true;
      notifyListeners();
    }
  }

  Future<void> refreshApiLectures() async {
    await loadApiLectures();
  }

  Future<void> refreshLectures() async {
    await loadApiLectures();
  }

  // ─── 어드민: 강의 직접 추가 ───
  Future<void> addAdminLecture(Map<String, dynamic> lectureData) async {
    final lecture = ApiService.parseLectureFromMap(lectureData);
    // 중복 ID 체크
    final exists = _apiLectures.any((l) => l.id == lecture.id);
    if (!exists) {
      _apiLectures = [lecture, ..._apiLectures];
      notifyListeners();
    }
  }

  // ─── 강사 목록 동적 생성 ───────────────────────────────────────────────────
  /// 현재 로드된 강의 목록을 기반으로 강사 목록을 자동 생성합니다.
  /// 새 강의가 추가될 때마다 강사 카드가 자동으로 갱신됩니다.
  List<Instructor> get dynamicInstructors {
    return _dataService.getAllInstructors(lectures: _apiLectures);
  }

  /// 특정 강사의 강의 목록 (강의 제목 순 정렬)
  List<Lecture> getLecturesByInstructor(String instructorName) {
    return InstructorService().getLecturesByInstructor(_apiLectures, instructorName);
  }

  // ─── 강의 데이터 Getters ───
  // NAS/DNS 영상은 현재 비활성화 (당분간 YouTube 영상만 표시)
  // _validLectures: NAS/MP4 영상 제외한 재생 가능 강의 목록 (내부용)
  List<Lecture> get _validLectures =>
      _apiLectures.where((l) => !l.isNasVideo).toList();

  List<Lecture> get allLectures => _validLectures;

  List<Lecture> get recommendedLectures {
    final sorted = List<Lecture>.from(_validLectures)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(8).toList();
  }

  List<Lecture> get popularLectures {
    final sorted = List<Lecture>.from(_validLectures)
      ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sorted.take(10).toList();
  }

  List<Lecture> get favoriteLectures =>
      _validLectures.where((l) => _favoriteIds.contains(l.id)).toList();

  List<Lecture> get recentViewedLectures {
    final all = _validLectures;
    if (all.isEmpty) return [];
    return _recentViewedIds
        .map((id) {
          try {
            return all.firstWhere((l) => l.id == id);
          } catch (e) {
            // ID에 해당하는 강의가 없으면 null 반환
            return null;
          }
        })
        .where((l) => l != null)  // null 제거
        .cast<Lecture>()  // Lecture 타입으로 캐스팅
        .toList();
  }

  List<Lecture> getLecturesBySubject(String subject) {
    final valid = _validLectures;
    if (valid.isNotEmpty) {
      if (subject == '전체') return valid;
      // 두번설명 탭: lectureType == 'shorts' 인 강의 전체 (과목 무관)
      if (subject == 'shorts') {
        return valid.where((l) => l.lectureType == 'shorts').toList();
      }
      // 과학 탭: 중등 과학 + 공통과학 + 고등 세분화 과목(물리/화학/생명과학/지구과학) 전체 포함
      if (subject == '과학') {
        const scienceSubjects = ['과학', '공통과학', '물리', '화학', '생명과학', '지구과학'];
        return valid.where((l) => scienceSubjects.contains(l.subject)).toList();
      }
      // 수학 등 과목 탭: 해당 subject이면서 일반 강의 + 두번설명 모두 포함
      return valid.where((l) => l.subject == subject).toList();
    }
    return [];
  }

  /// 공백·언더스코어·하이픈을 제거한 뒤 소문자 비교
  /// 예) "장미_전쟁" == "장미전쟁" == "장미 전쟁"
  static String _normalizeQuery(String s) =>
      s.replaceAll(RegExp(r'[\s_\-]+'), '').toLowerCase();

  List<Lecture> searchLectures(String query) {
    final nq = _normalizeQuery(query);
    if (nq.isEmpty) return _validLectures;
    return _validLectures.where((l) {
      return _normalizeQuery(l.title).contains(nq) ||
          l.hashtags.any((h) => _normalizeQuery(h).contains(nq)) ||
          _normalizeQuery(l.instructor).contains(nq) ||
          _normalizeQuery(l.description).contains(nq);
    }).toList();
  }

  // ─── 번역 헬퍼 ───
  String tr(String key) => AppTranslations.tLang(_selectedLanguage, key);

  // ─── Actions ───
  void setLanguage(String langCode) {
    _selectedLanguage = langCode;
    notifyListeners();
  }

  void setLanguageSelected(bool value) {
    _languageSelected = value;
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  void setHomeTab(String tab) {
    _homeTabIndex = tab;
    notifyListeners();
  }

  Future<void> toggleFavorite(String lectureId) async {
    if (_favoriteIds.contains(lectureId)) {
      _favoriteIds.remove(lectureId);
    } else {
      _favoriteIds.add(lectureId);
    }
    notifyListeners();
    // 로그인 상태면 저장
    if (_isLoggedIn) {
      await _authService.saveFavoriteIds(_userId, _favoriteIds);
    }
  }

  bool isFavorite(String lectureId) => _favoriteIds.contains(lectureId);

  Future<void> addRecentView(String lectureId) async {
    _recentViewedIds.remove(lectureId);
    _recentViewedIds.insert(0, lectureId);
    if (_recentViewedIds.length > 20) _recentViewedIds.removeLast();

    // 학습 통계 업데이트
    _todayStudyMinutes += 2;
    _totalStudyMinutes += 2;
    _totalWatchMinutes += 2;  // 시청 시간 누적
    _completedLectures++;
    // 오늘 재생 영상 수 증가 (날짜 기준 당일 누적, 완료 여부 무관)
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastViewedDate = await _getLastViewedDate();
    if (lastViewedDate != todayStr) {
      _todayViewedCount = 1;  // 날짜 바뀌면 리셋 후 1
    } else {
      _todayViewedCount++;
    }
    await _saveLastViewedDate(todayStr);
    notifyListeners();

    // 로그인 상태면 저장
    if (_isLoggedIn) {
      await _authService.addStudyTime(_userId, minutes: 2);
      await _authService.incrementCompletedLectures(_userId);
      await _authService.saveRecentViewedIds(_userId, _recentViewedIds);

      // 통계 다시 불러와서 streakDays 업데이트
      final stats = await _authService.loadStats(_userId);
      _streakDays = stats.streakDays;
      _totalStudyMinutes = stats.totalStudyMinutes;
      _todayStudyMinutes = stats.todayStudyMinutes;
      _completedLectures = stats.completedLectures;
      notifyListeners();

      // NAS 진도 동기화 (백그라운드)
      syncProgressToNas();
    }
  }

  // ─── 오늘 재생 영상 수 날짜 추적 헬퍼 ───
  static const String _keyLastViewedDate = 'lastViewedDate';
  static const String _keyTodayViewedCount = 'todayViewedCount';

  Future<String?> _getLastViewedDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastViewedDate);
  }

  Future<void> _saveLastViewedDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastViewedDate, date);
    await prefs.setInt(_keyTodayViewedCount, _todayViewedCount);
  }

  Future<void> _loadTodayViewedCount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyLastViewedDate);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (saved == today) {
      _todayViewedCount = prefs.getInt(_keyTodayViewedCount) ?? 0;
    } else {
      _todayViewedCount = 0;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.isNotEmpty) {
      _searchCount++;  // 검색 시 조회수 증가
    }
    notifyListeners();
  }

  Future<void> addRecentSearch(String query) async {
    if (query.isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) _recentSearches.removeLast();
    notifyListeners();
    if (_isLoggedIn) {
      await _authService.saveRecentSearches(_userId, _recentSearches);
    }
  }

  // ─── 어드민 서버 URL (NAS 진도 동기화) ───
  static const String _adminBase = 'http://localhost:5061';

  /// 현재 유저의 진도 데이터를 NAS/어드민 서버에 업로드
  Future<void> syncProgressToNas() async {
    if (!_isLoggedIn || _userId.isEmpty) return;
    try {
      final progressMap = await _authService.loadAllLectureProgress(_userId);
      final stats = await _authService.loadStats(_userId);
      final recentViewedIds = await _authService.loadRecentViewedIds(_userId);

      final payload = {
        'userId': _userId,
        'nickname': _nickname,
        'email': _email,
        'grade': _grade,
        'streakDays': stats.streakDays,
        'totalStudyMinutes': stats.totalStudyMinutes,
        'todayStudyMinutes': stats.todayStudyMinutes,
        'completedLecturesCount': stats.completedLectures,
        'lastSync': DateTime.now().toIso8601String(),
        'lectureProgress': progressMap,
        'recentViewedIds': recentViewedIds,
      };

      final resp = await http.post(
        Uri.parse('$_adminBase/api/save-user-progress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('[AppState] NAS 진도 업로드: ${resp.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AppState] NAS 진도 업로드 실패: $e');
    }
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
    if (_isLoggedIn) {
      _authService.saveRecentSearches(_userId, []);
    }
  }

  void setProgressSubject(String subject) {
    _progressSubject = subject;
    notifyListeners();
  }

  void setProgressGrade(String grade) {
    _progressGrade = grade;
    notifyListeners();
  }

  void setInstructorGrade(String grade) {
    _instructorGrade = grade;
    notifyListeners();
  }

  void setConsultationSort(String sort) {
    _consultationSort = sort;
    notifyListeners();
  }

  Future<void> updateProfile({String? nickname, String? email, String? grade}) async {
    if (nickname != null) _nickname = nickname;
    if (email != null) _email = email;
    if (grade != null) {
      _grade = grade;
      _progressGrade = grade;
    }
    notifyListeners();
  }

  List<Consultation> get consultations {
    // 번들 샘플 데이터 + 사용자가 직접 등록한 질문 합산
    final all = [..._dataService.getConsultations(), ..._userConsultations];
    switch (_consultationSort) {
      case '답변완료순':
        return [...all]..sort((a, b) => b.isAnswered ? 1 : -1);
      case '조회순':
        return [...all]..sort((a, b) => b.viewCount.compareTo(a.viewCount));
      default:
        return [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  /// 새 질문 등록
  void addConsultation(Consultation c) {
    _userConsultations.add(c);
    notifyListeners();
  }

  /// 질문 삭제 (id 기준, 사용자 등록 질문만 삭제 가능)
  void deleteConsultation(String id) {
    _userConsultations.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// 해당 id가 사용자가 직접 등록한 질문인지 여부
  bool isMyConsultation(String id) =>
      _userConsultations.any((c) => c.id == id);
}

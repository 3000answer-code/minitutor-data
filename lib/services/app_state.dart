import 'package:flutter/foundation.dart';
import '../models/lecture.dart';
import '../models/consultation.dart';
import 'data_service.dart';
import 'api_service.dart';
import 'translations.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final ApiService _apiService = ApiService();

  // ─── API 강의 캐시 ───
  List<Lecture> _apiLectures = [];
  bool _apiLoaded = false;

  List<Lecture> get apiLectures => _apiLectures;
  bool get apiLoaded => _apiLoaded;

  /// 앱 시작 시 API 강의 로드
  Future<void> loadApiLectures() async {
    try {
      final lectures = await _apiService.fetchLectures();
      _apiLectures = lectures;
      _apiLoaded = true;
      notifyListeners();
      if (kDebugMode) debugPrint('[AppState] API 강의 ${lectures.length}개 로드');
    } catch (e) {
      if (kDebugMode) debugPrint('[AppState] API 로드 실패: $e');
      _apiLoaded = true;
      notifyListeners();
    }
  }

  /// API 강의 새로고침
  Future<void> refreshApiLectures() async {
    _apiService.clearCache();
    await loadApiLectures();
  }

  // ─── 사용자 정보 ───
  String _nickname = '공부왕';
  String _email = 'user@2gong.com';
  String _grade = 'middle'; // elementary, middle, high
  String _profileImageUrl = 'https://picsum.photos/seed/myprofile/150/150';
  bool _isPremium = true;
  int _remainingDays = 120;

  // ─── 학습 통계 ───
  int _totalStudyMinutes = 245;
  int _todayStudyMinutes = 18;
  int _streakDays = 7;
  int _completedLectures = 23;

  // ─── 현재 선택 상태 ───
  int _currentNavIndex = 0;
  String _selectedSubject = '전체';
  String _selectedGrade = ''; // filter
  String _homeTabIndex = 'recommend'; // recommend, popular, korean, english, math, science, social, other
  String _progressSubject = '수학';
  String _progressGrade = 'middle';
  String _instructorGrade = 'middle';
  String _consultationSort = '최신순';

  // ─── 언어 설정 ───
  String _selectedLanguage = 'ko';
  bool _languageSelected = false;

  // ─── 검색 ───
  String _searchQuery = '';
  List<String> _recentSearches = ['이차방정식', '현재완료', '세포분열', '삼권분립'];
  final List<String> _popularSearches = ['이차방정식', '관계대명사', '세포분열', '삼권분립', '뉴턴법칙', '현재완료', '시 표현기법', '분수덧셈'];

  // ─── 즐겨찾기 / 최근 본 강의 ───
  List<String> _favoriteIds = ['kor_001', 'eng_001', 'math_001', 'sci_002'];
  List<String> _recentViewedIds = ['math_001', 'eng_001', 'kor_002', 'sci_001', 'soc_001'];

  // ─── Getters ───
  String get selectedLanguage => _selectedLanguage;
  bool get languageSelected => _languageSelected;
  String get nickname => _nickname;
  String get email => _email;
  String get grade => _grade;
  String get profileImageUrl => _profileImageUrl;
  bool get isPremium => _isPremium;
  int get remainingDays => _remainingDays;
  int get totalStudyMinutes => _totalStudyMinutes;
  int get todayStudyMinutes => _todayStudyMinutes;
  int get streakDays => _streakDays;
  int get completedLectures => _completedLectures;
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

  // ─── 강의 데이터 Getters (API 우선, 없으면 로컬) ───
  List<Lecture> get allLectures =>
      _apiLectures.isNotEmpty ? _apiLectures : _dataService.getAllLectures();
  List<Lecture> get recommendedLectures {
    final all = allLectures;
    if (_apiLectures.isNotEmpty) {
      final sorted = List<Lecture>.from(all)..sort((a, b) => b.rating.compareTo(a.rating));
      return sorted.take(8).toList();
    }
    return _dataService.getRecommendedLectures();
  }
  List<Lecture> get popularLectures {
    final all = allLectures;
    if (_apiLectures.isNotEmpty) {
      final sorted = List<Lecture>.from(all)..sort((a, b) => b.viewCount.compareTo(a.viewCount));
      return sorted.take(10).toList();
    }
    return _dataService.getPopularLectures();
  }
  List<Lecture> get favoriteLectures =>
      allLectures.where((l) => _favoriteIds.contains(l.id)).toList();
  List<Lecture> get recentViewedLectures =>
      _recentViewedIds.map((id) => allLectures.firstWhere(
        (l) => l.id == id, orElse: () => allLectures.first)).toList();

  List<Lecture> getLecturesBySubject(String subject) {
    if (subject == '전체') return allLectures;
    return _dataService.getLecturesBySubject(subject);
  }

  List<Lecture> searchLectures(String query) {
    return _dataService.searchLectures(query, grade: _selectedGrade);
  }

  // ─── 번역 헬퍼 ───
  /// 현재 선택된 언어로 번역 반환
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

  void toggleFavorite(String lectureId) {
    if (_favoriteIds.contains(lectureId)) {
      _favoriteIds.remove(lectureId);
    } else {
      _favoriteIds.add(lectureId);
    }
    notifyListeners();
  }

  bool isFavorite(String lectureId) => _favoriteIds.contains(lectureId);

  void addRecentView(String lectureId) {
    _recentViewedIds.remove(lectureId);
    _recentViewedIds.insert(0, lectureId);
    if (_recentViewedIds.length > 20) _recentViewedIds.removeLast();
    _todayStudyMinutes += 2; // 2분 공부 추가
    _completedLectures++;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void addRecentSearch(String query) {
    if (query.isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) _recentSearches.removeLast();
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
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

  void updateProfile({String? nickname, String? email, String? grade}) {
    if (nickname != null) _nickname = nickname;
    if (email != null) _email = email;
    if (grade != null) _grade = grade;
    notifyListeners();
  }

  List<Consultation> get consultations {
    final all = _dataService.getConsultations();
    switch (_consultationSort) {
      case '답변완료순':
        return [...all]..sort((a, b) => b.isAnswered ? 1 : -1);
      case '조회순':
        return [...all]..sort((a, b) => b.viewCount.compareTo(a.viewCount));
      default:
        return [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }
}

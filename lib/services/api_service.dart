import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lecture.dart';

/// 2공 API 서버 연동 서비스
/// 어드민 웹에서 등록한 강의를 실시간으로 가져옵니다.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // API 서버 주소 목록 (순서대로 시도)
  // 1순위: 샌드박스 공개 URL, 2순위: localhost 직접 연결
  static const List<String> _candidateUrls = [
    'https://5062-i9igdqirkxrt7g1sztl0y-a402f90a.sandbox.novita.ai',
    'http://localhost:5062',
    'http://10.0.2.2:5062',  // Android 에뮬레이터 → 호스트 localhost
  ];

  String? _workingUrl;

  // 캐시 (앱 성능 최적화)
  List<Lecture>? _cachedLectures;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 1);

  bool get _isCacheValid =>
      _cachedLectures != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  /// 동작하는 API URL 탐색
  Future<String?> _resolveUrl() async {
    if (_workingUrl != null) {
      // 기존 URL 재확인 (빠른 체크)
      try {
        final res = await http
            .get(Uri.parse('$_workingUrl/api/health'))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) return _workingUrl;
      } catch (_) {}
      _workingUrl = null;
    }

    for (final url in _candidateUrls) {
      try {
        final res = await http
            .get(Uri.parse('$url/api/health'))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          _workingUrl = url;
          if (kDebugMode) debugPrint('[API] 서버 연결 성공: $url');
          return url;
        }
      } catch (_) {
        if (kDebugMode) debugPrint('[API] $url 연결 실패, 다음 시도...');
      }
    }
    return null;
  }

  /// 강의 목록 조회 (visible=Y 만)
  Future<List<Lecture>> fetchLectures({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedLectures!;
    }

    try {
      final baseUrl = await _resolveUrl();
      if (baseUrl == null) {
        if (kDebugMode) debugPrint('[API] 모든 서버 연결 실패');
        return _cachedLectures ?? [];
      }

      final uri = Uri.parse('$baseUrl/api/lectures?visible=Y');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        // API 응답 형식: {"success": true, "data": [...], "count": N}
        final rawList = body['data'] ?? body['lectures'] ?? [];
        final list = (rawList as List<dynamic>)
            .map((e) => _parseLecture(e as Map<String, dynamic>))
            .toList();
        _cachedLectures = list;
        _cacheTime = DateTime.now();
        if (kDebugMode) debugPrint('[API] 강의 ${list.length}개 로드 성공');
        return list;
      } else {
        throw Exception('서버 오류: ${res.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[API] 로드 실패: $e');
      return _cachedLectures ?? [];
    }
  }

  /// 캐시 강제 초기화
  void clearCache() {
    _cachedLectures = null;
    _cacheTime = null;
    _workingUrl = null;
  }

  /// JSON → Lecture 변환
  Lecture _parseLecture(Map<String, dynamic> d) {
    return Lecture(
      id: d['id'] as String? ?? '',
      title: d['title'] as String? ?? '',
      subject: d['subject'] as String? ?? '기타',
      grade: d['grade'] as String? ?? 'middle',
      instructor: d['instructor'] as String? ?? '',
      thumbnailUrl: d['thumbnailUrl'] as String? ?? '',
      videoUrl: d['videoUrl'] as String? ?? '',
      duration: (d['duration'] as num?)?.toInt() ?? 60,
      viewCount: (d['viewCount'] as num?)?.toInt() ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      lectureType: d['lectureType'] as String? ?? 'concept',
      hashtags: (d['hashtags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: d['description'] as String? ?? '',
      isFavorite: d['isFavorite'] as bool? ?? false,
      series: d['series'] as String? ?? '',
      lectureNumber: (d['lectureNumber'] as num?)?.toInt() ?? 1,
      uploadDate: d['uploadDate'] as String? ?? '',
      relatedLectureId: d['relatedLectureId'] as String? ?? '',
    );
  }
}

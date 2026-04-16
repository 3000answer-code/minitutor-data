import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lecture.dart';

/// Asome Tutor API 서버 연동 서비스
/// - 환경 설정은 lib/config.dart 에서 관리
/// - NAS ↔ AWS 전환: config.dart 의 currentEnv 만 변경하면 됨
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // 강의 데이터 URL (GitHub Raw → 어디서든 접근 가능, APK 재설치 없이 자동 업데이트)
  static const List<String> _adminUrls = [
    'https://raw.githubusercontent.com/3000answer-code/asometutor-data/main/lectures.json',
    'https://5061-i9igdqirkxrt7g1sztl0y-2e1b9533.sandbox.novita.ai/lectures.json',
    'http://10.0.2.2:5061/lectures.json',
  ];

  List<Lecture>? _cachedLectures;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(seconds: 30);

  bool get _isCacheValid =>
      _cachedLectures != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  // ─── 앱 내장 번들 강의 데이터 (구글 드라이브 전용) ───
  static List<Map<String, dynamic>> get _bundledLectures => [
    // ── 두번설명 강의 (구글 드라이브 - 16:9 일반 영상 형태) ──
    {
      'id': 'gd_twice_001',
      'title': '부분분수 (식, 분해)',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '최성빈, 최형규, 전요셉',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1ipuLgcGWsO93u5kRqxhEEImJi0rohwe0&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1ipuLgcGWsO93u5kRqxhEEImJi0rohwe0/view?usp=sharing',
      'duration': 176, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['부분분수식', '급수', '분해', '분리'],
      'description': '부분분수 식의 분해 방법을 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '다항식', 'lectureNumber': 1,
      'uploadDate': '2026-04-10', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/twice_001_p1.png',
        'assets/handouts/twice_001_p2.png',
        'assets/handouts/twice_001_p3.png',
        'assets/handouts/twice_001_p4.png',
        'assets/handouts/twice_001_p5.png',
      ],
    },
    {
      'id': 'gd_twice_002',
      'title': '원의 접선 (길이와 각)',
      'subject': '수학',
      'grade': 'middle',
      'gradeYear': 'All',
      'instructor': '김재은, 공병찬',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1QaMle-tbdB6fiUibJKzyVyzuYj-Uk9tP&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1QaMle-tbdB6fiUibJKzyVyzuYj-Uk9tP/view?usp=sharing',
      'duration': 177, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['접선', '원'],
      'description': '원의 접선의 길이와 각을 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '원의 성질', 'lectureNumber': 2,
      'uploadDate': '2026-04-13', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/twice_002_p1.png',
        'assets/handouts/twice_002_p2.png',
        'assets/handouts/twice_002_p3.png',
        'assets/handouts/twice_002_p4.png',
        'assets/handouts/twice_002_p5.png',
        'assets/handouts/twice_002_p6.png',
      ],
    },
    {
      'id': 'gd_twice_003',
      'title': '정적분의 치환적분',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '한성훈, 최성빈',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1qVKYmCRx7jhoZbaSlaPpnOpgABzooPSG&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1qVKYmCRx7jhoZbaSlaPpnOpgABzooPSG/view?usp=sharing',
      'duration': 168, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['정적분', '치환적분'],
      'description': '정적분의 치환적분을 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '미적분(적분법)', 'lectureNumber': 3,
      'uploadDate': '2026-04-13', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/twice_003_p1.png',
        'assets/handouts/twice_003_p2.png',
        'assets/handouts/twice_003_p3.png',
        'assets/handouts/twice_003_p4.png',
        'assets/handouts/twice_003_p5.png',
      ],
    },
    {
      'id': 'gd_twice_004',
      'title': '근의 분리(이차방정식)',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '김본, 최성빈, 전요셉',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1P2oGR3nVHvo5jb7WWSSgTkCP8mjvkAXA&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1P2oGR3nVHvo5jb7WWSSgTkCP8mjvkAXA/view?usp=sharing',
      'duration': 166, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['이차방정식', '판별식', '근의 분리'],
      'description': '이차방정식의 근의 분리를 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '방정식과 부등식', 'lectureNumber': 4,
      'uploadDate': '2026-04-14', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/twice_004_p1.png',
        'assets/handouts/twice_004_p2.png',
        'assets/handouts/twice_004_p3.png',
        'assets/handouts/twice_004_p4.png',
        'assets/handouts/twice_004_p5.png',
      ],
    },
    {
      'id': 'gd_twice_005',
      'title': '로그의 계산',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '한성훈, 최형규, 전요셉',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=19bL7iZPrz-iK_NFAg3ASoWLivoukCi3J&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/19bL7iZPrz-iK_NFAg3ASoWLivoukCi3J/view?usp=sharing',
      'duration': 167, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['로그', '로그의 성질'],
      'description': '로그의 계산을 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '지수함수와 로그함수', 'lectureNumber': 5,
      'uploadDate': '2026-04-14', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/twice_005_p1.png',
        'assets/handouts/twice_005_p2.png',
        'assets/handouts/twice_005_p3.png',
        'assets/handouts/twice_005_p4.png',
      ],
    },
    {
      'id': 'gd_twice_006',
      'title': '필요조건과 충분조건',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '한성훈, 김본, 전요셉',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1xKpWZBa230WQ-QYSjPgHmcQZaHF90nU4&sz=w480',
      'fallbackThumbnailUrl': 'assets/handouts/twice_006_p1.png',
      'videoUrl': 'https://drive.google.com/file/d/1xKpWZBa230WQ-QYSjPgHmcQZaHF90nU4/view?usp=sharing',
      'duration': 178, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['필요조건', '충분조건', '필요충분조건'],
      'description': '필요조건과 충분조건을 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '집합과 명제', 'lectureNumber': 6,
      'uploadDate': '2026-04-14', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/twice_006_p1.png',
        'assets/handouts/twice_006_p2.png',
        'assets/handouts/twice_006_p3.png',
        'assets/handouts/twice_006_p4.png',
        'assets/handouts/twice_006_p5.png',
      ],
    },
    {
      'id': 'gd_twice_007',
      'title': '나머지정리와 인수정리',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '김본, 전요셉',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1wJ3p_Zf_Uhuln_wrb9J3pPgWaD-LUldp&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1wJ3p_Zf_Uhuln_wrb9J3pPgWaD-LUldp/view?usp=sharing',
      'duration': 177, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['나머지정리', '인수정리', '다항식'],
      'description': '나머지정리와 인수정리를 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '다항식', 'lectureNumber': 7,
      'uploadDate': '2026-04-14', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/twice_007_p1.png',
        'assets/handouts/twice_007_p2.png',
        'assets/handouts/twice_007_p3.png',
        'assets/handouts/twice_007_p4.png',
      ],
    },
    {
      'id': 'gd_twice_008',
      'title': '조합을 이용한 도형의 개수',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '최성빈, 최형규',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1QzE1A28nP09FEONP73t6fId35BrYUNvG&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1QzE1A28nP09FEONP73t6fId35BrYUNvG/view?usp=sharing',
      'duration': 171, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['조합', '도형의 개수'],
      'description': '조합을 이용한 도형의 개수를 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '확률과 통계', 'lectureNumber': 8,
      'uploadDate': '2026-04-14', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/twice_008_p1.png',
        'assets/handouts/twice_008_p2.png',
        'assets/handouts/twice_008_p3.png',
        'assets/handouts/twice_008_p4.png',
        'assets/handouts/twice_008_p5.png',
      ],
    },
    {
      'id': 'gd_twice_009',
      'title': '검전기',
      'subject': '과학',
      'grade': 'middle',
      'gradeYear': 'All',
      'instructor': '김정아, 임지현',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1ncJPe3N9ZlExO4tyKQfkHlw2kdQRbssk&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1ncJPe3N9ZlExO4tyKQfkHlw2kdQRbssk/view?usp=sharing',
      'duration': 169, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['정전기유도', '검전기', '금속박'],
      'description': '검전기와 정전기 유도의 원리를 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '전기와 자기', 'lectureNumber': 9,
      'uploadDate': '2026-04-11', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/twice_009_p1.png',
        'assets/handouts/twice_009_p2.png',
        'assets/handouts/twice_009_p3.png',
        'assets/handouts/twice_009_p4.png',
        'assets/handouts/twice_009_p5.png',
        'assets/handouts/twice_009_p6.png',
        'assets/handouts/twice_009_p7.png',
      ],
    },
    {
      'id': 'gd_twice_010',
      'title': '지구의 크기 측정',
      'subject': '과학',
      'grade': 'middle',
      'gradeYear': 'All',
      'instructor': '김정아, 임지현',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1SxeunlPodLToddvK2XpE1G0HZvETTJW3&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1SxeunlPodLToddvK2XpE1G0HZvETTJW3/view?usp=sharing',
      'duration': 164, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'twice',
      'hashtags': ['에라토스테네스', '지구의 크기', '가정'],
      'description': '에라토스테네스의 방법으로 지구의 크기를 측정하는 원리를 두 번 설명으로 완벽하게 이해합니다.',
      'isFavorite': false, 'series': '태양계', 'lectureNumber': 10,
      'uploadDate': '2026-04-10', 'relatedLectureId': '',
      'handoutUrls': [
        'assets/handouts/earth_size_p1.png',
        'assets/handouts/earth_size_p2.png',
        'assets/handouts/earth_size_p3.png',
        'assets/handouts/earth_size_p4.png',
        'assets/handouts/earth_size_p5.png',
        'assets/handouts/earth_size_p6.png',
        'assets/handouts/earth_size_p7.png',
      ],
    },
    // ── 일반 강의 (구글 드라이브) ──
    {
      'id': 'gd_math_001',
      'title': '숫자, 수, 기수, 서수',
      'subject': '수학',
      'grade': 'middle',
      'gradeYear': 'All',
      'instructor': '김본',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1BviEeFspD4eh5GcbmgJGkyHZqGrs1q2B&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1BviEeFspD4eh5GcbmgJGkyHZqGrs1q2B/view?usp=sharing',
      'duration': 58, 'viewCount': 720, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['숫자', '기수', '서수', '수학', '예비중'],
      'description': '숫자, 수, 기수, 서수의 개념을 기초부터 이해합니다.',
      'isFavorite': false, 'series': '수학 기초', 'lectureNumber': 1,
      'uploadDate': '2026-04-05', 'relatedLectureId': 'gd_math_002',
      'handoutUrls': [
        'assets/handouts/math_num_001_p1.png',
        'assets/handouts/math_num_001_p2.png',
      ],
    },
    {
      'id': 'gd_math_002',
      'title': '자릿값, 수 읽기, 수 쓰기',
      'subject': '수학',
      'grade': 'middle',
      'gradeYear': 'All',
      'instructor': '김본',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1jffJNXMqiV8lheWiuKAmFf9zh3TP22_G&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1jffJNXMqiV8lheWiuKAmFf9zh3TP22_G/view?usp=sharing',
      'duration': 60, 'viewCount': 1890, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['자릿값', '수 읽기', '수 쓰기', '수학', '예비중'],
      'description': '자릿값, 수 읽기, 수 쓰기를 기초부터 이해합니다.',
      'isFavorite': false, 'series': '수학 기초', 'lectureNumber': 2,
      'uploadDate': '2026-04-05', 'relatedLectureId': 'gd_math_001',
      'handoutUrls': [
        'assets/handouts/math_place_001_p1.png',
        'assets/handouts/math_place_001_p2.png',
      ],
    },
    {
      'id': 'gd_math_003',
      'title': '지수함수의 뜻',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '한성훈',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1J6WirYDuav90c5tONxPgXaKGiAA4AVFN&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1J6WirYDuav90c5tONxPgXaKGiAA4AVFN/view?usp=sharing',
      'duration': 80, 'viewCount': 2100, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['지수', '지수함수', '수학', '고등'],
      'description': '고등 수학 - 지수함수의 뜻을 기초부터 이해합니다.',
      'isFavorite': false, 'series': '지수함수와 로그함수', 'lectureNumber': 1,
      'uploadDate': '2026-04-05', 'relatedLectureId': 'gd_math_004',
      'handoutUrls': [
        'assets/handouts/math_exp_001_p1.png',
        'assets/handouts/math_exp_001_p2.png',
      ],
    },
    {
      'id': 'gd_math_004',
      'title': 'y = aˣ 꼴',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '한성훈',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1k3P46GoawpHgqxVBQNQ12SpzRZKhxCMA&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1k3P46GoawpHgqxVBQNQ12SpzRZKhxCMA/view?usp=sharing',
      'duration': 80, 'viewCount': 1450, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['지수', '지수함수', '수학', '고등'],
      'description': '고등 수학 - y = aˣ 꼴 지수함수의 핵심 성질을 정리합니다.',
      'isFavorite': false, 'series': '지수함수와 로그함수', 'lectureNumber': 2,
      'uploadDate': '2026-04-05', 'relatedLectureId': 'gd_math_003',
      'handoutUrls': [
        'assets/handouts/math_exp_002_p1.png',
        'assets/handouts/math_exp_002_p2.png',
      ],
    },
    // ── 화학 강의 (고광윤 / 화학과 우리생활 시리즈) ──
    {
      'id': 'gd_chem_009',
      'title': '화학식량',
      'subject': '화학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '고광윤',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=13vwLh92F-7g1nxZSebLm6XhnX3JVHVo6&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/13vwLh92F-7g1nxZSebLm6XhnX3JVHVo6/view?usp=sharing',
      'duration': 300, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['원자량', '분자량', '실험식량', '탄소', '화학식량'],
      'description': '탄소 원자량을 기준으로 한 화학식량(원자량·분자량·실험식량) 개념을 정리합니다.',
      'isFavorite': false, 'series': '화학과 우리생활', 'lectureNumber': 9,
      'uploadDate': '2026-04-09', 'relatedLectureId': 'gd_chem_011',
      'handoutUrls': [
        'assets/handouts/chem_009_formula_mass_p1.png',
      ],
    },
    {
      'id': 'gd_chem_011',
      'title': '평균원자량',
      'subject': '화학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '고광윤',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1bAtGUVAKiBYLLMrJRPNNArlZ6A7_LUTh&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1bAtGUVAKiBYLLMrJRPNNArlZ6A7_LUTh/view?usp=sharing',
      'duration': 300, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['동위원소', '평균원자량', '양성자수', '중성자수', '질량수'],
      'description': '동위원소와 존재비율을 바탕으로 평균원자량을 계산하는 방법을 학습합니다.',
      'isFavorite': false, 'series': '화학과 우리생활', 'lectureNumber': 11,
      'uploadDate': '2026-04-09', 'relatedLectureId': 'gd_chem_015',
      'handoutUrls': [
        'assets/handouts/chem_011_avg_atomic_mass_p1.png',
      ],
    },
    {
      'id': 'gd_chem_015',
      'title': '몰(Mole)',
      'subject': '화학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '고광윤',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1OliDUBHe5aInnrGe0L8zpttpNIhTPhjg&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1OliDUBHe5aInnrGe0L8zpttpNIhTPhjg/view?usp=sharing',
      'duration': 300, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['몰', '몰질량', '아보가드로수', '탄소'],
      'description': '몰(mol) 개념과 몰질량, 아보가드로수의 관계를 이해합니다.',
      'isFavorite': false, 'series': '화학과 우리생활', 'lectureNumber': 15,
      'uploadDate': '2026-04-09', 'relatedLectureId': 'gd_chem_009',
      'handoutUrls': [
        'assets/handouts/chem_015_mole_p1.png',
      ],
    },
    // ── 구글 드라이브 강의 (다항식 시리즈) ──
    {
      'id': 'gd_math_poly_001',
      'title': '제곱 곱셈공식',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '김본',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=164NoYsOvEYp9bgu4tqBULg1gmVsHxasb&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/164NoYsOvEYp9bgu4tqBULg1gmVsHxasb/view?usp=sharing',
      'duration': 98, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['완전제곱', '곱셈공식', '제곱'],
      'description': '제곱 곱셈공식을 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '다항식', 'lectureNumber': 1,
      'uploadDate': '2026-04-14', 'relatedLectureId': 'gd_math_poly_002',
      'handoutUrls': [
        'assets/handouts/math_poly_001_p1.png',
        'assets/handouts/math_poly_001_p2.png',
      ],
    },
    {
      'id': 'gd_math_poly_002',
      'title': '세제곱 곱셈공식',
      'subject': '수학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '김본',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1a3CjoyhCSdgOvf_gv71TWS1uzfdiZSEj&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1a3CjoyhCSdgOvf_gv71TWS1uzfdiZSEj/view?usp=sharing',
      'duration': 106, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['곱셈공식', '제곱'],
      'description': '세제곱 곱셈공식을 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '다항식', 'lectureNumber': 2,
      'uploadDate': '2026-04-14', 'relatedLectureId': 'gd_math_poly_001',
      'handoutUrls': [
        'assets/handouts/math_poly_002_p1.png',
        'assets/handouts/math_poly_002_p2.png',
      ],
    },
    // ── 생명과학 강의 (유전 시리즈) ──
    {
      'id': 'gd_bio_001',
      'title': '독립의 법칙과 중간유전',
      'subject': '생명과학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '권용락',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1VpLVoxN9vYG0Ow5DrrVhuszQjacMfbSK&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1VpLVoxN9vYG0Ow5DrrVhuszQjacMfbSK/view?usp=sharing',
      'duration': 172, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['독립의 법칙', '중간유전', '우성', '유전자형', '표현형', '염색체'],
      'description': '독립의 법칙과 중간유전을 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '유전', 'lectureNumber': 1,
      'uploadDate': '2026-04-14', 'relatedLectureId': 'gd_bio_002',
      'handoutUrls': [
        'assets/handouts/bio_001_p1.png',
      ],
    },
    {
      'id': 'gd_bio_002',
      'title': '우열의 법칙의 예외(중간유전, 공동 우성)',
      'subject': '생명과학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '권용락',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1tjd3NyGgD3d02IKHHq69Tsr4f093m4jo&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1tjd3NyGgD3d02IKHHq69Tsr4f093m4jo/view?usp=sharing',
      'duration': 173, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['중간유전', '불완전 우성', '우열의 법칙', '공동 우성', 'ABO식 혈액형', '분꽃', '금어초'],
      'description': '우열의 법칙의 예외인 중간유전과 공동 우성을 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '유전', 'lectureNumber': 2,
      'uploadDate': '2026-04-14', 'relatedLectureId': 'gd_bio_003',
      'handoutUrls': [
        'assets/handouts/bio_002_p1.png',
      ],
    },
    {
      'id': 'gd_bio_003',
      'title': '염색체설과 유전자설',
      'subject': '생명과학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '권용락',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1wD2w_9B0WPmND4n4PVFsAXruIx050E7t&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1wD2w_9B0WPmND4n4PVFsAXruIx050E7t/view?usp=sharing',
      'duration': 169, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['염색체설', '유전자설', '서턴', '멘델', '대립 유전자', '상동 염색체', '모세포', '생식 세포', '수정란'],
      'description': '염색체설과 유전자설(서턴, 멘델)을 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '유전', 'lectureNumber': 3,
      'uploadDate': '2026-04-14', 'relatedLectureId': 'gd_bio_002',
      'handoutUrls': [
        'assets/handouts/bio_003_p1.png',
        'assets/handouts/bio_003_p2.png',
      ],
    },
    // ── 지구과학 강의 (지구의 역동성 시리즈) ──
    {
      'id': 'gd_earth_001',
      'title': '지진의 세기',
      'subject': '지구과학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '방정훈',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1Cg-KQBuKfY7pTxlEKsAorGuu5Ob7L8On&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1Cg-KQBuKfY7pTxlEKsAorGuu5Ob7L8On/view?usp=sharing',
      'duration': 164, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['지진', '리히터', '진도', '진앙'],
      'description': '지진의 세기(규모와 진도)를 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '지구의 역동성', 'lectureNumber': 1,
      'uploadDate': '2026-04-15', 'relatedLectureId': 'gd_earth_002',
      'handoutUrls': [
        'assets/handouts/earth_001_p1.png',
      ],
    },
    {
      'id': 'gd_earth_002',
      'title': '화산대 지진대 변동대',
      'subject': '지구과학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '방정훈',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=11VD-svk0g0p6KmIgUVcfA53G8ECXx-jR&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/11VD-svk0g0p6KmIgUVcfA53G8ECXx-jR/view?usp=sharing',
      'duration': 163, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['환태평양지진대', '화산대', '지진대', '변동대', '해령', '해구'],
      'description': '화산대·지진대·변동대의 분포와 특징을 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '지구의 변동', 'lectureNumber': 2,
      'uploadDate': '2026-04-15', 'relatedLectureId': 'gd_earth_003',
      'handoutUrls': [
        'assets/handouts/earth_002_p1.png',
        'assets/handouts/earth_002_p2.png',
      ],
    },
    {
      'id': 'gd_earth_003',
      'title': '화산 활동의 형태',
      'subject': '지구과학',
      'grade': 'high',
      'gradeYear': 'All',
      'instructor': '방정훈',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1BVSlrpzRZVOiQJdzp4YixTu26kLphbpc&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1BVSlrpzRZVOiQJdzp4YixTu26kLphbpc/view?usp=sharing',
      'duration': 175, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['용암', '순상화산', '성층화산', '종상화산', '규산', '현무암', '안산암', '유문암'],
      'description': '화산 활동의 형태(순상·성층·종상 화산)를 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '마그마의 생성', 'lectureNumber': 3,
      'uploadDate': '2026-04-15', 'relatedLectureId': 'gd_earth_002',
      'handoutUrls': [
        'assets/handouts/earth_003_p1.png',
      ],
    },
    // ── 이차방정식의 풀이 시리즈 (중등 수학) ──
    {
      'id': 'gd_math_quad_001',
      'title': '이차방정식의 해',
      'subject': '수학',
      'grade': 'middle',
      'gradeYear': 'All',
      'instructor': '김재은',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1HfK4CaRx1Zw4HriiyqXzpD9Drpz3VPnu&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1HfK4CaRx1Zw4HriiyqXzpD9Drpz3VPnu/view?usp=sharing',
      'duration': 149, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['이차방정식', '근', '해'],
      'description': '이차방정식의 해(근)의 개념을 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '이차방정식의 풀이', 'lectureNumber': 1,
      'uploadDate': '2026-04-16', 'relatedLectureId': 'gd_math_quad_002',
      'handoutUrls': [
        'assets/handouts/math_quad_001_p1.png',
      ],
    },
    {
      'id': 'gd_math_quad_002',
      'title': '이차방정식의 중근',
      'subject': '수학',
      'grade': 'middle',
      'gradeYear': 'All',
      'instructor': '김재은',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1xS5O4FWMuo6vYksctra99G3GJlgBCQyK&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1xS5O4FWMuo6vYksctra99G3GJlgBCQyK/view?usp=sharing',
      'duration': 168, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['이차방정식', '중근', '완전제곱식'],
      'description': '이차방정식의 중근 개념과 중근을 가질 조건을 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '이차방정식의 풀이', 'lectureNumber': 2,
      'uploadDate': '2026-04-16', 'relatedLectureId': 'gd_math_quad_003',
      'handoutUrls': [
        'assets/handouts/math_quad_002_p1.png',
        'assets/handouts/math_quad_002_p2.png',
      ],
    },
    {
      'id': 'gd_math_quad_003',
      'title': '제곱근을 이용한 이차방정식의 풀이',
      'subject': '수학',
      'grade': 'middle',
      'gradeYear': 'All',
      'instructor': '김재은',
      'thumbnailUrl': 'https://drive.google.com/thumbnail?id=1a9KhzdMXsz2SQK1oSiQEV7QrC32U1gOg&sz=w480',
      'videoUrl': 'https://drive.google.com/file/d/1a9KhzdMXsz2SQK1oSiQEV7QrC32U1gOg/view?usp=sharing',
      'duration': 170, 'viewCount': 0, 'rating': 0.0, 'ratingCount': 0,
      'lectureType': 'concept',
      'hashtags': ['이차방정식', '중근', '완전제곱식', '제곱근', '음수의 제곱근'],
      'description': '제곱근을 이용한 이차방정식 풀이 방법을 핵심만 빠르게 이해합니다.',
      'isFavorite': false, 'series': '이차방정식의 풀이', 'lectureNumber': 3,
      'uploadDate': '2026-04-16', 'relatedLectureId': 'gd_math_quad_002',
      'handoutUrls': [
        'assets/handouts/math_quad_003_p1.png',
      ],
    },
  ];

  // ── NAS 터널 URL 동적 업데이트 (구글 드라이브 전환으로 비활성화) ──
  static Future<void> fetchTunnelUrl() async {
    // 구글 드라이브 전용으로 전환 → NAS/터널 완전 비활성화
    return;
  }

  // ── nas:// 프로토콜 → 실제 NAS URL 변환 ──
  static Map<String, dynamic> _resolveNasUrl(Map<String, dynamic> m) {
    final video = m['videoUrl'] as String? ?? '';
    final thumb = m['thumbnailUrl'] as String? ?? '';
    const nasBase = 'https://appreciation-staffing-night-where.trycloudflare.com/igong';
    if (video.startsWith('nas://')) {
      final fileId = video.replaceFirst('nas://', '');
      m['videoUrl'] = '$nasBase/$fileId.mp4';
      if (thumb.isEmpty) {
        m['thumbnailUrl'] = '$nasBase/thumbs/$fileId.jpg';
      }
    }
    return m;
  }

  // ── 🎯 자동 썸네일 추출 (videoUrl → thumbnailUrl 자동 생성) ──
  //
  // 강의가 탑재되는 순간 썸네일을 별도로 지정하지 않아도
  // videoUrl 에서 자동으로 첫 화면(썸네일)을 추출합니다.
  //
  // 지원 플랫폼:
  //   ① Google Drive  → drive.google.com/thumbnail?id=FILE_ID&sz=w480
  //   ② YouTube       → img.youtube.com/vi/VIDEO_ID/hqdefault.jpg
  //   ③ NAS(MP4)      → 이미 _resolveNasUrl 에서 처리됨
  //   ④ 기타 URL      → 변경 없이 그대로 사용
  //
  static String _autoThumb(String videoUrl, String existingThumb) {
    // 이미 유효한 썸네일이 있으면 그대로 사용
    // (assets/ 로컬 파일은 유효하지 않은 것으로 간주 → 자동 교체)
    if (existingThumb.isNotEmpty && !existingThumb.startsWith('assets/')) {
      // drive.google.com/thumbnail → lh3 직접 URL로 변환 (302 리다이렉트 회피)
      if (existingThumb.contains('drive.google.com/thumbnail')) {
        final idMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(existingThumb);
        if (idMatch != null) {
          return 'https://lh3.googleusercontent.com/d/${idMatch.group(1)}=w480';
        }
      }
      return existingThumb;
    }

    if (videoUrl.isEmpty) return existingThumb;

    // ① Google Drive URL 처리
    // 형식: https://drive.google.com/file/d/FILE_ID/view?...
    //   또는 https://drive.google.com/open?id=FILE_ID
    // lh3 직접 URL 사용 (302 리다이렉트 없이 Flutter에서 안정적으로 로드)
    final driveFileMatch = RegExp(
      r'drive\.google\.com/file/d/([a-zA-Z0-9_\-]+)',
    ).firstMatch(videoUrl);
    if (driveFileMatch != null) {
      final fileId = driveFileMatch.group(1)!;
      return 'https://lh3.googleusercontent.com/d/$fileId=w480';
    }
    final driveOpenMatch = RegExp(
      r'drive\.google\.com/open\?id=([a-zA-Z0-9_\-]+)',
    ).firstMatch(videoUrl);
    if (driveOpenMatch != null) {
      final fileId = driveOpenMatch.group(1)!;
      return 'https://lh3.googleusercontent.com/d/$fileId=w480';
    }

    // ② YouTube URL 처리
    // 형식: https://youtu.be/VIDEO_ID
    //   또는 https://www.youtube.com/watch?v=VIDEO_ID
    //   또는 https://www.youtube.com/embed/VIDEO_ID
    final ytShortMatch = RegExp(
      r'youtu\.be/([a-zA-Z0-9_\-]{11})',
    ).firstMatch(videoUrl);
    if (ytShortMatch != null) {
      final videoId = ytShortMatch.group(1)!;
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    final ytLongMatch = RegExp(
      r'youtube\.com/(?:watch\?v=|embed/)([a-zA-Z0-9_\-]{11})',
    ).firstMatch(videoUrl);
    if (ytLongMatch != null) {
      final videoId = ytLongMatch.group(1)!;
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }

    // ③ NAS MP4: _resolveNasUrl 에서 이미 처리됨 → 여기서는 그대로 반환
    if (videoUrl.contains('/igong/') && videoUrl.endsWith('.mp4')) {
      final nasThumbUrl = videoUrl
          .replaceFirst('/igong/', '/igong/thumbs/')
          .replaceFirst('.mp4', '.jpg');
      return nasThumbUrl;
    }

    // ④ 그 외: 기존 값 유지
    return existingThumb;
  }

  /// 강의 목록 조회
  /// 우선순위: 어드민 JSON + 번들 데이터 병합 (어드민 우선, 중복 ID 제거)
  Future<List<Lecture>> fetchLectures({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) return _cachedLectures!;

    List<Lecture> adminLectures = [];

    // 1순위: 어드민 서버 lectures.json 시도
    for (final url in _adminUrls) {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final rawList =
              json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
          final lectures = rawList.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final existingVideo = m['videoUrl'] as String? ?? '';
            final existingThumb = m['thumbnailUrl'] as String? ?? '';
            if (existingVideo.isEmpty) m['videoUrl'] = '';
            if (existingThumb.isEmpty) m['thumbnailUrl'] = '';
            // nas:// 프로토콜 변환
            _resolveNasUrl(m);
            // 🎯 자동 썸네일: 어드민 JSON 에도 동일하게 적용
            //   thumbnailUrl 미지정 or assets/ 경로 → videoUrl 에서 자동 추출
            m['thumbnailUrl'] = _autoThumb(
              m['videoUrl'] as String? ?? '',
              m['thumbnailUrl'] as String? ?? '',
            );
            return _parseLecture(m);
          }).toList();
          if (lectures.isNotEmpty) {
            adminLectures = lectures;
            if (kDebugMode) {
              debugPrint('[API] ✅ 어드민 JSON 로드: ${lectures.length}개');
            }
            break;
          }
        }
      } catch (_) {}
    }

    // 번들 데이터와 병합 (어드민에 없는 강의만 번들에서 추가)
    final bundledRaw = _bundledLectures.map((e) {
      final m = Map<String, dynamic>.from(e);
      _resolveNasUrl(m);
      return _parseLecture(m);
    }).toList();

    if (adminLectures.isEmpty) {
      // 어드민 서버 연결 실패 → 번들 전체 사용
      if (kDebugMode) {
        debugPrint('[API] 번들 데이터 사용: ${bundledRaw.length}개');
      }
      _cachedLectures = bundledRaw;
      _cacheTime = DateTime.now();
      return bundledRaw;
    }

    // 어드민 + 번들 병합 (중복 ID 제거, 어드민 우선)
    final adminIds = adminLectures.map((l) => l.id).toSet();
    final bundledOnly = bundledRaw.where((l) => !adminIds.contains(l.id)).toList();
    final merged = [...adminLectures, ...bundledOnly];
    if (kDebugMode) {
      debugPrint('[API] ✅ 병합 완료: 어드민 ${adminLectures.length}개 + 번들 ${bundledOnly.length}개 = 총 ${merged.length}개');
    }
    _cachedLectures = merged;
    _cacheTime = DateTime.now();
    return merged;
  }

  static List<Lecture> getBundledLecturesDirect() {
    return _bundledLectures.map((d) => _parseLectureStatic(d)).toList();
  }

  /// 어드민에서 직접 추가할 때 사용 (외부 접근용)
  static Lecture parseLectureFromMap(Map<String, dynamic> d) =>
      _parseLectureStatic(d);

  void clearCache() {
    _cachedLectures = null;
    _cacheTime = null;
  }

  Lecture _parseLecture(Map<String, dynamic> d) =>
      _parseLectureStatic(d);

  static Lecture _parseLectureStatic(Map<String, dynamic> d) {
    // 🎯 자동 썸네일: videoUrl 에서 첫 화면을 자동 추출
    //   - thumbnailUrl 이 비어 있거나 assets/ 로컬 파일이면 자동 교체
    //   - Google Drive / YouTube / NAS 모두 지원
    final rawVideoUrl = d['videoUrl'] as String? ?? '';
    final rawThumbUrl = d['thumbnailUrl'] as String? ?? '';
    final resolvedThumbUrl = _autoThumb(rawVideoUrl, rawThumbUrl);

    return Lecture(
      id: d['id'] as String? ?? '',
      title: d['title'] as String? ?? '',
      subject: d['subject'] as String? ?? '기타',
      grade: d['grade'] as String? ?? 'middle',
      instructor: d['instructor'] as String? ?? '',
      thumbnailUrl: resolvedThumbUrl,
      videoUrl: rawVideoUrl,
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
      gradeYear: d['gradeYear'] as String? ?? 'All',
      handoutUrls: (d['handoutUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

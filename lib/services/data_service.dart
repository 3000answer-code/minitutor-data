import '../models/lecture.dart';
import '../models/instructor.dart';
import '../models/consultation.dart';
import '../models/study_progress.dart';
import 'api_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final _api = ApiService();

  // ─── API에서 강의 로드 (어드민 등록 콘텐츠 우선) ───
  Future<List<Lecture>> getLecturesFromApi() async {
    final apiLectures = await _api.fetchLectures();
    if (apiLectures.isNotEmpty) return apiLectures;
    // API 실패 시 로컬 샘플 반환
    return getYoutubeLectures();
  }

  Future<List<Lecture>> getRecommendedFromApi() async {
    final all = await getLecturesFromApi();
    final recommended = all.where((l) => true).toList();
    recommended.sort((a, b) => b.rating.compareTo(a.rating));
    return recommended.take(8).toList();
  }

  Future<List<Lecture>> getPopularFromApi() async {
    final all = await getLecturesFromApi();
    all.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return all.take(10).toList();
  }

  // YouTube 강의만 (로컬 폴백)
  List<Lecture> getYoutubeLectures() {
    return getAllLectures()
        .where((l) => l.videoUrl.contains('youtube'))
        .toList();
  }

  // ─── 샘플 강의 데이터 ───
  List<Lecture> getAllLectures() {
    return [
      // 국어
      Lecture(id: 'kor_001', title: '소설의 3요소와 구성 단계', subject: '국어', grade: 'middle',
        instructor: '이국어', thumbnailUrl: 'https://picsum.photos/seed/kor1/400/225',
        videoUrl: '', duration: 118, viewCount: 24500, rating: 4.8, ratingCount: 342,
        lectureType: 'concept', hashtags: ['소설', '3요소', '인물', '사건', '배경'],
        description: '소설의 핵심 3요소인 인물, 사건, 배경을 2분 안에 완벽 정리!',
        isFavorite: true, series: '중등 국어 기초', lectureNumber: 1,
        uploadDate: '2024-10-15', relatedLectureId: 'kor_001_Q'),
      Lecture(id: 'kor_001_Q', title: '[문제풀이] 소설의 3요소와 구성 단계', subject: '국어', grade: 'middle',
        instructor: '이국어', thumbnailUrl: 'https://picsum.photos/seed/kor1q/400/225',
        videoUrl: '', duration: 95, viewCount: 18200, rating: 4.7, ratingCount: 215,
        lectureType: 'problem', relatedLectureId: 'kor_001',
        hashtags: ['소설', '문제풀이'], description: '소설의 3요소 실전 문제 완전 정복',
        isFavorite: false, series: '중등 국어 기초', lectureNumber: 2,
        uploadDate: '2024-10-15'),
      Lecture(id: 'kor_002', title: '시의 표현기법 총정리', subject: '국어', grade: 'middle',
        instructor: '이국어', thumbnailUrl: 'https://picsum.photos/seed/kor2/400/225',
        videoUrl: '', duration: 112, viewCount: 31200, rating: 4.9, ratingCount: 521,
        lectureType: 'concept', hashtags: ['시', '비유법', '강조법', '변화법'],
        description: '은유, 직유, 의인법 등 시의 표현기법을 2분에 마스터!',
        isFavorite: false, series: '중등 국어 기초', lectureNumber: 3,
        uploadDate: '2024-11-01'),
      // 영어
      Lecture(id: 'eng_001', title: '현재완료 vs 과거시제 완벽 구분', subject: '영어', grade: 'middle',
        instructor: '박영어', thumbnailUrl: 'https://picsum.photos/seed/eng1/400/225',
        videoUrl: '', duration: 105, viewCount: 45600, rating: 4.9, ratingCount: 892,
        lectureType: 'concept', hashtags: ['현재완료', '과거시제', '영문법'],
        description: '헷갈리는 현재완료와 과거시제 차이를 예문으로 확실히 구분!',
        isFavorite: true, series: '중등 영문법 완성', lectureNumber: 5,
        uploadDate: '2024-09-20', relatedLectureId: 'eng_001_Q'),
      Lecture(id: 'eng_001_Q', title: '[문제풀이] 현재완료 vs 과거시제', subject: '영어', grade: 'middle',
        instructor: '박영어', thumbnailUrl: 'https://picsum.photos/seed/eng1q/400/225',
        videoUrl: '', duration: 88, viewCount: 38000, rating: 4.8, ratingCount: 640,
        lectureType: 'problem', relatedLectureId: 'eng_001',
        hashtags: ['현재완료', '문제풀이'],
        description: '현재완료 실전 문제 총정리', isFavorite: false,
        series: '중등 영문법 완성', lectureNumber: 6, uploadDate: '2024-09-21'),
      Lecture(id: 'eng_002', title: '관계대명사 who/which/that 핵심 정리', subject: '영어', grade: 'high',
        instructor: '박영어', thumbnailUrl: 'https://picsum.photos/seed/eng2/400/225',
        videoUrl: '', duration: 115, viewCount: 28900, rating: 4.7, ratingCount: 445,
        lectureType: 'concept', hashtags: ['관계대명사', '영문법', '고등영어'],
        description: '관계대명사 who, which, that을 2분 만에 마스터!',
        isFavorite: false, series: '고등 영문법 완성', lectureNumber: 1,
        uploadDate: '2024-10-05'),
      // ── 실제 YouTube 강의 ──
      // 수학 (한국어)
      Lecture(id: 'math_yt_001', title: '현의 길이', subject: '수학', grade: 'middle',
        instructor: '김재은', thumbnailUrl: 'https://i.ytimg.com/vi/IoYdRHwiFJg/hqdefault.jpg',
        videoUrl: 'https://youtube.com/shorts/IoYdRHwiFJg', duration: 60,
        viewCount: 1000, rating: 4.8, ratingCount: 10,
        lectureType: 'concept', hashtags: ['현의길이', '원', '중등수학', '기하'],
        description: '원에서 현의 길이 공식을 2분 안에 완벽 정리!',
        isFavorite: false, series: '중등 수학 핵심', lectureNumber: 10,
        uploadDate: '2024-12-01'),
      Lecture(id: 'math_yt_002', title: '조건이 있는 순열', subject: '수학', grade: 'high',
        instructor: '한성훈', thumbnailUrl: 'https://i.ytimg.com/vi/paBDxUDjv24/hqdefault.jpg',
        videoUrl: 'https://youtube.com/shorts/paBDxUDjv24', duration: 60,
        viewCount: 1000, rating: 4.8, ratingCount: 10,
        lectureType: 'concept', hashtags: ['순열', '조건부순열', '확률', '고등수학'],
        description: '조건이 있는 순열 풀이법을 2분 만에 정복!',
        isFavorite: false, series: '고등 수학 심화', lectureNumber: 2,
        uploadDate: '2024-12-01'),
      Lecture(id: 'math_yt_003', title: '점과 직선 사이의 거리', subject: '수학', grade: 'high',
        instructor: '김본', thumbnailUrl: 'https://i.ytimg.com/vi/fMye4sKykgY/hqdefault.jpg',
        videoUrl: 'https://youtube.com/shorts/fMye4sKykgY', duration: 60,
        viewCount: 1000, rating: 4.8, ratingCount: 10,
        lectureType: 'concept', hashtags: ['점과직선', '거리공식', '좌표기하', '고등수학'],
        description: '점과 직선 사이의 거리 공식 완전 정복!',
        isFavorite: false, series: '고등 수학 심화', lectureNumber: 3,
        uploadDate: '2024-12-01'),
      Lecture(id: 'math_yt_004', title: '음수 제곱근', subject: '수학', grade: 'high',
        instructor: '최형규', thumbnailUrl: 'https://i.ytimg.com/vi/WxcrKt9lX6A/hqdefault.jpg',
        videoUrl: 'https://youtube.com/shorts/WxcrKt9lX6A', duration: 60,
        viewCount: 1000, rating: 4.8, ratingCount: 10,
        lectureType: 'concept', hashtags: ['음수제곱근', '허수', '복소수', '고등수학'],
        description: '음수의 제곱근과 허수 개념을 2분에 완벽 이해!',
        isFavorite: false, series: '고등 수학 심화', lectureNumber: 4,
        uploadDate: '2024-12-01'),
      // 수학 (영어)
      Lecture(id: 'math_yt_005', title: 'Radian (래디안)', subject: '수학', grade: 'high',
        instructor: '한성훈', thumbnailUrl: 'https://i.ytimg.com/vi/bn-d-wImU90/hqdefault.jpg',
        videoUrl: 'https://youtube.com/shorts/bn-d-wImU90', duration: 60,
        viewCount: 1000, rating: 4.8, ratingCount: 10,
        lectureType: 'concept', hashtags: ['래디안', 'radian', '삼각함수', '고등수학'],
        description: '래디안의 개념과 활용을 영어로 2분에 완성!',
        isFavorite: false, series: '고등 수학 심화', lectureNumber: 5,
        uploadDate: '2024-12-01'),
      // 수학 (스페인어)
      Lecture(id: 'math_yt_006', title: 'Permutación Circular (원순열)', subject: '수학', grade: 'high',
        instructor: '최성빈', thumbnailUrl: 'https://i.ytimg.com/vi/qjeTh7c3AYA/hqdefault.jpg',
        videoUrl: 'https://youtube.com/shorts/qjeTh7c3AYA', duration: 60,
        viewCount: 1000, rating: 4.8, ratingCount: 10,
        lectureType: 'concept', hashtags: ['원순열', '순열', '확률', '고등수학'],
        description: '원순열 개념을 스페인어로 2분에 완벽 정리!',
        isFavorite: false, series: '고등 수학 심화', lectureNumber: 6,
        uploadDate: '2024-12-01'),
      // 수학 (기존 샘플)
      Lecture(id: 'math_001', title: '이차방정식 근의 공식 완전 정복', subject: '수학', grade: 'middle',
        instructor: '김수학', thumbnailUrl: 'https://picsum.photos/seed/math1/400/225',
        videoUrl: '', duration: 119, viewCount: 67800, rating: 4.9, ratingCount: 1240,
        lectureType: 'concept', hashtags: ['이차방정식', '근의공식', '판별식'],
        description: '근의 공식 유도부터 적용까지 2분에 완성!',
        isFavorite: true, series: '중등 수학 핵심', lectureNumber: 8,
        uploadDate: '2024-08-15', relatedLectureId: 'math_001_Q'),
      Lecture(id: 'math_001_Q', title: '[문제풀이] 이차방정식 근의 공식', subject: '수학', grade: 'middle',
        instructor: '김수학', thumbnailUrl: 'https://picsum.photos/seed/math1q/400/225',
        videoUrl: '', duration: 108, viewCount: 55000, rating: 4.9, ratingCount: 890,
        lectureType: 'problem', relatedLectureId: 'math_001',
        hashtags: ['이차방정식', '문제풀이'], description: '이차방정식 실전 5문제 완전 해설',
        isFavorite: false, series: '중등 수학 핵심', lectureNumber: 9,
        uploadDate: '2024-08-16'),
      Lecture(id: 'math_002', title: '삼각함수 sin·cos·tan 개념 정리', subject: '수학', grade: 'high',
        instructor: '김수학', thumbnailUrl: 'https://picsum.photos/seed/math2/400/225',
        videoUrl: '', duration: 116, viewCount: 42100, rating: 4.8, ratingCount: 765,
        lectureType: 'concept', hashtags: ['삼각함수', 'sin', 'cos', 'tan', '고등수학'],
        description: '삼각함수의 기초부터 단위원까지 2분 완성!',
        isFavorite: false, series: '고등 수학 심화', lectureNumber: 1,
        uploadDate: '2024-11-10'),
      // 과학
      Lecture(id: 'sci_001', title: '세포분열 미토시스 vs 메이오시스', subject: '과학', grade: 'high',
        instructor: '최과학', thumbnailUrl: 'https://picsum.photos/seed/sci1/400/225',
        videoUrl: '', duration: 113, viewCount: 33400, rating: 4.7, ratingCount: 567,
        lectureType: 'concept', hashtags: ['세포분열', '미토시스', '메이오시스', '생물'],
        description: '유사분열과 감수분열의 차이점 2분에 완벽 정리!',
        isFavorite: false, series: '고등 생물 핵심', lectureNumber: 3,
        uploadDate: '2024-09-30', relatedLectureId: 'sci_001_Q'),
      Lecture(id: 'sci_001_Q', title: '[문제풀이] 세포분열', subject: '과학', grade: 'high',
        instructor: '최과학', thumbnailUrl: 'https://picsum.photos/seed/sci1q/400/225',
        videoUrl: '', duration: 97, viewCount: 22500, rating: 4.6, ratingCount: 340,
        lectureType: 'problem', relatedLectureId: 'sci_001',
        hashtags: ['세포분열', '문제풀이'], description: '세포분열 실전 문제 해설',
        isFavorite: false, series: '고등 생물 핵심', lectureNumber: 4,
        uploadDate: '2024-10-01'),
      Lecture(id: 'sci_002', title: '뉴턴의 운동법칙 3가지 완전정복', subject: '과학', grade: 'middle',
        instructor: '최과학', thumbnailUrl: 'https://picsum.photos/seed/sci2/400/225',
        videoUrl: '', duration: 109, viewCount: 29800, rating: 4.8, ratingCount: 482,
        lectureType: 'concept', hashtags: ['뉴턴', '운동법칙', '관성', '작용반작용'],
        description: '뉴턴 1·2·3법칙을 실생활 예로 2분에 이해!',
        isFavorite: true, series: '중등 물리 기초', lectureNumber: 2,
        uploadDate: '2024-10-22'),
      // 사회
      Lecture(id: 'soc_001', title: '자유무역 vs 보호무역 핵심 비교', subject: '사회', grade: 'middle',
        instructor: '정사회', thumbnailUrl: 'https://picsum.photos/seed/soc1/400/225',
        videoUrl: '', duration: 107, viewCount: 18700, rating: 4.6, ratingCount: 298,
        lectureType: 'concept', hashtags: ['자유무역', '보호무역', '국제경제'],
        description: '자유무역과 보호무역의 장단점 2분 요약!',
        isFavorite: false, series: '중등 사회 경제', lectureNumber: 5,
        uploadDate: '2024-11-05'),
      Lecture(id: 'soc_002', title: '민주주의 3권 분립 원리', subject: '사회', grade: 'middle',
        instructor: '정사회', thumbnailUrl: 'https://picsum.photos/seed/soc2/400/225',
        videoUrl: '', duration: 103, viewCount: 22100, rating: 4.7, ratingCount: 367,
        lectureType: 'concept', hashtags: ['민주주의', '삼권분립', '입법', '사법', '행정'],
        description: '입법·사법·행정 삼권분립 원리 2분 완성!',
        isFavorite: false, series: '중등 사회 정치', lectureNumber: 2,
        uploadDate: '2024-11-15'),
      // 초등
      Lecture(id: 'elem_001', title: '분수의 덧셈과 뺄셈 쉽게 배우기', subject: '수학', grade: 'elementary',
        instructor: '오초등', thumbnailUrl: 'https://picsum.photos/seed/elem1/400/225',
        videoUrl: '', duration: 98, viewCount: 52300, rating: 4.9, ratingCount: 1120,
        lectureType: 'concept', hashtags: ['분수', '덧셈', '뺄셈', '초등수학'],
        description: '분수의 덧셈·뺄셈 공통분모 구하는 법 2분 마스터!',
        isFavorite: false, series: '초등 수학 4학년', lectureNumber: 3,
        uploadDate: '2024-10-10', relatedLectureId: 'elem_001_Q'),
      Lecture(id: 'elem_001_Q', title: '[문제풀이] 분수의 덧셈과 뺄셈', subject: '수학', grade: 'elementary',
        instructor: '오초등', thumbnailUrl: 'https://picsum.photos/seed/elem1q/400/225',
        videoUrl: '', duration: 86, viewCount: 44500, rating: 4.9, ratingCount: 890,
        lectureType: 'problem', relatedLectureId: 'elem_001',
        hashtags: ['분수', '문제풀이'], description: '분수 연산 실전 문제 5개 해설',
        isFavorite: false, series: '초등 수학 4학년', lectureNumber: 4,
        uploadDate: '2024-10-11'),
    ];
  }

  List<Lecture> getRecommendedLectures() {
    final all = getAllLectures();
    // YouTube 강의(실제 영상)를 맨 앞에, 나머지는 rating 순으로
    final ytLectures = all.where((l) => l.videoUrl.contains('youtube')).toList();
    final others = all.where((l) => !l.videoUrl.contains('youtube') && l.rating >= 4.8).toList();
    return [...ytLectures, ...others].take(8).toList();
  }

  List<Lecture> getPopularLectures() {
    final all = getAllLectures();
    // YouTube 강의(실제 영상)를 맨 앞에, 나머지는 viewCount 순으로
    final ytLectures = all.where((l) => l.videoUrl.contains('youtube')).toList();
    final others = all.where((l) => !l.videoUrl.contains('youtube')).toList();
    others.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return [...ytLectures, ...others].take(10).toList();
  }

  List<Lecture> getLecturesBySubject(String subject) {
    return getAllLectures().where((l) => l.subject == subject).toList();
  }

  List<Lecture> searchLectures(String query, {String? grade, String? subject}) {
    return getAllLectures().where((l) {
      final matchQuery = l.title.contains(query) ||
          l.hashtags.any((h) => h.contains(query)) ||
          l.instructor.contains(query);
      final matchGrade = grade == null || grade.isEmpty || l.grade == grade;
      final matchSubject = subject == null || subject.isEmpty || l.subject == subject;
      return matchQuery && matchGrade && matchSubject;
    }).toList();
  }

  // ─── 강사 데이터 ───
  List<Instructor> getAllInstructors() {
    return [
      Instructor(id: 'ins_001', name: '김수학', grade: 'middle', subject: '수학',
        profileImageUrl: 'https://picsum.photos/seed/ins1/150/150',
        introduction: '10년 경력의 수학 전문 강사. 어려운 수학도 2분이면 OK!',
        lectureCount: 48, rating: 4.9, followerCount: 12400,
        series: ['중등 수학 핵심', '고등 수학 심화']),
      Instructor(id: 'ins_002', name: '박영어', grade: 'middle', subject: '영어',
        profileImageUrl: 'https://picsum.photos/seed/ins2/150/150',
        introduction: 'Cambridge 출신 영어 강사. 문법부터 독해까지 완벽 커버!',
        lectureCount: 62, rating: 4.8, followerCount: 18900,
        series: ['중등 영문법 완성', '고등 영문법 완성']),
      Instructor(id: 'ins_003', name: '이국어', grade: 'middle', subject: '국어',
        profileImageUrl: 'https://picsum.photos/seed/ins3/150/150',
        introduction: '국어교육학 박사. 문학·비문학 모두 2분 요약으로!',
        lectureCount: 35, rating: 4.7, followerCount: 8700,
        series: ['중등 국어 기초', '고등 국어 심화']),
      Instructor(id: 'ins_004', name: '최과학', grade: 'high', subject: '과학',
        profileImageUrl: 'https://picsum.photos/seed/ins4/150/150',
        introduction: 'KAIST 출신 과학 강사. 물리·화학·생물 올킬!',
        lectureCount: 55, rating: 4.8, followerCount: 14200,
        series: ['고등 물리 완성', '고등 생물 핵심', '중등 물리 기초']),
      Instructor(id: 'ins_005', name: '정사회', grade: 'middle', subject: '사회',
        profileImageUrl: 'https://picsum.photos/seed/ins5/150/150',
        introduction: '사회 선생님 15년 경력. 역사·지리·일반사회 전문!',
        lectureCount: 41, rating: 4.6, followerCount: 7300,
        series: ['중등 사회 경제', '중등 사회 정치', '한국사 완성']),
      Instructor(id: 'ins_006', name: '오초등', grade: 'elementary', subject: '수학',
        profileImageUrl: 'https://picsum.photos/seed/ins6/150/150',
        introduction: '초등 교육 전문. 아이들 눈높이에 맞는 2분 강의!',
        lectureCount: 72, rating: 4.9, followerCount: 23500,
        series: ['초등 수학 3학년', '초등 수학 4학년', '초등 수학 5학년']),
      Instructor(id: 'ins_007', name: '김재은', grade: 'middle', subject: '수학',
        profileImageUrl: 'https://picsum.photos/seed/ins7/150/150',
        introduction: '중등 수학 전문 강사. 도형과 기하를 쉽고 명확하게!',
        lectureCount: 15, rating: 4.8, followerCount: 3200,
        series: ['중등 수학 핵심']),
      Instructor(id: 'ins_008', name: '한성훈', grade: 'high', subject: '수학',
        profileImageUrl: 'https://picsum.photos/seed/ins8/150/150',
        introduction: '고등 수학 확률·통계 전문. 수능까지 완벽 대비!',
        lectureCount: 22, rating: 4.7, followerCount: 5100,
        series: ['고등 수학 심화']),
      Instructor(id: 'ins_009', name: '김본', grade: 'high', subject: '수학',
        profileImageUrl: 'https://picsum.photos/seed/ins9/150/150',
        introduction: '고등 수학 좌표기하 전문. 직관적인 그림 풀이로 명쾌하게!',
        lectureCount: 18, rating: 4.9, followerCount: 4700,
        series: ['고등 수학 심화']),
      Instructor(id: 'ins_010', name: '최형규', grade: 'high', subject: '수학',
        profileImageUrl: 'https://picsum.photos/seed/ins10/150/150',
        introduction: '고등 수학 대수·복소수 전문. 어려운 개념도 2분이면 OK!',
        lectureCount: 20, rating: 4.8, followerCount: 4400,
        series: ['고등 수학 심화']),
    ];
  }

  // ─── 상담 데이터 ───
  List<Consultation> getConsultations() {
    return [
      Consultation(id: 'con_001', title: '이차방정식 근의 공식 언제 쓰는 건가요?',
        content: '인수분해가 안 될 때만 쓰는 건가요? 아니면 항상 써도 되나요? 구체적인 기준이 궁금합니다.',
        authorNickname: '수학고민중', authorProfileUrl: 'https://picsum.photos/seed/user1/80/80',
        subject: '수학', grade: 'middle', createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isAnswered: true, answer: '근의 공식은 모든 이차방정식에 사용 가능하지만, 인수분해가 가능할 때는 인수분해가 더 빠릅니다. 인수분해가 안 되거나 어렵다고 느껴질 때 근의 공식을 활용하는 것이 효율적입니다.',
        answerAuthor: '김수학 강사', answeredAt: DateTime.now().subtract(const Duration(hours: 1)),
        viewCount: 234, attachments: []),
      Consultation(id: 'con_002', title: '현재완료 have + p.p. 써야 하는 경우가 헷갈려요',
        content: '언제 과거를 쓰고 언제 현재완료를 써야 하는지 정확한 기준을 알고 싶어요.',
        authorNickname: '영어왕이될래', authorProfileUrl: 'https://picsum.photos/seed/user2/80/80',
        subject: '영어', grade: 'middle', createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isAnswered: false, viewCount: 156, attachments: []),
      Consultation(id: 'con_003', title: '세포분열 미토시스 단계 외우는 팁이 있을까요?',
        content: '전기 중기 후기 말기 순서는 알겠는데 각 단계에서 일어나는 일이 자꾸 헷갈립니다.',
        authorNickname: '생물배우는중', authorProfileUrl: 'https://picsum.photos/seed/user3/80/80',
        subject: '과학', grade: 'high', createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isAnswered: true, answer: '전중후말을 "전기(준비), 중기(정렬), 후기(분리), 말기(분열완성)"로 암기하세요. 각 단계의 핵심 키워드를 먼저 외우고 나서 세부 내용을 연결하는 방식이 효과적입니다!',
        answerAuthor: '최과학 강사', answeredAt: DateTime.now().subtract(const Duration(hours: 20)),
        viewCount: 445, attachments: []),
      Consultation(id: 'con_004', title: '삼권분립에서 견제와 균형 원리가 왜 중요한가요?',
        content: '사회 시험에 자주 나오는데 단순 암기보다 원리를 이해하고 싶습니다.',
        authorNickname: '사회공부열심히', authorProfileUrl: 'https://picsum.photos/seed/user4/80/80',
        subject: '사회', grade: 'middle', createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isAnswered: true, answer: '삼권분립의 핵심은 권력 남용 방지입니다. 역사적으로 한 기관에 권력이 집중되면 독재가 발생했기 때문에, 3개 기관이 서로를 견제함으로써 민주주의를 지킵니다.',
        answerAuthor: '정사회 강사', answeredAt: DateTime.now().subtract(const Duration(days: 1, hours: 18)),
        viewCount: 312, attachments: []),
    ];
  }

  // ─── 진도학습 데이터 ───
  List<StudyUnit> getStudyUnits(String subject, String grade) {
    return [
      StudyUnit(id: 'unit_001', subject: subject, grade: grade,
        unitName: '수와 식', chapter: '1단원',
        totalLectures: 8, completedLectures: 5,
        lectureIds: ['math_001', 'math_001_Q'],
        completionRate: 0.625),
      StudyUnit(id: 'unit_002', subject: subject, grade: grade,
        unitName: '방정식과 부등식', chapter: '2단원',
        totalLectures: 10, completedLectures: 3,
        lectureIds: ['math_002'],
        completionRate: 0.3),
      StudyUnit(id: 'unit_003', subject: subject, grade: grade,
        unitName: '함수', chapter: '3단원',
        totalLectures: 12, completedLectures: 0,
        lectureIds: [],
        completionRate: 0.0),
      StudyUnit(id: 'unit_004', subject: subject, grade: grade,
        unitName: '확률과 통계', chapter: '4단원',
        totalLectures: 8, completedLectures: 8,
        lectureIds: [],
        completionRate: 1.0),
    ];
  }
}

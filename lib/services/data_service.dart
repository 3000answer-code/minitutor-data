import '../models/lecture.dart';
import '../models/instructor.dart';
import '../models/consultation.dart';
import '../models/study_progress.dart';
import 'api_service.dart';
import 'instructor_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final _api = ApiService();

  // ─── API 전용 (로컬 샘플 데이터 없음) ───
  Future<List<Lecture>> getLecturesFromApi() async {
    return await _api.fetchLectures();
  }

  // ─── 강의 데이터: API에서만 제공 (로컬 없음) ───
  List<Lecture> getAllLectures() => [];

  List<Lecture> getRecommendedLectures() => [];

  List<Lecture> getPopularLectures() => [];

  List<Lecture> getLecturesBySubject(String subject) => [];

  List<Lecture> searchLectures(String query, {String? grade, String? subject}) => [];

  // ─── 수동 등록 강사 (프로필·소개 고정 강사) ───────────────────────────────
  // 이 목록에 있는 강사는 콘텐츠 자동 생성보다 우선 적용됩니다.
  // 새 강사가 콘텐츠를 올리면 자동으로 목록에 추가되며,
  // 여기에 수동으로 추가하면 소개글·프로필 등을 직접 지정할 수 있습니다.
  static final List<Instructor> _manualInstructors = [
    // ── 고등 수학 ──
    Instructor(
      id: 'ins_hansh', name: '한성훈', grade: 'high', subject: '수학',
      profileImageUrl: 'https://picsum.photos/seed/hansh/150/150',
      introduction: '고등 수학 지수·로그·미적분 전문. 핵심 개념을 명확하고 빠르게!',
      lectureCount: 4, rating: 4.8, followerCount: 5800,
      series: ['지수함수와 로그함수', '미적분', '집합과 명제']),
    Instructor(
      id: 'ins_kimb', name: '김본', grade: 'high', subject: '수학',
      profileImageUrl: 'https://picsum.photos/seed/kimb/150/150',
      introduction: '고등 수학 대수·다항식 전문. 직관적인 풀이로 빠르게 이해!',
      lectureCount: 5, rating: 4.9, followerCount: 6200,
      series: ['다항식', '방정식과 부등식', '집합과 명제']),
    Instructor(
      id: 'ins_choisk', name: '최성빈', grade: 'high', subject: '수학',
      profileImageUrl: 'https://picsum.photos/seed/choisk/150/150',
      introduction: '고등 수학 수열·미적분·조합 전문. 두번설명으로 확실하게!',
      lectureCount: 3, rating: 4.8, followerCount: 4900,
      series: ['수열과 급수', '미적분', '순열과 조합']),
    Instructor(
      id: 'ins_choihk', name: '최형규', grade: 'high', subject: '수학',
      profileImageUrl: 'https://picsum.photos/seed/choihk/150/150',
      introduction: '고등 수학 로그·조합 전문. 두번설명으로 개념을 완벽 정복!',
      lectureCount: 3, rating: 4.7, followerCount: 4100,
      series: ['지수함수와 로그함수', '순열과 조합', '수열과 급수']),
    Instructor(
      id: 'ins_jeonys', name: '전요셉', grade: 'high', subject: '수학',
      profileImageUrl: 'https://picsum.photos/seed/jeonys/150/150',
      introduction: '고등 수학 방정식·로그·다항식 두번설명 전문 강사!',
      lectureCount: 4, rating: 4.8, followerCount: 4600,
      series: ['수열과 급수', '지수함수와 로그함수', '방정식과 부등식', '다항식']),
    // ── 중등 수학 ──
    Instructor(
      id: 'ins_kimje', name: '김재은', grade: 'middle', subject: '수학',
      profileImageUrl: 'https://picsum.photos/seed/kimje/150/150',
      introduction: '중등 도형·기하 전문 강사. 원의 성질을 쉽고 명확하게!',
      lectureCount: 1, rating: 4.8, followerCount: 3100,
      series: ['원의 성질']),
    Instructor(
      id: 'ins_kongbc', name: '공병찬', grade: 'middle', subject: '수학',
      profileImageUrl: 'https://picsum.photos/seed/kongbc/150/150',
      introduction: '중등 수학 도형 전문. 두번설명으로 확실한 이해를 도와드립니다!',
      lectureCount: 1, rating: 4.7, followerCount: 2800,
      series: ['원의 성질']),
    Instructor(
      id: 'ins_kimb_mid', name: '김본', grade: 'middle', subject: '수학',
      profileImageUrl: 'https://picsum.photos/seed/kimb/150/150',
      introduction: '예비중 수학 기초 전문. 숫자·자릿값부터 차근차근!',
      lectureCount: 2, rating: 4.9, followerCount: 5300,
      series: ['수학 기초']),
    // ── 중등 과학 ──
    Instructor(
      id: 'ins_kimja', name: '김정아', grade: 'middle', subject: '과학',
      profileImageUrl: 'https://picsum.photos/seed/kimja/150/150',
      introduction: '중등 과학 전기·지구과학 전문. 두번설명으로 개념을 쉽게!',
      lectureCount: 2, rating: 4.8, followerCount: 3600,
      series: ['전기와 자기', '태양계']),
    Instructor(
      id: 'ins_limjh', name: '임지현', grade: 'middle', subject: '과학',
      profileImageUrl: 'https://picsum.photos/seed/limjh/150/150',
      introduction: '중등 과학 전기·우주 전문. 두번설명으로 어려운 개념도 OK!',
      lectureCount: 2, rating: 4.7, followerCount: 3200,
      series: ['전기와 자기', '태양계']),
    // ── 고등 화학 ──
    Instructor(
      id: 'ins_kogwy', name: '고광윤', grade: 'high', subject: '화학',
      profileImageUrl: 'https://picsum.photos/seed/kogwy/150/150',
      introduction: '고등 화학 전문 강사. 화학과 우리생활 시리즈로 화학을 쉽게!',
      lectureCount: 3, rating: 4.9, followerCount: 4200,
      series: ['화학과 우리생활']),
    // ── 고등 생명과학 (권용락 - 실제 콘텐츠 강사) ──
    Instructor(
      id: 'ins_kwonyr', name: '권용락', grade: 'high', subject: '생명과학',
      profileImageUrl: 'https://picsum.photos/seed/kwonyr/150/150',
      introduction: '고등 생명과학 유전·염색체 전문. 핵심 개념을 빠르고 명확하게!',
      lectureCount: 3, rating: 4.9, followerCount: 4500,
      series: ['유전']),
    // ── 고등 지구과학 (방정훈 - 실제 콘텐츠 강사) ──
    Instructor(
      id: 'ins_bangjh', name: '방정훈', grade: 'high', subject: '지구과학',
      profileImageUrl: 'https://picsum.photos/seed/bangjh/150/150',
      introduction: '고등 지구과학 지진·화산·지구 역동성 전문. 핵심만 빠르게!',
      lectureCount: 3, rating: 4.8, followerCount: 3800,
      series: ['지구의 역동성', '지구의 변동', '마그마의 생성']),
  ];

  // ─── 강사 목록 (자동 생성) ──────────────────────────────────────────────
  /// 콘텐츠(강의) 데이터에서 강사 정보를 자동으로 추출합니다.
  /// - 수동 등록 강사(_manualInstructors)는 소개·프로필 그대로 유지
  /// - 새 강의가 올라오면 강사 카드가 자동으로 추가됨
  /// [lectures] 파라미터로 최신 강의 목록을 넘겨주면 동적으로 동기화됩니다.
  List<Instructor> getAllInstructors({List<Lecture>? lectures}) {
    final allLectures = lectures ?? ApiService.getBundledLecturesDirect();
    return InstructorService().buildInstructorsFromLectures(
      allLectures,
      manualInstructors: _manualInstructors,
    );
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
      Consultation(id: 'con_002', title: '세포분열 미토시스 단계 외우는 팁이 있을까요?',
        content: '전기 중기 후기 말기 순서는 알겠는데 각 단계에서 일어나는 일이 자꾸 헷갈립니다.',
        authorNickname: '생물배우는중', authorProfileUrl: 'https://picsum.photos/seed/user3/80/80',
        subject: '과학', grade: 'high', createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isAnswered: true, answer: '전중후말을 "전기(준비), 중기(정렬), 후기(분리), 말기(분열완성)"로 암기하세요. 각 단계의 핵심 키워드를 먼저 외우고 나서 세부 내용을 연결하는 방식이 효과적입니다!',
        answerAuthor: '최과학 강사', answeredAt: DateTime.now().subtract(const Duration(hours: 20)),
        viewCount: 445, attachments: []),
      Consultation(id: 'con_003', title: '이차함수 꼭짓점 구하는 공식이 헷갈려요',
        content: '완전제곱식으로 변환하는 방법과 공식을 이용하는 방법 중 어떤 게 더 빠른가요?',
        authorNickname: '수학열공중', authorProfileUrl: 'https://picsum.photos/seed/user4/80/80',
        subject: '수학', grade: 'middle', createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isAnswered: true, answer: '꼭짓점 공식 (-b/2a, f(-b/2a))을 먼저 익히면 빠르게 구할 수 있습니다. 완전제곱식은 원리 이해에 좋고, 시험에서는 공식이 더 빠릅니다.',
        answerAuthor: '김수학 강사', answeredAt: DateTime.now().subtract(const Duration(days: 1, hours: 18)),
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

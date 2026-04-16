import 'package:flutter/material.dart';
import '../models/note.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  // ── 저장된 노트 샘플 ──────────────────────────────
  List<SavedNote> getSavedNotes() => [
    SavedNote(id: 'note_001', lectureId: 'math_001', lectureTitle: '이차방정식 근의 공식 완전 정복',
      subject: '수학', savedAt: '2024-11-20 14:32', previewText: '근의 공식: x = (-b ± √(b²-4ac)) / 2a', strokeCount: 12),
    SavedNote(id: 'note_002', lectureId: 'sci_001', lectureTitle: '세포분열 미토시스 vs 메이오시스',
      subject: '과학', savedAt: '2024-11-18 10:15', previewText: '미토시스: 체세포분열(2n→2n), 메이오시스: 감수분열(2n→n)', strokeCount: 20),
    SavedNote(id: 'note_003', lectureId: 'math_002', lectureTitle: '이차함수 그래프 완전 정복',
      subject: '수학', savedAt: '2024-11-15 16:45', previewText: 'y=a(x-p)²+q: 꼭짓점(p,q), a>0 아래로 볼록', strokeCount: 15),
    SavedNote(id: 'note_004', lectureId: 'sci_001', lectureTitle: '세포분열 미토시스 vs 메이오시스',
      subject: '과학', savedAt: '2024-11-12 09:20', previewText: '미토시스: 체세포분열(2n→2n), 메이오시스: 감수분열(2n→n)', strokeCount: 20),
  ];

  // ── 일정 샘플 ──────────────────────────────────────
  List<ScheduleEvent> getScheduleEvents() {
    final now = DateTime.now();
    return [
      ScheduleEvent(id: 'sch_001', title: '수학 이차방정식 복습', content: '근의공식 5문제 풀기',
        dateTime: DateTime(now.year, now.month, now.day + 1, 18, 0),
        alertBefore: '30분전', repeat: '없음', color: const Color(0xFF10B981), isAppEvent: false),
      ScheduleEvent(id: 'sch_002', title: '과학 세포분열 시리즈 시청', content: '미토시스 강의 보기',
        dateTime: DateTime(now.year, now.month, now.day + 3, 20, 0),
        alertBefore: '1시간전', repeat: '없음', color: const Color(0xFF3B82F6), isAppEvent: false),
<<<<<<< Updated upstream
      ScheduleEvent(id: 'sch_003', title: '어썸튜터 퀴즈 이벤트', content: '수학·과학 퀴즈 대회 참여하고 경품 받아가세요!',
=======
      ScheduleEvent(id: 'sch_003', title: '미니튜터 퀴즈 이벤트', content: '수학·과학 퀴즈 대회 참여하고 경품 받아가세요!',
>>>>>>> Stashed changes
        dateTime: DateTime(now.year, now.month, now.day + 5, 14, 0),
        alertBefore: '1일전', repeat: '없음', color: const Color(0xFFF97316), isAppEvent: true),
      ScheduleEvent(id: 'sch_004', title: '매일 2분 공부 목표', content: '하루 한 강의 완료',
        dateTime: DateTime(now.year, now.month, now.day, 21, 0),
        alertBefore: '정시', repeat: '매일', color: const Color(0xFF8B5CF6), isAppEvent: false),
<<<<<<< Updated upstream
      ScheduleEvent(id: 'sch_005', title: '어썸튜터 강의 오픈', content: '고등 물리 시리즈 전편 업데이트!',
=======
      ScheduleEvent(id: 'sch_005', title: '미니튜터 강의 오픈', content: '고등 물리 시리즈 전편 업데이트!',
>>>>>>> Stashed changes
        dateTime: DateTime(now.year, now.month, now.day + 7, 10, 0),
        alertBefore: '1일전', repeat: '없음', color: const Color(0xFFF97316), isAppEvent: true),
      ScheduleEvent(id: 'sch_006', title: '과학 단원 완료 목표', content: '생물 단원 전강의 완수',
        dateTime: DateTime(now.year, now.month, now.day + 10, 19, 0),
        alertBefore: '30분전', repeat: '없음', color: const Color(0xFF8B5CF6), isAppEvent: false),
    ];
  }

  // ── 공지사항 샘플 ──────────────────────────────────
  List<Notice> getNotices() => [
    Notice(id: 'not_001', title: '[공지] Asome Tutor 앱 버전 2.0 업데이트 안내',
      content: 'Asome Tutor 앱이 새롭게 업데이트 되었습니다.\n\n✅ 주요 변경사항\n- 강의 재생 속도 조절 기능 개선\n- 노트 필기 3색 펜 추가\n- 나의 일정 달력 기능 추가\n- 전반적인 성능 최적화\n\n더 편리해진 Asome Tutor로 공부를 시작해보세요!',
      category: '공지', createdAt: DateTime.now().subtract(const Duration(days: 1)), isImportant: true),
    Notice(id: 'not_002', title: '[이벤트] 11월 퀴즈왕 선발 대회 🏆',
      content: 'Asome Tutor 퀴즈왕 선발 대회를 개최합니다!\n\n📅 기간: 2024년 11월 25일 ~ 11월 30일\n🎁 경품: 1등 - 스타벅스 기프티콘 5만원권\n\n참여 방법:\n1. Asome Tutor 앱 내 퀴즈 메뉴 접속\n2. 수학/과학 퀴즈 10문제 풀기\n3. 최고점 기록 달성!\n\n지금 바로 도전해보세요!',
      category: '이벤트', createdAt: DateTime.now().subtract(const Duration(days: 2)), isImportant: false),
    Notice(id: 'not_003', title: '[공지] 고등 물리 시리즈 신규 강의 오픈',
      content: '고등 물리 완성 시리즈가 새로 업로드 되었습니다.\n\n📚 신규 강의 목록\n- 뉴턴의 운동법칙 3편\n- 전기와 자기 2편\n- 파동과 빛 1편\n\n최과학 강사의 2분 명강의를 지금 만나보세요!',
      category: '공지', createdAt: DateTime.now().subtract(const Duration(days: 4)), isImportant: false),
    Notice(id: 'not_004', title: '[행사] 겨울방학 특별 할인 이벤트 ❄️',
      content: '겨울방학을 맞아 프리미엄 이용권 특별 할인!\n\n💰 할인 혜택\n- 1개월권: 9,900원 → 6,900원 (30% 할인)\n- 3개월권: 24,900원 → 15,900원 (36% 할인)\n- 12개월권: 79,900원 → 49,900원 (37% 할인)\n\n📅 기간: 2024년 12월 1일 ~ 2025년 1월 31일',
      category: '행사', createdAt: DateTime.now().subtract(const Duration(days: 7)), isImportant: false),
    Notice(id: 'not_005', title: '[공지] 서버 점검 안내 (12/1 새벽 2시~4시)',
      content: '서비스 품질 향상을 위한 서버 점검이 예정되어 있습니다.\n\n⚠️ 점검 일시: 2024년 12월 1일 (일) 새벽 2:00 ~ 4:00\n⚠️ 점검 중 앱 사용이 일시 중단됩니다.\n\n이용에 불편을 드려 죄송합니다.',
      category: '공지', createdAt: DateTime.now().subtract(const Duration(days: 10)), isImportant: true),
  ];

  // ── FAQ 샘플 ──────────────────────────────────────
  List<FaqItem> getFaqItems() => [
    FaqItem(id: 'faq_001', category: '이용방법',
      question: 'Asome Tutor 앱은 어떻게 사용하나요?',
      answer: 'Asome Tutor는 짧은 짧은 강의 영상으로 공부하는 앱입니다.\n\n① 홈에서 원하는 강의를 선택하세요\n② 영상을 시청하며 노트에 필기하세요\n③ 진도학습에서 학습 현황을 확인하세요\n④ 모르는 내용은 전문가 상담을 활용하세요'),
    FaqItem(id: 'faq_002', category: '이용방법',
      question: '자막은 어떻게 켜고 끄나요?',
      answer: '강의 재생 화면 우상단의 [CC] 버튼을 누르면 자막을 켜고 끌 수 있습니다.\n설정 메뉴에서 자막 기본값(On/Off)을 설정할 수 있습니다.'),
    FaqItem(id: 'faq_003', category: '이용방법',
      question: '강의 재생 속도를 바꾸려면?',
      answer: '강의 재생 중 우상단 ⚙️ 아이콘을 누르면 배속 설정이 가능합니다.\n지원 배속: 0.5x / 0.75x / 1.0x(기본) / 1.25x / 1.5x'),
    FaqItem(id: 'faq_004', category: '이용방법',
      question: '노트 필기는 어떻게 저장하나요?',
      answer: '강의 재생 화면 하단 [노트보기] 탭에서 필기도구를 활성화 후 필기하세요.\n필기 완료 후 [노트 저장] 버튼을 누르면 나의 활동 > 노트 목록에 저장됩니다.'),
    FaqItem(id: 'faq_005', category: '결제/이용권',
      question: '이용권 종류와 가격은 어떻게 되나요?',
      answer: '현재 제공 중인 이용권:\n\n• 1개월권: 9,900원\n• 3개월권: 24,900원 (월 8,300원)\n• 12개월권: 79,900원 (월 6,658원)\n\n이용권 구매는 슬라이드 메뉴 > 사용기간 연장에서 하실 수 있습니다.'),
    FaqItem(id: 'faq_006', category: '결제/이용권',
      question: '환불은 어떻게 신청하나요?',
      answer: '환불은 구매 후 7일 이내, 강의 수강 이력이 없는 경우에 가능합니다.\n고객센터 > 1:1 문의에서 [결제] 카테고리로 환불 신청해 주세요.\n영업일 기준 3~5일 내 처리됩니다.'),
    FaqItem(id: 'faq_007', category: '결제/이용권',
      question: '이용기간이 만료되면 어떻게 되나요?',
      answer: '이용기간 만료 시 강의 시청이 제한됩니다.\n단, 저장된 노트와 즐겨찾기 목록은 유지됩니다.\n슬라이드 메뉴에서 이용권을 연장하시면 계속 이용하실 수 있습니다.'),
    FaqItem(id: 'faq_008', category: '계정/회원',
      question: '닉네임이나 프로필 사진을 바꾸고 싶어요',
      answer: '슬라이드 메뉴 상단 프로필 영역에서 [프로필 수정] 버튼을 누르시면\n닉네임, 이메일, 프로필 사진을 수정할 수 있습니다.'),
    FaqItem(id: 'faq_009', category: '계정/회원',
      question: '비밀번호를 잊어버렸어요',
      answer: '로그인 화면 하단 [비밀번호 찾기]를 누르시면\n가입하신 이메일로 임시 비밀번호를 발송해드립니다.\n이메일을 확인하신 후 로그인 후 비밀번호를 변경해 주세요.'),
    FaqItem(id: 'faq_010', category: '강의',
      question: '개념 강의와 문제풀이 강의의 차이는 뭔가요?',
      answer: '• 개념 강의: 핵심 이론과 개념을 2분 안에 정리\n• 문제풀이 강의: 해당 개념의 실전 문제를 풀어드리는 강의\n\n개념 강의를 먼저 보신 후, 연결된 문제풀이 강의를 보시면 효과적입니다!\n재생 화면 하단 [문제풀이 강의 보기] 버튼으로 바로 이동하실 수 있습니다.'),
    FaqItem(id: 'faq_011', category: '강의',
      question: '원하는 강의가 없어요. 추가 요청이 가능한가요?',
      answer: '강의 요청은 고객센터 > 1:1 문의에서 [강의 요청] 카테고리를 선택하여\n원하시는 과목, 학년, 단원을 작성해 주시면 검토 후 업로드해 드리겠습니다.'),
    FaqItem(id: 'faq_012', category: '기술/오류',
      question: '영상이 재생되지 않아요',
      answer: '아래 방법을 순서대로 시도해보세요:\n\n① 앱을 완전히 종료 후 재시작\n② Wi-Fi / 모바일 데이터 연결 상태 확인\n③ 앱 캐시 삭제 (설정 > 앱 정보 > 캐시 삭제)\n④ 앱 최신 버전으로 업데이트\n\n해결되지 않으면 1:1 문의로 문의해 주세요.'),
  ];

  // ── 1:1 문의 샘플 ──────────────────────────────────
  List<Inquiry> getMyInquiries() => [
    Inquiry(id: 'inq_001', category: '이용방법', title: '강의 다운로드 기능이 있나요?',
      content: '오프라인에서도 강의를 볼 수 있는지 궁금합니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isAnswered: true, answer: '현재 오프라인 다운로드 기능은 지원하지 않습니다. Wi-Fi 환경에서 설정 > 모바일 데이터 허용을 통해 데이터 절약 모드로 이용하실 수 있습니다. 오프라인 기능은 향후 업데이트에서 지원 예정입니다.'),
    Inquiry(id: 'inq_002', category: '결제', title: '영수증 발급 요청',
      content: '지난달 결제한 3개월권 영수증을 발급받고 싶습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isAnswered: false),
  ];
}

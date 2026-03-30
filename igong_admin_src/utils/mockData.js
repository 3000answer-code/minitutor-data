// ── 샘플 데이터 ────────────────────────────────────────────

export const mockMembers = Array.from({ length: 50 }, (_, i) => ({
  id: i + 1,
  name: ['김민준', '이서연', '박지호', '최유진', '정하은', '강도현', '윤서아', '임준혁', '오나연', '한승우'][i % 10],
  userId: `user${String(i + 1).padStart(3, '0')}`,
  nickname: `닉네임${i + 1}`,
  phone: `010-${String(Math.floor(Math.random() * 9000) + 1000)}-${String(Math.floor(Math.random() * 9000) + 1000)}`,
  joinDate: `2024-${String(Math.floor(Math.random() * 12) + 1).padStart(2, '0')}-${String(Math.floor(Math.random() * 28) + 1).padStart(2, '0')}`,
  permission: i % 5 === 0 ? 'Y' : 'N',
  expireDate: i % 5 === 0 ? `2025-${String(Math.floor(Math.random() * 12) + 1).padStart(2, '0')}-${String(Math.floor(Math.random() * 28) + 1).padStart(2, '0')}` : '-',
  status: 'active',
}));

export const mockPayments = Array.from({ length: 20 }, (_, i) => ({
  id: i + 1,
  name: mockMembers[i].name,
  userId: mockMembers[i].userId,
  nickname: mockMembers[i].nickname,
  product: ['30일 이용권', '90일 이용권', '180일 이용권', '7일 이용권'][i % 4],
  method: ['신용카드', '카카오페이', '네이버페이', '계좌이체'][i % 4],
  amount: [9900, 24900, 44900, 3900][i % 4],
  payDate: `2025-0${(i % 3) + 1}-${String(Math.floor(Math.random() * 28) + 1).padStart(2, '0')}`,
}));

export const mockInstructors = [
  { id: 1, name: '김정아', email: 'kja@igong.kr', phone: '010-1111-2222', regDate: '2024-01-10', visible: 'Y' },
  { id: 2, name: '이민호', email: 'lmh@igong.kr', phone: '010-2222-3333', regDate: '2024-02-15', visible: 'Y' },
  { id: 3, name: '박수진', email: 'psj@igong.kr', phone: '010-3333-4444', regDate: '2024-03-20', visible: 'Y' },
  { id: 4, name: '최현우', email: 'chw@igong.kr', phone: '010-4444-5555', regDate: '2024-04-05', visible: 'N' },
  { id: 5, name: '정다은', email: 'jde@igong.kr', phone: '010-5555-6666', regDate: '2024-05-12', visible: 'Y' },
];

export const mockSeries = [
  { id: 1, category: '수학/중등', title: '이차방정식 완전정복', count: 12, visible: 'Y', recommended: 'Y' },
  { id: 2, category: '영어/고등', title: '수능 영어 독해전략', count: 20, visible: 'Y', recommended: 'Y' },
  { id: 3, category: '과학/중등', title: '뉴턴의 역학 기초', count: 8, visible: 'Y', recommended: 'N' },
  { id: 4, category: '국어/고등', title: '현대문학의 이해', count: 15, visible: 'N', recommended: 'N' },
  { id: 5, category: '수학/고등', title: '삼각함수 시리즈', count: 11, visible: 'Y', recommended: 'Y' },
  { id: 6, category: '사회/중등', title: '민주주의와 정치', count: 8, visible: 'Y', recommended: 'N' },
];

export const mockVideos = Array.from({ length: 30 }, (_, i) => ({
  id: i + 1,
  category: ['수학/중등', '영어/고등', '과학/중등', '국어/고등', '사회/중등'][i % 5],
  series: mockSeries[i % 6].title,
  title: [`이차방정식 근의 공식`, `현재완료 시제`, `뉴턴의 운동법칙`, `소설의 이해`, `민주주의 원리`][i % 5] + ` ${i + 1}강`,
  instructor: mockInstructors[i % 5].name,
  regDate: `2024-${String((i % 12) + 1).padStart(2, '0')}-${String((i % 28) + 1).padStart(2, '0')}`,
  visible: i % 4 === 0 ? 'N' : 'Y',
  recommended: i % 3 === 0 ? 'Y' : 'N',
  views: Math.floor(Math.random() * 10000),
  rating: (Math.random() * 2 + 3).toFixed(1),
}));

export const mockConsultations = Array.from({ length: 15 }, (_, i) => ({
  id: i + 1,
  name: mockMembers[i].name,
  userId: mockMembers[i].userId,
  nickname: mockMembers[i].nickname,
  content: ['삼각함수 sin, cos, tan이 헷갈려요', '현재완료와 과거시제의 차이점', '뉴턴 제2법칙 공식 이해', '소설 시점 분류 방법'][i % 4],
  regDate: `2025-0${(i % 3) + 1}-${String((i % 28) + 1).padStart(2, '0')}`,
  answered: i % 3 !== 0,
}));

export const mockNotices = [
  { id: 1, title: '서비스 이용 약관 개정 안내', regDate: '2025-03-01', visible: 'Y', views: 1234, recommended: 'Y' },
  { id: 2, title: '2025년 수능 대비 특별 강의 오픈', regDate: '2025-02-15', visible: 'Y', views: 3456, recommended: 'Y' },
  { id: 3, title: '앱 업데이트 안내 (v2.3.0)', regDate: '2025-02-01', visible: 'Y', views: 890, recommended: 'N' },
  { id: 4, title: '설 연휴 고객센터 운영 안내', regDate: '2025-01-20', visible: 'Y', views: 456, recommended: 'N' },
  { id: 5, title: '신규 강사 합류 안내', regDate: '2025-01-10', visible: 'N', views: 234, recommended: 'N' },
];

export const mockEvents = [
  { id: 1, category: '이벤트', period: '2025-03-01 ~ 2025-03-31', title: '봄맞이 30% 할인 이벤트', regDate: '2025-02-28', visible: 'Y', views: 2345 },
  { id: 2, category: '행사', period: '2025-02-14 ~ 2025-02-14', title: '발렌타인 특별 혜택', regDate: '2025-02-10', visible: 'Y', views: 1678 },
  { id: 3, category: '이벤트', period: '2025-01-01 ~ 2025-01-31', title: '신년 맞이 특별 쿠폰 증정', regDate: '2024-12-30', visible: 'N', views: 3456 },
];

export const mockFaqs = [
  { id: 1, category: '이용권', question: '이용권은 어떻게 구매하나요?', regDate: '2024-01-01', visible: 'Y', views: 5678, answer: '앱 내 스토어 메뉴에서 구매하실 수 있습니다.' },
  { id: 2, category: '계정', question: '비밀번호를 잊어버렸어요', regDate: '2024-01-02', visible: 'Y', views: 4567, answer: '로그인 화면의 비밀번호 찾기 버튼을 눌러주세요.' },
  { id: 3, category: '강의', question: '오프라인에서도 강의를 볼 수 있나요?', regDate: '2024-01-03', visible: 'Y', views: 3456, answer: '프리미엄 이용권 구매 시 오프라인 다운로드가 가능합니다.' },
  { id: 4, category: '결제', question: '환불은 어떻게 하나요?', regDate: '2024-01-04', visible: 'Y', views: 2345, answer: '고객센터 1:1 문의로 접수해 주시면 처리해드립니다.' },
];

export const mockInquiries = Array.from({ length: 10 }, (_, i) => ({
  id: i + 1,
  name: mockMembers[i].name,
  userId: mockMembers[i].userId,
  nickname: mockMembers[i].nickname,
  category: ['결제', '계정', '강의', '기술문의'][i % 4],
  content: ['결제가 안돼요', '로그인이 안됩니다', '영상이 재생되지 않아요', '앱이 자꾸 꺼져요'][i % 4],
  regDate: `2025-0${(i % 3) + 1}-${String((i % 28) + 1).padStart(2, '0')}`,
  answered: i % 2 === 0,
}));

export const mockCoupons = [
  { id: 1, name: '신규가입 할인쿠폰', issueDate: '2025-01-01', quantity: 1000, expiry: '2025-06-30', used: 342, status: '사용중' },
  { id: 2, name: '봄맞이 특별쿠폰', issueDate: '2025-03-01', quantity: 500, expiry: '2025-03-31', used: 123, status: '사용중' },
  { id: 3, name: '2024 연말쿠폰', issueDate: '2024-12-01', quantity: 2000, expiry: '2024-12-31', used: 1876, status: '중지' },
];

export const mockBanners = [
  { id: 1, title: '수능 D-100 특별 이벤트', regDate: '2025-03-01', visible: 'Y', url: '/event/1' },
  { id: 2, title: '봄 학기 신규 강의 오픈', regDate: '2025-02-20', visible: 'Y', url: '/new' },
  { id: 3, title: '프리미엄 30% 할인', regDate: '2025-02-01', visible: 'N', url: '/store' },
];

export const mockAdmins = [
  { id: 1, name: '슈퍼관리자', userId: 'superadmin', permissions: ['members', 'videos', 'consult', 'notice', 'support', 'coupon', 'admin'] },
  { id: 2, name: '콘텐츠담당', userId: 'content01', permissions: ['videos', 'notice'] },
  { id: 3, name: '고객담당', userId: 'support01', permissions: ['consult', 'support'] },
];

export const mockPushHistory = [
  { id: 1, title: '신규 강의 알림', target: '전체', sentDate: '2025-03-01 10:00', url: '/home', content: '새로운 수학 강의가 업로드되었습니다!' },
  { id: 2, title: '이벤트 안내', target: '무료회원', sentDate: '2025-02-15 14:00', url: '/event', content: '봄맞이 할인 이벤트가 시작되었습니다!' },
  { id: 3, title: '이용권 만료 안내', target: '유료회원', sentDate: '2025-02-01 09:00', url: '/store', content: '이용권이 곧 만료됩니다. 연장해 주세요.' },
];

export const mockStats = {
  totalMembers: 12847,
  paidMembers: 3421,
  todayVisitors: 1234,
  totalVideos: 10234,
  newMembersThisMonth: 342,
  revenueThisMonth: 12450000,
  visitData: Array.from({ length: 30 }, (_, i) => ({
    date: `3/${i + 1}`,
    visitors: Math.floor(Math.random() * 2000) + 500,
    members: Math.floor(Math.random() * 50) + 10,
  })),
  topVideos: mockVideos.slice(0, 5).map(v => ({ ...v, views: Math.floor(Math.random() * 10000) + 1000 })),
};

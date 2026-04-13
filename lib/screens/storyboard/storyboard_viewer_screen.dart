import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ─── 스토리보드 슬라이드 데이터 모델 ───────────────────
class StoryboardSlide {
  final int page;
  final String section;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<StoryboardElement> elements;
  final String? note;

  const StoryboardSlide({
    required this.page,
    required this.section,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.elements = const [],
    this.note,
  });
}

class StoryboardElement {
  final String type; // 'ui', 'flow', 'spec', 'button', 'screen'
  final String label;
  final String? detail;
  final IconData? icon;
  final Color? color;

  const StoryboardElement({
    required this.type,
    required this.label,
    this.detail,
    this.icon,
    this.color,
  });
}

// ─── 전체 스토리보드 데이터 (92p → 슬라이드) ──────────────
class StoryboardData {
  static List<StoryboardSlide> get slides => [

    // ────── SECTION 0: 타이틀 & 소개 ──────
    StoryboardSlide(
      page: 1, section: '소개', title: 'miniTutor 앱 스토리보드',
      description: '2분 공부 - 핵심 개념만 쏙쏙!\n공만세를 새롭게 리뉴얼한 2공 앱의 전체 UI/UX 설계 문서입니다.',
      icon: Icons.menu_book_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'spec', label: '총 92페이지 스토리보드'),
        StoryboardElement(type: 'spec', label: '5개 메인 섹션 구성'),
        StoryboardElement(type: 'spec', label: '하단 퀵메뉴 5탭 구조'),
        StoryboardElement(type: 'spec', label: '슬라이드 드로어 메뉴'),
      ],
    ),
    StoryboardSlide(
      page: 2, section: '소개', title: '강의 파일 구성 규칙',
      description: '파일명 규칙: 촬영일_과목_학제_강사명_강의번호_강의명.확장자',
      icon: Icons.folder_rounded, color: const Color(0xFF6366F1),
      elements: [
        StoryboardElement(type: 'spec', label: '개념 강의', detail: '일반 강의 (예: 231115_수학_중2_김민준_001_이차방정식.mp4)'),
        StoryboardElement(type: 'spec', label: '문제풀이 강의', detail: '파일명 끝에 _Q 추가 (예: ...이차방정식_Q.mp4)'),
        StoryboardElement(type: 'spec', label: '용어 해설 강의', detail: '파일명 끝에 _W 추가'),
        StoryboardElement(type: 'spec', label: '교안 파일', detail: '강의와 동일명의 PNG 파일'),
        StoryboardElement(type: 'spec', label: '자막 파일', detail: 'SRT 형식, 동일 파일명'),
      ],
      note: '개념 강의 ↔ 문제풀이 강의는 서로 연결됨',
    ),
    StoryboardSlide(
      page: 3, section: '소개', title: '전체 메뉴 구조',
      description: '앱의 전체 화면 흐름과 메뉴 체계',
      icon: Icons.account_tree_rounded, color: const Color(0xFF8B5CF6),
      elements: [
        StoryboardElement(type: 'flow', label: '홈 (동영상 강의)', detail: '추천/인기/국영수/과학/사회/기타', icon: Icons.home_rounded, color: AppColors.primary),
        StoryboardElement(type: 'flow', label: '진도학습', detail: '과목/학년/단원별 학습 진도', icon: Icons.trending_up_rounded, color: AppColors.success),
        StoryboardElement(type: 'flow', label: '검색', detail: '키워드/필터/결과 3탭', icon: Icons.search_rounded, color: AppColors.accent),
        StoryboardElement(type: 'flow', label: '전문가 상담', detail: 'Q&A 목록/상세/작성', icon: Icons.support_agent_rounded, color: const Color(0xFF8B5CF6)),
        StoryboardElement(type: 'flow', label: '강사별 강의', detail: '학제별/강사별 강의 목록', icon: Icons.school_rounded, color: AppColors.korean),
        StoryboardElement(type: 'flow', label: '슬라이드 메뉴', detail: '프로필/나의활동/일정/설정', icon: Icons.menu_rounded, color: AppColors.textSecondary),
      ],
    ),

    // ────── SECTION 1: 홈 화면 ──────
    StoryboardSlide(
      page: 5, section: '홈', title: '홈 - 추천 탭',
      description: '상단 바: 알림 아이콘 + 로고(2공) + 슬라이드 메뉴 아이콘\n롤링 배너 + 무작위 추천 강의 목록',
      icon: Icons.home_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'ui', label: '상단 앱바', detail: '알림(🔔) / 2공 로고 / 햄버거 메뉴(☰)'),
        StoryboardElement(type: 'ui', label: '롤링 배너', detail: '자동 슬라이드 이미지 배너'),
        StoryboardElement(type: 'ui', label: '추천 강의 목록', detail: '썸네일 + 강의명 + 강사 + 시간'),
        StoryboardElement(type: 'ui', label: '하단 퀵메뉴', detail: '홈/진도/검색/상담/강사 5탭'),
      ],
    ),
    StoryboardSlide(
      page: 6, section: '홈', title: '홈 - 인기 탭',
      description: '조회수 기준 상위 300개 강의 목록\n매일 오전 06:00 자동 업데이트',
      icon: Icons.local_fire_department_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'spec', label: '인기 기준', detail: '조회수 Top 300'),
        StoryboardElement(type: 'spec', label: '업데이트 주기', detail: '매일 06:00 자동 갱신'),
        StoryboardElement(type: 'ui', label: '순위 배지', detail: '1위~300위 번호 표시'),
        StoryboardElement(type: 'ui', label: '정렬 옵션', detail: '평점/최신/이름/과목/관련도'),
        StoryboardElement(type: 'ui', label: '자동재생 토글', detail: 'ON/OFF 스위치'),
      ],
    ),
    StoryboardSlide(
      page: 7, section: '홈', title: '홈 - 국영수 탭',
      description: '국어/영어/수학 과목 탭 → 강의 리스트\n학제별 필터 + 소분류 카테고리',
      icon: Icons.calculate_rounded, color: AppColors.math,
      elements: [
        StoryboardElement(type: 'ui', label: '과목 탭', detail: '국어 / 영어 / 수학'),
        StoryboardElement(type: 'ui', label: '학제 필터', detail: '초1~고3 선택'),
        StoryboardElement(type: 'ui', label: '소분류 카테고리', detail: '전체/시리즈/문제풀이/노트보기'),
        StoryboardElement(type: 'ui', label: '강의 카드', detail: '썸네일 + 제목 + 강사 + 시간 + 별점'),
      ],
    ),
    StoryboardSlide(
      page: 8, section: '홈', title: '카테고리 선택 팝업',
      description: '전체 / 시리즈 / 문제풀이 / 노트보기 선택',
      icon: Icons.filter_list_rounded, color: AppColors.textSecondary,
      elements: [
        StoryboardElement(type: 'button', label: '전체', detail: '모든 강의 표시'),
        StoryboardElement(type: 'button', label: '시리즈', detail: '시리즈별 묶음 강의'),
        StoryboardElement(type: 'button', label: '문제풀이', detail: '문제풀이 전용 강의 (_Q)'),
        StoryboardElement(type: 'button', label: '노트 보기', detail: '교안 썸네일 목록'),
      ],
    ),
    StoryboardSlide(
      page: 9, section: '홈', title: '시리즈 보기',
      description: '시리즈별 강의 묶음 목록 → 세부 강의 리스트',
      icon: Icons.playlist_play_rounded, color: AppColors.english,
      elements: [
        StoryboardElement(type: 'ui', label: '시리즈 목록', detail: '시리즈명 + 강의수 + 썸네일'),
        StoryboardElement(type: 'ui', label: '시리즈 상세', detail: '전체 강의 순서대로 나열'),
        StoryboardElement(type: 'spec', label: '시리즈 진행 표시', detail: '현재 수강 진도 표시'),
      ],
    ),
    StoryboardSlide(
      page: 11, section: '홈', title: '문제풀이 탭',
      description: '문제풀이 전용 강의 목록 (_Q 파일)\n개념 강의와 연결',
      icon: Icons.quiz_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'ui', label: '문제풀이 강의 목록', detail: '_Q 파일 강의만 필터링'),
        StoryboardElement(type: 'spec', label: '연결 개념 표시', detail: '관련 개념 강의 링크 표시'),
        StoryboardElement(type: 'ui', label: '난이도 배지', detail: '기본/심화 구분'),
      ],
    ),
    StoryboardSlide(
      page: 12, section: '홈', title: '노트 보기 탭',
      description: '강의별 교안(노트) 썸네일 목록',
      icon: Icons.note_alt_rounded, color: AppColors.korean,
      elements: [
        StoryboardElement(type: 'ui', label: '교안 그리드', detail: 'PNG 썸네일 카드 형식'),
        StoryboardElement(type: 'ui', label: '강의 연결', detail: '교안 탭 → 해당 강의로 이동'),
        StoryboardElement(type: 'spec', label: '교안 구성', detail: '강의당 2장 이상 PNG 파일'),
      ],
    ),
    StoryboardSlide(
      page: 13, section: '홈', title: '홈 - 과학/사회/기타 탭',
      description: '과학/사회/기타 과목 탭별 강의 리스트',
      icon: Icons.science_rounded, color: AppColors.science,
      elements: [
        StoryboardElement(type: 'ui', label: '과목 탭', detail: '과학 / 사회 / 기타'),
        StoryboardElement(type: 'ui', label: '소분류 과목', detail: '물리/화학/생물/지구과학 등'),
        StoryboardElement(type: 'ui', label: '강의 리스트', detail: '홈 국영수 탭과 동일 구조'),
      ],
    ),
    StoryboardSlide(
      page: 16, section: '홈', title: '알림 화면',
      description: '1:1 문의 답변 / 강의 Q&A 답변 등 푸시 알림 내역',
      icon: Icons.notifications_rounded, color: AppColors.warning,
      elements: [
        StoryboardElement(type: 'ui', label: '알림 목록', detail: '최신순 알림 나열'),
        StoryboardElement(type: 'ui', label: '알림 유형 배지', detail: 'Q&A답변 / 상담답변 / 시스템'),
        StoryboardElement(type: 'spec', label: '읽음 처리', detail: '탭 시 읽음 표시'),
        StoryboardElement(type: 'spec', label: '전체 삭제', detail: '알림 전체 삭제 버튼'),
      ],
    ),

    // ────── SECTION 2: 강의 플레이어 ──────
    StoryboardSlide(
      page: 17, section: '강의 플레이어', title: '강의 재생 화면 (기본)',
      description: '① 영상 영역 ② 자막 표시 ③ 해시태그 ④ 하단 탭(노트/Q&A/재생목록)\n⑤ 필기도구 버튼 ⑥ 노트(교안) 표시 영역',
      icon: Icons.play_circle_rounded, color: const Color(0xFF1E293B),
      elements: [
        StoryboardElement(type: 'ui', label: '① 영상 플레이어', detail: '16:9 비율, SRT 자막 지원'),
        StoryboardElement(type: 'ui', label: '② 자막 패널', detail: '해시태그 주황색(#ff8000) / 강조 노란색(#ffff00)'),
        StoryboardElement(type: 'ui', label: '③ 해시태그', detail: '탭 시 검색 페이지 이동'),
        StoryboardElement(type: 'ui', label: '④ 하단 탭', detail: '노트보기(기본) / 강의Q&A / 재생목록 / 강의정보'),
      ],
      note: '디폴트 탭: 노트 보기',
    ),
    StoryboardSlide(
      page: 18, section: '강의 플레이어', title: '재생 컨트롤',
      description: '재생/일시정지 / 10초 앞뒤 스킵 / 배속 / 자막 ON·OFF / 전체화면',
      icon: Icons.tune_rounded, color: const Color(0xFF374151),
      elements: [
        StoryboardElement(type: 'button', label: '10초 뒤로', icon: Icons.replay_10_rounded, color: Colors.white),
        StoryboardElement(type: 'button', label: '재생/일시정지', icon: Icons.pause_circle_outline_rounded, color: Colors.white),
        StoryboardElement(type: 'button', label: '10초 앞으로', icon: Icons.forward_10_rounded, color: Colors.white),
        StoryboardElement(type: 'spec', label: '배속 조절', detail: '0.5× / 0.75× / 1.0× / 1.25× / 1.5×'),
        StoryboardElement(type: 'spec', label: '자막 ON/OFF', detail: '상단 CC 버튼'),
        StoryboardElement(type: 'spec', label: '전체화면', detail: '가로 전환 지원'),
      ],
    ),
    StoryboardSlide(
      page: 19, section: '강의 플레이어', title: '자막 및 해시태그',
      description: 'SRT 자막 파일 기반 / 해시태그 강조 표시',
      icon: Icons.closed_caption_rounded, color: const Color(0xFF0F172A),
      elements: [
        StoryboardElement(type: 'spec', label: '자막 형식', detail: 'SRT 파일 (.srt)'),
        StoryboardElement(type: 'spec', label: '해시태그 색상', detail: '주황색 #ff8000으로 표시'),
        StoryboardElement(type: 'spec', label: '강조 표시', detail: '노란색 #ffff00 배경'),
        StoryboardElement(type: 'spec', label: '해시태그 탭', detail: '해당 태그 검색 결과로 이동'),
      ],
    ),
    StoryboardSlide(
      page: 20, section: '강의 플레이어', title: '노트(교안) 보기 탭',
      description: '⑥ 교안 이미지 표시\n⑦ 필기 도구로 필기/저장 가능\n⑧ 저장 버튼 → 나의 활동-노트에 저장',
      icon: Icons.note_alt_rounded, color: AppColors.korean,
      elements: [
        StoryboardElement(type: 'ui', label: '⑥ 교안 영역', detail: 'PNG 이미지 (2장 이상), 스크롤'),
        StoryboardElement(type: 'ui', label: '⑦ 필기 도구', detail: '3색 펜(파/빨/검) + 지우개'),
        StoryboardElement(type: 'ui', label: '⑧ 노트 저장', detail: '저장 시 나의 활동-노트목록에 추가'),
        StoryboardElement(type: 'spec', label: '모드 전환', detail: '도구 비활성: 스크롤 / 활성: 필기'),
        StoryboardElement(type: 'spec', label: '자동 불러오기', detail: '같은 강의 재시청 시 필기 자동 표시'),
      ],
      note: '교안은 강의와 동일명 PNG 파일',
    ),
    StoryboardSlide(
      page: 21, section: '강의 플레이어', title: '교안 필기 저장',
      description: '필기한 노트는 해당 강의 재시청 시 자동 표시\n나의 활동 → 노트 목록에서 모아보기 가능',
      icon: Icons.save_rounded, color: AppColors.success,
      elements: [
        StoryboardElement(type: 'spec', label: '저장 방식', detail: '강의ID 기준으로 필기 데이터 저장'),
        StoryboardElement(type: 'spec', label: '자동 로드', detail: '강의 재생 시 이전 필기 자동 불러오기'),
        StoryboardElement(type: 'spec', label: '노트 목록', detail: '나의 활동 > 노트 목록에서 전체 보기'),
        StoryboardElement(type: 'ui', label: 'PIP 모드', detail: '영상 소창 유지하며 필기 가능 (22p)'),
      ],
    ),
    StoryboardSlide(
      page: 22, section: '강의 플레이어', title: 'PIP(Picture-in-Picture) 모드',
      description: '영상을 소창으로 유지하면서 교안에 필기',
      icon: Icons.picture_in_picture_rounded, color: const Color(0xFF0369A1),
      elements: [
        StoryboardElement(type: 'ui', label: 'PIP 영상', detail: '화면 우측 상단 소창'),
        StoryboardElement(type: 'ui', label: '교안 전체 표시', detail: '필기에 집중할 수 있도록 전체 영역'),
        StoryboardElement(type: 'spec', label: '소창 이동', detail: '드래그로 위치 변경'),
      ],
    ),
    StoryboardSlide(
      page: 23, section: '강의 플레이어', title: '강의 Q&A 탭',
      description: 'Q.닉네임 / A.답변자 형식의 말풍선 UI\n질문 입력창 + 등록 버튼',
      icon: Icons.question_answer_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'ui', label: 'Q. 닉네임', detail: '질문자 닉네임과 질문 내용'),
        StoryboardElement(type: 'ui', label: 'A. 답변자', detail: '강사/운영자 답변 표시'),
        StoryboardElement(type: 'ui', label: '답변 상태 배지', detail: '답변완료(초록) / 답변대기(주황)'),
        StoryboardElement(type: 'ui', label: '질문 입력창', detail: '하단 텍스트 입력 + 등록 버튼'),
      ],
    ),
    StoryboardSlide(
      page: 24, section: '강의 플레이어', title: '재생목록 탭',
      description: '시리즈 순서/전체 강의수 표시 (예: 3/10강)\n자동재생 ON/OFF + 해시태그',
      icon: Icons.playlist_play_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'ui', label: '진행 표시', detail: '현재강의번호 / 전체강의수 (예: 3/10강)'),
        StoryboardElement(type: 'ui', label: '자동재생 스위치', detail: 'ON: 다음 강의 자동 재생'),
        StoryboardElement(type: 'ui', label: '해시태그 행', detail: '이 강의의 전체 해시태그'),
        StoryboardElement(type: 'ui', label: '목록 나열', detail: '시리즈 내 전체 강의 순서대로'),
      ],
    ),
    StoryboardSlide(
      page: 25, section: '강의 플레이어', title: '해시태그 이동',
      description: '자막 내 해시태그 탭 → 해당 태그 검색 결과 화면',
      icon: Icons.tag_rounded, color: const Color(0xFFF97316),
      elements: [
        StoryboardElement(type: 'spec', label: '탭 동작', detail: '강의 재생 중 → 검색 결과 화면 이동'),
        StoryboardElement(type: 'ui', label: '검색 결과', detail: '동영상 백과 / 전문가 상담 / 노트 탭'),
      ],
    ),
    StoryboardSlide(
      page: 26, section: '강의 플레이어', title: '강의정보 탭 (26p 핵심)',
      description: '과목 / 강사명 / 강의명 / 전체 해시태그\n즐겨찾기 / 평점 / 공유 / 관련시리즈 / 문제풀이 버튼',
      icon: Icons.info_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'ui', label: '① 과목 배지', detail: '과목명 컬러 배지'),
        StoryboardElement(type: 'ui', label: '② 강사명', detail: '프로필 사진 + 이름 + 전문 분야'),
        StoryboardElement(type: 'ui', label: '③ 강의명', detail: '전체 강의 제목'),
        StoryboardElement(type: 'ui', label: '④ 전체 해시태그', detail: '좌우 스크롤 / 탭 시 검색 이동'),
        StoryboardElement(type: 'button', label: '즐겨찾기', icon: Icons.bookmark_rounded, color: AppColors.primary),
        StoryboardElement(type: 'button', label: '평점', icon: Icons.star_rounded, color: const Color(0xFFFBBF24)),
        StoryboardElement(type: 'button', label: '공유', icon: Icons.share_rounded, color: AppColors.textSecondary),
        StoryboardElement(type: 'button', label: '관련 시리즈', icon: Icons.playlist_play_rounded, color: AppColors.textSecondary),
        StoryboardElement(type: 'button', label: '문제풀이', icon: Icons.quiz_rounded, color: AppColors.accent),
      ],
      note: '정보 탭 활성화 시 노트 영역이 아래로 내려감',
    ),
    StoryboardSlide(
      page: 27, section: '강의 플레이어', title: '즐겨찾기 기능',
      description: '강의정보 탭의 즐겨찾기 버튼 → 나의 활동 > 즐겨찾기 저장',
      icon: Icons.bookmark_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'spec', label: '즐겨찾기 등록', detail: '아이콘 탭 → 색상 변경 + 저장'),
        StoryboardElement(type: 'spec', label: '즐겨찾기 해제', detail: '다시 탭 → 해제'),
        StoryboardElement(type: 'spec', label: '목록 확인', detail: '나의 활동 > 즐겨찾기 탭'),
      ],
    ),
    StoryboardSlide(
      page: 28, section: '강의 플레이어', title: '평점 기능',
      description: '별점 팝업 → 1~5점 선택\n아이콘 아래 총 평점 표시',
      icon: Icons.star_rounded, color: const Color(0xFFFBBF24),
      elements: [
        StoryboardElement(type: 'ui', label: '별점 팝업', detail: '1~5점 별 아이콘'),
        StoryboardElement(type: 'ui', label: '평점 표시', detail: '버튼 아래 평균 별점 숫자'),
        StoryboardElement(type: 'spec', label: '중복 방지', detail: '1인 1회 평가'),
      ],
    ),
    StoryboardSlide(
      page: 29, section: '강의 플레이어', title: '공유 기능',
      description: '카카오톡 / 페이스북으로 강의 링크 공유',
      icon: Icons.share_rounded, color: const Color(0xFF10B981),
      elements: [
        StoryboardElement(type: 'button', label: '카카오톡 공유', icon: Icons.chat_bubble_rounded, color: const Color(0xFFFEE500)),
        StoryboardElement(type: 'button', label: '페이스북 공유', icon: Icons.facebook_rounded, color: const Color(0xFF1877F2)),
        StoryboardElement(type: 'button', label: '링크 복사', icon: Icons.copy_rounded, color: AppColors.textSecondary),
      ],
    ),
    StoryboardSlide(
      page: 30, section: '강의 플레이어', title: '관련 시리즈',
      description: '해당 강의가 속한 시리즈 전체 목록',
      icon: Icons.playlist_play_rounded, color: AppColors.english,
      elements: [
        StoryboardElement(type: 'ui', label: '시리즈 목록', detail: '전체 강의 순서대로 나열'),
        StoryboardElement(type: 'ui', label: '현재 강의 표시', detail: '재생 중인 강의 하이라이트'),
        StoryboardElement(type: 'spec', label: '직접 이동', detail: '목록 내 강의 탭으로 해당 강의 재생'),
      ],
    ),
    StoryboardSlide(
      page: 31, section: '강의 플레이어', title: '문제풀이 강의 연결',
      description: '개념 강의 → 연결된 문제풀이 강의(_Q) 재생',
      icon: Icons.quiz_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'spec', label: '연결 규칙', detail: '동일 파일명 + _Q 파일 자동 연결'),
        StoryboardElement(type: 'ui', label: '문제풀이 버튼', detail: '강의정보 탭 하단 버튼'),
        StoryboardElement(type: 'spec', label: '전환', detail: '문제풀이 강의 플레이어로 바로 이동'),
      ],
    ),
    StoryboardSlide(
      page: 32, section: '강의 플레이어', title: '가로 보기 / 전체화면',
      description: '전체화면 버튼 탭 → 가로 전환\n가로 모드 전용 UI',
      icon: Icons.fullscreen_rounded, color: const Color(0xFF1E293B),
      elements: [
        StoryboardElement(type: 'ui', label: '전체화면 진입', detail: '우측 하단 전체화면 버튼'),
        StoryboardElement(type: 'ui', label: '가로 컨트롤', detail: '배속/자막/종료 버튼 유지'),
        StoryboardElement(type: 'spec', label: '복귀', detail: '전체화면 종료 버튼 또는 뒤로가기'),
      ],
    ),

    // ────── SECTION 3: 진도학습 ──────
    StoryboardSlide(
      page: 35, section: '진도학습', title: '진도학습 메인',
      description: '과목 / 학년(초1~고3) / 단원 선택 → 강의 목록',
      icon: Icons.trending_up_rounded, color: AppColors.success,
      elements: [
        StoryboardElement(type: 'ui', label: '과목 탭', detail: '국어/영어/수학/과학/사회'),
        StoryboardElement(type: 'ui', label: '학년 선택', detail: '초1~고3 (드롭다운)'),
        StoryboardElement(type: 'ui', label: '단원 선택', detail: '학년별 단원 목록'),
        StoryboardElement(type: 'ui', label: '강의 리스트', detail: '강의명/학제/과목/전체강의수 표시'),
        StoryboardElement(type: 'ui', label: '자동재생 토글', detail: 'ON: 연속 자동 재생'),
      ],
    ),
    StoryboardSlide(
      page: 36, section: '진도학습', title: '학년 선택 팝업',
      description: '예비중(1~6학년) / 중학(1~3학년) / 고등(1~3학년)',
      icon: Icons.school_rounded, color: AppColors.success,
      elements: [
        StoryboardElement(type: 'button', label: '예비중', detail: '예비중 1/2/3/4/5/6학년'),
        StoryboardElement(type: 'button', label: '중학', detail: '중1 / 중2 / 중3'),
        StoryboardElement(type: 'button', label: '고등', detail: '고1 / 고2 / 고3'),
      ],
    ),
    StoryboardSlide(
      page: 37, section: '진도학습', title: '단원 선택 팝업',
      description: '선택된 학년의 단원 목록 표시',
      icon: Icons.list_rounded, color: AppColors.success,
      elements: [
        StoryboardElement(type: 'ui', label: '단원 목록', detail: '번호 + 단원명 리스트'),
        StoryboardElement(type: 'spec', label: '선택 후', detail: '해당 단원 강의 목록으로 이동'),
      ],
    ),
    StoryboardSlide(
      page: 38, section: '진도학습', title: '단원 강의 상세',
      description: '특정 단원의 개념/문제풀이 강의 리스트',
      icon: Icons.play_lesson_rounded, color: AppColors.success,
      elements: [
        StoryboardElement(type: 'ui', label: '강의 목록', detail: '개념강의 + 문제풀이강의 구분'),
        StoryboardElement(type: 'ui', label: '진도 표시', detail: '수강 완료/미완 표시'),
        StoryboardElement(type: 'ui', label: '자동재생', detail: 'ON 시 다음 강의 자동 실행'),
      ],
    ),

    // ────── SECTION 4: 검색 ──────
    StoryboardSlide(
      page: 40, section: '검색', title: '검색 메인',
      description: '검색창 + 학제/과목 필터\n인기 검색어(매일 18:00) / 최근 검색어',
      icon: Icons.search_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'ui', label: '검색창', detail: '텍스트 입력 + 검색 버튼'),
        StoryboardElement(type: 'ui', label: '학제 필터', detail: '예비중/중학/고등'),
        StoryboardElement(type: 'ui', label: '과목 필터', detail: '국어/영어/수학/과학/사회/기타'),
        StoryboardElement(type: 'ui', label: '인기 검색어', detail: '매일 18:00 업데이트, 순위 표시'),
        StoryboardElement(type: 'ui', label: '최근 검색어', detail: '사용자 최근 검색 기록'),
      ],
    ),
    StoryboardSlide(
      page: 41, section: '검색', title: '인기 검색어',
      description: '전체 사용자 기준 인기 키워드 순위\n매일 18:00 자동 업데이트',
      icon: Icons.trending_up_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'spec', label: '업데이트', detail: '매일 18:00 자동 갱신'),
        StoryboardElement(type: 'ui', label: '순위 표시', detail: '1위~순위 번호 + 키워드'),
        StoryboardElement(type: 'spec', label: '순위 변동', detail: '▲상승 / ▼하락 / NEW 표시'),
      ],
    ),
    StoryboardSlide(
      page: 42, section: '검색', title: '최근 검색어 관리',
      description: '개별 삭제 / 전체 삭제',
      icon: Icons.history_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'ui', label: '최근 키워드 목록', detail: '최신 검색어부터 나열'),
        StoryboardElement(type: 'button', label: '개별 삭제', detail: '×버튼으로 개별 제거'),
        StoryboardElement(type: 'button', label: '전체 삭제', detail: '전체 검색 기록 삭제'),
      ],
    ),
    StoryboardSlide(
      page: 44, section: '검색', title: '검색 결과 - 동영상 백과',
      description: '검색어 매칭 강의 목록\n정렬: 평점/최신/이름/과목/관련도',
      icon: Icons.video_library_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'ui', label: '결과 탭', detail: '동영상 백과 / 전문가 상담 / 노트 검색'),
        StoryboardElement(type: 'ui', label: '정렬 옵션', detail: '평점 / 최신 / 이름 / 과목 / 관련도'),
        StoryboardElement(type: 'ui', label: '결과 카드', detail: '썸네일 + 제목 + 강사 + 별점'),
      ],
    ),
    StoryboardSlide(
      page: 45, section: '검색', title: '검색 결과 - 전문가 상담',
      description: '검색어가 포함된 상담 글 목록',
      icon: Icons.support_agent_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'ui', label: '상담 결과 목록', detail: '닉네임 + 날짜 + 답변상태 + 내용'),
        StoryboardElement(type: 'spec', label: '정렬', detail: '관련도 / 최신 순'),
      ],
    ),
    StoryboardSlide(
      page: 46, section: '검색', title: '검색 결과 - 노트 검색',
      description: '검색어가 포함된 노트(교안) 목록',
      icon: Icons.note_alt_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'ui', label: '노트 그리드', detail: '교안 썸네일 목록'),
        StoryboardElement(type: 'spec', label: '탭 동작', detail: '해당 강의의 노트 탭으로 이동'),
      ],
    ),

    // ────── SECTION 5: 전문가 상담 ──────
    StoryboardSlide(
      page: 48, section: '전문가 상담', title: '전문가 상담 목록',
      description: '닉네임 / 날짜 / 답변상태(대기/완료) 표시\n정렬: 최신/조회수/답변완료',
      icon: Icons.support_agent_rounded, color: const Color(0xFF8B5CF6),
      elements: [
        StoryboardElement(type: 'ui', label: '상담 목록', detail: '닉네임 + 날짜 + 답변상태 배지'),
        StoryboardElement(type: 'ui', label: '답변대기 배지', detail: '주황색'),
        StoryboardElement(type: 'ui', label: '답변완료 배지', detail: '초록색'),
        StoryboardElement(type: 'ui', label: '정렬 버튼', detail: '최신 / 조회수 / 답변완료'),
        StoryboardElement(type: 'button', label: '질문 작성 FAB', detail: '우측 하단 + 버튼'),
      ],
    ),
    StoryboardSlide(
      page: 49, section: '전문가 상담', title: '상담 상세 보기',
      description: '질문 내용 + 첨부파일 + 답변 내용',
      icon: Icons.chat_bubble_rounded, color: const Color(0xFF8B5CF6),
      elements: [
        StoryboardElement(type: 'ui', label: '질문 내용', detail: '닉네임 + 날짜 + 본문'),
        StoryboardElement(type: 'ui', label: '첨부 이미지/영상', detail: '첨부파일 미리보기'),
        StoryboardElement(type: 'ui', label: '답변 내용', detail: '전문가 답변 (있는 경우)'),
        StoryboardElement(type: 'ui', label: '답변 대기 안내', detail: '답변 없는 경우 안내 문구'),
      ],
    ),
    StoryboardSlide(
      page: 50, section: '전문가 상담', title: '상담 질문 작성',
      description: '텍스트 + 이미지/동영상 첨부\n카테고리 선택 + 제목 + 내용',
      icon: Icons.edit_note_rounded, color: const Color(0xFF8B5CF6),
      elements: [
        StoryboardElement(type: 'ui', label: '카테고리 선택', detail: '과목/학년 분류'),
        StoryboardElement(type: 'ui', label: '제목 입력', detail: '텍스트 필드'),
        StoryboardElement(type: 'ui', label: '내용 입력', detail: '멀티라인 텍스트'),
        StoryboardElement(type: 'ui', label: '미디어 첨부', detail: '이미지/동영상 첨부 버튼'),
        StoryboardElement(type: 'button', label: '등록 버튼', detail: '상담 글 제출'),
      ],
    ),

    // ────── SECTION 6: 강사별 강의 ──────
    StoryboardSlide(
      page: 53, section: '강사별 강의', title: '강사 목록',
      description: '학제별 탭(예비중/중학/고등) → 강사 그리드',
      icon: Icons.people_rounded, color: AppColors.korean,
      elements: [
        StoryboardElement(type: 'ui', label: '학제 탭', detail: '예비중 / 중학 / 고등'),
        StoryboardElement(type: 'ui', label: '강사 카드', detail: '프로필 사진 + 이름 + 과목 + 강의수'),
        StoryboardElement(type: 'spec', label: '탭 동작', detail: '강사 카드 탭 → 해당 강사 강의 목록'),
      ],
    ),
    StoryboardSlide(
      page: 54, section: '강사별 강의', title: '강사 상세 - 강의 시리즈',
      description: '선택 강사의 시리즈별 강의 목록',
      icon: Icons.person_rounded, color: AppColors.korean,
      elements: [
        StoryboardElement(type: 'ui', label: '강사 프로필', detail: '사진 + 이름 + 학제 + 과목 + 강의수'),
        StoryboardElement(type: 'ui', label: '시리즈 목록', detail: '시리즈명 + 썸네일 + 강의수'),
        StoryboardElement(type: 'button', label: '팔로우', detail: '강사 팔로우/언팔로우'),
      ],
    ),
    StoryboardSlide(
      page: 55, section: '강사별 강의', title: '강사 시리즈 상세',
      description: '특정 시리즈의 전체 강의 목록',
      icon: Icons.playlist_play_rounded, color: AppColors.korean,
      elements: [
        StoryboardElement(type: 'ui', label: '강의 목록', detail: '번호 + 강의명 + 시간'),
        StoryboardElement(type: 'ui', label: '미리보기', detail: '강의 썸네일'),
        StoryboardElement(type: 'spec', label: '탭 동작', detail: '강의 탭 → 플레이어 화면'),
      ],
    ),

    // ────── SECTION 7: 슬라이드 메뉴 ──────
    StoryboardSlide(
      page: 57, section: '슬라이드 메뉴', title: '슬라이드 메뉴 (드로어)',
      description: '상단 우측 햄버거 버튼 탭 → 우측에서 슬라이드\n프로필 + 이용권 + 메뉴 목록',
      icon: Icons.menu_rounded, color: AppColors.textPrimary,
      elements: [
        StoryboardElement(type: 'ui', label: '프로필 헤더', detail: '프로필 사진 + 닉네임 + 이메일'),
        StoryboardElement(type: 'ui', label: '이용권 정보', detail: '회원 유형 + 남은 기간'),
        StoryboardElement(type: 'ui', label: '기간 연장 버튼', detail: '이용권 구매 화면으로 이동'),
        StoryboardElement(type: 'flow', label: '나의 활동', detail: '최근영상/노트/Q&A/상담/즐겨찾기'),
        StoryboardElement(type: 'flow', label: '나의 일정', detail: '캘린더 일정 관리'),
        StoryboardElement(type: 'flow', label: 'miniTutor란?', detail: '앱 소개 화면'),
        StoryboardElement(type: 'flow', label: '공지사항', detail: '공지/이벤트 목록'),
        StoryboardElement(type: 'flow', label: '고객센터', detail: 'FAQ + 1:1 문의'),
        StoryboardElement(type: 'flow', label: '설정', detail: '학년/자막/알림/데이터'),
      ],
    ),
    StoryboardSlide(
      page: 58, section: '슬라이드 메뉴', title: '회원 정보 수정',
      description: '닉네임 / 이메일 / 프로필 사진 편집',
      icon: Icons.edit_rounded, color: AppColors.textPrimary,
      elements: [
        StoryboardElement(type: 'ui', label: '프로필 사진', detail: '카메라/갤러리에서 선택'),
        StoryboardElement(type: 'ui', label: '닉네임 변경', detail: '텍스트 입력'),
        StoryboardElement(type: 'ui', label: '이메일 변경', detail: '이메일 입력'),
        StoryboardElement(type: 'button', label: '저장 버튼', detail: '변경사항 저장'),
      ],
    ),
    StoryboardSlide(
      page: 59, section: '슬라이드 메뉴', title: '이용권 구매',
      description: '이용권 종류 선택 → 스토어 결제',
      icon: Icons.card_membership_rounded, color: const Color(0xFFF59E0B),
      elements: [
        StoryboardElement(type: 'ui', label: '이용권 목록', detail: '1개월/3개월/6개월/12개월'),
        StoryboardElement(type: 'ui', label: '가격 표시', detail: '가격 + 할인율'),
        StoryboardElement(type: 'button', label: '구매하기', detail: '앱스토어/플레이스토어 결제'),
        StoryboardElement(type: 'ui', label: '결제 내역', detail: '구매 이력 확인'),
      ],
    ),

    // ────── SECTION 8: 나의 활동 ──────
    StoryboardSlide(
      page: 62, section: '나의 활동', title: '나의 활동 - 최근 본 영상',
      description: '시청한 강의 목록 + 정렬 + 전체 삭제',
      icon: Icons.history_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'ui', label: '시청 목록', detail: '썸네일 + 강의명 + 날짜'),
        StoryboardElement(type: 'ui', label: '정렬', detail: '최근/평점/이름 순'),
        StoryboardElement(type: 'button', label: '전체 삭제', detail: '시청 기록 전체 삭제'),
        StoryboardElement(type: 'button', label: '개별 삭제', detail: '스와이프 또는 롱프레스'),
      ],
    ),
    StoryboardSlide(
      page: 63, section: '나의 활동', title: '나의 활동 - 노트 목록',
      description: '저장된 필기 노트 목록\n강의로 이동 / 삭제 / 미리보기',
      icon: Icons.note_alt_rounded, color: AppColors.korean,
      elements: [
        StoryboardElement(type: 'ui', label: '노트 카드', detail: '과목컬러 + 강의명 + 필기 미리보기'),
        StoryboardElement(type: 'ui', label: '날짜/필기량', detail: '저장 날짜 + 필기 획 수'),
        StoryboardElement(type: 'button', label: '노트 열기', detail: '해당 강의 교안으로 이동'),
        StoryboardElement(type: 'button', label: '삭제', detail: '노트 삭제'),
      ],
    ),
    StoryboardSlide(
      page: 64, section: '나의 활동', title: '나의 활동 - 강의 Q&A',
      description: '내가 작성한 질문 목록 + 답변 확인',
      icon: Icons.question_answer_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'ui', label: 'Q&A 목록', detail: '강의명 + 질문 내용 + 답변 상태'),
        StoryboardElement(type: 'ui', label: '답변 상태', detail: '답변대기(주황) / 답변완료(초록)'),
        StoryboardElement(type: 'spec', label: '탭 동작', detail: '탭 → 해당 강의 Q&A 탭으로 이동'),
      ],
    ),
    StoryboardSlide(
      page: 65, section: '나의 활동', title: '나의 활동 - 전문가 상담',
      description: '내가 작성한 전문가 상담 목록',
      icon: Icons.support_agent_rounded, color: const Color(0xFF8B5CF6),
      elements: [
        StoryboardElement(type: 'ui', label: '상담 목록', detail: '제목 + 날짜 + 답변 상태'),
        StoryboardElement(type: 'spec', label: '탭 동작', detail: '탭 → 상담 상세 화면'),
      ],
    ),
    StoryboardSlide(
      page: 66, section: '나의 활동', title: '나의 활동 - 즐겨찾기',
      description: '즐겨찾기한 강의 목록\n북마크 해제 가능',
      icon: Icons.bookmark_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'ui', label: '즐겨찾기 목록', detail: '썸네일 + 강의명 + 강사'),
        StoryboardElement(type: 'button', label: '북마크 해제', detail: '북마크 아이콘 탭'),
        StoryboardElement(type: 'spec', label: '탭 동작', detail: '카드 탭 → 강의 플레이어'),
      ],
    ),

    // ────── SECTION 9: 나의 일정 ──────
    StoryboardSlide(
      page: 69, section: '나의 일정', title: '나의 일정 - 달력',
      description: '월별 캘린더 + 날짜별 일정 표시\n개인 일정 + 2공 행사/이벤트',
      icon: Icons.calendar_month_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'ui', label: '월 달력', detail: '월 네비게이션 + 날짜 그리드'),
        StoryboardElement(type: 'ui', label: '일정 점 표시', detail: '일정 있는 날짜에 색상 점'),
        StoryboardElement(type: 'ui', label: '선택 날짜 일정', detail: '달력 하단 해당일 일정 목록'),
        StoryboardElement(type: 'ui', label: 'miniTutor 이벤트 탭', detail: 'miniTutor 공식 행사/이벤트'),
      ],
    ),
    StoryboardSlide(
      page: 70, section: '나의 일정', title: '일정 추가',
      description: '제목 / 내용 / 날짜/시간 / 알림 / 반복 설정',
      icon: Icons.add_circle_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'ui', label: '제목 입력', detail: '일정 제목'),
        StoryboardElement(type: 'ui', label: '내용 입력', detail: '상세 내용'),
        StoryboardElement(type: 'ui', label: '날짜/시간 선택', detail: '달력 + 시간 피커'),
        StoryboardElement(type: 'ui', label: '알림 설정', detail: '정시/10분전/30분전/1시간전/1일전/1주전'),
        StoryboardElement(type: 'ui', label: '반복 설정', detail: '없음/매일/매주/매월/매년'),
        StoryboardElement(type: 'ui', label: '색상 선택', detail: '과목별 색상 팔레트'),
      ],
    ),
    StoryboardSlide(
      page: 75, section: '나의 일정', title: '일정 수정 / 삭제',
      description: '기존 일정 수정 및 삭제',
      icon: Icons.edit_calendar_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'button', label: '수정', detail: '일정 상세 화면에서 수정'),
        StoryboardElement(type: 'button', label: '삭제', detail: '단일 삭제 / 반복 일정 전체 삭제'),
      ],
    ),

    // ────── SECTION 10: 2공이란? ──────
    StoryboardSlide(
      page: 79, section: 'miniTutor란?', title: 'miniTutor 앱 소개',
      description: '2분 공부 컨셉 소개 + 이용 방법',
      icon: Icons.info_rounded, color: AppColors.primary,
      elements: [
        StoryboardElement(type: 'ui', label: '앱 소개 이미지', detail: 'miniTutor 브랜드 스토리'),
        StoryboardElement(type: 'ui', label: '이용 방법', detail: '단계별 사용 가이드'),
        StoryboardElement(type: 'ui', label: '강사 소개', detail: '주요 강사 프로필 이미지'),
      ],
    ),

    // ────── SECTION 11: 공지사항 ──────
    StoryboardSlide(
      page: 83, section: '공지사항', title: '공지사항 목록',
      description: '일반 공지 / 이벤트 구분 탭\n카테고리 필터 + NEW 배지',
      icon: Icons.campaign_rounded, color: AppColors.warning,
      elements: [
        StoryboardElement(type: 'ui', label: '탭', detail: '공지사항 / 이벤트'),
        StoryboardElement(type: 'ui', label: '카테고리 필터', detail: '공지/업데이트/이벤트/정책'),
        StoryboardElement(type: 'ui', label: '공지 카드', detail: '카테고리배지 + NEW배지 + 제목 + 날짜'),
        StoryboardElement(type: 'ui', label: '고정글 핀', detail: '📌 중요 공지 상단 고정'),
      ],
    ),
    StoryboardSlide(
      page: 84, section: '공지사항', title: '공지 상세',
      description: '제목 + 날짜 + 본문 내용\n공유 버튼',
      icon: Icons.article_rounded, color: AppColors.warning,
      elements: [
        StoryboardElement(type: 'ui', label: '헤더 카드', detail: '카테고리 + NEW + 제목 + 날짜'),
        StoryboardElement(type: 'ui', label: '본문', detail: '전체 공지 내용 (줄바꿈 지원)'),
        StoryboardElement(type: 'button', label: '공유', detail: '링크 공유'),
        StoryboardElement(type: 'button', label: '목록으로', detail: '목록 화면 복귀'),
      ],
    ),
    StoryboardSlide(
      page: 85, section: '공지사항', title: '이벤트 탭',
      description: '진행 중인 이벤트 카드 (그라데이션 디자인)',
      icon: Icons.celebration_rounded, color: AppColors.accent,
      elements: [
        StoryboardElement(type: 'ui', label: '이벤트 카드', detail: '그라데이션 배경 + 이벤트명'),
        StoryboardElement(type: 'ui', label: '이벤트 기간', detail: '시작일~종료일'),
        StoryboardElement(type: 'button', label: '자세히 보기', detail: '이벤트 상세 화면'),
      ],
    ),

    // ────── SECTION 12: 고객센터 ──────
    StoryboardSlide(
      page: 86, section: '고객센터', title: 'FAQ - 자주 묻는 질문',
      description: '카테고리 필터 + 드롭다운 Q&A',
      icon: Icons.help_rounded, color: AppColors.success,
      elements: [
        StoryboardElement(type: 'ui', label: '카테고리 필터', detail: '전체/이용방법/결제/계정/강의/기술'),
        StoryboardElement(type: 'ui', label: 'FAQ 카드', detail: 'Q 아이콘 + 질문 + 드롭다운'),
        StoryboardElement(type: 'ui', label: '답변 영역', detail: 'A 아이콘 + 답변 내용 (펼침)'),
        StoryboardElement(type: 'ui', label: '카테고리 배지', detail: '해당 FAQ 카테고리 표시'),
      ],
    ),
    StoryboardSlide(
      page: 87, section: '고객센터', title: '1:1 문의 목록',
      description: '내 문의 내역 + 답변 상태',
      icon: Icons.mail_rounded, color: AppColors.success,
      elements: [
        StoryboardElement(type: 'ui', label: '문의 카드', detail: '카테고리 + 제목 + 내용 미리보기'),
        StoryboardElement(type: 'ui', label: '답변 상태', detail: '답변대기(주황) / 답변완료(초록)'),
        StoryboardElement(type: 'ui', label: '평균 답변 시간', detail: '영업일 기준 1~2일'),
        StoryboardElement(type: 'button', label: '문의 작성하기', detail: '새 1:1 문의 작성'),
      ],
    ),
    StoryboardSlide(
      page: 88, section: '고객센터', title: '1:1 문의 상세',
      description: '문의 내용 + 2공 고객센터 답변',
      icon: Icons.question_answer_rounded, color: AppColors.success,
      elements: [
        StoryboardElement(type: 'ui', label: '문의 내용', detail: '카테고리 + 제목 + 내용'),
        StoryboardElement(type: 'ui', label: '답변 카드', detail: 'miniTutor 고객센터 답변 + 날짜'),
        StoryboardElement(type: 'ui', label: '미답변 안내', detail: '답변 대기 중 안내 문구'),
      ],
    ),
    StoryboardSlide(
      page: 89, section: '고객센터', title: '1:1 문의 작성',
      description: '문의 유형 선택 + 제목 + 내용 입력',
      icon: Icons.edit_rounded, color: AppColors.success,
      elements: [
        StoryboardElement(type: 'ui', label: '문의 유형', detail: '이용방법/장애·오류/결제/강의요청/기타'),
        StoryboardElement(type: 'ui', label: '제목 입력', detail: '문의 제목'),
        StoryboardElement(type: 'ui', label: '내용 입력', detail: '상세 내용 (멀티라인)'),
        StoryboardElement(type: 'spec', label: '이미지 첨부', detail: '앱에서 지원 (웹 미지원)'),
        StoryboardElement(type: 'button', label: '문의 등록', detail: '접수 후 알림'),
      ],
    ),

    // ────── SECTION 13: 설정 ──────
    StoryboardSlide(
      page: 90, section: '설정', title: '앱 설정',
      description: '기본 학년/과목 / 자막 / 모바일 데이터 / 푸시 알림',
      icon: Icons.settings_rounded, color: AppColors.textSecondary,
      elements: [
        StoryboardElement(type: 'ui', label: '기본 학년/과목', detail: '앱 시작 시 기본 표시 학년·과목 설정'),
        StoryboardElement(type: 'ui', label: '자막 기본 표시', detail: 'ON/OFF 스위치'),
        StoryboardElement(type: 'ui', label: '모바일 데이터 재생', detail: 'ON: 모바일 데이터로 영상 재생 허용'),
        StoryboardElement(type: 'ui', label: '푸시 알림', detail: '카테고리별 알림 ON/OFF'),
      ],
    ),
    StoryboardSlide(
      page: 91, section: '설정', title: '이용약관 / 개인정보처리방침',
      description: '이용약관 및 개인정보처리방침 전문',
      icon: Icons.description_rounded, color: AppColors.textSecondary,
      elements: [
        StoryboardElement(type: 'ui', label: '이용약관', detail: '전문 스크롤 뷰'),
        StoryboardElement(type: 'ui', label: '개인정보처리방침', detail: '전문 스크롤 뷰'),
      ],
    ),
  ];
}

// ─── 스토리보드 뷰어 화면 ────────────────────────────────
class StoryboardViewerScreen extends StatefulWidget {
  const StoryboardViewerScreen({super.key});

  @override
  State<StoryboardViewerScreen> createState() => _StoryboardViewerScreenState();
}

class _StoryboardViewerScreenState extends State<StoryboardViewerScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  String _selectedSection = '전체';
  bool _showThumbnails = false;

  late List<StoryboardSlide> _allSlides;
  List<StoryboardSlide> get _filteredSlides => _selectedSection == '전체'
      ? _allSlides
      : _allSlides.where((s) => s.section == _selectedSection).toList();

  List<String> get _sections {
    final sections = <String>{'전체'};
    for (final s in _allSlides) { sections.add(s.section); }
    return sections.toList();
  }

  @override
  void initState() {
    super.initState();
    _allSlides = StoryboardData.slides;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _filteredSlides;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('miniTutor 스토리보드', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('${_currentPage + 1} / ${slides.length}슬라이드',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
        ]),
        actions: [
          // 썸네일 토글
          IconButton(
            icon: Icon(_showThumbnails ? Icons.view_carousel_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _showThumbnails = !_showThumbnails),
          ),
          // 섹션 필터
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (s) {
              setState(() {
                _selectedSection = s;
                _currentPage = 0;
              });
              _pageController.jumpToPage(0);
            },
            itemBuilder: (_) => _sections.map((s) => PopupMenuItem(
              value: s,
              child: Row(children: [
                if (_selectedSection == s)
                  const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(s),
              ]),
            )).toList(),
          ),
        ],
      ),
      body: _showThumbnails
          ? _buildThumbnailGrid(slides)
          : _buildSlideView(slides),
      // 하단 네비게이션
      bottomNavigationBar: _showThumbnails ? null : _buildBottomNav(slides),
    );
  }

  Widget _buildSlideView(List<StoryboardSlide> slides) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemCount: slides.length,
      itemBuilder: (_, i) => _buildSlide(slides[i]),
    );
  }

  Widget _buildSlide(StoryboardSlide slide) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B),
            Color.lerp(const Color(0xFF1E293B), slide.color, 0.15)!,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // 섹션 배지 + 페이지 번호
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: slide.color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: slide.color.withValues(alpha: 0.5)),
                ),
                child: Text(slide.section,
                    style: TextStyle(fontSize: 11, color: slide.color, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('p.${slide.page}',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 16),

            // 아이콘 + 제목
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: slide.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: slide.color.withValues(alpha: 0.4)),
                ),
                child: Icon(slide.icon, color: slide.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(slide.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2))),
            ]),
            const SizedBox(height: 14),

            // 설명
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(slide.description,
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), height: 1.6)),
            ),
            const SizedBox(height: 16),

            // 요소 목록
            if (slide.elements.isNotEmpty) ...[
              _buildElementsSection(slide),
              const SizedBox(height: 12),
            ],

            // 노트 (스토리보드 특이사항)
            if (slide.note != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(slide.note!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFFBBF24), height: 1.5))),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildElementsSection(StoryboardSlide slide) {
    // 버튼형 요소들
    final buttons = slide.elements.where((e) => e.type == 'button').toList();
    // 나머지 요소들
    final others = slide.elements.where((e) => e.type != 'button').toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // UI / SPEC / FLOW 요소
      if (others.isNotEmpty) ...[
        ...others.map((e) => _buildElementRow(e, slide.color)),
        if (buttons.isNotEmpty) const SizedBox(height: 10),
      ],
      // 버튼 요소 (가로 Wrap)
      if (buttons.isNotEmpty) ...[
        Text('버튼 / 기능',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: buttons.map((b) => _buildButtonChip(b, slide.color)).toList()),
      ],
    ]);
  }

  Widget _buildElementRow(StoryboardElement e, Color slideColor) {
    Color typeColor;
    String typeLabel;
    switch (e.type) {
      case 'ui': typeColor = AppColors.primary; typeLabel = 'UI';
      case 'spec': typeColor = AppColors.success; typeLabel = 'SPEC';
      case 'flow': typeColor = AppColors.accent; typeLabel = 'FLOW';
      case 'screen': typeColor = AppColors.warning; typeLabel = 'SCR';
      default: typeColor = AppColors.textSecondary; typeLabel = '•';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (e.icon != null)
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: (e.color ?? typeColor).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6)),
            child: Icon(e.icon, size: 16, color: e.color ?? typeColor),
          )
        else
          Container(
            margin: const EdgeInsets.only(right: 8, top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4)),
            child: Text(typeLabel,
                style: TextStyle(fontSize: 9, color: typeColor, fontWeight: FontWeight.w800)),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            if (e.detail != null) ...[
              const SizedBox(height: 2),
              Text(e.detail!,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55), height: 1.4)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildButtonChip(StoryboardElement b, Color slideColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (b.color ?? slideColor).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (b.color ?? slideColor).withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (b.icon != null) ...[
          Icon(b.icon, size: 14, color: b.color ?? slideColor),
          const SizedBox(width: 5),
        ],
        Text(b.label,
            style: TextStyle(fontSize: 12, color: b.color ?? slideColor, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildBottomNav(List<StoryboardSlide> slides) {
    final progress = slides.isEmpty ? 0.0 : (_currentPage + 1) / slides.length;
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // 진행 바
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
                slides.isNotEmpty ? slides[_currentPage].color : AppColors.primary),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 10),
        // 이전 / 슬라이드명 / 다음
        Row(children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () { _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut); }
                : null,
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: _currentPage > 0 ? Colors.white : Colors.white24, size: 18),
          ),
          Expanded(child: Center(
            child: Text(
              slides.isNotEmpty ? slides[_currentPage].title : '',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          )),
          IconButton(
            onPressed: _currentPage < slides.length - 1
                ? () { _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut); }
                : null,
            icon: Icon(Icons.arrow_forward_ios_rounded,
                color: _currentPage < slides.length - 1 ? Colors.white : Colors.white24, size: 18),
          ),
        ]),
      ]),
    );
  }

  Widget _buildThumbnailGrid(List<StoryboardSlide> slides) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: slides.length,
      itemBuilder: (_, i) {
        final s = slides[i];
        final isCurrent = i == _currentPage;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentPage = i;
              _showThumbnails = false;
            });
            _pageController.jumpToPage(i);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF1E293B), s.color, 0.2)!,
                  Color.lerp(const Color(0xFF0F172A), s.color, 0.1)!,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent ? s.color : Colors.white.withValues(alpha: 0.1),
                width: isCurrent ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text(s.section,
                      style: TextStyle(fontSize: 9, color: s.color, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text('p.${s.page}',
                    style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
              ]),
              const SizedBox(height: 8),
              Icon(s.icon, color: s.color, size: 26),
              const SizedBox(height: 6),
              Text(s.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(s.description,
                  style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5), height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      },
    );
  }
}

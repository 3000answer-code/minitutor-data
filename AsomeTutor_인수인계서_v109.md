# 어썸튜터 (Asome Tutor) — 전체 인수인계서
> 작성일: 2026년 4월 18일 | 최종 버전: v109 | 총 111개 커밋

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **앱 이름** | 어썸튜터 (Asome Tutor) |
| **슬로건** | 매일 2분, 쌓이는 실력. 짧고 강한 강의 플랫폼 |
| **플랫폼** | Android (Flutter) + Web 미리보기 |
| **패키지명** | `com.asometutor.study` |
| **pubspec 앱명** | `asometutor` |
| **버전** | 3.60.0+1 (pubspec) |
| **개발 기간** | 2026.03.30 ~ 2026.04.18 (20일간) |
| **총 커밋 수** | 111개 (v001 ~ v109) |
| **총 소스 코드** | 31,675줄 (Dart 49개 파일) |
| **에셋 파일** | 111개 (교안 이미지, 배너, 아이콘 등) |
| **개발 환경** | Flutter 3.35.4 / Dart 3.9.2 / Java OpenJDK 17 |

---

## 2. 소스코드 위치

| 위치 | 설명 |
|------|------|
| **GitHub** | https://github.com/3000answer-code/minitutor-data |
| **강의 데이터 JSON** | https://raw.githubusercontent.com/3000answer-code/asometutor-data/main/lectures.json |
| **소스 ZIP** | AsomeTutor_v109_source.zip (23MB, 순수 소스만) |

---

## 3. 개발 환경 세팅

```bash
# 1. Flutter SDK 설치 (3.35.4)
# 2. 소스 클론
git clone https://github.com/3000answer-code/minitutor-data
cd minitutor-data

# 3. 의존성 설치
flutter pub get

# 4. 실행 (디버그)
flutter run

# 5. 릴리즈 APK 빌드
flutter build apk --release
# 결과물: build/app/outputs/flutter-apk/app-release.apk
```

### 키스토어 (릴리즈 서명)
- 위치: `android/release-key.jks`
- 설정: `android/key.properties`
- **이 두 파일은 반드시 안전하게 보관 (분실 시 Play Store 업데이트 불가)**

---

## 4. 프로젝트 구조

```
flutter_app/
├── lib/                              # 소스코드 (31,675줄)
│   ├── main.dart                     # 앱 진입점, 하단 탭 네비게이션, PIP 오버레이 (1,219줄)
│   ├── config.dart                   # 환경 설정 (구글 드라이브 ↔ AWS 전환) (43줄)
│   ├── models/                       # 데이터 모델 (577줄)
│   │   ├── lecture.dart              # 강의 모델 (핵심) (226줄)
│   │   ├── instructor.dart           # 강사 모델 (34줄)
│   │   ├── note.dart                 # 노트 모델 (126줄)
│   │   ├── personal_qa.dart          # 개인 Q&A 모델 (93줄)
│   │   ├── study_progress.dart       # 학습 진도 모델 (55줄)
│   │   └── consultation.dart         # 상담 모델 (43줄)
│   ├── screens/                      # 화면 (23,441줄)
│   │   ├── home/
│   │   │   ├── home_screen.dart              # 홈 화면 (추천/인기/과목별) (1,767줄)
│   │   │   └── category_lecture_screen.dart   # 카테고리별 강의 (1,218줄)
│   │   ├── lecture/
│   │   │   ├── lecture_player_screen.dart     # ★ 핵심: 강의 영상 플레이어 (5,179줄)
│   │   │   ├── drive_video_player_screen.dart # 드라이브 영상 플레이어 (459줄)
│   │   │   └── note_canvas_screen.dart       # 노트 필기 캔버스 (514줄)
│   │   ├── search/
│   │   │   ├── search_screen.dart            # 검색 화면 (1,913줄)
│   │   │   └── note_search_viewer_screen.dart # 노트 검색 뷰어 (887줄)
│   │   ├── progress/
│   │   │   └── progress_screen.dart          # 학습 진도/통계 (1,338줄)
│   │   ├── curriculum/
│   │   │   └── curriculum_screen.dart        # 진도학습 (1,038줄)
│   │   ├── instructor/
│   │   │   └── instructor_screen.dart        # 강사 소개+시리즈 (683줄)
│   │   ├── consultation/
│   │   │   └── consultation_screen.dart      # Q&A 게시판 (804줄)
│   │   ├── profile/
│   │   │   ├── my_activity_screen.dart       # 나의 활동 (1,211줄)
│   │   │   ├── my_note_viewer_screen.dart    # 내 노트 뷰어 (861줄)
│   │   │   ├── profile_drawer.dart           # 사이드 프로필 드로어 (478줄)
│   │   │   ├── settings_screen.dart          # 설정 화면
│   │   │   └── store_screen.dart             # 스토어 화면
│   │   ├── admin/
│   │   │   └── admin_lecture_screen.dart      # 관리자 강의 관리 (749줄)
│   │   ├── auth/
│   │   │   └── login_screen.dart             # 로그인 화면
│   │   ├── language/
│   │   │   └── language_select_screen.dart    # 언어 선택 (첫 화면)
│   │   ├── notice/
│   │   │   └── notice_screen.dart            # 공지사항 (595줄)
│   │   ├── schedule/
│   │   │   └── schedule_screen.dart          # 시간표 (578줄)
│   │   ├── storyboard/
│   │   │   └── storyboard_viewer_screen.dart # 스토리보드 뷰어 (1,193줄)
│   │   └── support/
│   │       └── support_screen.dart           # 고객지원 (531줄)
│   ├── services/                      # 비즈니스 로직 (5,465줄)
│   │   ├── api_service.dart           # ★ 강의 데이터 로드 (내장+GitHub JSON) (851줄)
│   │   ├── app_state.dart             # 앱 전역 상태 (Provider) (765줄)
│   │   ├── auth_service.dart          # 인증 서비스 (389줄)
│   │   ├── content_service.dart       # 콘텐츠 서비스 (116줄)
│   │   ├── data_service.dart          # 로컬 데이터 서비스 (187줄)
│   │   ├── instructor_service.dart    # 강사 데이터 (167줄)
│   │   ├── note_repository.dart       # 노트 저장소 (Hive) (107줄)
│   │   ├── problem_bank.dart          # 문제은행 (88문제) (1,636줄)
│   │   └── translations.dart          # 다국어 번역 (한/영) (1,247줄)
│   ├── widgets/                       # 재사용 위젯
│   │   ├── lecture_card.dart          # ★ 강의 카드 위젯 (공통)
│   │   ├── common_app_bar.dart        # 공통 앱바
│   │   ├── drive_web_player.dart      # 드라이브 웹 플레이어
│   │   └── eraser_widgets.dart        # 지우개 위젯
│   ├── theme/
│   │   └── app_theme.dart             # ★ 앱 전체 색상/테마 (AppColors)
│   └── utils/
│       ├── web_speech_stub.dart       # 웹 음성 스텁
│       └── web_speech_web.dart        # 웹 음성 구현
├── assets/
│   ├── handouts/                      # 강의 교안 이미지 (67개+ PNG)
│   ├── icons/                         # 앱 아이콘
│   ├── images/                        # 배너/배경 이미지
│   │   ├── banners/                   # 홈 배너 이미지
│   │   └── subjects/                  # 과목별 이미지
├── android/
│   ├── app/
│   │   ├── build.gradle.kts           # Android 빌드 설정 (com.asometutor.study)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/asometutor/study/MainActivity.kt
│   ├── release-key.jks                # ★ 릴리즈 서명 키 (보안 중요)
│   └── key.properties                 # ★ 키스토어 비밀번호 (보안 중요)
├── pubspec.yaml                       # 패키지 의존성
└── web/                               # 웹 미리보기 설정
```

---

## 5. 앱 화면 구조

### 5-1. 하단 탭 네비게이션 (5개)

```
① 홈 (Home)           → home_screen.dart       추천/인기/수학/과학/두번설명 탭
② 진도학습 (Progress)   → progress_screen.dart   학습 통계 + 기간별 그래프
③ 진도학습 (Curriculum) → curriculum_screen.dart  수학/과학 교과서 단원별 강의
④ 검색 (Search)        → search_screen.dart      강의/노트 검색 + Q&A 키워드 연동
⑤ Q&A                 → consultation_screen.dart Q&A 게시판 (질문/답변)
```

### 5-2. 상단 메뉴

```
좌: 프로필 드로어 (사이드바)
  ├── 나의 활동 (최근 본 강의 / 내 노트 / 나의 Q&A) - 3개 탭
  ├── 시간표
  ├── 강사
  ├── 공지사항
  ├── 고객지원
  ├── 스토어
  └── 설정

우: 알림 벨 아이콘 → 알림 바텀시트
```

### 5-3. 강의 플레이어 화면 (lecture_player_screen.dart - 5,179줄)

앱의 가장 핵심적인 화면입니다.

**레이아웃 모드:**

| 모드 | 설명 | 전환 방법 |
|------|------|-----------|
| **세로화면** (기본) | 영상 + 탭(노트/Q&A/재생목록/문제풀이) | 기본 |
| **가로화면 + 사이드패널** | 왼쪽 영상 50% + 오른쪽 탭 50% | 영상 우하단 회전 버튼 |
| **전체화면** | 영상만 풀스크린 | 영상 우하단 전체화면 버튼 |
| **PIP (미니플레이어)** | 화면 위 떠다니는 소형 플레이어 | 해시태그 터치 시 자동 |

**플레이어 내 탭 (4개):**
```
① 노트 보기   — 교안 슬라이드 이미지 뷰어 + 필기(5색 펜, 지우개)
② 강의 Q&A   — 질문/답변 게시판 (키워드 필터링)
③ 재생 목록  — 시리즈 강의 목록 (가로모드에서도 강의 전환 시 가로 유지)
④ 문제풀이   — 관련 문제 풀기 (ProblemBank 88문제)
```

**주요 State 변수:**
```dart
bool _isLandscape          // 가로화면 모드
bool _isFullScreen         // 전체화면 모드
bool _isMiniPlayer         // PIP 미니플레이어 모드
bool _isMetaBarCollapsed   // 세로화면 강의정보 접힘/펼침
bool _showControls         // 재생 컨트롤 표시 여부
bool _webViewLoading       // WebView 로딩 중 여부
double _playbackSpeed      // 재생 속도 (0.5/0.75/1.0/1.25/1.5/2.0)
bool _keepLandscapeOnDispose // 가로모드 강의 전환 시 가로 유지 플래그
```

---

## 6. 핵심 서비스 설명

### 6-1. api_service.dart — 강의 데이터 관리 ★★★

강의 데이터는 **두 가지 소스**에서 로드:

```
우선순위 1: GitHub Raw JSON (원격 업데이트)
  → https://raw.githubusercontent.com/3000answer-code/asometutor-data/main/lectures.json

우선순위 2: 앱 내장 번들 데이터 (_bundledLectures)
  → api_service.dart 파일 내 하드코딩된 강의 목록
```

**강의 추가 방법:**
1. `asometutor-data` GitHub 저장소의 `lectures.json` 수정
2. 앱 재설치 없이 자동 업데이트

**강의 데이터 형식:**
```json
{
  "id": "gd_twice_001",
  "title": "부분분수 (식, 분해)",
  "subject": "수학",
  "grade": "high",
  "gradeYear": "All",
  "instructor": "강사명",
  "thumbnailUrl": "https://drive.google.com/thumbnail?id=...",
  "videoUrl": "https://drive.google.com/file/d/.../view?usp=sharing",
  "duration": 176,
  "lectureType": "twice",
  "hashtags": ["태그1", "태그2"],
  "series": "시리즈명",
  "uploadDate": "2026-04-10",
  "handoutUrls": ["assets/handouts/파일명.png"]
}
```

### 6-2. app_state.dart — 앱 전역 상태 (Provider)

```dart
// 주요 상태 관리 항목
- 강의 목록 로드/필터링
- PIP (미니플레이어) 활성화/비활성화
- 최근 본 강의 기록 (SharedPreferences)
- 검색 기록 관리
- 언어 설정 (한국어/영어)
- 학습 진도 추적
```

### 6-3. problem_bank.dart — 문제은행

- 총 **88문제** (수학 + 과학)
- 중등: 검전기, 지구의 크기, 이차방정식 등
- 고등: 화학, 생명과학, 지구과학 (수능/내신 수준)
- 난이도 라벨: 상(10%), 중(30%), 하(50%)
- `ProblemBank.getProblems(lectureId)` 로 강의별 문제 연결

### 6-4. translations.dart — 다국어 지원

- 한국어 / 영어 지원
- `T('key')` 함수로 번역된 텍스트 사용
- 언어 선택: `language_select_screen.dart` (앱 첫 화면)

### 6-5. config.dart — 영상 소스 전환

```dart
// 현재: 구글 드라이브
static const Env currentEnv = Env.googleDrive;

// AWS S3 + CloudFront로 전환 시:
// 1. currentEnv = Env.aws
// 2. _awsBase = 'https://실제주소.cloudfront.net'
// 3. api_service.dart의 videoUrl을 AWS URL로 교체
```

---

## 7. 색상 테마 (app_theme.dart)

```dart
class AppColors {
  // 학제 배지 색상
  static const elementary = Color(0xFF34D399);  // 예비중 - 민트 그린
  static const middle     = Color(0xFF059669);  // 중등 - 에메랄드 그린
  static const high       = Color(0xFFA78BFA);  // 고등 - 보라

  // 해시태그 색상 (통일)
  // 배경: #EEF4FF, 테두리: #C3D4F0, 텍스트: #5E8ED6

  // 기본 강조색
  static const orange = Color(0xFFFF6B00);  // 주황
}
```

---

## 8. 패키지 의존성

```yaml
provider: 6.1.5+1          # 상태 관리
go_router: 14.8.1           # 라우팅
shared_preferences: 2.5.3   # 로컬 키-값 저장
hive: 2.2.3                 # 로컬 DB (노트 저장)
hive_flutter: 1.1.0         # Hive Flutter 통합
http: 1.5.0                 # HTTP 통신 (강의 JSON 로드)
cached_network_image: 3.4.1 # 이미지 캐싱 (썸네일)
shimmer: 3.0.0              # 로딩 스켈레톤 효과
flutter_rating_bar: 4.0.1   # 평점 바
percent_indicator: 4.2.3    # 진도 표시 바
fl_chart: 0.71.0            # 차트 (진도 분석 그래프)
video_player: 2.9.5         # 비디오 플레이어 (백업용)
chewie: 1.8.5               # 비디오 UI 래퍼
webview_flutter: 4.13.0     # ★ WebView (영상 재생 핵심)
webview_flutter_android: 4.10.15  # WebView Android 네이티브
iconsax: 0.0.8              # 아이콘 팩
intl: 0.19.0                # 날짜/숫자 형식
url_launcher: 6.3.1         # 외부 URL 열기
```

---

## 9. 전체 개발 이력 (v001 ~ v109)

### Phase 1: 초기 개발 (2026.03.30 ~ 03.31)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| 초기 | 03.30 | 이공(2공) 서비스 전체 코드 저장 - Flutter 앱 v2.3.0 + 어드민 웹 |
| v2.8.0 | 03.31 | YouTube 재생 완전 수정 (Android 11+ 호환, intent queries 추가) |
| v2.9.0 | 03.31 | **Google Drive 전용 전환** (YouTube 완전 제거) |

### Phase 2: UI 전면 개편 + 브랜드 전환 (2026.04.13 ~ 04.14)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| APK68 | 04.13 | 내상담 용어 변경, 검색탭 수정, translations 오류 수정 |
| APK69 | 04.13 | **Asome Tutor 브랜드 전환** (패키지명, 아이콘, 앱이름 전체 변경) |
| v010 | 04.13 | 배너 이미지 교체, 과학 카테고리, 교과서 파스텔톤 카드 |
| v011 | 04.13 | 추천/인기 탭 강의 목록 개편 (NEW/HOT 세로 리스트 카드) |
| v015 | 04.14 | **LectureCard 공통 위젯 통일** (모든 화면 동일 형식) |
| v016 | 04.14 | 앱 종료 다이얼로그 UI 개선 |
| v017 | 04.14 | 최근 본 강의 추천탭 연결, 가로스크롤 카드 |
| v018 | 04.14 | 수학탭 헤더배너, 교재화면 과목별 배너 |
| v019 | 04.14 | **영상 플레이어 UI 전면 개편** (아이보리 배경, 탭 균등, 전체화면 버튼 이동) |
| v020 | 04.14 | 교안 67개 전체 크롭 확대 (오른쪽30%+아래28% → 가독성 개선) |
| v021 | 04.14 | 교안 크롭 최종 적용, 버전 코드 21 |

### Phase 3: 가로화면 + 재생 기능 강화 (2026.04.15)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| v022 | 04.15 | **가로화면 + 사이드패널 모드 추가** (영상+노트/Q&A/재생목록/문제풀이) |
| v025 | 04.15 | 패키지명 통일 + 영상 로딩 속도 개선 (WebView 캐시, 자동재생) |
| v026 | 04.15 | 가로/전체화면 일시정지 버튼 수정 |
| v027 | 04.15 | B강의 버튼/Drive 플레이 버튼 삭제, CC-1x 가로전체화면 추가 |
| v028 | 04.15 | CC버튼 삭제, 해시태그 색 통일 (#5E8ED6), 중등 배지색 변경 |
| v029 | 04.15 | 중등 배지 에메랄드 그린 통일, 속도 팝업 컴팩트화 |
| v030 | 04.15 | 세로화면 속도버튼 주황 강조, 가로화면 강의정보 항상 표시 |
| v031 | 04.15 | 속도팝업 시스템바 겹침 수정, 가로화면 세로전환 버튼 |

### Phase 4: 노트/검색/카드 UI 정교화 (2026.04.15)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| v032 | 04.15 | 홈화면 검색수 자동 집계 (SharedPrefs 저장) |
| v033 | 04.15 | 진도학습 배너 사진 교체, 기간별 그래프 명품 스타일 리디자인 |
| v034 | 04.15 | **내노트 FAB + 노트뷰어 미니플레이어** (이전/다음 강의 이동) |
| v035 | 04.15 | 내노트 FAB 소형화, 인라인 교안 슬라이드업 |
| v036 | 04.15 | **필기 버그 수정** (다중 페이지 동시 필기 해결) |
| v037 | 04.15 | 강의카드 3줄 표시 (시리즈+배지+강사) |
| v038 | 04.15 | 노트검색 카드 3줄 (시리즈/학년배지/강사) |

### Phase 5: PIP + 강사 + 브랜드 확정 (2026.04.15 ~ 04.16)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| v052 | 04.15 | **PIP UI 개선**: 닫기/재생 하단 정보바 이동, 중복호출 방지 |
| v053 | 04.15 | **강사탭 학제별 분리**: 예비중/중등(전체/수학/과학), 고등(+물리/화학/생명과학/지구과학) |
| v054~055 | 04.16 | 가로화면 흰색배경+스크롤힌트, 세로화면 원상복구 |
| v056 | 04.16 | **Release APK 빌드** (com.asometutor.study / Asome Tutor 확정) |
| v057 | 04.16 | 앱 이름 최종 수정: Tutor Express → Asome Tutor |
| v058~059 | 04.16 | **필기 3종 통합**: 펜 5색 통일, 떨림 완전 제거 (NeverScrollable) |
| v060 | 04.16 | **근본 수정**: com.asometutor.study 전체 통일 (build.gradle/Manifest/MainActivity) |
| v061~064 | 04.16 | **PIP 버그 완전 수정**: 모든 화면에서 PIP 정상 작동, Navigator 최상단 렌더링 |
| v065 | 04.16 | 5개 강의 교안 추가, 앱이름/패키지명 완전 통일 |
| v066 | 04.16 | 교안 순서 수정 (p1↔p2 swap) |
| v067 | 04.16 | **520 스타일 통합**: 노트검색/내노트/LectureCard 강의 안내 규칙 통일 |

### Phase 6: 검색/진도/언어/교과서 정교화 (2026.04.16)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| v068 | 04.16 | 검색 화면: 인기/최근 검색어 중앙 정렬 |
| v069 | 04.16 | 진도학습 인기 영상 LectureCard 520 스타일 교체 |
| v070 | 04.16 | 검색 최근검색 헤더, 가로 메모 다이얼로그 크기 축소 |
| v071 | 04.16 | 최근영상 → "최근 본 강의" 명칭 변경, 하단 겹침 해결 |
| v072~073 | 04.16 | 언어선택 첫 화면 균형 배치 (3그룹 Spacer) |
| v074 | 04.16 | 내 노트 뷰어: SnackBar floating 변경 |
| v075 | 04.16 | 검색 인기검색어 번호+단어 Row 중앙 배치 |
| v076~082 | 04.16 | **진도학습(교과서) 탭 정교화**: 수학/과학 탭 중앙 배치, 명칭 변경/복원 |

### Phase 7: 문제은행 대폭 확장 (2026.04.16)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| v083 | 04.16 | 중등 과학 문제 재작성 (검전기, 지구 크기, 이차방정식 9문제 추가) |
| v084 | 04.16 | **고등 과학 문제 전면 재작성** (화학3, 생명과학3, 지구과학3 - 수능/내신 수준) |
| v085 | 04.16 | **문제풀이 연결 완성**: 하드코딩 76문제 제거 → ProblemBank.getProblems() (88문제) |
| v086 | 04.16 | 세제곱 곱셈공식 영상 URL 교체 (720p 재인코딩) |

### Phase 8: 가로화면 강의전환 + 레이아웃 겹침 수정 (2026.04.18)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| v087 | 04.18 | **가로화면 비율 조정**: 영상/사이드패널 50:50 균등, 영상 최대높이 68% |
| v088~090 | 04.18 | **가로화면 강의 전환 시 가로 유지**: startInLandscape 파라미터, _keepLandscapeOnDispose |
| v091 | 04.18 | 나의활동 썸네일 넘침 수정 |
| v092 | 04.18 | **모든 메뉴 카드 겹침 수정**: LectureCard 행 82px 고정, 카드 간격 14px |
| v093 | 04.18 | 나의 활동 하단 패딩 시스템 네비바 높이 반영 |
| v094~095 | 04.18 | **근본 수정**: 시스템 네비게이션 바 겹침 해결 (edgeToEdge→manual, SafeArea) |

### Phase 9: Q&A 전면 개편 (2026.04.18)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| v096 | 04.18 | 상단바 정리, 알림 개선, 나의 Q&A → 나의 Q&A 답변 |
| v097 | 04.18 | **하단네비 상담→Q&A 변경**, 질문 쓰기/수정/삭제 기능 개선 |
| v098 | 04.18 | Q&A FAB 소형화+그림자, 바텀시트 네비바 겹침 수정 |
| v099 | 04.18 | 4건 수정: 답변대기 빈공간, 질문수정 겹침, 검색→Q&A 키워드 연동 |
| v099a | 04.18 | 동영상탭 Q&A 미니카드 제거 |

### Phase 10: 강사 시리즈 UX + 최종 정리 (2026.04.18)

| 버전 | 날짜 | 주요 내용 |
|------|------|----------|
| v100 | 04.18 | **강사별 강의 시리즈 선택 필터링** + 최대 5개 표시 |
| v101 | 04.18 | 시리즈 전체보기 바텀시트 (시리즈별 그룹화) |
| v102 | 04.18 | 시리즈 강의데이터 직접 추출 (누락 해결) |
| v103~104 | 04.18 | 시리즈 전체보기: 선택된 시리즈 내 강의만 표시 |
| v105 | 04.18 | **가로화면 강의정보를 세로화면과 동일 통일** |
| v106 | 04.18 | 강사카드: 평점/조회수 삭제, 강의수만 표시, 소개문구 간결화 |
| v107 | 04.18 | 나의활동: Q&A 탭 삭제 → 3개 탭으로 정리 |
| v108 | 04.18 | **나의 Q&A 전면 개편**: 질문하기/작성/수정/휴지통 기능 구현 |
| v109 | 04.18 | 강사 시리즈 미선택 시 바텀시트 UX 개선 |

---

## 10. 주요 기능 목록

### 핵심 기능
| 기능 | 설명 | 관련 파일 |
|------|------|-----------|
| **영상 재생** | WebView 기반 구글 드라이브 영상 재생 | lecture_player_screen.dart |
| **가로화면 모드** | 영상 50% + 사이드패널(노트/Q&A/목록/문제) 50% | lecture_player_screen.dart |
| **PIP 미니플레이어** | 화면 이동 시 소형 플레이어 유지 | main.dart, app_state.dart |
| **노트 필기** | 교안 위에 5색 펜 필기 + 지우개 | note_canvas_screen.dart |
| **문제풀이** | 강의별 문제 88문제, 난이도 라벨 | problem_bank.dart |
| **강의 검색** | 제목/강사/태그 통합 검색 + Q&A 키워드 연동 | search_screen.dart |
| **강사 시리즈** | 강사별 시리즈 필터링 + 바텀시트 선택 | instructor_screen.dart |
| **Q&A 게시판** | 질문 작성/수정/삭제/휴지통 + 답변 확인 | consultation_screen.dart |
| **나의 Q&A** | 개인 메모/질문 로컬 저장 (SharedPreferences) | my_activity_screen.dart |
| **다국어** | 한국어/영어 지원 | translations.dart |
| **학습 진도** | 기간별 학습 통계 그래프 | progress_screen.dart |

### 나의 Q&A vs Q&A 차이
| 구분 | 나의 Q&A (나의 활동 탭) | Q&A (하단 메뉴) |
|------|------------------------|----------------|
| **용도** | 나 혼자만 사용하는 개인 메모/질문 | 여러 사용자 대상 |
| **저장** | SharedPreferences (로컬) | 서버 연동 가능 |
| **기능** | 작성/수정/휴지통(soft delete)/복원/영구삭제 | 검색 결과와 연동 |

---

## 11. 강의 타입 분류

| lectureType | 설명 | 특징 |
|-------------|------|------|
| `twice` | 두번설명 | 두 강사가 같은 내용을 다르게 설명 |
| `concept` | 개념 강의 | 일반 강의 |

---

## 12. 학제별 과목 구분

| 학제 | 배지색 | 과목 메뉴 |
|------|--------|----------|
| **예비중** | 민트 그린 (#34D399) | 전체 / 수학 / 과학 |
| **중등** | 에메랄드 그린 (#059669) | 전체 / 수학 / 과학 |
| **고등** | 보라 (#A78BFA) | 전체 / 수학 / 과학 / 공통과학 / 물리 / 화학 / 생명과학 / 지구과학 |

---

## 13. 자주 발생하는 문제 & 해결법

### (1) APK 빌드 실패
```bash
cd flutter_app
rm -rf android/build android/app/build android/.gradle
flutter pub get
flutter build apk --release
```

### (2) 강의 목록이 안 불러와짐
- `api_service.dart`의 GitHub Raw URL 접근 확인
- 네트워크 문제 시 앱 내장 번들 데이터로 자동 폴백

### (3) 영상이 재생 안 됨 (구글 드라이브)
- 드라이브 파일 공유 설정: "링크가 있는 모든 사용자"
- 비공개 파일은 WebView에서 재생 불가

### (4) 필기(노트) 데이터 초기화
- Hive DB에 저장됨 (`note_repository.dart`)
- 앱 데이터 초기화 시 함께 삭제

### (5) PIP가 안 보임
- PIP는 MaterialApp builder에서 Navigator 최상단에 렌더링 (v064에서 수정)
- `appState.pipActive && appState.pipLecture != null` 조건 확인

### (6) 가로화면 강의 전환 시 세로로 돌아감
- `startInLandscape` 파라미터와 `_keepLandscapeOnDispose` 플래그로 제어 (v088~090)

### (7) 시스템 네비게이션 바 겹침
- v094에서 edgeToEdge → manual 모드 전환으로 해결
- SafeArea 적용 (v095)

---

## 14. 앞으로 할 일 / 개선 예정 사항

### 단기
- [ ] 강의 수 확대 (현재 28개+ → 목표 100개+)
- [ ] Q&A 서버 연동 (현재 로컬 전용)
- [ ] 교안 이미지 추가 (신규 강의)

### 중기
- [ ] AWS S3 + CloudFront로 영상 소스 전환 (`config.dart` 변경)
- [ ] 로그인/회원가입 기능 강화
- [ ] Google Play Store 출시
- [ ] 실시간 Q&A (Firebase 연동)

### 장기
- [ ] iOS 버전 개발
- [ ] 강의 오프라인 저장 기능
- [ ] AI 기반 학습 진단 기능

---

## 15. 브랜드 변경 이력

| 시점 | 앱 이름 | 패키지명 |
|------|---------|----------|
| 초기 | 이공 / 미니튜터 | com.minitutor.study |
| v019 | 어썸튜터 | com.awsometutor.study |
| v056+ | **Asome Tutor** | **com.asometutor.study** (최종 확정) |

---

## 16. 연락처 / 계정 정보

| 항목 | 내용 |
|------|------|
| **GitHub 계정** | 3000answer-code |
| **소스 저장소** | https://github.com/3000answer-code/minitutor-data |
| **강의 데이터 저장소** | https://github.com/3000answer-code/asometutor-data |

---

*이 문서는 v109 기준 (2026.04.18) 전체 개발 이력을 포함하여 작성되었습니다.*
*총 111개 커밋, 31,675줄 Dart 코드, 49개 소스 파일, 111개 에셋 파일*

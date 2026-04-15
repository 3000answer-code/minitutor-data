# 어썸튜터 (Asome Tutor) — 인수인계 문서
> 작성일: 2025년 7월 | 최종 버전: v031

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 앱 이름 | 어썸튜터 (Asome Tutor) |
| 슬로건 | 매일 2분, 쌓이는 실력. 짧고 강한 강의 플랫폼 |
| 플랫폼 | Android (Flutter) |
| 패키지명 | `com.minitutor.study` |
| pubspec 앱명 | `asometutor` |
| 버전 | 3.60.0+1 (pubspec) / versionCode 27 (Android) |
| 최소 SDK | Flutter minSdkVersion |
| 타겟 SDK | Flutter targetSdkVersion |
| 개발 환경 | Flutter 3.35.4 / Dart 3.9.2 / Java OpenJDK 17 |

---

## 2. 소스코드 위치

| 위치 | 설명 |
|------|------|
| **GitHub** | https://github.com/3000answer-code/minitutor-data |
| **강의 데이터 JSON** | https://raw.githubusercontent.com/3000answer-code/asometutor-data/main/lectures.json |
| **전체 소스 백업(tar.gz)** | 별도 제공 (약 47MB) |

---

## 3. 개발 환경 세팅

```bash
# 1. Flutter SDK 설치 (3.35.4)
# 2. 소스 클론
git clone https://github.com/3000answer-code/minitutor-data

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
- **⚠️ 이 두 파일은 반드시 안전하게 보관 (분실 시 Play Store 업데이트 불가)**

---

## 4. 프로젝트 구조

```
flutter_app/
├── lib/
│   ├── main.dart                  # 앱 진입점, 하단 탭 네비게이션, PIP 플레이어
│   ├── config.dart                # 환경 설정 (구글 드라이브 ↔ AWS 전환)
│   ├── models/                    # 데이터 모델
│   │   ├── lecture.dart           # 강의 모델 (핵심)
│   │   ├── instructor.dart        # 강사 모델
│   │   ├── note.dart              # 노트 모델
│   │   ├── study_progress.dart    # 학습 진도 모델
│   │   └── consultation.dart      # 상담 모델
│   ├── screens/                   # 화면 (스크린)
│   │   ├── home/
│   │   │   ├── home_screen.dart           # 홈 (추천/인기/과목별 강의 목록)
│   │   │   └── category_lecture_screen.dart # 카테고리별 강의 목록
│   │   ├── lecture/
│   │   │   ├── lecture_player_screen.dart  # ★ 핵심: 강의 영상 플레이어
│   │   │   ├── drive_video_player_screen.dart # 드라이브 영상 플레이어
│   │   │   └── note_canvas_screen.dart    # 노트 필기 캔버스
│   │   ├── search/
│   │   │   ├── search_screen.dart         # 검색 화면
│   │   │   └── note_search_viewer_screen.dart # 검색 결과 노트 뷰어
│   │   ├── progress/
│   │   │   └── progress_screen.dart       # 학습 진도 화면
│   │   ├── curriculum/
│   │   │   └── curriculum_screen.dart     # 커리큘럼 화면
│   │   ├── instructor/
│   │   │   └── instructor_screen.dart     # 강사 소개 화면
│   │   ├── consultation/
│   │   │   └── consultation_screen.dart   # 상담 신청 화면
│   │   ├── auth/
│   │   │   └── login_screen.dart          # 로그인 화면
│   │   ├── profile/
│   │   │   ├── profile_drawer.dart        # 사이드 프로필 드로어
│   │   │   ├── my_activity_screen.dart    # 나의 활동 화면
│   │   │   ├── my_note_viewer_screen.dart # 나의 노트 뷰어
│   │   │   ├── settings_screen.dart       # 설정 화면
│   │   │   └── store_screen.dart          # 스토어 화면
│   │   ├── admin/
│   │   │   └── admin_lecture_screen.dart  # 관리자 강의 관리
│   │   └── ...기타 화면들
│   ├── services/                  # 비즈니스 로직 / API
│   │   ├── api_service.dart       # ★ 강의 데이터 로드 (내장 + GitHub JSON)
│   │   ├── data_service.dart      # 로컬 데이터 서비스
│   │   ├── app_state.dart         # 앱 전역 상태 (Provider)
│   │   ├── auth_service.dart      # 인증 서비스
│   │   ├── content_service.dart   # 콘텐츠 서비스
│   │   ├── instructor_service.dart # 강사 데이터 서비스
│   │   ├── note_repository.dart   # 노트 저장소 (Hive)
│   │   ├── problem_bank.dart      # 문제은행
│   │   └── translations.dart      # 다국어 번역 (한국어/영어)
│   ├── widgets/                   # 재사용 위젯
│   │   ├── lecture_card.dart      # ★ 강의 카드 위젯
│   │   ├── common_app_bar.dart    # 공통 앱바
│   │   ├── drive_web_player.dart  # 드라이브 웹 플레이어
│   │   └── ...
│   ├── theme/
│   │   └── app_theme.dart         # ★ 앱 전체 색상/테마 (AppColors 클래스)
│   └── utils/
│       ├── web_speech_stub.dart   # 웹 음성 스텁
│       └── web_speech_web.dart    # 웹 음성 구현
├── assets/
│   ├── handouts/                  # 강의 교안 이미지 (67개 PNG)
│   ├── icon/                      # 앱 아이콘
│   ├── icons/                     # 기타 아이콘
│   ├── images/                    # 배너/배경 이미지
│   └── lottie/                    # Lottie 애니메이션
├── android/
│   ├── app/
│   │   ├── build.gradle.kts       # Android 빌드 설정
│   │   ├── google-services.json   # Firebase 설정 (있는 경우)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/minitutor/study/MainActivity.kt
│   ├── release-key.jks            # ★ 릴리즈 서명 키 (보안 중요)
│   └── key.properties             # ★ 키스토어 비밀번호 (보안 중요)
├── pubspec.yaml                   # 패키지 의존성
└── HANDOVER.md                    # 이 문서
```

---

## 5. 핵심 파일 설명

### 5-1. `lib/services/api_service.dart` — 강의 데이터 관리 ★★★

강의 데이터는 **두 가지 소스**에서 로드됩니다:

```
우선순위 1: GitHub Raw JSON (원격 업데이트)
  → https://raw.githubusercontent.com/3000answer-code/asometutor-data/main/lectures.json

우선순위 2: 앱 내장 번들 데이터 (_bundledLectures)
  → api_service.dart 파일 내 하드코딩된 강의 목록
```

**강의 추가 방법 (추천):**
1. `asometutor-data` GitHub 저장소의 `lectures.json` 파일 수정
2. 앱 재설치 없이 자동 업데이트 됨

**강의 데이터 형식:**
```json
{
  "id": "gd_twice_001",
  "title": "부분분수 (식, 분해)",
  "subject": "수학",
  "grade": "high",          // "elementary" | "middle" | "high"
  "gradeYear": "All",       // "All" | "1학년" | "2학년" | "3학년"
  "instructor": "강사명",
  "thumbnailUrl": "https://drive.google.com/thumbnail?id=...",
  "videoUrl": "https://drive.google.com/file/d/.../view?usp=sharing",
  "duration": 176,           // 초 단위
  "lectureType": "twice",   // "twice"(두번설명) | "concept"(개념)
  "hashtags": ["태그1", "태그2"],
  "series": "시리즈명",
  "uploadDate": "2026-04-10",
  "handoutUrls": ["assets/handouts/파일명.png"]
}
```

---

### 5-2. `lib/screens/lecture/lecture_player_screen.dart` — 영상 플레이어 ★★★

약 5,650줄의 핵심 화면입니다.

**주요 레이아웃 모드:**

| 모드 | 설명 | 전환 방법 |
|------|------|-----------|
| **세로화면** (기본) | 영상 + 탭(노트/QA/재생목록/문제풀이) | 기본 |
| **가로화면 + 사이드패널** | 왼쪽 영상 + 오른쪽 탭 | 영상 우하단 🔄 버튼 |
| **전체화면** | 영상만 풀스크린 | 영상 우하단 ⛶ 버튼 |
| **PIP (미니플레이어)** | 화면 위 떠다니는 소형 플레이어 | 해시태그 터치 시 자동 |

**주요 State 변수:**
```dart
bool _isLandscape          // 가로화면 모드
bool _isFullScreen         // 전체화면 모드
bool _isMiniPlayer         // PIP 미니플레이어 모드
bool _isMetaBarCollapsed   // 세로화면 강의정보 접힘/펼침
bool _showControls         // 재생 컨트롤 표시 여부
bool _webViewLoading       // WebView 로딩 중 여부
double _playbackSpeed      // 재생 속도 (0.5/0.75/1.0/1.25/1.5/2.0)
bool _showSubtitle         // 자막 표시 여부
```

**영상 플레이어 방식:**
- YouTube / 구글 드라이브 / MP4 모두 **WebView**로 재생
- WebView에 자바스크립트 주입으로 속도 제어

---

### 5-3. `lib/theme/app_theme.dart` — 색상 테마 ★★

앱 전체 색상을 관리하는 클래스입니다.

```dart
class AppColors {
  // 학제 배지 색상
  static const elementary = Color(0xFF34D399);  // 초등 - 민트 그린
  static const middle     = Color(0xFF059669);  // 중등 - 에메랄드 그린 ← v029에서 변경
  static const high       = Color(0xFFA78BFA);  // 고등 - 보라

  // 해시태그 색상 (v028에서 통일)
  // 배경: #EEF4FF, 테두리: #C3D4F0, 텍스트: #5E8ED6

  // 기본 주황 (강조색)
  static const orange = Color(0xFFFF6B00);  // _kOrange
}
```

---

### 5-4. `lib/config.dart` — 영상 소스 전환

```dart
// 현재: 구글 드라이브
static const Env currentEnv = Env.googleDrive;

// AWS S3 + CloudFront로 전환 시:
// 1. currentEnv = Env.aws
// 2. _awsBase = 'https://실제주소.cloudfront.net'
// 3. api_service.dart의 videoUrl을 AWS URL로 교체
```

---

## 6. 패키지 의존성

```yaml
provider: 6.1.5+1          # 상태 관리
go_router: 14.8.1           # 라우팅
shared_preferences: 2.5.3   # 로컬 키-값 저장 (설정 등)
hive: 2.2.3                 # 로컬 DB (노트 저장)
hive_flutter: 1.1.0         # Hive Flutter 통합
http: 1.5.0                 # HTTP 통신 (강의 JSON 로드)
cached_network_image: 3.4.1 # 이미지 캐싱 (썸네일)
shimmer: 3.0.0              # 로딩 스켈레톤 효과
percent_indicator: 4.2.3    # 진도 표시 바
fl_chart: 0.71.0            # 차트 (진도 분석)
video_player: 2.9.5         # 비디오 플레이어 (백업용)
chewie: 1.8.5               # 비디오 UI 래퍼
iconsax: 0.0.8              # 아이콘 팩
intl: 0.19.0                # 날짜/숫자 형식
url_launcher: 6.3.1         # 외부 URL 열기
webview_flutter: 4.13.0     # WebView (영상 재생 핵심)
```

---

## 7. 하단 탭 네비게이션 구조

```
① 홈 (Home)            → home_screen.dart
② 진도 (Progress)      → progress_screen.dart
③ 커리큘럼 (Curriculum) → curriculum_screen.dart
④ 검색 (Search)        → search_screen.dart
⑤ 상담 (Consultation)  → consultation_screen.dart
⑥ 강사 (Instructor)    → instructor_screen.dart
```

---

## 8. 강의 플레이어 내 탭 구조

```
① 노트 보기   — 교안 슬라이드 이미지 뷰어 + 필기 기능
② 강의 Q&A   — 질문/답변 게시판
③ 재생 목록  — 시리즈 강의 목록
④ 문제풀이   — 관련 문제 풀기
```

---

## 9. 강의 타입 분류

| lectureType | 설명 | 현재 강의 수 |
|-------------|------|-------------|
| `twice` | 두번설명 (두 강사가 같은 내용을 다르게 설명) | 10개 |
| `concept` | 개념 강의 (일반 강의) | 18개 |

---

## 10. 다국어 지원

- 한국어 / 영어 지원
- `lib/services/translations.dart` 에서 번역 키 관리
- `T('key')` 함수로 번역된 텍스트 사용
- 언어 선택: `lib/screens/language/language_select_screen.dart`

---

## 11. 주요 변경 이력 (최근)

| 버전 | 주요 변경 내용 |
|------|--------------|
| v019 | 영상 플레이어 UI 전면 개편 (탭 균등, 아이보리 배경, 전체화면 버튼) |
| v021 | 교안 크롭 최종 적용 (오른쪽 30% + 아래 28%) |
| v022 | 가로화면 + 사이드패널 모드 추가 |
| v025 | 패키지명 com.awsometutor.study 통일 / 영상 로딩 속도 개선 |
| v026 | 가로/전체화면 일시정지 버튼 수정 |
| v027 | B강의 버튼 삭제 / Drive 플레이버튼 삭제 / CC·1x 가로전체화면 추가 |
| v028 | CC버튼 삭제 / 로딩중 플레이버튼 숨김 / 해시태그 색 통일 (#5E8ED6) |
| v029 | 중등 배지 에메랄드 그린(#059669) 통일 / 속도 팝업 컴팩트화 |
| v030 | 세로화면 속도버튼 주황 강조 / 가로화면 강의정보 항상 표시 + 세로전환 |
| v031 | 속도팝업 시스템바 겹침 수정 / 가로화면 세로전환 버튼 명확화 |

---

## 12. 앞으로 할 일 / 개선 예정 사항

### 단기
- [ ] 강의 수 확대 (현재 28개 → 목표 100개+)
- [ ] GitHub lectures.json으로 강의 관리 전환 완료
- [ ] Q&A 실시간 기능 (Firebase 연동)

### 중기
- [ ] AWS S3 + CloudFront로 영상 소스 전환 (`config.dart` 변경만으로 가능)
- [ ] 로그인/회원가입 기능 강화
- [ ] Google Play Store 출시

### 장기
- [ ] iOS 버전 개발
- [ ] 강의 오프라인 저장 기능
- [ ] AI 기반 학습 진단 기능

---

## 13. 자주 발생하는 문제 & 해결법

### ① APK 빌드 실패
```bash
# Android 캐시 정리 후 재빌드
cd flutter_app
rm -rf android/build android/app/build android/.gradle
flutter pub get
flutter build apk --release
```

### ② 강의 목록이 안 불러와짐
- `api_service.dart`의 `_adminUrls` 리스트 첫 번째 URL (GitHub Raw) 접근 가능한지 확인
- 네트워크 문제 시 앱 내장 번들 데이터(`_bundledLectures`)로 자동 폴백

### ③ 영상이 재생 안 됨 (구글 드라이브)
- 드라이브 파일의 공유 설정이 "링크가 있는 모든 사용자" 인지 확인
- 비공개 파일은 WebView에서 재생 불가

### ④ 필기(노트) 데이터 초기화
- Hive DB에 저장됨 (`note_repository.dart`)
- 앱 데이터 초기화 시 함께 삭제됨

---

## 14. 연락처 / 계정 정보

| 항목 | 내용 |
|------|------|
| GitHub 계정 | 3000answer-code |
| 소스 저장소 | https://github.com/3000answer-code/minitutor-data |
| 강의 데이터 저장소 | https://github.com/3000answer-code/asometutor-data |

---

*이 문서는 v031 기준으로 작성되었습니다.*

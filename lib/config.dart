// ─────────────────────────────────────────────
// AppConfig — 영상 소스 관리
//
// ✅ 현재: 구글 드라이브 전용
// 🔮 나중에: AWS S3 + CloudFront 전환 가능
// ─────────────────────────────────────────────

enum Env { googleDrive, aws }

class AppConfig {
  // ✅ 현재 환경: 구글 드라이브 전용 (NAS/터널 완전 제거)
  static const Env currentEnv = Env.googleDrive;

  // ── AWS 설정 (나중에 출시용으로 전환 시 사용) ──
  static const String _awsBase = 'https://CHANGE_ME.cloudfront.net';

  /// 베이스 URL (현재 구글 드라이브 모드에서는 미사용)
  static String get baseUrl => _awsBase;

  /// 현재 환경 이름 (디버그용)
  static String get envName =>
      currentEnv == Env.googleDrive ? '구글 드라이브' : '출시(AWS)';

  // ─────────────────────────────────────────────
  // 📋 나중에 AWS 전환 시 체크리스트
  // ─────────────────────────────────────────────
  // 1. currentEnv = Env.aws 로 변경
  // 2. _awsBase = 'https://실제CloudFront주소.cloudfront.net' 로 변경
  // 3. 영상 파일을 S3 버킷에 업로드
  // 4. api_service.dart 의 videoUrl 을 AWS URL 로 교체
  // ─────────────────────────────────────────────

  // ── NAS/터널 관련 코드 완전 제거 (구글 드라이브로 전환) ──
  // fetchTunnelUrl(), updateNasBase() 등 모두 비활성화됨
  static void updateNasBase(String newTunnelUrl) {
    // 구글 드라이브 전환으로 NAS 완전 비활성화
  }

  static String get tunnelUpdateUrl => '';
  static String videoUrl(String lectureId) => '';
  static String thumbnailUrl(String lectureId) => '';
  static String get lecturesJsonUrl => '';
}

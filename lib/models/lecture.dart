import '../config.dart';

class Lecture {
  final String id;
  final String title;
  final String subject;
  final String grade;       // elementary, middle, high
  final String instructor;
  final String thumbnailUrl;
  final String videoUrl;
  final int duration;       // seconds
  final int viewCount;
  final double rating;
  final int ratingCount;
  final String lectureType; // concept, problem, term
  final String? relatedLectureId;
  final List<String> hashtags;
  final String description;
  final bool isFavorite;
  final String series;
  final int lectureNumber;
  final String uploadDate;
  final String gradeYear;   // 'All', '1', '2', '3'
  final List<String> handoutUrls; // 교안 PNG URL 목록 (순서대로 표시)

  Lecture({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.instructor,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.viewCount,
    required this.rating,
    required this.ratingCount,
    required this.lectureType,
    this.relatedLectureId,
    required this.hashtags,
    required this.description,
    required this.isFavorite,
    required this.series,
    required this.lectureNumber,
    required this.uploadDate,
    this.gradeYear = 'All',
    this.handoutUrls = const [],
  });

  String get durationText {
    final min = duration ~/ 60;
    final sec = duration % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String get gradeText {
    switch (grade) {
      case 'elementary': return '예비중';
      case 'middle': return '중등';
      case 'high': return '고등';
      default: return grade;
    }
  }

  /// 학제+학년 표시 텍스트 (예: '중등', '중등 1학년', '고등 All')
  String get gradeFullText {
    final base = gradeText;
    if (gradeYear == 'All' || gradeYear.isEmpty) return base;
    return '$base ${gradeYear}학년';
  }

  String get lectureTypeText {
    switch (lectureType) {
      case 'concept': return '개념';
      case 'problem': return '문제풀이';
      case 'term': return '용어';
      case 'twice': return '두번설명';
      case 'shorts': return '쇼츠';
      default: return lectureType;
    }
  }

  // Google Drive 파일 ID 추출
  String? get driveFileId {
    final regexps = [
      RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'id=([a-zA-Z0-9_-]+)'),
      RegExp(r'/d/([a-zA-Z0-9_-]+)'),
    ];
    for (final re in regexps) {
      final match = re.firstMatch(videoUrl);
      if (match != null) return match.group(1);
    }
    return null;
  }

  // YouTube URL에서 비디오 ID 추출
  String? get youtubeVideoId {
    final patterns = [
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
    ];
    for (final re in patterns) {
      final match = re.firstMatch(videoUrl);
      if (match != null) return match.group(1);
    }
    return null;
  }

  // Google Drive 영상 여부
  bool get isDriveVideo => videoUrl.contains('drive.google.com');

  // NAS/클라우드 MP4 영상인지 확인
  // Google Drive, YouTube는 NAS 아님
  bool get isNasVideo =>
      !isDriveVideo &&
      youtubeVideoId == null &&
      (videoUrl.contains(AppConfig.baseUrl) ||
       videoUrl.contains('quickconnect.to') ||
       videoUrl.contains('synology') ||
       videoUrl.contains('trycloudflare.com') ||
       videoUrl.contains('cloudfront.net') ||
       videoUrl.contains('amazonaws.com') ||
       (videoUrl.startsWith('http') && videoUrl.endsWith('.mp4')));

  // ── Google Drive 파일 ID 추출 (thumbnailUrl 포함) ────────
  String? _extractDriveId(String url) {
    final patterns = [
      RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'[?&]id=([a-zA-Z0-9_-]+)'),
      RegExp(r'lh3\.googleusercontent\.com/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'/d/([a-zA-Z0-9_-]+)'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  // 썸네일 URL 우선순위:
  // 1) thumbnailUrl이 있고 유효하면 사용 (단, 교안/handout 이미지 제외)
  //    - drive.google.com/thumbnail → lh3 직접 URL로 변환 (리다이렉트 없이 로드)
  //    - lh3.googleusercontent.com → 그대로 사용
  // 2) YouTube URL이면 img.youtube.com 자동 생성
  // 3) Google Drive 영상이면 lh3 직접 URL 자동 생성
  // 4) NAS thumbs 폴더
  // 5) 빈 문자열
  String get effectiveThumbnailUrl {
    // 1) 유효한 썸네일 URL이 있으면 사용
    // 단, 교안(handout) 이미지이거나 .mp4 이거나 nas_ 접두사면 제외
    if (thumbnailUrl.isNotEmpty && !thumbnailUrl.endsWith('.mp4') &&
        !thumbnailUrl.startsWith('nas_') &&
        !thumbnailUrl.startsWith('assets/') &&
        !thumbnailUrl.contains('/handouts/')) {
      // drive.google.com/thumbnail?id=FILE_ID → lh3 직접 URL로 변환
      // (302 리다이렉트 없이 바로 이미지 로드 가능)
      if (thumbnailUrl.contains('drive.google.com/thumbnail')) {
        final id = _extractDriveId(thumbnailUrl);
        if (id != null) {
          return 'https://lh3.googleusercontent.com/d/$id=w480';
        }
      }
      // lh3.googleusercontent.com/d/FILE_ID → 그대로 사용
      if (thumbnailUrl.contains('lh3.googleusercontent.com')) {
        return thumbnailUrl;
      }
      return thumbnailUrl;
    }
    // 2) YouTube 영상이면 YouTube 썸네일 자동 생성
    final ytId = youtubeVideoId;
    if (ytId != null) {
      return 'https://img.youtube.com/vi/$ytId/mqdefault.jpg';
    }
    // 3) Google Drive 영상이면 lh3 직접 URL 자동 생성
    final id = driveFileId;
    if (id != null) {
      return 'https://lh3.googleusercontent.com/d/$id=w480';
    }
    // 4) NAS 영상이면 thumbs 폴더에서 썸네일 자동 생성 URL 시도
    if (isNasVideo) {
      final uri = Uri.tryParse(videoUrl);
      if (uri != null && videoUrl.endsWith('.mp4')) {
        final fileName = uri.pathSegments.last;
        final lectureId = fileName.replaceAll('.mp4', '');
        final basePath = videoUrl.replaceAll('/$fileName', '');
        return '$basePath/thumbs/$lectureId.jpg';
      }
      return 'nas_default';
    }
    return '';
  }

  // Drive thumbnail fallback URL (2차 시도용)
  // lh3 실패 시 drive.google.com/thumbnail 로 재시도
  String get fallbackThumbnailUrl {
    final id = driveFileId ?? _extractDriveId(thumbnailUrl);
    if (id != null) {
      return 'https://drive.google.com/thumbnail?id=$id&sz=w480';
    }
    return '';
  }

  String get viewCountText {
    if (viewCount >= 10000) {
      return '${(viewCount / 10000).toStringAsFixed(1)}만';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}천';
    }
    return viewCount.toString();
  }

  Lecture copyWith({bool? isFavorite}) {
    return Lecture(
      id: id, title: title, subject: subject, grade: grade,
      instructor: instructor, thumbnailUrl: thumbnailUrl, videoUrl: videoUrl,
      duration: duration, viewCount: viewCount, rating: rating, ratingCount: ratingCount,
      lectureType: lectureType, relatedLectureId: relatedLectureId, hashtags: hashtags,
      description: description, isFavorite: isFavorite ?? this.isFavorite,
      series: series, lectureNumber: lectureNumber, uploadDate: uploadDate,
      gradeYear: gradeYear, handoutUrls: handoutUrls,
    );
  }
}

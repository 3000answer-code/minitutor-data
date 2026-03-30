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
  });

  String get durationText {
    final min = duration ~/ 60;
    final sec = duration % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String get gradeText {
    switch (grade) {
      case 'elementary': return '초등';
      case 'middle': return '중등';
      case 'high': return '고등';
      default: return grade;
    }
  }

  String get lectureTypeText {
    switch (lectureType) {
      case 'concept': return '개념';
      case 'problem': return '문제풀이';
      case 'term': return '용어';
      default: return lectureType;
    }
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
    );
  }
}

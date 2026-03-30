class Instructor {
  final String id;
  final String name;
  final String grade;
  final String subject;
  final String profileImageUrl;
  final String introduction;
  final int lectureCount;
  final double rating;
  final int followerCount;
  final List<String> series;

  Instructor({
    required this.id,
    required this.name,
    required this.grade,
    required this.subject,
    required this.profileImageUrl,
    required this.introduction,
    required this.lectureCount,
    required this.rating,
    required this.followerCount,
    required this.series,
  });

  String get gradeText {
    switch (grade) {
      case 'elementary': return '초등';
      case 'middle': return '중등';
      case 'high': return '고등';
      default: return grade;
    }
  }
}

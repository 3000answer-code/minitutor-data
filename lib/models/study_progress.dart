class StudyUnit {
  final String id;
  final String subject;
  final String grade;
  final String unitName;
  final String chapter;
  final int totalLectures;
  final int completedLectures;
  final List<String> lectureIds;
  final double completionRate;

  StudyUnit({
    required this.id,
    required this.subject,
    required this.grade,
    required this.unitName,
    required this.chapter,
    required this.totalLectures,
    required this.completedLectures,
    required this.lectureIds,
    required this.completionRate,
  });

  String get progressText => '$completedLectures/$totalLectures 강의';
  bool get isCompleted => completedLectures == totalLectures;
}

class StudyProgress {
  final String userId;
  final String subject;
  final String grade;
  final List<StudyUnit> units;
  final int totalMinutes;
  final int todayMinutes;
  final int streakDays;
  final DateTime lastStudied;

  StudyProgress({
    required this.userId,
    required this.subject,
    required this.grade,
    required this.units,
    required this.totalMinutes,
    required this.todayMinutes,
    required this.streakDays,
    required this.lastStudied,
  });

  double get overallProgress {
    if (units.isEmpty) return 0;
    final total = units.fold<int>(0, (sum, u) => sum + u.totalLectures);
    final completed = units.fold<int>(0, (sum, u) => sum + u.completedLectures);
    return total > 0 ? completed / total : 0;
  }
}

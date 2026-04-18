/// 개인 Q&A 모델 (나의 활동 > 나의 Q&A 전용)
/// 공용 Q&A(Consultation)와 독립 — 나만 볼 수 있는 개인 메모/질문
class PersonalQA {
  final String id;
  final String title;
  final String content;
  final String subject;       // 수학, 과학 등
  final String grade;         // elementary, middle, high
  final String? lectureTitle; // 연관 강의 (선택)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;       // 휴지통 (soft-delete)

  PersonalQA({
    required this.id,
    required this.title,
    required this.content,
    required this.subject,
    required this.grade,
    this.lectureTitle,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  PersonalQA copyWith({
    String? title,
    String? content,
    String? subject,
    String? grade,
    String? lectureTitle,
    DateTime? updatedAt,
    bool? isDeleted,
  }) =>
      PersonalQA(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        subject: subject ?? this.subject,
        grade: grade ?? this.grade,
        lectureTitle: lectureTitle ?? this.lectureTitle,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }

  String get gradeLabel {
    switch (grade) {
      case 'elementary':
        return '예비중';
      case 'middle':
        return '중등';
      case 'high':
        return '고등';
      default:
        return grade;
    }
  }

  /// JSON 직렬화 (SharedPreferences 저장용)
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'subject': subject,
        'grade': grade,
        'lectureTitle': lectureTitle,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory PersonalQA.fromJson(Map<String, dynamic> json) => PersonalQA(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        subject: json['subject'] as String,
        grade: json['grade'] as String,
        lectureTitle: json['lectureTitle'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        isDeleted: json['isDeleted'] as bool? ?? false,
      );
}

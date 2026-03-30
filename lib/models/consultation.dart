class Consultation {
  final String id;
  final String title;
  final String content;
  final String authorNickname;
  final String authorProfileUrl;
  final String subject;
  final String grade;
  final DateTime createdAt;
  final bool isAnswered;
  final String? answer;
  final String? answerAuthor;
  final DateTime? answeredAt;
  final int viewCount;
  final List<String> attachments;

  Consultation({
    required this.id,
    required this.title,
    required this.content,
    required this.authorNickname,
    required this.authorProfileUrl,
    required this.subject,
    required this.grade,
    required this.createdAt,
    required this.isAnswered,
    this.answer,
    this.answerAuthor,
    this.answeredAt,
    required this.viewCount,
    required this.attachments,
  });

  String get statusText => isAnswered ? '답변완료' : '답변대기';
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}

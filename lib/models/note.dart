import 'package:flutter/material.dart';

class NoteStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  NoteStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isEraser,
  });
}

class SavedNote {
  final String id;
  final String lectureId;
  final String lectureTitle;
  final String subject;
  final String savedAt;
  final String previewText;
  final int strokeCount;

  SavedNote({
    required this.id,
    required this.lectureId,
    required this.lectureTitle,
    required this.subject,
    required this.savedAt,
    required this.previewText,
    required this.strokeCount,
  });
}

class ScheduleEvent {
  final String id;
  final String title;
  final String content;
  final DateTime dateTime;
  final String alertBefore; // 정시/10분전/30분전/1시간전/1일전/1주전
  final String repeat;      // 없음/매일/매주/매월/매년
  final Color color;
  final bool isAppEvent;    // true: Asome Tutor 이벤트, false: 내 일정

  ScheduleEvent({
    required this.id,
    required this.title,
    required this.content,
    required this.dateTime,
    required this.alertBefore,
    required this.repeat,
    required this.color,
    required this.isAppEvent,
  });
}

class Notice {
  final String id;
  final String title;
  final String content;
  final String category; // 공지/행사/이벤트
  final DateTime createdAt;
  final bool isImportant;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.isImportant,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}달 전';
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    return '방금 전';
  }
}

class FaqItem {
  final String id;
  final String category;
  final String question;
  final String answer;
  bool isExpanded;

  FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class Inquiry {
  final String id;
  final String category;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isAnswered;
  final String? answer;

  Inquiry({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isAnswered,
    this.answer,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    return '방금 전';
  }
}

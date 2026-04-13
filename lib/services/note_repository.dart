import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 필기 저장 메타데이터 관리 (나의활동 > 노트 목록용)
class NoteRepository {
  static final NoteRepository _instance = NoteRepository._internal();
  factory NoteRepository() => _instance;
  NoteRepository._internal();

  static const String _metaKey = 'saved_note_meta_list';

  // ── 저장된 노트 메타 목록 전체 조회
  Future<List<NoteMetaData>> getAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_metaKey);
      if (json == null) return [];
      final List decoded = jsonDecode(json);
      return decoded.map((m) => NoteMetaData.fromJson(m as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return [];
    }
  }

  // ── 특정 강의 노트 메타 조회
  Future<NoteMetaData?> getNoteByLectureId(String lectureId) async {
    final all = await getAllNotes();
    try {
      return all.firstWhere((n) => n.lectureId == lectureId);
    } catch (_) {
      return null;
    }
  }

  // ── 필기 저장 시 메타데이터 추가/업데이트
  Future<void> saveNoteMeta(NoteMetaData meta) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAllNotes();
      all.removeWhere((n) => n.lectureId == meta.lectureId);
      all.insert(0, meta);
      await prefs.setString(_metaKey, jsonEncode(all.map((n) => n.toJson()).toList()));
    } catch (_) {}
  }

  // ── 노트 삭제 (강의 ID 기준)
  Future<void> deleteNote(String lectureId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAllNotes();
      all.removeWhere((n) => n.lectureId == lectureId);
      await prefs.setString(_metaKey, jsonEncode(all.map((n) => n.toJson()).toList()));
      await prefs.remove('strokes_$lectureId');
      await prefs.remove('notes_$lectureId');
    } catch (_) {}
  }
}

/// 나의활동 > 노트 목록 메타데이터
class NoteMetaData {
  final String lectureId;
  final String lectureTitle;
  final String subject;
  final String instructorName;
  final String savedAt;
  final int strokeCount;
  final int memoCount;
  final List<String> handoutUrls;
  final String thumbnailUrl;

  NoteMetaData({
    required this.lectureId,
    required this.lectureTitle,
    required this.subject,
    required this.instructorName,
    required this.savedAt,
    required this.strokeCount,
    required this.memoCount,
    required this.handoutUrls,
    required this.thumbnailUrl,
  });

  factory NoteMetaData.fromJson(Map<String, dynamic> json) => NoteMetaData(
    lectureId:      json['lectureId'] as String? ?? '',
    lectureTitle:   json['lectureTitle'] as String? ?? '',
    subject:        json['subject'] as String? ?? '',
    instructorName: json['instructorName'] as String? ?? '',
    savedAt:        json['savedAt'] as String? ?? '',
    strokeCount:    json['strokeCount'] as int? ?? 0,
    memoCount:      json['memoCount'] as int? ?? 0,
    handoutUrls:    List<String>.from(json['handoutUrls'] as List? ?? []),
    thumbnailUrl:   json['thumbnailUrl'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'lectureId':      lectureId,
    'lectureTitle':   lectureTitle,
    'subject':        subject,
    'instructorName': instructorName,
    'savedAt':        savedAt,
    'strokeCount':    strokeCount,
    'memoCount':      memoCount,
    'handoutUrls':    handoutUrls,
    'thumbnailUrl':   thumbnailUrl,
  };
}

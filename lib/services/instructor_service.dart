import '../models/instructor.dart';
import '../models/lecture.dart';

/// 강의 데이터에서 강사 정보를 자동으로 추출·생성하는 서비스
/// - 강의가 업로드되면 강사 카드가 자동으로 생성됨
/// - 수동 등록 강사 데이터와 병합 (수동 데이터 우선)
class InstructorService {
  static final InstructorService _instance = InstructorService._internal();
  factory InstructorService() => _instance;
  InstructorService._internal();

  // ─── 과목별 전문 분야 키워드 ───────────────────────────────────────────────
  static const Map<String, String> _subjectSpecialty = {
    '수학':     '개념·풀이 전문',
    '과학':     '원리·실험 전문',
    '공통과학': '통합과학 전문',
    '물리':     '역학·전자기 전문',
    '화학':     '반응·원리 전문',
    '생명과학': '유전·생태 전문',
    '지구과학': '지질·천체 전문',
    '영어':     '어법·독해 전문',
    '국어':     '문학·언어 전문',
  };

  // ─── 강사명 → 시드 해시 (일관된 프로필 이미지 보장) ──────────────────────
  static String _nameSeed(String name) {
    // 한글 이름을 영문 seed로 변환 (일관성 유지)
    int hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return 'inst_$hash';
  }

  // ─── 강의 목록 → 강사 목록 자동 생성 ────────────────────────────────────
  /// [lectures] : 전체 강의 목록 (API + 번들 병합본)
  /// [manualInstructors] : 수동 등록 강사 목록 (수동 데이터가 우선 적용됨)
  List<Instructor> buildInstructorsFromLectures(
    List<Lecture> lectures, {
    List<Instructor> manualInstructors = const [],
  }) {
    // 1. 수동 등록 강사를 키(이름+학제)로 인덱싱
    final Map<String, Instructor> manualMap = {};
    for (final ins in manualInstructors) {
      manualMap['${ins.name}_${ins.grade}'] = ins;
    }

    // 2. 강의에서 강사 그룹핑: {강사명+학제: [강의 목록]}
    final Map<String, List<Lecture>> grouped = {};
    for (final lec in lectures) {
      if (lec.instructor.trim().isEmpty) continue;

      // "두번설명" 형태처럼 복수 강사 처리
      final names = lec.instructor
          .split(RegExp(r'[,\s]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      for (final name in names) {
        final key = '${name}_${lec.grade}';
        grouped.putIfAbsent(key, () => []).add(lec);
      }
    }

    // 3. 그룹핑된 강의로부터 강사 객체 생성
    final Map<String, Instructor> autoMap = {};
    for (final entry in grouped.entries) {
      final key = entry.key;
      final lecList = entry.value;
      final firstLec = lecList.first;
      final name = key.split('_').first;
      final grade = firstLec.grade;

      // 수동 등록 강사가 있으면 그대로 사용 (덮어쓰지 않음)
      if (manualMap.containsKey(key)) continue;

      // 시리즈 목록 추출 (중복 제거, 빈 값 제외)
      final seriesSet = <String>{};
      for (final l in lecList) {
        if (l.series.isNotEmpty) seriesSet.add(l.series);
      }
      final seriesList = seriesSet.toList();

      // 과목 (가장 많이 등장하는 과목 사용)
      final subjectCount = <String, int>{};
      for (final l in lecList) {
        subjectCount[l.subject] = (subjectCount[l.subject] ?? 0) + 1;
      }
      final subject = subjectCount.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      // 소개 문구: "학제 · 과목 · 전문분야, 시리즈명" 형태로 간결하게
      final specialty = _subjectSpecialty[subject] ?? '$subject 전문';
      final gradeLabel = gradeText(grade);
      final seriesText = seriesList.isNotEmpty
          ? seriesList.join(', ')
          : '';
      final introduction = seriesText.isNotEmpty
          ? '$gradeLabel $subject $specialty\n$seriesText'
          : '$gradeLabel $subject $specialty';

      autoMap[key] = Instructor(
        id: 'auto_${key.replaceAll(' ', '_')}',
        name: name,
        grade: grade,
        subject: subject,
        profileImageUrl:
            'https://picsum.photos/seed/${_nameSeed(name)}/150/150',
        introduction: introduction,
        lectureCount: lecList.length,
        rating: 0.0,
        followerCount: 0,
        series: seriesList,
      );
    }

    // 4. 수동 + 자동 병합 (수동 우선)
    final result = <Instructor>[...manualInstructors];
    for (final entry in autoMap.entries) {
      result.add(entry.value);
    }

    // 5. 정렬: 학제(high→middle→elementary) → 과목 → 강사명
    result.sort((a, b) {
      final gradeOrder = {'high': 0, 'middle': 1, 'elementary': 2};
      final gComp = (gradeOrder[a.grade] ?? 9)
          .compareTo(gradeOrder[b.grade] ?? 9);
      if (gComp != 0) return gComp;
      final sComp = a.subject.compareTo(b.subject);
      if (sComp != 0) return sComp;
      return a.name.compareTo(b.name);
    });

    return result;
  }

  // ─── 특정 강사의 강의 목록 추출 ──────────────────────────────────────────
  List<Lecture> getLecturesByInstructor(
    List<Lecture> allLectures,
    String instructorName,
  ) {
    return allLectures.where((l) {
      final names = l.instructor
          .split(RegExp(r'[,\s]+'))
          .map((s) => s.trim())
          .toList();
      return names.contains(instructorName);
    }).toList()
      ..sort((a, b) {
        final sComp = a.series.compareTo(b.series);
        if (sComp != 0) return sComp;
        return a.lectureNumber.compareTo(b.lectureNumber);
      });
  }
}

// ─── 헬퍼: grade 코드 → 텍스트 변환 ──────────────────────────────────────
String gradeText(String grade) {
  switch (grade) {
    case 'high':        return '고등';
    case 'middle':      return '중등';
    case 'elementary':  return '예비중';
    default:            return grade;
  }
}

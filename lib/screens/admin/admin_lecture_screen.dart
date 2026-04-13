import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../models/lecture.dart';
import '../../theme/app_theme.dart';

/// 어드민 전용 강의 등록/관리 화면
/// 접근 조건: isAdmin == true (이메일 기반)
class AdminLectureScreen extends StatefulWidget {
  const AdminLectureScreen({super.key});

  @override
  State<AdminLectureScreen> createState() => _AdminLectureScreenState();
}

class _AdminLectureScreenState extends State<AdminLectureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2D5A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('ADMIN', style: TextStyle(
              color: Color(0xFF1A2D5A), fontSize: 10, fontWeight: FontWeight.w900,
            )),
          ),
          const SizedBox(width: 10),
          const Text('강의 관리', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: '강의 등록'),
            Tab(text: '강의 목록'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AddLectureTab(onAdded: () => setState(() {})),
          const _LectureListTab(),
        ],
      ),
    );
  }
}

// ─── 강의 등록 탭 ─────────────────────────────────────────────
class _AddLectureTab extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddLectureTab({required this.onAdded});

  @override
  State<_AddLectureTab> createState() => _AddLectureTabState();
}

class _AddLectureTabState extends State<_AddLectureTab> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _instructorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hashtagCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController();

  String _subject = '수학';
  String _grade = 'high';
  String _gradeYear = 'All';  // 'All', '1', '2', '3'
  String _lectureType = 'concept';
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _detectedVideoId;
  String? _videoType; // 'youtube', 'shorts'

  final List<String> _subjects = ['수학', '과학', '국어', '영어', '기타'];
  final Map<String, String> _gradeLabels = {
    'elementary': '예비중', 'middle': '중등', 'high': '고등'
  };
  final Map<String, String> _gradeYearLabels = {
    'All': 'All', '1': '1학년', '2': '2학년', '3': '3학년',
  };
  final Map<String, String> _typeLabels = {
    'concept': '개념강의', 'problem': '문제풀이', 'term': '용어', 'shorts': '두번설명'
  };

  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    _instructorCtrl.dispose();
    _descCtrl.dispose();
    _hashtagCtrl.dispose();
    _seriesCtrl.dispose();
    super.dispose();
  }

  // YouTube URL에서 비디오 ID 추출 & 정보 자동 감지
  void _analyzeUrl(String url) {
    if (url.isEmpty) return;
    setState(() => _isAnalyzing = true);

    String? videoId;
    String? type;

    if (url.contains('/shorts/')) {
      final match = RegExp(r'/shorts/([a-zA-Z0-9_-]+)').firstMatch(url);
      videoId = match?.group(1);
      type = 'shorts';
    } else if (url.contains('youtu.be/')) {
      final match = RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)').firstMatch(url);
      videoId = match?.group(1);
      type = 'youtube';
    } else if (url.contains('watch?v=')) {
      final match = RegExp(r'[?&]v=([a-zA-Z0-9_-]+)').firstMatch(url);
      videoId = match?.group(1);
      type = 'youtube';
    }

    setState(() {
      _detectedVideoId = videoId;
      _videoType = type;
      _isAnalyzing = false;

      // 두번설명이면 자동으로 타입/과목 설정
      if (type == 'shorts') {
        _lectureType = 'shorts';
        _subject = '두번설명';
      }
    });
  }

  Future<void> _submitLecture() async {
    if (!_formKey.currentState!.validate()) return;
    if (_detectedVideoId == null) {
      _showSnack('올바른 YouTube URL을 먼저 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = context.read<AppState>();
      final videoUrl = _urlCtrl.text.trim();

      // 썸네일 URL 자동 생성
      final thumbnailUrl = 'https://img.youtube.com/vi/$_detectedVideoId/mqdefault.jpg';

      // 해시태그 파싱
      final hashtags = _hashtagCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // 고유 ID 생성
      final id = 'admin_${DateTime.now().millisecondsSinceEpoch}';

      final lectureData = {
        'id': id,
        'title': _titleCtrl.text.trim(),
        'subject': _subject,
        'grade': _grade,
        'gradeYear': _gradeYear,
        'instructor': _instructorCtrl.text.trim(),
        'thumbnailUrl': thumbnailUrl,
        'videoUrl': videoUrl,
        'duration': _videoType == 'shorts' ? 60 : 600,
        'viewCount': 0,
        'rating': 0.0,
        'ratingCount': 0,
        'lectureType': _lectureType,
        'hashtags': hashtags,
        'description': _descCtrl.text.trim(),
        'isFavorite': false,
        'series': _seriesCtrl.text.trim().isEmpty ? '시리즈' : _seriesCtrl.text.trim(),
        'lectureNumber': 1,
        'uploadDate': DateTime.now().toIso8601String().substring(0, 10),
        'relatedLectureId': '',
      };

      // AppState에 강의 추가
      await appState.addAdminLecture(lectureData);

      if (mounted) {
        _showSnack('✅ "${_titleCtrl.text.trim()}" 강의가 등록되었습니다!');
        _clearForm();
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('등록 실패: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _urlCtrl.clear();
    _titleCtrl.clear();
    _instructorCtrl.clear();
    _descCtrl.clear();
    _hashtagCtrl.clear();
    _seriesCtrl.clear();
    setState(() {
      _subject = '수학';
      _grade = 'high';
      _gradeYear = 'All';
      _lectureType = 'concept';
      _detectedVideoId = null;
      _videoType = null;
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── 안내 배너
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              const Expanded(child: Text(
                'YouTube URL을 붙여넣으면 자동으로 분석됩니다.\n일반 영상과 두번설명(Shorts) 모두 지원합니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.5),
              )),
            ]),
          ),

          // ── YouTube URL 입력
          _buildSectionTitle('YouTube URL *'),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _urlCtrl,
                decoration: _inputDecoration(
                  'https://youtu.be/... 또는 https://youtube.com/shorts/...',
                  Icons.link_rounded,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'URL을 입력하세요' : null,
                onChanged: (v) {
                  if (v.length > 15) _analyzeUrl(v);
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _analyzeUrl(_urlCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2D5A),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isAnalyzing
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.search_rounded, color: Colors.white),
            ),
          ]),

          // ── URL 감지 결과
          if (_detectedVideoId != null) ...[
            const SizedBox(height: 12),
            _buildDetectedCard(),
          ],

          const SizedBox(height: 20),

          // ── 강의 제목
          _buildSectionTitle('강의 제목 *'),
          TextFormField(
            controller: _titleCtrl,
            decoration: _inputDecoration('예: 세제곱 곱셈공식 완벽 정리', Icons.title_rounded),
            validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
          ),
          const SizedBox(height: 16),

          // ── 강사명
          _buildSectionTitle('강사명 *'),
          TextFormField(
            controller: _instructorCtrl,
            decoration: _inputDecoration('예: 김본 / 최형규 외', Icons.person_rounded),
            validator: (v) => (v == null || v.trim().isEmpty) ? '강사명을 입력하세요' : null,
          ),
          const SizedBox(height: 16),

          // ── 과목 선택
          _buildSectionTitle('과목'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _subjects.map((s) {
              final selected = _subject == s;
              return GestureDetector(
                onTap: () => setState(() => _subject = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1A2D5A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFF1A2D5A) : const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: Text(s, style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF555555),
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── 학년 선택 (예비중/중등/고등)
          _buildSectionTitle('대상 학제'),
          Row(
            children: _gradeLabels.entries.map((e) {
              final selected = _grade == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _grade = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFF97316) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFFF97316) : const Color(0xFFDDDDDD),
                      ),
                    ),
                    child: Text(e.value, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF555555),
                    )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── 학년 선택 (All / 1 / 2 / 3학년)
          _buildSectionTitle('학년 (모든 학년이면 All)'),
          Row(
            children: _gradeYearLabels.entries.map((e) {
              final selected = _gradeYear == e.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _gradeYear = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1A2D5A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFF1A2D5A) : const Color(0xFFDDDDDD),
                      ),
                    ),
                    child: Text(e.value, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF555555),
                    )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── 강의 유형
          _buildSectionTitle('강의 유형'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _typeLabels.entries.map((e) {
              final selected = _lectureType == e.key;
              return GestureDetector(
                onTap: () => setState(() => _lectureType = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF7C3AED) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFF7C3AED) : const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: Text(e.value, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF555555),
                  )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── 해시태그
          _buildSectionTitle('해시태그 (쉼표로 구분)'),
          TextFormField(
            controller: _hashtagCtrl,
            decoration: _inputDecoration('예: 수학, 고등, 곱셈공식', Icons.tag_rounded),
          ),
          const SizedBox(height: 16),

          // ── 시리즈명
          _buildSectionTitle('시리즈명'),
          TextFormField(
            controller: _seriesCtrl,
            decoration: _inputDecoration('예: 곱셈공식 완성', Icons.library_books_rounded),
          ),
          const SizedBox(height: 16),

          // ── 강의 설명
          _buildSectionTitle('강의 설명'),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: _inputDecoration('강의 내용을 간단히 설명해주세요.', Icons.description_rounded),
          ),
          const SizedBox(height: 28),

          // ── 등록 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitLecture,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2D5A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _isLoading
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('등록 중...', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ])
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text('강의 등록하기', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
                      )),
                    ]),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildDetectedCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 8),
          Text(
            _videoType == 'shorts' ? '✅ YouTube Shorts 감지' : '✅ YouTube 영상 감지',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
          ),
        ]),
        const SizedBox(height: 10),
        // 썸네일 미리보기
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://img.youtube.com/vi/$_detectedVideoId/mqdefault.jpg',
              width: 110, height: 70, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 110, height: 70, color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('비디오 ID: $_detectedVideoId',
              style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('유형: ${_videoType == 'shorts' ? '두번설명 (60초 이하)' : '일반 영상'}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF166534))),
            const SizedBox(height: 4),
            Text('썸네일: 자동 설정됨',
              style: const TextStyle(fontSize: 12, color: Color(0xFF166534))),
          ])),
        ]),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151),
      )),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1A2D5A), width: 1.5),
      ),
    );
  }
}

// ─── 강의 목록 탭 ─────────────────────────────────────────────
class _LectureListTab extends StatelessWidget {
  const _LectureListTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lectures = appState.allLectures;

    return Column(children: [
      // 헤더
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(children: [
          Text('총 ${lectures.length}개 강의',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2D5A))),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await appState.refreshLectures();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('강의 목록을 새로고침했습니다.'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: Row(children: [
              const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              const Text('새로고침', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
            ]),
          ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFEEEEEE)),
      // 강의 목록
      Expanded(
        child: lectures.isEmpty
            ? const Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.video_library_outlined, size: 48, color: Color(0xFFCCCCCC)),
                  SizedBox(height: 12),
                  Text('등록된 강의가 없습니다.', style: TextStyle(color: Color(0xFFAAAAAA))),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: lectures.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                itemBuilder: (context, i) => _LectureListItem(
                  lecture: lectures[i],
                  index: i + 1,
                ),
              ),
      ),
    ]);
  }
}

class _LectureListItem extends StatelessWidget {
  final Lecture lecture;
  final int index;

  const _LectureListItem({required this.lecture, required this.index});

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _subjectColor(lecture.subject);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // 인덱스 번호
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text('$index',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        ),
        const SizedBox(width: 10),
        // 썸네일
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            lecture.effectiveThumbnailUrl.isNotEmpty
                ? lecture.effectiveThumbnailUrl
                : 'https://img.youtube.com/vi/default/mqdefault.jpg',
            width: 70, height: 45, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 70, height: 45,
              color: Colors.grey[200],
              child: const Icon(Icons.videocam_outlined, size: 20, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 강의 정보
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lecture.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: subjectColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(lecture.subject,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: subjectColor)),
            ),
            const SizedBox(width: 6),
            Text(lecture.instructor,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(width: 6),
            Text(lecture.gradeText,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ]),
        ])),
        // 강의 유형 배지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: lecture.lectureType == 'shorts'
                ? const Color(0xFFFFF7ED)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(lecture.lectureTypeText, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: lecture.lectureType == 'shorts'
                ? const Color(0xFFEA580C)
                : const Color(0xFF2563EB),
          )),
        ),
      ]),
    );
  }

  Color _subjectColor(String subject) {
    switch (subject) {
      case '수학': return const Color(0xFF10B981);
      case '과학': return const Color(0xFF8B5CF6);
      case '국어': return const Color(0xFFEF4444);
      case '영어': return const Color(0xFF3B82F6);
      case '역사': return const Color(0xFF78716C);
      case '두번설명': return const Color(0xFFF97316);
      default: return const Color(0xFF6B7280);
    }
  }
}

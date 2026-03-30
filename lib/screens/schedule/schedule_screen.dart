import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../services/translations.dart';
import '../../models/note.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ScheduleEvent> _events;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<String> _alertOptions = ['정시', '10분전', '30분전', '1시간전', '1일전', '1주전'];
  final List<String> _repeatOptions = ['없음', '매일', '매주', '매월', '매년'];
  final List<Color> _colorOptions = [
    AppColors.primary, AppColors.accent, AppColors.math,
    AppColors.science, AppColors.korean, AppColors.social,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _events = ContentService().getScheduleEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ScheduleEvent> _eventsForDay(DateTime day) => _events.where((e) =>
    e.dateTime.year == day.year &&
    e.dateTime.month == day.month &&
    e.dateTime.day == day.day).toList();

  List<ScheduleEvent> get _myEvents =>
      _events.where((e) => !e.isAppEvent).toList();

  List<ScheduleEvent> get _appEvents =>
      _events.where((e) => e.isAppEvent).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppTranslations.tLang(context.read<AppState>().selectedLanguage, 'schedule_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '내 일정'), Tab(text: '2공 행사/이벤트')],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          dividerColor: AppColors.divider,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventSheet(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('일정 추가', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyScheduleTab(),
          _buildAppEventsTab(),
        ],
      ),
    );
  }

  // ── 내 일정 탭 ────────────────────────────────────
  Widget _buildMyScheduleTab() {
    return Column(children: [
      // 달력
      _buildCalendar(),
      // 선택된 날 일정
      Expanded(child: _buildDayEvents()),
    ]);
  }

  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(children: [
        // 월 네비게이션
        Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
            onPressed: () => setState(() =>
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
          ),
          Expanded(
            child: Text(
              '${_focusedDay.year}년 ${_focusedDay.month}월',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
            onPressed: () => setState(() =>
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
          ),
        ]),
        // 요일 헤더
        Row(children: ['일', '월', '화', '수', '목', '금', '토'].map((d) =>
          Expanded(child: Center(child: Text(d,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: d == '일' ? AppColors.korean : d == '토' ? AppColors.english : AppColors.textSecondary))))).toList()),
        const SizedBox(height: 6),
        // 날짜 그리드
        _buildDayGrid(),
      ]),
    );
  }

  Widget _buildDayGrid() {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final startOffset = firstDay.weekday % 7;
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) => Row(
        children: List.generate(7, (col) {
          final index = row * 7 + col;
          final dayNum = index - startOffset + 1;
          if (dayNum < 1 || dayNum > lastDay.day) return const Expanded(child: SizedBox(height: 40));

          final day = DateTime(_focusedDay.year, _focusedDay.month, dayNum);
          final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
          final isSelected = day.year == _selectedDay.year && day.month == _selectedDay.month && day.day == _selectedDay.day;
          final dayEvents = _eventsForDay(day);
          final isSunday = col == 0;
          final isSaturday = col == 6;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = day),
              child: Container(
                height: 44,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : isToday ? AppColors.primary.withValues(alpha: 0.08) : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$dayNum',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w400,
                      color: isSelected ? Colors.white
                          : isToday ? AppColors.primary
                          : isSunday ? AppColors.korean
                          : isSaturday ? AppColors.english
                          : AppColors.textPrimary,
                    )),
                  if (dayEvents.isNotEmpty)
                    Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: dayEvents.take(3).map((e) => Container(
                        width: 5, height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.8) : e.color,
                          shape: BoxShape.circle),
                      )).toList()),
                ]),
              ),
            ),
          );
        }),
      )),
    );
  }

  Widget _buildDayEvents() {
    final dayEvents = _eventsForDay(_selectedDay);
    final today = DateTime.now();
    final isToday = _selectedDay.year == today.year &&
        _selectedDay.month == today.month &&
        _selectedDay.day == today.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            isToday
                ? '오늘 (${_selectedDay.month}/${_selectedDay.day})'
                : '${_selectedDay.month}월 ${_selectedDay.day}일',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        Expanded(
          child: dayEvents.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.event_note_outlined, size: 52, color: AppColors.textHint.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    const Text('이 날은 일정이 없어요', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('+ 버튼으로 일정을 추가해보세요', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: dayEvents.length,
                  itemBuilder: (_, i) => _buildEventCard(dayEvents[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildEventCard(ScheduleEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // 왼쪽 컬러 바
        Container(
          width: 5,
          height: 72,
          decoration: BoxDecoration(
            color: event.color,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              if (event.content.isNotEmpty)
                Text(event.content,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 13, color: event.color),
                const SizedBox(width: 3),
                Text('${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 12, color: event.color, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Icon(Icons.notifications_outlined, size: 13, color: AppColors.textHint),
                const SizedBox(width: 3),
                Text(event.alertBefore, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                if (event.repeat != '없음') ...[
                  const SizedBox(width: 8),
                  Icon(Icons.repeat_rounded, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Text(event.repeat, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ]),
            ]),
          ),
        ),
        // 삭제 버튼
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textHint),
          onPressed: () => _deleteEvent(event),
        ),
      ]),
    );
  }

  // ── 2공 행사/이벤트 탭 ───────────────────────────
  Widget _buildAppEventsTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _appEvents.length,
      itemBuilder: (_, i) {
        final e = _appEvents[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 헤더 배너
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [e.color, e.color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20)),
                    child: const Text('2공 이벤트',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                ])),
                const Icon(Icons.celebration_rounded, color: Colors.white, size: 40),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: e.color),
                  const SizedBox(width: 6),
                  Text('${e.dateTime.month}월 ${e.dateTime.day}일 (${_weekdayText(e.dateTime.weekday)}) ${e.dateTime.hour.toString().padLeft(2, '0')}:${e.dateTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: e.color)),
                ]),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: e.color,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() => _events.add(ScheduleEvent(
                      id: 'added_${e.id}', title: e.title, content: e.content,
                      dateTime: e.dateTime, alertBefore: '1일전', repeat: '없음',
                      color: e.color, isAppEvent: false,
                    )));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('\'${e.title}\' 일정이 내 일정에 추가되었습니다!')));
                  },
                  child: const Text('내 일정에 추가', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  String _weekdayText(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }

  // ── 일정 추가 시트 ────────────────────────────────
  void _showAddEventSheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedAlert = '30분전';
    String selectedRepeat = '없음';
    Color selectedColor = AppColors.primary;
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime selectedDate = _selectedDay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('일정 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              // 제목
              TextField(controller: titleCtrl,
                decoration: const InputDecoration(labelText: '제목 *', hintText: '일정 제목을 입력하세요')),
              const SizedBox(height: 10),
              // 내용
              TextField(controller: contentCtrl, maxLines: 2,
                decoration: const InputDecoration(labelText: '내용', hintText: '일정 내용을 입력하세요 (선택)')),
              const SizedBox(height: 14),
              // 날짜/시간
              Row(children: [
                Expanded(child: _buildPickerTile(
                  Icons.calendar_today_rounded,
                  '${selectedDate.month}월 ${selectedDate.day}일',
                  () async {
                    final d = await showDatePicker(context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d != null) setModalState(() => selectedDate = d);
                  },
                )),
                const SizedBox(width: 8),
                Expanded(child: _buildPickerTile(
                  Icons.access_time_rounded,
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  () async {
                    final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                    if (t != null) setModalState(() => selectedTime = t);
                  },
                )),
              ]),
              const SizedBox(height: 14),
              // 알림
              _buildDropdownRow('알림', selectedAlert, _alertOptions,
                (v) => setModalState(() => selectedAlert = v!)),
              const SizedBox(height: 10),
              // 반복
              _buildDropdownRow('반복', selectedRepeat, _repeatOptions,
                (v) => setModalState(() => selectedRepeat = v!)),
              const SizedBox(height: 14),
              // 색상 선택
              const Text('색상', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(children: _colorOptions.map((c) => GestureDetector(
                onTap: () => setModalState(() => selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32, height: 32,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedColor == c ? AppColors.textPrimary : Colors.transparent,
                      width: 2.5)),
                  child: selectedColor == c
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : null,
                ),
              )).toList()),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;
                    final newEvent = ScheduleEvent(
                      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text, content: contentCtrl.text,
                      dateTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day,
                        selectedTime.hour, selectedTime.minute),
                      alertBefore: selectedAlert, repeat: selectedRepeat,
                      color: selectedColor, isAppEvent: false,
                    );
                    setState(() => _events.add(newEvent));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('일정이 추가되었습니다!')));
                  },
                  child: const Text('일정 추가'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile(IconData icon, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> options,
      ValueChanged<String?> onChanged) {
    return Row(children: [
      SizedBox(width: 44, child: Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
      const SizedBox(width: 12),
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          onChanged: onChanged,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        )),
      )),
    ]);
  }

  void _deleteEvent(ScheduleEvent event) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('일정 삭제'),
      content: Text('\'${event.title}\' 일정을 삭제하시겠습니까?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            setState(() => _events.removeWhere((e) => e.id == event.id));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('일정이 삭제되었습니다.')));
          },
          child: const Text('삭제'),
        ),
      ],
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/models/attendance_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/app_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _currentMonth = DateTime.now();
  MonthlyAttendance? _attendance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    if (uid.isEmpty) return;
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    MonthlyAttendance? att = await db.getAttendance(uid, _currentMonth.year, _currentMonth.month);
    att ??= MonthlyAttendance(
      id: '${uid}_${_currentMonth.year}_${_currentMonth.month}',
      uid: uid,
      year: _currentMonth.year,
      month: _currentMonth.month,
    );
    setState(() { _attendance = att; _loading = false; });
  }

  Future<void> _markDay(int day, AttendanceStatus status) async {
    if (_attendance == null) return;
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final updated = _attendance!.copyWithDay(day, status);
    await DatabaseHelper.instance.saveAttendance(updated);
    setState(() => _attendance = updated);
  }

  void _previousMonth() {
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
    _loadAttendance();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) return;
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));
    _loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = context.watch<AuthProvider>().user?.isAdminLike ?? false;
    final arabicMonths = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل الحضور'),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.people_outline),
                onPressed: () => _showAllUsersAttendance(context),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Month navigator
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(onPressed: _previousMonth, icon: const Icon(Icons.chevron_right)),
                          Text(
                            '${arabicMonths[_currentMonth.month - 1]} ${_currentMonth.year}',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            onPressed: _nextMonth,
                            icon: Icon(Icons.chevron_left,
                              color: (_currentMonth.year == DateTime.now().year && _currentMonth.month == DateTime.now().month)
                                  ? AppColors.text3Light : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Summary
                    if (_attendance != null) _SummaryRow(attendance: _attendance!),
                    const SizedBox(height: 16),
                    // Calendar
                    if (_attendance != null) _CalendarGrid(
                      year: _currentMonth.year,
                      month: _currentMonth.month,
                      attendance: _attendance!,
                      isAdmin: isAdmin,
                      onMarkDay: _markDay,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  void _showAllUsersAttendance(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة مخصصة للأدمن — قريباً')),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final MonthlyAttendance attendance;
  const _SummaryRow({required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatBox('حضور', '${attendance.presentCount}', AppColors.ok)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox('غياب', '${attendance.absentCount}', AppColors.err)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox('تأخير', '${attendance.lateCount}', AppColors.warn)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox('نسبة', '${(attendance.attendanceRate * 100).toStringAsFixed(0)}%', AppColors.accent)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final MonthlyAttendance attendance;
  final bool isAdmin;
  final void Function(int, AttendanceStatus) onMarkDay;

  const _CalendarGrid({
    required this.year, required this.month, required this.attendance,
    required this.isAdmin, required this.onMarkDay,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOfMonth = DateTime(year, month, 1);
    // Sunday=0, Saturday=6 → we want Saturday=0 for Arabic (RTL week)
    int startWeekday = firstDayOfMonth.weekday % 7; // Mon=1..Sun=0 → Mon=1 in our case
    // for RTL calendar starting Saturday: need to adjust
    final dayHeaders = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: dayHeaders.map((d) => Expanded(
              child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
            )).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (ctx, i) {
              if (i < startWeekday) return const SizedBox();
              final day = i - startWeekday + 1;
              final status = attendance.statusForDay(day);
              final isToday = DateTime.now().year == year &&
                  DateTime.now().month == month && DateTime.now().day == day;
              return _DayCell(
                day: day, status: status, isToday: isToday, isAdmin: isAdmin,
                onTap: isAdmin ? () => _showMarkSheet(ctx, day, status) : null,
              );
            },
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12, runSpacing: 6,
            children: [
              _LegendItem('✓ حضور', AppColors.ok),
              _LegendItem('✗ غياب', AppColors.err),
              _LegendItem('~ تأخير', AppColors.warn),
              _LegendItem('★ إجازة', AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  void _showMarkSheet(BuildContext context, int day, AttendanceStatus current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('يوم $day — تغيير الحضور', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...AttendanceStatus.values.where((s) => s != AttendanceStatus.none).map((s) {
              final att = MonthlyAttendance(id: '', uid: '', year: 0, month: 0).copyWithDay(day, s);
              final dayVal = att.statusForDay(day);
              final label = MonthlyAttendance(id:'', uid:'', year: 0, month: 0).copyWithDay(day, s).statusForDay(day);
              return ListTile(
                onTap: () {
                  onMarkDay(day, s);
                  Navigator.pop(context);
                },
                title: Text(
                  '${_statusSymbol(s)} ${_statusLabel(s)}',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                ),
                selected: current == s,
                selectedTileColor: AppColors.accentDark,
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _statusSymbol(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return '✓';
      case AttendanceStatus.absent: return '✗';
      case AttendanceStatus.late: return '~';
      case AttendanceStatus.excused: return 'E';
      case AttendanceStatus.holiday: return '★';
      default: return '';
    }
  }

  String _statusLabel(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return 'حضور';
      case AttendanceStatus.absent: return 'غياب';
      case AttendanceStatus.late: return 'تأخير';
      case AttendanceStatus.excused: return 'عذر';
      case AttendanceStatus.holiday: return 'إجازة';
      default: return '';
    }
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final AttendanceStatus status;
  final bool isToday;
  final bool isAdmin;
  final VoidCallback? onTap;

  const _DayCell({required this.day, required this.status, this.isToday = false, this.isAdmin = false, this.onTap});

  Color get _bgColor {
    switch (status) {
      case AttendanceStatus.present: return AppColors.ok.withOpacity(0.15);
      case AttendanceStatus.absent: return AppColors.err.withOpacity(0.15);
      case AttendanceStatus.late: return AppColors.warn.withOpacity(0.15);
      case AttendanceStatus.excused: return AppColors.info.withOpacity(0.15);
      case AttendanceStatus.holiday: return AppColors.accent.withOpacity(0.15);
      default: return Colors.transparent;
    }
  }

  Color get _symbolColor {
    switch (status) {
      case AttendanceStatus.present: return AppColors.ok;
      case AttendanceStatus.absent: return AppColors.err;
      case AttendanceStatus.late: return AppColors.warn;
      case AttendanceStatus.excused: return AppColors.info;
      case AttendanceStatus.holiday: return AppColors.accent;
      default: return AppColors.text3Light;
    }
  }

  String get _symbol {
    switch (status) {
      case AttendanceStatus.present: return '✓';
      case AttendanceStatus.absent: return '✗';
      case AttendanceStatus.late: return '~';
      case AttendanceStatus.excused: return 'E';
      case AttendanceStatus.holiday: return '★';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday ? AppColors.accent : Colors.transparent,
            width: isToday ? 2 : 0,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isToday ? AppColors.accent : null,
                ),
              ),
            ),
            if (_symbol.isNotEmpty)
              Positioned(
                top: 2, left: 2,
                child: Text(_symbol, style: TextStyle(fontSize: 8, color: _symbolColor)),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: color, fontWeight: FontWeight.w600));
  }
}

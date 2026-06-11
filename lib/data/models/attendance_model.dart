import 'dart:convert';

enum AttendanceStatus { present, absent, late, excused, holiday, none }

class AttendanceDay {
  final int day;
  final AttendanceStatus status;

  const AttendanceDay({required this.day, this.status = AttendanceStatus.none});

  String get symbol {
    switch (status) {
      case AttendanceStatus.present: return '✓';
      case AttendanceStatus.absent: return '✗';
      case AttendanceStatus.late: return '~';
      case AttendanceStatus.excused: return 'E';
      case AttendanceStatus.holiday: return '★';
      case AttendanceStatus.none: return '';
    }
  }

  String get label {
    switch (status) {
      case AttendanceStatus.present: return 'حضور';
      case AttendanceStatus.absent: return 'غياب';
      case AttendanceStatus.late: return 'تأخير';
      case AttendanceStatus.excused: return 'عذر';
      case AttendanceStatus.holiday: return 'إجازة';
      case AttendanceStatus.none: return '';
    }
  }
}

class MonthlyAttendance {
  final String id; // uid_YYYY-MM
  final String uid;
  final int year;
  final int month;
  final Map<int, AttendanceStatus> days; // day number → status

  const MonthlyAttendance({
    required this.id,
    required this.uid,
    required this.year,
    required this.month,
    this.days = const {},
  });

  int get presentCount => days.values.where((s) => s == AttendanceStatus.present).length;
  int get absentCount => days.values.where((s) => s == AttendanceStatus.absent).length;
  int get lateCount => days.values.where((s) => s == AttendanceStatus.late).length;
  int get excusedCount => days.values.where((s) => s == AttendanceStatus.excused).length;
  int get totalMarked => days.values.where((s) => s != AttendanceStatus.none).length;

  double get attendanceRate {
    if (totalMarked == 0) return 0;
    return presentCount / totalMarked;
  }

  AttendanceStatus statusForDay(int day) => days[day] ?? AttendanceStatus.none;

  MonthlyAttendance copyWithDay(int day, AttendanceStatus status) {
    final newDays = Map<int, AttendanceStatus>.from(days);
    newDays[day] = status;
    return MonthlyAttendance(id: id, uid: uid, year: year, month: month, days: newDays);
  }

  factory MonthlyAttendance.fromJson(Map<String, dynamic> json) {
    final daysMap = <int, AttendanceStatus>{};
    if (json['days'] is Map) {
      (json['days'] as Map).forEach((k, v) {
        final day = int.tryParse(k.toString());
        if (day != null) {
          daysMap[day] = _parseStatus(v.toString());
        }
      });
    }
    return MonthlyAttendance(
      id: json['id']?.toString() ?? '',
      uid: json['uid']?.toString() ?? '',
      year: int.tryParse(json['year']?.toString() ?? '') ?? DateTime.now().year,
      month: int.tryParse(json['month']?.toString() ?? '') ?? DateTime.now().month,
      days: daysMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'year': year,
    'month': month,
    'days': days.map((k, v) => MapEntry(k.toString(), _statusToString(v))),
  };

  String toJsonString() => jsonEncode(toJson());

  static AttendanceStatus _parseStatus(String s) {
    switch (s) {
      case 'present': return AttendanceStatus.present;
      case 'absent': return AttendanceStatus.absent;
      case 'late': return AttendanceStatus.late;
      case 'excused': return AttendanceStatus.excused;
      case 'holiday': return AttendanceStatus.holiday;
      default: return AttendanceStatus.none;
    }
  }

  static String _statusToString(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return 'present';
      case AttendanceStatus.absent: return 'absent';
      case AttendanceStatus.late: return 'late';
      case AttendanceStatus.excused: return 'excused';
      case AttendanceStatus.holiday: return 'holiday';
      case AttendanceStatus.none: return 'none';
    }
  }
}

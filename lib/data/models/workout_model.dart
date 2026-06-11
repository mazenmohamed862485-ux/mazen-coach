import 'dart:convert';

class WorkoutSet {
  final double weight;
  final int reps;
  final bool isDone;
  final String? note;

  const WorkoutSet({
    this.weight = 0,
    this.reps = 0,
    this.isDone = false,
    this.note,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    weight: double.tryParse(json['w']?.toString() ?? '0') ?? 0,
    reps: int.tryParse(json['r']?.toString() ?? '0') ?? 0,
    isDone: json['done'] == true,
    note: json['note']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'w': weight,
    'r': reps,
    'done': isDone,
    if (note != null) 'note': note,
  };

  WorkoutSet copyWith({double? weight, int? reps, bool? isDone, String? note}) =>
      WorkoutSet(
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        isDone: isDone ?? this.isDone,
        note: note ?? this.note,
      );

  // Epley 1RM formula
  double get epley1RM {
    if (weight <= 0 || reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  double get volume => weight * reps;
}

class ExerciseLog {
  final String name;
  final List<WorkoutSet> sets;
  final String? note;
  final String? muscle;
  final bool isPrimary;

  const ExerciseLog({
    required this.name,
    this.sets = const [],
    this.note,
    this.muscle,
    this.isPrimary = false,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
    name: json['name']?.toString() ?? '',
    sets: (json['sets'] as List<dynamic>? ?? [])
        .map((s) => WorkoutSet.fromJson(Map<String, dynamic>.from(s)))
        .toList(),
    note: json['note']?.toString(),
    muscle: json['muscle']?.toString(),
    isPrimary: json['primary'] == true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets.map((s) => s.toJson()).toList(),
    if (note != null) 'note': note,
    if (muscle != null) 'muscle': muscle,
    'primary': isPrimary,
  };

  WorkoutSet? get bestSet {
    if (sets.isEmpty) return null;
    return sets.reduce((a, b) => a.epley1RM >= b.epley1RM ? a : b);
  }

  double get totalVolume =>
      sets.fold(0, (sum, s) => sum + s.volume);

  double get best1RM => bestSet?.epley1RM ?? 0;
}

class WorkoutLog {
  final String id; // uid_YYYY-MM-DD_sessionName
  final String uid;
  final String date; // YYYY-MM-DD
  final String programId;
  final String sessionName;
  final List<ExerciseLog> exercises;
  final int durationMinutes;
  final String? note;
  final DateTime createdAt;
  final bool synced;

  const WorkoutLog({
    required this.id,
    required this.uid,
    required this.date,
    required this.programId,
    required this.sessionName,
    this.exercises = const [],
    this.durationMinutes = 0,
    this.note,
    required this.createdAt,
    this.synced = false,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
    id: json['id']?.toString() ?? '',
    uid: json['uid']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    programId: json['programId']?.toString() ?? '',
    sessionName: json['sessionName']?.toString() ?? '',
    exercises: (json['exercises'] as List<dynamic>? ?? [])
        .map((e) => ExerciseLog.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    durationMinutes: int.tryParse(json['durationMinutes']?.toString() ?? '0') ?? 0,
    note: json['note']?.toString(),
    createdAt: json['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['createdAt'].toString()) ?? 0)
        : DateTime.now(),
    synced: json['synced'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'date': date,
    'programId': programId,
    'sessionName': sessionName,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'durationMinutes': durationMinutes,
    if (note != null) 'note': note,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'synced': synced,
  };

  String toJsonString() => jsonEncode(toJson());

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
  double get totalVolume => exercises.fold(0, (sum, e) => sum + e.totalVolume);

  WorkoutLog copyWith({bool? synced}) => WorkoutLog(
    id: id,
    uid: uid,
    date: date,
    programId: programId,
    sessionName: sessionName,
    exercises: exercises,
    durationMinutes: durationMinutes,
    note: note,
    createdAt: createdAt,
    synced: synced ?? this.synced,
  );
}

class Exercise {
  final String name;
  final bool isPrimary;
  final String warmupSets; // e.g. "1~2"
  final int workSets;
  final String reps; // e.g. "6~8"
  final String rest; // e.g. "3~5" (minutes)
  final String muscle;
  final String alt1;
  final String alt2;
  final String note;

  const Exercise({
    required this.name,
    this.isPrimary = false,
    this.warmupSets = '1',
    this.workSets = 3,
    this.reps = '8~12',
    this.rest = '2~3',
    this.muscle = '',
    this.alt1 = '',
    this.alt2 = '',
    this.note = '',
  });

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    name: map['name']?.toString() ?? '',
    isPrimary: map['primary'] == true,
    warmupSets: map['wu']?.toString() ?? '1',
    workSets: int.tryParse(map['sets']?.toString() ?? '3') ?? 3,
    reps: map['reps']?.toString() ?? '8~12',
    rest: map['rest']?.toString() ?? '2~3',
    muscle: map['muscle']?.toString() ?? '',
    alt1: map['alt1']?.toString() ?? '',
    alt2: map['alt2']?.toString() ?? '',
    note: map['note']?.toString() ?? '',
  );

  String get repsRange {
    final parts = reps.split('~');
    if (parts.length == 2) return '${parts[0]}-${parts[1]}';
    return reps;
  }

  String get restRange {
    final parts = rest.split('~');
    if (parts.length == 2) return '${parts[0]}-${parts[1]} دقيقة';
    return '$rest دقيقة';
  }
}

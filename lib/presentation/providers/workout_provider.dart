import 'package:flutter/foundation.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/workout_model.dart';
import '../../data/remote/gas_api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/evaluator.dart';

class ActiveSession {
  final String programId;
  final String sessionName;
  final DateTime startedAt;
  final List<ExerciseLog> exercises;

  ActiveSession({
    required this.programId,
    required this.sessionName,
    required this.startedAt,
    required this.exercises,
  });

  int get elapsedMinutes =>
      DateTime.now().difference(startedAt).inMinutes;
}

class WorkoutProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  final GasApiService _api;
  String? _uid;

  WorkoutProvider({required DatabaseHelper db, required GasApiService api})
      : _db = db,
        _api = api;

  List<WorkoutLog> _recentLogs = [];
  ActiveSession? _activeSession;
  bool _isLoading = false;
  String? _error;

  // Rest timer
  int _restSeconds = AppConstants.defaultRestSeconds;
  int _restRemaining = 0;
  bool _restRunning = false;

  List<WorkoutLog> get recentLogs => _recentLogs;
  ActiveSession? get activeSession => _activeSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession => _activeSession != null;
  int get restRemaining => _restRemaining;
  bool get restRunning => _restRunning;

  void setUser(String? uid) {
    if (_uid != uid) {
      _uid = uid;
      if (uid != null) loadRecentLogs();
    }
  }

  Future<void> loadRecentLogs() async {
    if (_uid == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _recentLogs = await _db.getWorkoutLogsByUid(_uid!, limit: 50);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> getSessionsForProgram(String programId, int days) {
    final prog = AppConstants.programs[programId];
    if (prog == null) return [];
    final sessions = prog['sessions'] as List<dynamic>? ?? [];
    return sessions.take(days).map((s) => s.toString()).toList();
  }

  List<Exercise> getExercisesForSession(String sessionName) {
    final data = _getExerciseData(sessionName);
    return data.map((m) => Exercise.fromMap(m)).toList();
  }

  void startSession(String programId, String sessionName) {
    final exercises = getExercisesForSession(sessionName)
        .map((ex) => ExerciseLog(
              name: ex.name,
              muscle: ex.muscle,
              isPrimary: ex.isPrimary,
              sets: List.generate(ex.workSets, (_) => const WorkoutSet()),
            ))
        .toList();

    _activeSession = ActiveSession(
      programId: programId,
      sessionName: sessionName,
      startedAt: DateTime.now(),
      exercises: exercises,
    );
    notifyListeners();
  }

  void updateSet(int exIndex, int setIndex, WorkoutSet updatedSet) {
    if (_activeSession == null) return;
    final ex = _activeSession!.exercises[exIndex];
    final newSets = List<WorkoutSet>.from(ex.sets);
    if (setIndex < newSets.length) {
      newSets[setIndex] = updatedSet;
    }
    _activeSession!.exercises[exIndex] = ExerciseLog(
      name: ex.name,
      sets: newSets,
      muscle: ex.muscle,
      isPrimary: ex.isPrimary,
      note: ex.note,
    );
    notifyListeners();
  }

  Future<WorkoutLog?> finishSession(String uid) async {
    if (_activeSession == null) return null;
    final session = _activeSession!;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final id = '${uid}_${dateStr}_${session.sessionName}';

    final log = WorkoutLog(
      id: id,
      uid: uid,
      date: dateStr,
      programId: session.programId,
      sessionName: session.sessionName,
      exercises: session.exercises
          .where((ex) => ex.sets.any((s) => s.reps > 0))
          .toList(),
      durationMinutes: session.elapsedMinutes,
      createdAt: now,
    );

    await _db.saveWorkoutLog(log);
    _recentLogs = [log, ..._recentLogs.take(49).toList()];
    _activeSession = null;

    // Sync in background
    _syncLog(log);
    notifyListeners();
    return log;
  }

  void cancelSession() {
    _activeSession = null;
    notifyListeners();
  }

  Future<void> _syncLog(WorkoutLog log) async {
    if (!_api.isConfigured) return;
    try {
      final res = await _api.syncWorkoutLog(log.toJson());
      if (res.ok) {
        final synced = log.copyWith(synced: true);
        await _db.saveWorkoutLog(synced);
      }
    } catch (_) {}
  }

  Future<List<WorkoutLog>> getExerciseHistory(String exerciseName) async {
    if (_uid == null) return [];
    return _db.getExerciseHistory(_uid!, exerciseName);
  }

  EvaluationResult? evaluateCurrentSet({
    required int exIndex,
    required int setIndex,
    required WorkoutSet currentSet,
    required String exerciseName,
  }) {
    if (_recentLogs.isEmpty) return null;
    final history = _recentLogs
        .where((log) => log.exercises.any((e) => e.name == exerciseName))
        .toList();
    if (history.isEmpty) return null;

    WorkoutSet? prev;
    for (final log in history) {
      final ex = log.exercises.firstWhere(
        (e) => e.name == exerciseName,
        orElse: () => ExerciseLog(name: ''),
      );
      if (ex.name.isEmpty) continue;
      final bs = Evaluator.bestSet(ex.sets);
      if (bs != null) { prev = bs; break; }
    }

    return Evaluator.evaluate(
      previous: prev,
      current: currentSet,
      history: history,
      exerciseName: exerciseName,
    );
  }

  // ── Rest Timer ────────────────────────────────────────────────────
  void startRestTimer(int seconds) {
    _restSeconds = seconds;
    _restRemaining = seconds;
    _restRunning = true;
    notifyListeners();
    _tickRest();
  }

  Future<void> _tickRest() async {
    while (_restRunning && _restRemaining > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_restRunning) break;
      _restRemaining--;
      notifyListeners();
    }
    _restRunning = false;
    notifyListeners();
  }

  void stopRestTimer() {
    _restRunning = false;
    _restRemaining = 0;
    notifyListeners();
  }

  List<Map<String, dynamic>> _getExerciseData(String sessionName) {
    final allExercises = _exercises;
    return allExercises[sessionName] ?? [];
  }

  static final Map<String, List<Map<String, dynamic>>> _exercises = {
    'Upper A': [
      {'name': 'Smith High Incline Press', 'primary': true, 'wu': '1~2', 'sets': 2, 'reps': '6~8', 'rest': '3~5', 'muscle': 'صدر عالي', 'alt1': 'DB High Incline Press', 'note': 'ضم ايدك لجوه عشان تحاكي اتجاه الياف الصدر العالي'},
      {'name': 'Machine Wide Grip Row', 'primary': true, 'wu': '1~2', 'sets': 2, 'reps': '6~8', 'rest': '3~5', 'muscle': 'ظهر عريض', 'alt1': 'Seated Cable Row Wide', 'note': 'فتح الكوع للجانب'},
      {'name': 'Machine Shoulder Press', 'primary': false, 'wu': '1', 'sets': 2, 'reps': '8~10', 'rest': '2~3', 'muscle': 'كتف أمامي', 'alt1': 'DB Shoulder Press'},
      {'name': 'Cable Lateral Raise', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '12~15', 'rest': '1~2', 'muscle': 'كتف جانبي', 'alt1': 'DB Lateral Raise'},
      {'name': 'Cable Tricep Pushdown', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '1~2', 'muscle': 'ترايسبس', 'alt1': 'Overhead Tricep Extension'},
      {'name': 'Cable Curl', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '1~2', 'muscle': 'بايسبس', 'alt1': 'DB Curl'},
    ],
    'Lower A': [
      {'name': 'Squat', 'primary': true, 'wu': '2~3', 'sets': 3, 'reps': '5~8', 'rest': '3~5', 'muscle': 'رباعية', 'alt1': 'Leg Press', 'note': 'ظهرك مستقيم'},
      {'name': 'Romanian Deadlift', 'primary': true, 'wu': '1~2', 'sets': 3, 'reps': '8~10', 'rest': '3~4', 'muscle': 'وركين', 'alt1': 'Leg Curl Machine'},
      {'name': 'Leg Press', 'primary': false, 'wu': '1', 'sets': 3, 'reps': '10~12', 'rest': '2~3', 'muscle': 'رباعية'},
      {'name': 'Leg Curl', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '2', 'muscle': 'وركين'},
      {'name': 'Calf Raise', 'primary': false, 'wu': '0', 'sets': 4, 'reps': '12~15', 'rest': '1~2', 'muscle': 'ساق'},
      {'name': 'Plank', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '30~60 sec', 'rest': '1', 'muscle': 'بطن'},
    ],
    'Upper B': [
      {'name': 'Incline Barbell Press', 'primary': true, 'wu': '2~3', 'sets': 3, 'reps': '5~7', 'rest': '3~5', 'muscle': 'صدر', 'alt1': 'DB Incline Press'},
      {'name': 'Weighted Pull Up', 'primary': true, 'wu': '1~2', 'sets': 3, 'reps': '4~6', 'rest': '3~5', 'muscle': 'ظهر', 'alt1': 'Lat Pulldown'},
      {'name': 'Machine Chest Fly', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '12~15', 'rest': '1~2', 'muscle': 'صدر داخلي'},
      {'name': 'Cable Face Pull', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '15~20', 'rest': '1~2', 'muscle': 'كتف خلفي'},
      {'name': 'Overhead Tricep Extension', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '1~2', 'muscle': 'ترايسبس'},
      {'name': 'Hammer Curl', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '1~2', 'muscle': 'بايسبس'},
    ],
    'Lower B': [
      {'name': 'Deadlift', 'primary': true, 'wu': '2~3', 'sets': 2, 'reps': '4~6', 'rest': '4~5', 'muscle': 'ظهر/وركين', 'alt1': 'Trap Bar Deadlift', 'note': 'الحوض منخفض في البداية'},
      {'name': 'Hack Squat', 'primary': true, 'wu': '1~2', 'sets': 3, 'reps': '8~10', 'rest': '3~4', 'muscle': 'رباعية', 'alt1': 'Bulgarian Split Squat'},
      {'name': 'Hip Thrust', 'primary': false, 'wu': '1', 'sets': 3, 'reps': '10~12', 'rest': '2~3', 'muscle': 'الأرداف'},
      {'name': 'Leg Extension', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '12~15', 'rest': '1~2', 'muscle': 'رباعية'},
      {'name': 'Seated Leg Curl', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '2', 'muscle': 'وركين'},
      {'name': 'Ab Wheel', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '8~12', 'rest': '1~2', 'muscle': 'بطن'},
    ],
    'PUSH': [
      {'name': 'Bench Press', 'primary': true, 'wu': '2~3', 'sets': 3, 'reps': '5~7', 'rest': '3~5', 'muscle': 'صدر', 'alt1': 'Machine Chest Press'},
      {'name': 'Incline DB Press', 'primary': true, 'wu': '1', 'sets': 3, 'reps': '8~10', 'rest': '2~3', 'muscle': 'صدر عالي'},
      {'name': 'OHP (Barbell)', 'primary': true, 'wu': '1~2', 'sets': 3, 'reps': '6~8', 'rest': '3~4', 'muscle': 'كتف أمامي', 'alt1': 'Machine OHP'},
      {'name': 'DB Lateral Raise', 'primary': false, 'wu': '0', 'sets': 4, 'reps': '12~15', 'rest': '1', 'muscle': 'كتف جانبي'},
      {'name': 'Skullcrusher', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '1~2', 'muscle': 'ترايسبس'},
    ],
    'PULL': [
      {'name': 'Barbell Row', 'primary': true, 'wu': '2', 'sets': 3, 'reps': '5~7', 'rest': '3~5', 'muscle': 'ظهر', 'alt1': 'Cable Row'},
      {'name': 'Weighted Pull Up', 'primary': true, 'wu': '1', 'sets': 3, 'reps': '5~8', 'rest': '3~4', 'muscle': 'ظهر عريض', 'alt1': 'Lat Pulldown'},
      {'name': 'Cable Face Pull', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '15~20', 'rest': '1', 'muscle': 'كتف خلفي'},
      {'name': 'Incline DB Curl', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '1~2', 'muscle': 'بايسبس'},
      {'name': 'Hammer Curl', 'primary': false, 'wu': '0', 'sets': 2, 'reps': '10~12', 'rest': '1', 'muscle': 'براكيو'},
    ],
    'Full Body #1': [
      {'name': 'Squat', 'primary': true, 'wu': '2', 'sets': 3, 'reps': '6~8', 'rest': '3~5', 'muscle': 'رباعية'},
      {'name': 'Bench Press', 'primary': true, 'wu': '2', 'sets': 3, 'reps': '6~8', 'rest': '3~5', 'muscle': 'صدر'},
      {'name': 'Barbell Row', 'primary': true, 'wu': '1', 'sets': 3, 'reps': '6~8', 'rest': '3~4', 'muscle': 'ظهر'},
      {'name': 'OHP', 'primary': false, 'wu': '1', 'sets': 2, 'reps': '8~10', 'rest': '2~3', 'muscle': 'كتف'},
      {'name': 'Romanian Deadlift', 'primary': false, 'wu': '1', 'sets': 2, 'reps': '8~10', 'rest': '2~3', 'muscle': 'وركين'},
    ],
    'Full Body #2': [
      {'name': 'Deadlift', 'primary': true, 'wu': '2~3', 'sets': 2, 'reps': '4~6', 'rest': '4~5', 'muscle': 'ظهر/وركين'},
      {'name': 'Incline DB Press', 'primary': true, 'wu': '1', 'sets': 3, 'reps': '8~10', 'rest': '3~4', 'muscle': 'صدر عالي'},
      {'name': 'Lat Pulldown', 'primary': true, 'wu': '1', 'sets': 3, 'reps': '8~10', 'rest': '3', 'muscle': 'ظهر عريض'},
      {'name': 'Leg Press', 'primary': false, 'wu': '1', 'sets': 3, 'reps': '10~12', 'rest': '2~3', 'muscle': 'رباعية'},
      {'name': 'DB Curl', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '1~2', 'muscle': 'بايسبس'},
    ],
    'Full Body #3': [
      {'name': 'Hack Squat', 'primary': true, 'wu': '1~2', 'sets': 3, 'reps': '8~10', 'rest': '3~4', 'muscle': 'رباعية'},
      {'name': 'Machine Chest Press', 'primary': true, 'wu': '1', 'sets': 3, 'reps': '8~10', 'rest': '3', 'muscle': 'صدر'},
      {'name': 'Seated Cable Row', 'primary': true, 'wu': '1', 'sets': 3, 'reps': '8~10', 'rest': '3', 'muscle': 'ظهر'},
      {'name': 'Machine OHP', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '2', 'muscle': 'كتف'},
      {'name': 'Hip Thrust', 'primary': false, 'wu': '1', 'sets': 3, 'reps': '10~12', 'rest': '2~3', 'muscle': 'أرداف'},
    ],
    'Chest & Back': [
      {'name': 'Bench Press', 'primary': true, 'wu': '2~3', 'sets': 4, 'reps': '6~8', 'rest': '3~5', 'muscle': 'صدر'},
      {'name': 'Incline DB Press', 'primary': true, 'wu': '1', 'sets': 3, 'reps': '8~10', 'rest': '3', 'muscle': 'صدر عالي'},
      {'name': 'Pull Up', 'primary': true, 'wu': '1', 'sets': 4, 'reps': '6~8', 'rest': '3~4', 'muscle': 'ظهر'},
      {'name': 'Barbell Row', 'primary': true, 'wu': '1', 'sets': 3, 'reps': '6~8', 'rest': '3', 'muscle': 'ظهر'},
      {'name': 'Machine Chest Fly', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '12~15', 'rest': '1~2', 'muscle': 'صدر'},
      {'name': 'Cable Row', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '12~15', 'rest': '1~2', 'muscle': 'ظهر'},
    ],
    'Shoulders & Arms': [
      {'name': 'OHP (Barbell)', 'primary': true, 'wu': '2', 'sets': 4, 'reps': '6~8', 'rest': '3~5', 'muscle': 'كتف'},
      {'name': 'DB Lateral Raise', 'primary': false, 'wu': '0', 'sets': 4, 'reps': '12~15', 'rest': '1', 'muscle': 'كتف جانبي'},
      {'name': 'Cable Curl', 'primary': false, 'wu': '0', 'sets': 4, 'reps': '10~12', 'rest': '1~2', 'muscle': 'بايسبس'},
      {'name': 'Skullcrusher', 'primary': false, 'wu': '0', 'sets': 4, 'reps': '10~12', 'rest': '1~2', 'muscle': 'ترايسبس'},
      {'name': 'Hammer Curl', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '10~12', 'rest': '1', 'muscle': 'بايسبس'},
      {'name': 'Cable Face Pull', 'primary': false, 'wu': '0', 'sets': 3, 'reps': '15~20', 'rest': '1', 'muscle': 'كتف خلفي'},
    ],
  };
}

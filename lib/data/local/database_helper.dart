import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';
import '../models/nutrition_model.dart';
import '../models/attendance_model.dart';
import '../models/measurement_model.dart';
import '../models/chat_model.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: AppConstants.dbVersion, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_logs (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        json TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_wl_uid_date ON workout_logs(uid, date)');
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        json TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_meals_uid_date ON meals(uid, date)');
    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        json TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE measurements (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        date TEXT NOT NULL,
        json TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_meas_uid ON measurements(uid)');
    await db.execute('''
      CREATE TABLE chat_rooms (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        json TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        uid TEXT NOT NULL,
        json TEXT NOT NULL,
        sent_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_cm_room ON chat_messages(room_id, sent_at)');
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        json TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempts INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE kv (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── KV Store ────────────────────────────────────────────────────
  Future<void> kvSet(String key, String value) async {
    final db = await database;
    await db.insert('kv', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> kvGet(String key) async {
    final db = await database;
    final rows = await db.query('kv', where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty ? rows.first['value'] as String? : null;
  }

  Future<void> kvDelete(String key) async {
    final db = await database;
    await db.delete('kv', where: 'key = ?', whereArgs: [key]);
  }

  // ── Users ───────────────────────────────────────────────────────
  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      {'uid': user.uid, 'json': user.toJsonString(), 'updated_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser(String uid) async {
    final db = await database;
    final rows = await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    if (rows.isEmpty) return null;
    return UserModel.fromJson(jsonDecode(rows.first['json'] as String));
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final rows = await db.query('users');
    return rows.map((r) => UserModel.fromJson(jsonDecode(r['json'] as String))).toList();
  }

  Future<void> deleteUser(String uid) async {
    final db = await database;
    await db.delete('users', where: 'uid = ?', whereArgs: [uid]);
  }

  // ── Workout Logs ────────────────────────────────────────────────
  Future<void> saveWorkoutLog(WorkoutLog log) async {
    final db = await database;
    await db.insert(
      'workout_logs',
      {
        'id': log.id,
        'uid': log.uid,
        'date': log.date,
        'json': log.toJsonString(),
        'synced': log.synced ? 1 : 0,
        'created_at': log.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<WorkoutLog?> getWorkoutLog(String id) async {
    final db = await database;
    final rows = await db.query('workout_logs', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WorkoutLog.fromJson(jsonDecode(rows.first['json'] as String));
  }

  Future<List<WorkoutLog>> getWorkoutLogsByUid(String uid, {int limit = 50}) async {
    final db = await database;
    final rows = await db.query(
      'workout_logs',
      where: 'uid = ?', whereArgs: [uid],
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
    );
    return rows.map((r) => WorkoutLog.fromJson(jsonDecode(r['json'] as String))).toList();
  }

  Future<WorkoutLog?> getWorkoutLogByDate(String uid, String date, String sessionName) async {
    final db = await database;
    final id = '${uid}_${date}_$sessionName';
    return getWorkoutLog(id);
  }

  Future<List<WorkoutLog>> getExerciseHistory(String uid, String exerciseName, {int limit = 20}) async {
    final all = await getWorkoutLogsByUid(uid, limit: 200);
    return all.where((log) =>
      log.exercises.any((e) => e.name == exerciseName)
    ).take(limit).toList();
  }

  // ── Meals ────────────────────────────────────────────────────────
  Future<void> saveMeal(Meal meal) async {
    final db = await database;
    await db.insert(
      'meals',
      {
        'id': meal.id,
        'uid': meal.uid,
        'date': meal.date,
        'meal_type': meal.mealType,
        'json': meal.toJsonString(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Meal>> getMealsByDate(String uid, String date) async {
    final db = await database;
    final rows = await db.query(
      'meals',
      where: 'uid = ? AND date = ?', whereArgs: [uid, date],
    );
    return rows.map((r) => Meal.fromJson(jsonDecode(r['json'] as String))).toList();
  }

  Future<void> deleteMeal(String id) async {
    final db = await database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  // ── Attendance ───────────────────────────────────────────────────
  Future<void> saveAttendance(MonthlyAttendance att) async {
    final db = await database;
    await db.insert(
      'attendance',
      {
        'id': att.id,
        'uid': att.uid,
        'year': att.year,
        'month': att.month,
        'json': att.toJsonString(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<MonthlyAttendance?> getAttendance(String uid, int year, int month) async {
    final db = await database;
    final id = '${uid}_${year}_$month';
    final rows = await db.query('attendance', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return MonthlyAttendance.fromJson(jsonDecode(rows.first['json'] as String));
  }

  Future<List<MonthlyAttendance>> getAllAttendanceForUser(String uid) async {
    final db = await database;
    final rows = await db.query('attendance', where: 'uid = ?', whereArgs: [uid],
        orderBy: 'year DESC, month DESC');
    return rows.map((r) => MonthlyAttendance.fromJson(jsonDecode(r['json'] as String))).toList();
  }

  // ── Measurements ─────────────────────────────────────────────────
  Future<void> saveMeasurement(BodyMeasurement m) async {
    final db = await database;
    await db.insert(
      'measurements',
      {'id': m.id, 'uid': m.uid, 'date': m.date.toIso8601String().split('T')[0], 'json': m.toJsonString(), 'synced': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BodyMeasurement>> getMeasurements(String uid) async {
    final db = await database;
    final rows = await db.query('measurements', where: 'uid = ?', whereArgs: [uid], orderBy: 'date DESC');
    return rows.map((r) => BodyMeasurement.fromJson(jsonDecode(r['json'] as String))).toList();
  }

  Future<void> deleteMeasurement(String id) async {
    final db = await database;
    await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  // ── Chat ─────────────────────────────────────────────────────────
  Future<void> saveChatMessage(ChatMessage msg) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      {'id': msg.id, 'room_id': msg.roomId, 'uid': msg.senderUid, 'json': msg.toJsonString(), 'sent_at': msg.sentAt.millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getChatMessages(String roomId, {int limit = 50}) async {
    final db = await database;
    final rows = await db.query('chat_messages',
        where: 'room_id = ?', whereArgs: [roomId], orderBy: 'sent_at ASC', limit: limit);
    return rows.map((r) => ChatMessage.fromJson(jsonDecode(r['json'] as String))).toList();
  }

  // ── Notifications ────────────────────────────────────────────────
  Future<void> saveNotification(AppNotification n) async {
    final db = await database;
    await db.insert(
      'notifications',
      {'id': n.id, 'uid': n.uid, 'json': jsonEncode(n.toJson()), 'is_read': n.isRead ? 1 : 0, 'created_at': n.createdAt.millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AppNotification>> getNotifications(String uid) async {
    final db = await database;
    final rows = await db.query('notifications', where: 'uid = ?', whereArgs: [uid], orderBy: 'created_at DESC', limit: 50);
    return rows.map((r) => AppNotification.fromJson(jsonDecode(r['json'] as String))).toList();
  }

  Future<int> getUnreadNotificationCount(String uid) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM notifications WHERE uid = ? AND is_read = 0', [uid]);
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final db = await database;
    await db.update('notifications', {'is_read': 1}, where: 'uid = ?', whereArgs: [uid]);
  }

  // ── Sync Queue ───────────────────────────────────────────────────
  Future<void> addToSyncQueue(String action, Map<String, dynamic> payload) async {
    final db = await database;
    final id = '${action}_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('sync_queue', {
      'id': id, 'action': action, 'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch, 'attempts': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    final rows = await db.query('sync_queue', orderBy: 'created_at ASC', limit: 20);
    return rows.map((r) => {
      'id': r['id'], 'action': r['action'],
      'payload': jsonDecode(r['payload'] as String),
      'attempts': r['attempts'],
    }).toList();
  }

  Future<void> removeSyncQueueItem(String id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementSyncAttempts(String id) async {
    final db = await database;
    await db.rawUpdate('UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?', [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

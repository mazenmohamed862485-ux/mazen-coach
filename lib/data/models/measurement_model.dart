import 'dart:convert';

class BodyMeasurement {
  final String id;
  final String uid;
  final DateTime date;
  final double? weight; // kg
  final double? bodyFat; // %
  final double? muscleMass; // kg
  final double? chest; // cm
  final double? waist; // cm
  final double? hips; // cm
  final double? thigh; // cm
  final double? arm; // cm
  final String? note;
  final bool synced;

  const BodyMeasurement({
    required this.id,
    required this.uid,
    required this.date,
    this.weight,
    this.bodyFat,
    this.muscleMass,
    this.chest,
    this.waist,
    this.hips,
    this.thigh,
    this.arm,
    this.note,
    this.synced = false,
  });

  double? get bmi {
    if (weight == null) return null;
    return null; // needs height from user profile
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) => BodyMeasurement(
    id: json['id']?.toString() ?? '',
    uid: json['uid']?.toString() ?? '',
    date: json['date'] != null
        ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
        : DateTime.now(),
    weight: double.tryParse(json['weight']?.toString() ?? ''),
    bodyFat: double.tryParse(json['bodyFat']?.toString() ?? ''),
    muscleMass: double.tryParse(json['muscleMass']?.toString() ?? ''),
    chest: double.tryParse(json['chest']?.toString() ?? ''),
    waist: double.tryParse(json['waist']?.toString() ?? ''),
    hips: double.tryParse(json['hips']?.toString() ?? ''),
    thigh: double.tryParse(json['thigh']?.toString() ?? ''),
    arm: double.tryParse(json['arm']?.toString() ?? ''),
    note: json['note']?.toString(),
    synced: json['synced'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'date': date.toIso8601String().split('T')[0],
    if (weight != null) 'weight': weight,
    if (bodyFat != null) 'bodyFat': bodyFat,
    if (muscleMass != null) 'muscleMass': muscleMass,
    if (chest != null) 'chest': chest,
    if (waist != null) 'waist': waist,
    if (hips != null) 'hips': hips,
    if (thigh != null) 'thigh': thigh,
    if (arm != null) 'arm': arm,
    if (note != null) 'note': note,
    'synced': synced,
  };

  String toJsonString() => jsonEncode(toJson());
}

class AppNotification {
  final String id;
  final String uid;
  final String title;
  final String body;
  final String icon;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.uid,
    required this.title,
    required this.body,
    this.icon = '',
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification markRead() => AppNotification(
    id: id, uid: uid, title: title, body: body,
    icon: icon, isRead: true, createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id']?.toString() ?? '',
    uid: json['uid']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    icon: json['icon']?.toString() ?? '',
    isRead: json['isRead'] == true,
    createdAt: json['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(json['createdAt'].toString()) ?? 0)
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'title': title,
    'body': body,
    'icon': icon,
    'isRead': isRead,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}

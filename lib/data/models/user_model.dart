import 'dart:convert';

enum UserRole { user, coach, admin, superAdmin }

enum SubscriptionStatus { none, paymentPending, active, expired }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final SubscriptionStatus subscriptionStatus;
  final int? subscriptionEnd; // timestamp ms
  final String? subscriptionType; // light, standard, pro
  final String? trainingProgram; // UL, AP, FB, ARNOLD, PPL, CUSTOM
  final int trainingDays;
  final double? weight; // kg
  final double? height; // cm
  final int? age;
  final String? gender; // male, female
  final String? goal; // bulk, cut, maintain
  final int? dailyCalories;
  final Map<String, dynamic>? dietPrefs;
  final String? avatarUrl;
  final bool isGuest;
  final String? gasUrl;
  final String? paymentImageUrl;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.role = UserRole.user,
    this.subscriptionStatus = SubscriptionStatus.none,
    this.subscriptionEnd,
    this.subscriptionType,
    this.trainingProgram,
    this.trainingDays = 4,
    this.weight,
    this.height,
    this.age,
    this.gender,
    this.goal,
    this.dailyCalories,
    this.dietPrefs,
    this.avatarUrl,
    this.isGuest = false,
    this.gasUrl,
    this.paymentImageUrl,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdminLike =>
      role == UserRole.superAdmin ||
      role == UserRole.admin ||
      role == UserRole.coach;

  SubscriptionStatus get currentSubscriptionStatus {
    if (isAdminLike) return SubscriptionStatus.active;
    if (subscriptionStatus != SubscriptionStatus.active) return subscriptionStatus;
    if (subscriptionEnd != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > subscriptionEnd!) return SubscriptionStatus.expired;
    }
    return SubscriptionStatus.active;
  }

  bool get hasActiveSubscription =>
      currentSubscriptionStatus == SubscriptionStatus.active;

  Duration? get subscriptionRemaining {
    if (subscriptionEnd == null) return null;
    final remaining = subscriptionEnd! - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return Duration.zero;
    return Duration(milliseconds: remaining);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: _parseRole(json['role']?.toString()),
      subscriptionStatus: _parseSubStatus(json['subscriptionStatus']?.toString()),
      subscriptionEnd: json['subscriptionEnd'] != null
          ? int.tryParse(json['subscriptionEnd'].toString())
          : null,
      subscriptionType: json['subscriptionType']?.toString(),
      trainingProgram: json['trainingProgram']?.toString(),
      trainingDays: int.tryParse(json['trainingDays']?.toString() ?? '4') ?? 4,
      weight: double.tryParse(json['weight']?.toString() ?? ''),
      height: double.tryParse(json['height']?.toString() ?? ''),
      age: int.tryParse(json['age']?.toString() ?? ''),
      gender: json['gender']?.toString(),
      goal: json['goal']?.toString(),
      dailyCalories: int.tryParse(json['dailyCalories']?.toString() ?? ''),
      dietPrefs: json['dietPrefs'] is Map
          ? Map<String, dynamic>.from(json['dietPrefs'])
          : null,
      avatarUrl: json['avatarUrl']?.toString(),
      isGuest: json['isGuest'] == true,
      gasUrl: json['gasUrl']?.toString(),
      paymentImageUrl: json['paymentImageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name.toUpperCase(),
    'subscriptionStatus': subscriptionStatus.name,
    'subscriptionEnd': subscriptionEnd,
    'subscriptionType': subscriptionType,
    'trainingProgram': trainingProgram,
    'trainingDays': trainingDays,
    'weight': weight,
    'height': height,
    'age': age,
    'gender': gender,
    'goal': goal,
    'dailyCalories': dailyCalories,
    'dietPrefs': dietPrefs,
    'avatarUrl': avatarUrl,
    'isGuest': isGuest,
    'gasUrl': gasUrl,
    'paymentImageUrl': paymentImageUrl,
  };

  String toJsonString() => jsonEncode(toJson());

  UserModel copyWith({
    String? uid, String? name, String? email, String? phone,
    UserRole? role, SubscriptionStatus? subscriptionStatus,
    int? subscriptionEnd, String? subscriptionType,
    String? trainingProgram, int? trainingDays,
    double? weight, double? height, int? age, String? gender,
    String? goal, int? dailyCalories, Map<String, dynamic>? dietPrefs,
    String? avatarUrl, bool? isGuest, String? gasUrl, String? paymentImageUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      trainingProgram: trainingProgram ?? this.trainingProgram,
      trainingDays: trainingDays ?? this.trainingDays,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      goal: goal ?? this.goal,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dietPrefs: dietPrefs ?? this.dietPrefs,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
      gasUrl: gasUrl ?? this.gasUrl,
      paymentImageUrl: paymentImageUrl ?? this.paymentImageUrl,
    );
  }

  static UserRole _parseRole(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'SUPER_ADMIN': return UserRole.superAdmin;
      case 'ADMIN': return UserRole.admin;
      case 'COACH': return UserRole.coach;
      default: return UserRole.user;
    }
  }

  static SubscriptionStatus _parseSubStatus(String? raw) {
    switch (raw) {
      case 'active': return SubscriptionStatus.active;
      case 'payment_pending': return SubscriptionStatus.paymentPending;
      case 'expired': return SubscriptionStatus.expired;
      default: return SubscriptionStatus.none;
    }
  }
}

import 'dart:convert';

class FoodItem {
  final String name;
  final String nameEn;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String category;
  final double costLevel; // 1-10
  final String unit; // g, ml, piece
  final double defaultAmount; // in unit

  const FoodItem({
    required this.name,
    this.nameEn = '',
    required this.caloriesPer100g,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.category = '',
    this.costLevel = 5,
    this.unit = 'g',
    this.defaultAmount = 100,
  });

  double caloriesForAmount(double amount) => (caloriesPer100g * amount) / 100;
  double proteinForAmount(double amount) => (proteinPer100g * amount) / 100;
  double carbsForAmount(double amount) => (carbsPer100g * amount) / 100;
  double fatForAmount(double amount) => (fatPer100g * amount) / 100;

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    name: json['name']?.toString() ?? '',
    nameEn: json['nameEn']?.toString() ?? '',
    caloriesPer100g: double.tryParse(json['cal']?.toString() ?? '0') ?? 0,
    proteinPer100g: double.tryParse(json['p']?.toString() ?? '0') ?? 0,
    carbsPer100g: double.tryParse(json['c']?.toString() ?? '0') ?? 0,
    fatPer100g: double.tryParse(json['f']?.toString() ?? '0') ?? 0,
    category: json['cat']?.toString() ?? '',
    costLevel: double.tryParse(json['cost']?.toString() ?? '5') ?? 5,
    unit: json['unit']?.toString() ?? 'g',
    defaultAmount: double.tryParse(json['default']?.toString() ?? '100') ?? 100,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'nameEn': nameEn,
    'cal': caloriesPer100g,
    'p': proteinPer100g,
    'c': carbsPer100g,
    'f': fatPer100g,
    'cat': category,
    'cost': costLevel,
    'unit': unit,
    'default': defaultAmount,
  };
}

class MealEntry {
  final FoodItem food;
  final double amount;
  final DateTime time;

  const MealEntry({
    required this.food,
    required this.amount,
    required this.time,
  });

  double get calories => food.caloriesForAmount(amount);
  double get protein => food.proteinForAmount(amount);
  double get carbs => food.carbsForAmount(amount);
  double get fat => food.fatForAmount(amount);

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
    food: FoodItem.fromJson(Map<String, dynamic>.from(json['food'] ?? {})),
    amount: double.tryParse(json['amount']?.toString() ?? '100') ?? 100,
    time: json['time'] != null
        ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(json['time'].toString()) ?? 0)
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'food': food.toJson(),
    'amount': amount,
    'time': time.millisecondsSinceEpoch,
  };
}

class Meal {
  final String id; // uid_YYYY-MM-DD
  final String uid;
  final String date;
  final String mealType; // breakfast, lunch, dinner, snack
  final List<MealEntry> items;

  const Meal({
    required this.id,
    required this.uid,
    required this.date,
    required this.mealType,
    this.items = const [],
  });

  double get totalCalories => items.fold(0, (sum, i) => sum + i.calories);
  double get totalProtein => items.fold(0, (sum, i) => sum + i.protein);
  double get totalCarbs => items.fold(0, (sum, i) => sum + i.carbs);
  double get totalFat => items.fold(0, (sum, i) => sum + i.fat);

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id']?.toString() ?? '',
    uid: json['uid']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    mealType: json['mealType']?.toString() ?? 'meal',
    items: (json['items'] as List<dynamic>? ?? [])
        .map((i) => MealEntry.fromJson(Map<String, dynamic>.from(i)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'date': date,
    'mealType': mealType,
    'items': items.map((i) => i.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());
}

class DailyNutrition {
  final String date;
  final List<Meal> meals;
  final int targetCalories;

  const DailyNutrition({
    required this.date,
    this.meals = const [],
    this.targetCalories = 2000,
  });

  double get totalCalories => meals.fold(0, (sum, m) => sum + m.totalCalories);
  double get totalProtein => meals.fold(0, (sum, m) => sum + m.totalProtein);
  double get totalCarbs => meals.fold(0, (sum, m) => sum + m.totalCarbs);
  double get totalFat => meals.fold(0, (sum, m) => sum + m.totalFat);
  double get caloriesRemaining => targetCalories - totalCalories;
  double get caloriesProgress => totalCalories / targetCalories;
}

class NutritionStats {
  final double bmr;
  final double tdee;
  final double recommendedCalories;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

  const NutritionStats({
    required this.bmr,
    required this.tdee,
    required this.recommendedCalories,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });

  /// Mifflin-St Jeor BMR
  static NutritionStats calculate({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    double bmr;
    if (gender == 'male') {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }

    final activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    final multiplier = activityMultipliers[activityLevel] ?? 1.55;
    final tdee = bmr * multiplier;

    double calories;
    switch (goal) {
      case 'bulk': calories = tdee + 300; break;
      case 'cut': calories = tdee - 400; break;
      default: calories = tdee;
    }

    final protein = weightKg * 2.2;
    final fat = calories * 0.25 / 9;
    final carbs = (calories - (protein * 4) - (fat * 9)) / 4;

    return NutritionStats(
      bmr: bmr,
      tdee: tdee,
      recommendedCalories: calories,
      proteinTarget: protein,
      carbsTarget: carbs,
      fatTarget: fat,
    );
  }
}

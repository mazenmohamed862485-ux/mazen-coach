import 'package:flutter/foundation.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/nutrition_model.dart';
import '../../data/remote/gas_api_service.dart';

class NutritionProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  final GasApiService _api;
  String? _uid;
  int _targetCalories = 2000;

  DailyNutrition? _todayNutrition;
  bool _isLoading = false;

  NutritionProvider({required DatabaseHelper db, required GasApiService api})
      : _db = db,
        _api = api;

  DailyNutrition? get todayNutrition => _todayNutrition;
  bool get isLoading => _isLoading;
  int get targetCalories => _targetCalories;

  void setUser(String? uid, {int targetCalories = 2000}) {
    if (_uid != uid || _targetCalories != targetCalories) {
      _uid = uid;
      _targetCalories = targetCalories;
      if (uid != null) loadToday();
    }
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadToday() async {
    if (_uid == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final dateStr = _todayDate();
      final meals = await _db.getMealsByDate(_uid!, dateStr);
      _todayNutrition = DailyNutrition(
        date: dateStr,
        meals: meals,
        targetCalories: _targetCalories,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMealEntry({
    required String mealType,
    required FoodItem food,
    required double amount,
  }) async {
    if (_uid == null) return;
    final dateStr = _todayDate();
    final entry = MealEntry(food: food, amount: amount, time: DateTime.now());

    // Find or create meal for this type
    final existing = _todayNutrition?.meals
        .where((m) => m.mealType == mealType)
        .toList() ?? [];

    Meal meal;
    if (existing.isNotEmpty) {
      final old = existing.first;
      meal = Meal(
        id: old.id,
        uid: old.uid,
        date: old.date,
        mealType: old.mealType,
        items: [...old.items, entry],
      );
    } else {
      meal = Meal(
        id: '${_uid}_${dateStr}_$mealType',
        uid: _uid!,
        date: dateStr,
        mealType: mealType,
        items: [entry],
      );
    }

    await _db.saveMeal(meal);
    await loadToday();
    _syncMeal(meal);
  }

  Future<void> deleteMeal(String mealId) async {
    await _db.deleteMeal(mealId);
    await loadToday();
  }

  Future<void> _syncMeal(Meal meal) async {
    if (!_api.isConfigured) return;
    try { await _api.syncMeal(meal.toJson()); } catch (_) {}
  }

  // ── Food Database (sample data) ──────────────────────────────────
  static final List<FoodItem> foodDatabase = [
    FoodItem(name: 'بيض مسلوق', nameEn: 'Boiled Egg', caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11, category: 'بروتين', costLevel: 2, unit: 'بيضة', defaultAmount: 50),
    FoodItem(name: 'صدر فراخ مشوي', nameEn: 'Grilled Chicken Breast', caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6, category: 'بروتين', costLevel: 4),
    FoodItem(name: 'تونة معلب', nameEn: 'Canned Tuna', caloriesPer100g: 116, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 1, category: 'بروتين', costLevel: 3),
    FoodItem(name: 'لحم بقري', nameEn: 'Beef', caloriesPer100g: 250, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 15, category: 'بروتين', costLevel: 7),
    FoodItem(name: 'أرز مسلوق', nameEn: 'Boiled Rice', caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3, category: 'نشويات', costLevel: 1),
    FoodItem(name: 'شوفان', nameEn: 'Oats', caloriesPer100g: 389, proteinPer100g: 17, carbsPer100g: 66, fatPer100g: 7, category: 'نشويات', costLevel: 2),
    FoodItem(name: 'خبز بر', nameEn: 'Whole Wheat Bread', caloriesPer100g: 247, proteinPer100g: 9, carbsPer100g: 41, fatPer100g: 3.4, category: 'نشويات', costLevel: 2, unit: 'شريحة', defaultAmount: 30),
    FoodItem(name: 'مكرونة', nameEn: 'Pasta', caloriesPer100g: 131, proteinPer100g: 5, carbsPer100g: 25, fatPer100g: 1.1, category: 'نشويات', costLevel: 2),
    FoodItem(name: 'حليب كامل الدسم', nameEn: 'Whole Milk', caloriesPer100g: 61, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 3.3, category: 'ألبان', costLevel: 2, unit: 'مل', defaultAmount: 250),
    FoodItem(name: 'زبادي يوناني', nameEn: 'Greek Yogurt', caloriesPer100g: 59, proteinPer100g: 10, carbsPer100g: 3.6, fatPer100g: 0.4, category: 'ألبان', costLevel: 3),
    FoodItem(name: 'جبن قريش', nameEn: 'Cottage Cheese', caloriesPer100g: 72, proteinPer100g: 12.5, carbsPer100g: 3.4, fatPer100g: 1, category: 'ألبان', costLevel: 3),
    FoodItem(name: 'موز', nameEn: 'Banana', caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3, category: 'فاكهة', costLevel: 1, unit: 'حبة', defaultAmount: 120),
    FoodItem(name: 'تفاحة', nameEn: 'Apple', caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2, category: 'فاكهة', costLevel: 2, unit: 'حبة', defaultAmount: 150),
    FoodItem(name: 'خيار', nameEn: 'Cucumber', caloriesPer100g: 15, proteinPer100g: 0.7, carbsPer100g: 3.6, fatPer100g: 0.1, category: 'خضار', costLevel: 1),
    FoodItem(name: 'طماطم', nameEn: 'Tomato', caloriesPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2, category: 'خضار', costLevel: 1),
    FoodItem(name: 'زيت زيتون', nameEn: 'Olive Oil', caloriesPer100g: 884, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 100, category: 'دهون', costLevel: 5, unit: 'ملعقة كبيرة', defaultAmount: 13.5),
    FoodItem(name: 'مكسرات مشكلة', nameEn: 'Mixed Nuts', caloriesPer100g: 607, proteinPer100g: 20, carbsPer100g: 21, fatPer100g: 52, category: 'دهون', costLevel: 7, unit: 'حفنة', defaultAmount: 30),
    FoodItem(name: 'فول مدمس', nameEn: 'Fava Beans', caloriesPer100g: 341, proteinPer100g: 26, carbsPer100g: 58, fatPer100g: 1.5, category: 'بقوليات', costLevel: 1),
    FoodItem(name: 'عدس', nameEn: 'Lentils', caloriesPer100g: 116, proteinPer100g: 9, carbsPer100g: 20, fatPer100g: 0.4, category: 'بقوليات', costLevel: 1),
    FoodItem(name: 'بطاطا مشوية', nameEn: 'Baked Potato', caloriesPer100g: 93, proteinPer100g: 2.5, carbsPer100g: 21, fatPer100g: 0.1, category: 'نشويات', costLevel: 1, unit: 'حبة', defaultAmount: 200),
  ];

  List<FoodItem> searchFood(String query) {
    if (query.isEmpty) return foodDatabase;
    final q = query.toLowerCase();
    return foodDatabase.where((f) =>
      f.name.contains(q) || f.nameEn.toLowerCase().contains(q)
    ).toList();
  }
}

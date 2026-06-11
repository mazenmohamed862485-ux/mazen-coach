import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition_model.dart';
import '../../widgets/common/app_card.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final daily = nutrition.todayNutrition;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التغذية'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => _showAddFoodSheet(context),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: nutrition.loadToday,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Calories Overview ──
                _CaloriesCard(daily: daily, target: nutrition.targetCalories),
                const SizedBox(height: 20),

                // ── Macros ──
                if (daily != null) _MacrosRow(daily: daily),
                const SizedBox(height: 20),

                // ── Calculator Banner ──
                _CalculatorBanner(user: user),
                const SizedBox(height: 20),

                // ── Meals ──
                const Text('وجباتك اليوم', style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                ..._buildMealTypes(context, daily, nutrition),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddFoodSheet(context),
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('أضف طعام', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  List<Widget> _buildMealTypes(BuildContext context, DailyNutrition? daily, NutritionProvider nutrition) {
    final mealTypes = [
      {'id': 'breakfast', 'label': 'الإفطار', 'icon': Icons.wb_sunny_outlined},
      {'id': 'lunch', 'label': 'الغداء', 'icon': Icons.lunch_dining_outlined},
      {'id': 'dinner', 'label': 'العشاء', 'icon': Icons.nights_stay_outlined},
      {'id': 'snack', 'label': 'وجبة خفيفة', 'icon': Icons.cookie_outlined},
    ];

    return mealTypes.map((mt) {
      final mealType = mt['id'] as String;
      final meals = daily?.meals.where((m) => m.mealType == mealType).toList() ?? [];
      final totalCal = meals.fold<double>(0, (s, m) => s + m.totalCalories);

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _MealTypeCard(
          label: mt['label'] as String,
          icon: mt['icon'] as IconData,
          meals: meals,
          totalCalories: totalCal,
          onAddFood: () => _showAddFoodSheet(context, mealType: mealType),
        ),
      );
    }).toList();
  }

  void _showAddFoodSheet(BuildContext context, {String? mealType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFoodSheet(preSelectedMealType: mealType),
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  final DailyNutrition? daily;
  final int target;
  const _CaloriesCard({this.daily, required this.target});

  @override
  Widget build(BuildContext context) {
    final eaten = daily?.totalCalories ?? 0;
    final remaining = (target - eaten).clamp(0, target.toDouble());
    final progress = (eaten / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A7A4F), Color(0xFF0D7377)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تم تناوله', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
                  Text('${eaten.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  const Text('سعرة حرارية', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70)),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const Text('من الهدف', style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('متبقي', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
                  Text('${remaining.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('من $target', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1 ? AppColors.err : Colors.white,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacrosRow extends StatelessWidget {
  final DailyNutrition daily;
  const _MacrosRow({required this.daily});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MacroChip(label: 'بروتين', value: '${daily.totalProtein.toStringAsFixed(0)}g', color: AppColors.ok)),
        const SizedBox(width: 10),
        Expanded(child: _MacroChip(label: 'كارب', value: '${daily.totalCarbs.toStringAsFixed(0)}g', color: AppColors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _MacroChip(label: 'دهون', value: '${daily.totalFat.toStringAsFixed(0)}g', color: AppColors.warn)),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip({required this.label, required this.value, required this.color});

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
          Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _CalculatorBanner extends StatelessWidget {
  final dynamic user;
  const _CalculatorBanner({this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppColors.accent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('حاسبة السعرات المتقدمة', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                  'احسب احتياجاتك اليومية من البروتين والكارب والدهون',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? AppColors.text2Dark : AppColors.text2Light),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accent),
        ],
      ),
      onTap: () => _showCalcSheet(context),
    );
  }

  void _showCalcSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CalcSheet(),
    );
  }
}

class _CalcSheet extends StatefulWidget {
  const _CalcSheet();
  @override
  State<_CalcSheet> createState() => _CalcSheetState();
}

class _CalcSheetState extends State<_CalcSheet> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'male';
  String _activity = 'moderate';
  String _goal = 'maintain';
  NutritionStats? _result;

  void _calculate() {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final a = int.tryParse(_ageCtrl.text) ?? 0;
    if (w <= 0 || h <= 0 || a <= 0) return;
    setState(() {
      _result = NutritionStats.calculate(
        weightKg: w, heightCm: h, age: a,
        gender: _gender, activityLevel: _activity, goal: _goal,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('حاسبة السعرات المتقدمة', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الوزن (كجم)', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الطول (سم)', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العمر', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'الجنس', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('ذكر')),
                DropdownMenuItem(value: 'female', child: Text('أنثى')),
              ],
              onChanged: (v) => setState(() => _gender = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _activity,
              decoration: const InputDecoration(labelText: 'مستوى النشاط', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'sedentary', child: Text('خامل جداً')),
                DropdownMenuItem(value: 'light', child: Text('نشاط خفيف')),
                DropdownMenuItem(value: 'moderate', child: Text('نشاط معتدل')),
                DropdownMenuItem(value: 'active', child: Text('نشيط')),
                DropdownMenuItem(value: 'very_active', child: Text('نشيط جداً')),
              ],
              onChanged: (v) => setState(() => _activity = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _goal,
              decoration: const InputDecoration(labelText: 'الهدف', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'bulk', child: Text('بناء عضلي (زيادة سعرات)')),
                DropdownMenuItem(value: 'cut', child: Text('تنشيف (تقليل سعرات)')),
                DropdownMenuItem(value: 'maintain', child: Text('تثبيت الوزن')),
              ],
              onChanged: (v) => setState(() => _goal = v!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _calculate, child: const Text('احسب', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700))),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.accentDark, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    Text('السعرات الموصى بها: ${_result!.recommendedCalories.toStringAsFixed(0)} سعرة', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _MacroResult('بروتين', '${_result!.proteinTarget.toStringAsFixed(0)}g', AppColors.ok),
                      _MacroResult('كارب', '${_result!.carbsTarget.toStringAsFixed(0)}g', AppColors.accent),
                      _MacroResult('دهون', '${_result!.fatTarget.toStringAsFixed(0)}g', AppColors.warn),
                    ]),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroResult extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroResult(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: color.withOpacity(0.8))),
      ],
    );
  }
}

class _MealTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Meal> meals;
  final double totalCalories;
  final VoidCallback onAddFood;

  const _MealTypeCard({
    required this.label,
    required this.icon,
    required this.meals,
    required this.totalCalories,
    required this.onAddFood,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = meals.expand((m) => m.items).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (totalCalories > 0)
                  Text('${totalCalories.toStringAsFixed(0)} سعرة', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onAddFood,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.accentDark, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: AppColors.accent, size: 16),
                  ),
                ),
              ],
            ),
          ),
          if (allItems.isNotEmpty) ...[
            const Divider(height: 1),
            ...allItems.take(3).map((item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(item.food.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                  Text('${item.amount.toStringAsFixed(0)}${item.food.unit} · ${item.calories.toStringAsFixed(0)} سعرة',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isDark ? AppColors.text2Dark : AppColors.text2Light)),
                ],
              ),
            )),
            if (allItems.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('+${allItems.length - 3} أكثر', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.accent), textAlign: TextAlign.center),
              ),
          ],
        ],
      ),
    );
  }
}

class _AddFoodSheet extends StatefulWidget {
  final String? preSelectedMealType;
  const _AddFoodSheet({this.preSelectedMealType});
  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _searchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '100');
  FoodItem? _selectedFood;
  String _mealType = 'breakfast';
  List<FoodItem> _results = [];

  @override
  void initState() {
    super.initState();
    _mealType = widget.preSelectedMealType ?? 'breakfast';
    _results = NutritionProvider(db: context.read(), api: context.read()).searchFood('');
    // Use static list instead
    _results = NutritionProvider.foodDatabase;
  }

  void _search(String q) {
    setState(() {
      _results = NutritionProvider.foodDatabase.where((f) =>
        f.name.contains(q) || f.nameEn.toLowerCase().contains(q.toLowerCase())
      ).toList();
    });
  }

  Future<void> _addFood() async {
    if (_selectedFood == null) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 100;
    final nutrition = context.read<NutritionProvider>();
    await nutrition.addMealEntry(mealType: _mealType, food: _selectedFood!, amount: amount);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت إضافة ${_selectedFood!.name}'), backgroundColor: AppColors.ok),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              children: [
                const Text('إضافة طعام', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن طعام...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final food = _results[i];
                final isSelected = _selectedFood?.name == food.name;
                return ListTile(
                  onTap: () => setState(() => _selectedFood = food),
                  selected: isSelected,
                  selectedTileColor: AppColors.accentDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  title: Text(food.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('${food.caloriesPer100g.toStringAsFixed(0)} سعرة / 100${food.unit == 'g' ? 'g' : food.unit}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                );
              },
            ),
          ),
          if (_selectedFood != null)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'الكمية (${_selectedFood!.unit})', border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _mealType,
                          decoration: const InputDecoration(labelText: 'الوجبة', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'breakfast', child: Text('إفطار')),
                            DropdownMenuItem(value: 'lunch', child: Text('غداء')),
                            DropdownMenuItem(value: 'dinner', child: Text('عشاء')),
                            DropdownMenuItem(value: 'snack', child: Text('خفيف')),
                          ],
                          onChanged: (v) => setState(() => _mealType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addFood,
                    icon: const Icon(Icons.add),
                    label: Text('إضافة ${_selectedFood!.name}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

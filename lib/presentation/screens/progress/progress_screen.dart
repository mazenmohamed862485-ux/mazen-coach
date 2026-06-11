import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/models/measurement_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/app_button.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BodyMeasurement> _measurements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMeasurements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMeasurements() async {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    if (uid.isEmpty) return;
    final data = await DatabaseHelper.instance.getMeasurements(uid);
    setState(() { _measurements = data; _loading = false; });
  }

  void _showAddMeasurement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMeasurementSheet(onAdded: _loadMeasurements),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقدم'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            tabs: const [
              Tab(text: 'القياسات الجسدية'),
              Tab(text: 'تقدم التمارين'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _MeasurementsTab(measurements: _measurements, loading: _loading, onRefresh: _loadMeasurements),
            const _WorkoutProgressTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddMeasurement,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('قياس جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _MeasurementsTab extends StatelessWidget {
  final List<BodyMeasurement> measurements;
  final bool loading;
  final VoidCallback onRefresh;

  const _MeasurementsTab({required this.measurements, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (loading) return const Center(child: CircularProgressIndicator());

    if (measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_weight_outlined, size: 56, color: isDark ? AppColors.text3Dark : AppColors.text3Light),
            const SizedBox(height: 12),
            const Text('لا توجد قياسات بعد', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            const SizedBox(height: 6),
            const Text('أضف أول قياس لتتبع تقدمك', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.text2Light)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Latest measurements
          if (measurements.isNotEmpty) _LatestMeasurements(latest: measurements.first),
          const SizedBox(height: 20),
          const Text('سجل القياسات', style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...measurements.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(m.date.toIso8601String().split('T')[0], style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 12, runSpacing: 8, children: [
                    if (m.weight != null) _MeasureChip('الوزن', '${m.weight} كجم', AppColors.accent),
                    if (m.bodyFat != null) _MeasureChip('الدهون', '${m.bodyFat}%', AppColors.warn),
                    if (m.muscleMass != null) _MeasureChip('العضلات', '${m.muscleMass} كجم', AppColors.ok),
                    if (m.chest != null) _MeasureChip('الصدر', '${m.chest} سم', AppColors.info),
                    if (m.waist != null) _MeasureChip('الخصر', '${m.waist} سم', AppColors.err),
                    if (m.arm != null) _MeasureChip('الذراع', '${m.arm} سم', AppColors.ok),
                  ]),
                  if (m.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(m.note!, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? AppColors.text2Dark : AppColors.text2Light)),
                  ],
                ],
              ),
            ),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _LatestMeasurements extends StatelessWidget {
  final BodyMeasurement latest;
  const _LatestMeasurements({required this.latest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentLight], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('آخر قياس', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (latest.weight != null) _QuickStat('${latest.weight} كجم', 'الوزن'),
              if (latest.bodyFat != null) _QuickStat('${latest.bodyFat}%', 'الدهون'),
              if (latest.muscleMass != null) _QuickStat('${latest.muscleMass} كجم', 'العضلات'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  const _QuickStat(this.value, this.label);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

class _MeasureChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MeasureChip(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text('$label: $value', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _WorkoutProgressTab extends StatelessWidget {
  const _WorkoutProgressTab();

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final logs = workout.recentLogs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group by exercise name
    final Map<String, List<double>> exerciseProgress = {};
    for (final log in logs.reversed) {
      for (final ex in log.exercises) {
        final bs = ex.bestSet;
        if (bs != null) {
          exerciseProgress.putIfAbsent(ex.name, () => []).add(bs.epley1RM);
        }
      }
    }

    if (exerciseProgress.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_up_outlined, size: 56, color: isDark ? AppColors.text3Dark : AppColors.text3Light),
            const SizedBox(height: 12),
            const Text('لا توجد بيانات تمارين بعد', style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: exerciseProgress.entries.map((entry) {
        final name = entry.key;
        final values = entry.value;
        final latest = values.last;
        final prev = values.length > 1 ? values[values.length - 2] : null;
        final diff = prev != null ? latest - prev : 0;
        final isUp = diff > 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('${values.length} جلسة مسجلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? AppColors.text2Dark : AppColors.text2Light)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${latest.toStringAsFixed(1)} كجم (1RM)', style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    if (prev != null)
                      Row(
                        children: [
                          Icon(isUp ? Icons.trending_up : Icons.trending_down, size: 14, color: isUp ? AppColors.ok : AppColors.err),
                          const SizedBox(width: 3),
                          Text('${diff.abs().toStringAsFixed(1)} كجم', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isUp ? AppColors.ok : AppColors.err, fontWeight: FontWeight.w600)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AddMeasurementSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddMeasurementSheet({required this.onAdded});
  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  final _weightCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _muscleCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    if (uid.isEmpty) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final id = '${uid}_${now.toIso8601String().split('T')[0]}';
    final m = BodyMeasurement(
      id: id, uid: uid, date: now,
      weight: double.tryParse(_weightCtrl.text),
      bodyFat: double.tryParse(_fatCtrl.text),
      muscleMass: double.tryParse(_muscleCtrl.text),
      chest: double.tryParse(_chestCtrl.text),
      waist: double.tryParse(_waistCtrl.text),
      arm: double.tryParse(_armCtrl.text),
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );
    await DatabaseHelper.instance.saveMeasurement(m);
    widget.onAdded();
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إضافة قياس جديد', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: AppTextField(controller: _weightCtrl, label: 'الوزن (كجم)', keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: _fatCtrl, label: 'الدهون %', keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: _muscleCtrl, label: 'العضلات (كجم)', keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: AppTextField(controller: _chestCtrl, label: 'الصدر (سم)', keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: _waistCtrl, label: 'الخصر (سم)', keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: _armCtrl, label: 'الذراع (سم)', keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            AppTextField(controller: _noteCtrl, label: 'ملاحظات (اختياري)', maxLines: 2),
            const SizedBox(height: 16),
            AppButton(label: 'حفظ القياس', isLoading: _saving, onPressed: _saving ? null : _save),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout_model.dart';
import '../../widgets/common/app_card.dart';

class SessionScreen extends StatefulWidget {
  final String programId;
  final String sessionName;

  const SessionScreen({super.key, required this.programId, required this.sessionName});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().startSession(widget.programId, widget.sessionName);
    });
  }

  Future<bool> _onWillPop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إنهاء الجلسة؟', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل تريد إنهاء الجلسة بدون حفظ؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          TextButton(
            onPressed: () {
              context.read<WorkoutProvider>().cancelSession();
              Navigator.pop(context, true);
            },
            child: const Text('إنهاء', style: TextStyle(color: AppColors.err)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _finishSession() async {
    final auth = context.read<AuthProvider>();
    final workout = context.read<WorkoutProvider>();
    final uid = auth.user?.uid ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إنهاء الجلسة', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من إنهاء الجلسة وحفظها؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await workout.finishSession(uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الجلسة'),
        backgroundColor: AppColors.ok,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final session = workout.activeSession;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.sessionName, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
            actions: [
              if (session != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Text(
                      '${session.elapsedMinutes} دقيقة',
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 13,
                        color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: session == null
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // Warmup section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _WarmupSection(),
                      ),
                    ),
                    // Exercises
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _ExerciseCard(
                            exerciseIndex: i,
                            exercise: session.exercises[i],
                            workout: workout,
                          ),
                        ),
                        childCount: session.exercises.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ElevatedButton.icon(
                onPressed: _finishSession,
                icon: const Icon(Icons.check_rounded),
                label: const Text('إنهاء الجلسة وحفظها', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ok,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarmupSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.thermostat_outlined, color: AppColors.warn, size: 16),
              SizedBox(width: 6),
              Text('إحماء (قبل البدء)', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warn)),
            ],
          ),
          const SizedBox(height: 10),
          ...AppConstants.warmupExercises.map((ex) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${ex['name']} — ${ex['reps']}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final int exerciseIndex;
  final ExerciseLog exercise;
  final WorkoutProvider workout;

  const _ExerciseCard({
    required this.exerciseIndex,
    required this.exercise,
    required this.workout,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ex = widget.exercise;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ex.isPrimary ? AppColors.accentDark : AppColors.borderLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ex.isPrimary ? 'أساسي' : 'ثانوي',
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w600,
                        color: ex.isPrimary ? AppColors.accent : (isDark ? AppColors.text2Dark : AppColors.text2Light),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: TextStyle(
                            fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.text1Dark : AppColors.text1Light,
                          ),
                        ),
                        if (ex.muscle?.isNotEmpty == true)
                          Text(
                            ex.muscle!,
                            style: TextStyle(
                              fontFamily: 'Cairo', fontSize: 11,
                              color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20),
                ],
              ),
            ),
          ),

          // Sets
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Header row
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text('الست', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('الوزن (كجم)', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent), textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text('التكرار', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent), textAlign: TextAlign.center)),
                        Expanded(flex: 1, child: Text('✓', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  ...ex.sets.asMap().entries.map((entry) => _SetRow(
                    setNumber: entry.key + 1,
                    workoutSet: entry.value,
                    onChanged: (updated) => widget.workout.updateSet(widget.exerciseIndex, entry.key, updated),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int setNumber;
  final WorkoutSet workoutSet;
  final void Function(WorkoutSet) onChanged;

  const _SetRow({required this.setNumber, required this.workoutSet, required this.onChanged});

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.workoutSet.weight > 0 ? widget.workoutSet.weight.toString() : '',
    );
    _repsCtrl = TextEditingController(
      text: widget.workoutSet.reps > 0 ? widget.workoutSet.reps.toString() : '',
    );
    _done = widget.workoutSet.isDone;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _update() {
    widget.onChanged(WorkoutSet(
      weight: double.tryParse(_weightCtrl.text) ?? 0,
      reps: int.tryParse(_repsCtrl.text) ?? 0,
      isDone: _done,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: _done ? AppColors.ok.withOpacity(0.07) : (isDark ? const Color(0x08FFFFFF) : const Color(0x05000000)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _done ? AppColors.ok.withOpacity(0.3) : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '${widget.setNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _update(),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => _update(),
            ),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                setState(() => _done = !_done);
                _update();
              },
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _done ? AppColors.ok : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _done ? AppColors.ok : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: 2,
                    ),
                  ),
                  child: _done
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

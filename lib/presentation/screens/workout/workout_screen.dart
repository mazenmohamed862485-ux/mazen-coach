import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import 'session_screen.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('برنامج التدريب')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user?.trainingProgram != null)
                _ProgramInfo(user: user!)
              else
                _NoProgramCard(),
              const SizedBox(height: 24),
              const Text(
                'جلسات الأسبوع',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _SessionsList(user: user),
              const SizedBox(height: 24),
              const Text(
                'البرامج المتاحة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ..._buildProgramCards(context, isDark),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProgramCards(BuildContext context, bool isDark) {
    return AppConstants.programs.entries.map((entry) {
      final prog = entry.value;
      final sessions = prog['sessions'] as List<dynamic>? ?? [];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prog['name']?.toString() ?? '',
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.text1Dark : AppColors.text1Light,
                      ),
                    ),
                    Text(
                      prog['description']?.toString() ?? '',
                      style: TextStyle(
                        fontFamily: 'Cairo', fontSize: 12,
                        color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(prog['daysOptions'] as List).first} أيام',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _ProgramInfo extends StatelessWidget {
  final dynamic user;
  const _ProgramInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    final prog = AppConstants.programs[user.trainingProgram ?? ''];
    if (prog == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('برنامجك الحالي', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            prog['name']?.toString() ?? '',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            prog['description']?.toString() ?? '',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                '${user.trainingDays ?? 4} أيام في الأسبوع',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoProgramCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.fitness_center_outlined, size: 40, color: AppColors.accent),
          const SizedBox(height: 12),
          const Text(
            'لم يتم تعيين برنامج تدريب بعد',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'راجع المدرب لتعيين برنامجك',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.text2Light),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionsList extends StatelessWidget {
  final dynamic user;
  const _SessionsList({this.user});

  @override
  Widget build(BuildContext context) {
    final workout = context.read<WorkoutProvider>();
    final progId = user?.trainingProgram ?? 'UL';
    final days = user?.trainingDays ?? 4;
    final sessions = workout.getSessionsForProgram(progId, days);

    if (sessions.isEmpty) {
      return AppCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'لا توجد جلسات — اختر برنامجاً',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
          ),
        ),
      );
    }

    return Column(
      children: sessions.asMap().entries.map((e) {
        final idx = e.key;
        final sessionName = e.value;
        final exercises = workout.getExercisesForSession(sessionName);
        return _SessionCard(
          index: idx + 1,
          sessionName: sessionName,
          exerciseCount: exercises.length,
          progId: progId,
          onStart: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionScreen(
                programId: progId,
                sessionName: sessionName,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final int index;
  final String sessionName;
  final int exerciseCount;
  final String progId;
  final VoidCallback onStart;

  const _SessionCard({
    required this.index,
    required this.sessionName,
    required this.exerciseCount,
    required this.progId,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Y$index',
                  style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessionName,
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.text1Dark : AppColors.text1Light,
                    ),
                  ),
                  Text(
                    '$exerciseCount تمرين',
                    style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 12,
                      color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('ابدأ', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

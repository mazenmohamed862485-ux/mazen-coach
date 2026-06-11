import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/app_card.dart';
import '../settings/settings_screen.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final workout = context.watch<WorkoutProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: null,
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await workout.loadRecentLogs();
            await nutrition.loadToday();
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GreetingHeader(user: user),
                      const SizedBox(height: 20),
                      if (user != null && !user.hasActiveSubscription && !user.isAdminLike)
                        _SubscriptionBanner(user: user),
                      _TodaySummary(
                        workout: workout,
                        nutrition: nutrition,
                        user: user,
                      ),
                      const SizedBox(height: 20),
                      _QuickStats(workout: workout, nutrition: nutrition, user: user),
                      const SizedBox(height: 20),
                      _RecentWorkouts(workout: workout),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final UserModel? user;
  const _GreetingHeader({this.user});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء النور';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting 👋',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.name ?? 'المستخدم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.text1Dark : AppColors.text1Light,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.accentDark,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubscriptionBanner extends StatelessWidget {
  final UserModel user;
  const _SubscriptionBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    final isPending = user.subscriptionStatus == SubscriptionStatus.paymentPending;
    final color = isPending ? AppColors.warn : AppColors.err;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isPending ? Icons.hourglass_empty : Icons.warning_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPending
                  ? 'اشتراكك قيد المراجعة — سيتم التفعيل خلال 24 ساعة'
                  : 'اشتراكك منتهي — جدّد للوصول لكامل المميزات',
              style: TextStyle(
                fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final WorkoutProvider workout;
  final NutritionProvider nutrition;
  final UserModel? user;
  const _TodaySummary({required this.workout, required this.nutrition, this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final todayLogs = workout.recentLogs.where((l) => l.date == todayStr).toList();
    final calories = nutrition.todayNutrition?.totalCalories ?? 0;
    final target = nutrition.targetCalories;

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
          Row(
            children: [
              const Icon(Icons.today_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'ملخص اليوم',
                style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 13, color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayLogs.isEmpty ? 'لا يوجد تمرين اليوم' : '${todayLogs.length} جلسة مسجلة',
                      style: const TextStyle(
                        fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${calories.toStringAsFixed(0)} / $target سعرة',
                      style: const TextStyle(
                        fontFamily: 'Cairo', fontSize: 13, color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${(calories / target * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (calories / target).clamp(0, 1),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final WorkoutProvider workout;
  final NutritionProvider nutrition;
  final UserModel? user;

  const _QuickStats({required this.workout, required this.nutrition, this.user});

  @override
  Widget build(BuildContext context) {
    final totalWorkouts = workout.recentLogs.length;
    final weekLogs = workout.recentLogs.where((l) {
      final date = DateTime.tryParse(l.date) ?? DateTime.now();
      return DateTime.now().difference(date).inDays <= 7;
    }).length;
    final protein = nutrition.todayNutrition?.totalProtein ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إحصائياتك',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: '$weekLogs',
                label: 'تمارين الأسبوع',
                icon: Icons.fitness_center_rounded,
                iconColor: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                value: '${protein.toStringAsFixed(0)}g',
                label: 'بروتين اليوم',
                icon: Icons.egg_outlined,
                iconColor: AppColors.ok,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                value: '$totalWorkouts',
                label: 'إجمالي التمارين',
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecentWorkouts extends StatelessWidget {
  final WorkoutProvider workout;
  const _RecentWorkouts({required this.workout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recent = workout.recentLogs.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر التمارين',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center_outlined,
                        size: 36,
                        color: isDark ? AppColors.text3Dark : AppColors.text3Light),
                    const SizedBox(height: 8),
                    Text(
                      'لم تسجّل أي تمرين بعد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recent.map((log) => Padding(
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
                          log.sessionName,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.text1Dark : AppColors.text1Light,
                          ),
                        ),
                        Text(
                          '${log.date} · ${log.exercises.length} تمرين · ${log.durationMinutes} دقيقة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${log.totalVolume.toStringAsFixed(0)} كجم',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }
}

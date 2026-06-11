import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import 'home/home_screen.dart';
import 'workout/workout_screen.dart';
import 'nutrition/nutrition_screen.dart';
import 'attendance/attendance_screen.dart';
import 'progress/progress_screen.dart';
import '../../core/constants/app_colors.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    _TabInfo('الرئيسية', Icons.home_rounded, Icons.home_outlined),
    _TabInfo('التمرين', Icons.fitness_center_rounded, Icons.fitness_center_outlined),
    _TabInfo('التغذية', Icons.restaurant_rounded, Icons.restaurant_outlined),
    _TabInfo('الحضور', Icons.calendar_month_rounded, Icons.calendar_month_outlined),
    _TabInfo('التقدم', Icons.trending_up_rounded, Icons.trending_up_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark
        ? const Color(0xF5111210)
        : const Color(0xFAF7F4EE);

    final screens = [
      const HomeScreen(),
      const WorkoutScreen(),
      const NutritionScreen(),
      const AttendanceScreen(),
      const ProgressScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final isSelected = _selectedIndex == i;
                  final color = isSelected
                      ? AppColors.accent
                      : (isDark ? AppColors.text3Dark : AppColors.text3Light);
                  return InkWell(
                    onTap: () => setState(() => _selectedIndex = i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? tab.activeIcon : tab.inactiveIcon,
                              key: ValueKey(isSelected),
                              color: color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: color,
                            ),
                            child: Text(tab.label),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 18,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  const _TabInfo(this.label, this.activeIcon, this.inactiveIcon);
}

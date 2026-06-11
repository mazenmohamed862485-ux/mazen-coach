import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_text_field.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _gasUrlCtrl = TextEditingController();

  @override
  void dispose() {
    _gasUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل أنت متأكد من الخروج؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج', style: TextStyle(color: AppColors.err))),
        ],
      ),
    );
    if (confirmed != true) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showGasUrlEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GasUrlSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;
    final isDark = theme.isDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(color: AppColors.accentDark, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(user?.email ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? AppColors.text2Dark : AppColors.text2Light)),
                        const SizedBox(height: 4),
                        _RoleBadge(role: user?.role.name ?? ''),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subscription Info
            if (user != null && !user.isAdminLike) _SubscriptionCard(user: user),
            const SizedBox(height: 16),

            // Appearance
            const _SectionHeader('المظهر'),
            AppCard(
              child: Column(
                children: [
                  _SettingRow(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    label: isDark ? 'الوضع الداكن' : 'الوضع الفاتح',
                    trailing: Switch(value: isDark, onChanged: (_) => theme.toggleDark(), activeColor: AppColors.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Server Config
            const _SectionHeader('الخادم'),
            AppCard(
              onTap: _showGasUrlEditor,
              child: _SettingRow(
                icon: Icons.link_rounded,
                label: 'رابط Google Apps Script',
                subtitle: 'اضغط لتغيير رابط المزامنة',
                trailing: const Icon(Icons.chevron_left, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 16),

            // Training
            const _SectionHeader('التدريب'),
            AppCard(
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.fitness_center_outlined,
                    label: 'البرنامج الحالي',
                    subtitle: user?.trainingProgram ?? 'غير محدد',
                    trailing: const Icon(Icons.chevron_left, color: AppColors.accent),
                  ),
                  const Divider(height: 1),
                  _SettingRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'أيام التدريب',
                    subtitle: '${user?.trainingDays ?? 4} أيام في الأسبوع',
                    trailing: const Icon(Icons.chevron_left, color: AppColors.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Body
            const _SectionHeader('البيانات الجسدية'),
            AppCard(
              child: Column(
                children: [
                  if (user?.weight != null)
                    _SettingRow(icon: Icons.monitor_weight_outlined, label: 'الوزن', subtitle: '${user!.weight} كجم'),
                  if (user?.height != null)
                    _SettingRow(icon: Icons.height, label: 'الطول', subtitle: '${user!.height} سم'),
                  if (user?.age != null)
                    _SettingRow(icon: Icons.cake_outlined, label: 'العمر', subtitle: '${user!.age} سنة'),
                  if (user?.dailyCalories != null)
                    _SettingRow(icon: Icons.local_fire_department_outlined, label: 'السعرات اليومية', subtitle: '${user!.dailyCalories} سعرة'),
                  if (user?.weight == null && user?.height == null)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('لا توجد بيانات جسدية محفوظة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.err,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text('MAZEN COACH ${auth.user != null ? "v8.2.0" : ""}', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isDark ? AppColors.text3Dark : AppColors.text3Light))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final dynamic user;
  const _SubscriptionCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user.hasActiveSubscription;
    final color = isActive ? AppColors.ok : AppColors.warn;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_membership, color: color, size: 20),
              const SizedBox(width: 10),
              Text('الاشتراك', style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isActive ? 'نشط' : 'منتهي',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
          if (user.subscriptionEnd != null) ...[
            const SizedBox(height: 8),
            Text(
              'ينتهي في: ${DateTime.fromMillisecondsSinceEpoch(user.subscriptionEnd).toIso8601String().split('T')[0]}',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.text2Light),
            ),
          ],
          if (user.subscriptionType != null) ...[
            const SizedBox(height: 4),
            Text('النوع: ${user.subscriptionType}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.text2Light)),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  const _SettingRow({required this.icon, required this.label, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? AppColors.text2Dark : AppColors.text2Light)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});
  @override
  Widget build(BuildContext context) {
    final label = role == 'superAdmin' ? 'سوبر أدمن' : role == 'admin' ? 'أدمن' : role == 'coach' ? 'مدرب' : 'عضو';
    final color = role.contains('admin') || role.contains('super') ? AppColors.warn : role == 'coach' ? AppColors.info : AppColors.ok;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _GasUrlSheet extends StatefulWidget {
  @override
  State<_GasUrlSheet> createState() => _GasUrlSheetState();
}

class _GasUrlSheetState extends State<_GasUrlSheet> {
  final _ctrl = TextEditingController();

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    await context.read<AuthProvider>().setGasUrl(_ctrl.text.trim());
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الرابط'), backgroundColor: AppColors.ok),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('رابط Google Apps Script', style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('أدخل رابط GAS الخاص بمشروعك لتفعيل المزامنة السحابية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.text2Light)),
          const SizedBox(height: 16),
          AppTextField(controller: _ctrl, label: 'رابط GAS', hint: 'https://script.google.com/...', keyboardType: TextInputType.url, textDirection: TextDirection.ltr),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

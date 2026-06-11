import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _program = 'UL';
  int _days = 4;
  String _subType = 'light';
  int _subMonths = 1;
  bool _obscurePass = true;
  int _step = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _doRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim(),
      program: _program,
      days: _days,
      subscriptionType: _subType,
      subscriptionMonths: _subMonths,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.err),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء حساب جديد'),
          leading: BackButton(onPressed: () => Navigator.pop(context)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepIndicator(current: _step, total: 3),
                const SizedBox(height: 24),

                if (_step == 0) ...[
                  const _SectionTitle('معلوماتك الشخصية'),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _nameCtrl,
                    label: 'الاسم الكامل',
                    hint: 'اسمك بالكامل',
                    validator: (v) => v == null || v.length < 2 ? 'أدخل اسمك' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _emailCtrl,
                    label: 'البريد الإلكتروني',
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    validator: (v) => v == null || !v.contains('@') ? 'بريد غير صحيح' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _passCtrl,
                    label: 'كلمة المرور',
                    obscureText: _obscurePass,
                    textDirection: TextDirection.ltr,
                    suffix: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'كلمة المرور 6 أحرف على الأقل' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _phoneCtrl,
                    label: 'رقم الجوال',
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    validator: (v) => v == null || v.length < 8 ? 'أدخل رقم صحيح' : null,
                  ),
                ],

                if (_step == 1) ...[
                  const _SectionTitle('برنامج التدريب'),
                  const SizedBox(height: 16),
                  ...AppConstants.programs.entries.map((entry) {
                    final id = entry.key;
                    final prog = entry.value;
                    final daysOpts = (prog['daysOptions'] as List).cast<int>();
                    return GestureDetector(
                      onTap: () => setState(() {
                        _program = id;
                        _days = daysOpts.first;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _program == id
                              ? AppColors.accentDark
                              : (isDark ? AppColors.bgCardDark : AppColors.bgCardLight),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _program == id ? AppColors.accent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: _program == id ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: _program == id ? AppColors.accent : (isDark ? AppColors.text3Dark : AppColors.text3Light),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prog['name']?.toString() ?? '',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.text1Dark : AppColors.text1Light,
                                    ),
                                  ),
                                  Text(
                                    prog['description']?.toString() ?? '',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_program == id)
                              const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const _SectionTitle('أيام التدريب في الأسبوع'),
                  const SizedBox(height: 12),
                  Row(
                    children: (AppConstants.programs[_program]!['daysOptions'] as List<dynamic>)
                        .cast<int>()
                        .map((d) => Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _days = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _days == d ? AppColors.accent : (isDark ? AppColors.bgCardDark : AppColors.bgCardLight),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _days == d ? AppColors.accent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$d',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _days == d ? Colors.white : (isDark ? AppColors.text1Dark : AppColors.text1Light),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ))
                        .toList(),
                  ),
                ],

                if (_step == 2) ...[
                  const _SectionTitle('نوع الاشتراك'),
                  const SizedBox(height: 16),
                  ...AppConstants.defaultPlans.entries.map((entry) {
                    final id = entry.key;
                    final plan = entry.value;
                    return GestureDetector(
                      onTap: () => setState(() => _subType = id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _subType == id ? AppColors.accentDark : (isDark ? AppColors.bgCardDark : AppColors.bgCardLight),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _subType == id ? AppColors.accent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: _subType == id ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${plan['label']} — ${plan['price']} ج.م/شهر',
                                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  ...(plan['features'] as List<dynamic>).map((f) => Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check, size: 14, color: AppColors.ok),
                                        const SizedBox(width: 6),
                                        Text(f.toString(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            if (_subType == id)
                              const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const _SectionTitle('مدة الاشتراك'),
                  const SizedBox(height: 12),
                  Row(
                    children: AppConstants.durations.map((d) => Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _subMonths = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _subMonths == d ? AppColors.accent : (isDark ? AppColors.bgCardDark : AppColors.bgCardLight),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _subMonths == d ? AppColors.accent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                          ),
                          child: Text(
                            '$d شهر',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _subMonths == d ? Colors.white : (isDark ? AppColors.text1Dark : AppColors.text1Light),
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ],

                const SizedBox(height: 32),
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          child: const Text('رجوع'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: _step < 2 ? 'التالي' : 'إنشاء الحساب',
                        isLoading: auth.isLoading,
                        onPressed: auth.isLoading
                            ? null
                            : () {
                                if (_step < 2) {
                                  setState(() => _step++);
                                } else {
                                  _doRegister();
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isDone = i < current;
        final isCurrent = i == current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone || isCurrent ? AppColors.accent : AppColors.accentDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

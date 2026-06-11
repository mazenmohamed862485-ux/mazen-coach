import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _gasUrlCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _showGasSetup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _gasUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      _showError(error);
    }
  }

  Future<void> _doGuestLogin() async {
    final codeCtrl = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('دخول كضيف', style: TextStyle(fontFamily: 'Cairo')),
        content: AppTextField(
          controller: codeCtrl,
          label: 'رمز الضيف',
          hint: 'أدخل الرمز المقدم من المدرب',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, codeCtrl.text),
            child: const Text('دخول'),
          ),
        ],
      ),
    );
    if (confirmed == null || confirmed.isEmpty) return;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.guestLogin(confirmed);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      _showError(error);
    }
  }

  Future<void> _saveGasUrl() async {
    if (_gasUrlCtrl.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    await auth.setGasUrl(_gasUrlCtrl.text.trim());
    if (!mounted) return;
    setState(() => _showGasSetup = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ رابط الخادم'), backgroundColor: AppColors.ok),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.err),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // ── Logo ──
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accentDark,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.fitness_center, color: AppColors.accent, size: 36),
                ),
                const SizedBox(height: 14),
                const Text(
                  'MAZEN COACH',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: isDark ? AppColors.text2Dark : AppColors.text2Light,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Login Form ──
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _loginFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.text1Dark : AppColors.text1Light,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          controller: _emailCtrl,
                          label: 'البريد الإلكتروني',
                          hint: 'example@email.com',
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          validator: (v) => v == null || v.isEmpty
                              ? 'أدخل البريد الإلكتروني' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _passCtrl,
                          label: 'كلمة المرور',
                          hint: '••••••••',
                          obscureText: _obscurePass,
                          textDirection: TextDirection.ltr,
                          validator: (v) => v == null || v.length < 4
                              ? 'كلمة المرور قصيرة جداً' : null,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'دخول',
                          onPressed: auth.isLoading ? null : _doLogin,
                          isLoading: auth.isLoading,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: auth.isLoading ? null : _doGuestLogin,
                          child: const Text('دخول كضيف'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Register Button ──
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text(
                    'ليس لديك حساب؟ سجّل الآن',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),

                // ── GAS URL Setup ──
                InkWell(
                  onTap: () => setState(() => _showGasSetup = !_showGasSetup),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_outlined, size: 16,
                          color: isDark ? AppColors.text3Dark : AppColors.text3Light),
                        const SizedBox(width: 6),
                        Text(
                          'إعداد رابط الخادم',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: isDark ? AppColors.text3Dark : AppColors.text3Light,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showGasSetup) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'أدخل رابط Google Apps Script الخاص بك',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _gasUrlCtrl,
                          label: 'رابط GAS',
                          hint: 'https://script.google.com/...',
                          keyboardType: TextInputType.url,
                          textDirection: TextDirection.ltr,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'حفظ الرابط',
                          onPressed: _saveGasUrl,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

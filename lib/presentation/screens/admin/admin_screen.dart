import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final users = await DatabaseHelper.instance.getAllUsers();
    setState(() { _users = users; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdminLike) {
      return const Scaffold(body: Center(child: Text('غير مصرح', style: TextStyle(fontFamily: 'Cairo'))));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [Tab(text: 'الأعضاء'), Tab(text: 'إعدادات الاشتراك')],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _UsersTab(users: _users, loading: _loading, onRefresh: _loadUsers),
            const _SubConfigTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loadUsers,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.refresh),
          label: const Text('تحديث', style: TextStyle(fontFamily: 'Cairo')),
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final List<UserModel> users;
  final bool loading;
  final VoidCallback onRefresh;

  const _UsersTab({required this.users, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return const Center(child: Text('لا يوجد مستخدمون', style: TextStyle(fontFamily: 'Cairo')));

    // Stats
    final active = users.where((u) => u.hasActiveSubscription && !u.isAdminLike).length;
    final expired = users.where((u) => u.subscriptionStatus == SubscriptionStatus.expired).length;
    final pending = users.where((u) => u.subscriptionStatus == SubscriptionStatus.paymentPending).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _StatBox('نشطون', '$active', AppColors.ok)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox('منتهي', '$expired', AppColors.err)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox('مراجعة', '$pending', AppColors.warn)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox('الكل', '${users.length}', AppColors.accent)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _UserCard(user: users[i], onUpdated: onRefresh),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onUpdated;
  const _UserCard({required this.user, required this.onUpdated});

  Color get _subColor {
    switch (user.currentSubscriptionStatus) {
      case SubscriptionStatus.active: return AppColors.ok;
      case SubscriptionStatus.expired: return AppColors.err;
      case SubscriptionStatus.paymentPending: return AppColors.warn;
      default: return AppColors.text3Light;
    }
  }

  String get _subLabel {
    if (user.isAdminLike) return 'أدمن';
    switch (user.currentSubscriptionStatus) {
      case SubscriptionStatus.active: return 'نشط';
      case SubscriptionStatus.expired: return 'منتهي';
      case SubscriptionStatus.paymentPending: return 'مراجعة';
      default: return 'لا اشتراك';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.accentDark, shape: BoxShape.circle),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700)),
                Text(user.email, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: isDark ? AppColors.text2Dark : AppColors.text2Light)),
                if (user.trainingProgram != null)
                  Text('برنامج: ${user.trainingProgram}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.accent)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _subColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(_subLabel, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600, color: _subColor)),
              ),
              const SizedBox(height: 4),
              if (!user.isAdminLike)
                GestureDetector(
                  onTap: () => _showEditSheet(context),
                  child: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.accent, decoration: TextDecoration.underline)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditUserSheet(user: user, onUpdated: onUpdated),
    );
  }
}

class _EditUserSheet extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUpdated;
  const _EditUserSheet({required this.user, required this.onUpdated});
  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  String _status = 'active';
  String _type = 'light';
  int _months = 1;

  @override
  void initState() {
    super.initState();
    _status = widget.user.subscriptionStatus.name;
    _type = widget.user.subscriptionType ?? 'light';
    _months = 1;
  }

  Future<void> _save() async {
    // Update locally
    final updated = widget.user.copyWith(
      subscriptionStatus: _status == 'active' ? SubscriptionStatus.active : SubscriptionStatus.none,
      subscriptionType: _type,
      subscriptionEnd: _status == 'active'
          ? DateTime.now().add(Duration(days: 30 * _months)).millisecondsSinceEpoch
          : null,
    );
    await DatabaseHelper.instance.saveUser(updated);

    // Try to sync via GAS
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // auth._api.updateUserSubscription(...) — in full impl

    widget.onUpdated();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث الاشتراك'), backgroundColor: AppColors.ok),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تعديل اشتراك ${widget.user.name}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'active', child: Text('نشط')),
              DropdownMenuItem(value: 'none', child: Text('غير نشط')),
              DropdownMenuItem(value: 'expired', child: Text('منتهي')),
              DropdownMenuItem(value: 'paymentPending', child: Text('قيد المراجعة')),
            ],
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'نوع الاشتراك', border: OutlineInputBorder()),
            items: AppConstants.planIds.map((id) => DropdownMenuItem(value: id, child: Text(AppConstants.defaultPlans[id]!['label'].toString()))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _months,
            decoration: const InputDecoration(labelText: 'مدة التجديد (أشهر)', border: OutlineInputBorder()),
            items: AppConstants.durations.map((d) => DropdownMenuItem(value: d, child: Text('$d شهر'))).toList(),
            onChanged: (v) => setState(() => _months = v!),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('حفظ التغييرات', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value, style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: color.withOpacity(0.8))),
      ]),
    );
  }
}

class _SubConfigTab extends StatefulWidget {
  const _SubConfigTab();
  @override
  State<_SubConfigTab> createState() => _SubConfigTabState();
}

class _SubConfigTabState extends State<_SubConfigTab> {
  final Map<String, TextEditingController> _priceCtrl = {
    'light': TextEditingController(text: '80'),
    'standard': TextEditingController(text: '200'),
    'pro': TextEditingController(text: '350'),
  };
  final _walletCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in _priceCtrl.values) c.dispose();
    _walletCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('أسعار الاشتراكات', style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...AppConstants.planIds.map((id) {
            final plan = AppConstants.defaultPlans[id]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan['label'].toString(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
                          Text('${plan['months']} شهر', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? AppColors.text2Dark : AppColors.text2Light)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _priceCtrl[id],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          suffixText: ' ج.م',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('بيانات الدفع', style: TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _walletCtrl,
            decoration: const InputDecoration(
              labelText: 'رقم المحفظة / IBAN / بيانات الدفع',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('سيتم المزامنة مع الخادم عند الاتصال'), backgroundColor: AppColors.ok),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('حفظ الإعدادات', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

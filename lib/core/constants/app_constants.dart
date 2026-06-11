class AppConstants {
  AppConstants._();

  static const String appName = 'MAZEN COACH';
  static const String appVersion = 'v8.2.0';
  static const String appTagline = 'نظام التدريب الذكي';

  // ── SharedPreferences Keys ──
  static const String keyUserId = 'mc_uid';
  static const String keyUserJson = 'mc_user_json';
  static const String keyGasUrl = 'mc_gas_url';
  static const String keyTheme = 'mc_theme';
  static const String keyLanguage = 'mc_lang';
  static const String keyLastSync = 'mc_last_sync';
  static const String keySessionId = 'mc_session_id';
  static const String keySubConfig = 'mc_sub_config';

  // ── DB Name ──
  static const String dbName = 'mazen_coach.db';
  static const int dbVersion = 1;

  // ── Subscription Plans ──
  static const Map<String, Map<String, dynamic>> defaultPlans = {
    'light': {
      'label': 'خفيف',
      'labelEn': 'Light',
      'months': 1,
      'price': 80,
      'features': ['برامج تدريب أساسية', 'تتبع الحضور', 'حاسبة السعرات'],
    },
    'standard': {
      'label': 'قياسي',
      'labelEn': 'Standard',
      'months': 3,
      'price': 200,
      'features': ['كل مميزات الخفيف', 'خطط تغذية مخصصة', 'تقارير التقدم'],
    },
    'pro': {
      'label': 'احترافي',
      'labelEn': 'Pro',
      'months': 6,
      'price': 350,
      'features': ['كل المميزات', 'دردشة مع المدرب', 'تحليل الأداء المتقدم'],
    },
  };

  static const List<String> planIds = ['light', 'standard', 'pro'];
  static const List<int> durations = [1, 3, 6, 12];
  static const String defaultWallet = '';
  static const int defaultBasePrice = 80;

  // ── Training Programs ──
  static const Map<String, Map<String, dynamic>> programs = {
    'UL': {
      'id': 'UL',
      'name': 'Upper / Lower',
      'description': 'تقسيم جسم علوي وسفلي',
      'daysOptions': [4],
      'sessions': ['Upper A', 'Lower A', 'Upper B', 'Lower B'],
    },
    'AP': {
      'id': 'AP',
      'name': 'Anterior / Posterior',
      'description': 'نظام أمامي-خلفي',
      'daysOptions': [4],
      'sessions': ['Anterior A', 'Posterior A', 'Anterior B', 'Posterior B'],
    },
    'FB': {
      'id': 'FB',
      'name': 'Full Body',
      'description': 'جسم كامل',
      'daysOptions': [3],
      'sessions': ['Full Body #1', 'Full Body #2', 'Full Body #3'],
    },
    'ARNOLD': {
      'id': 'ARNOLD',
      'name': 'Arnold',
      'description': 'برنامج أرنولد الكلاسيكي',
      'daysOptions': [5],
      'sessions': ['Chest & Back', 'Shoulders & Arms', 'Lower A', 'Upper', 'Lower B'],
    },
    'PPL': {
      'id': 'PPL',
      'name': 'Push / Pull / Legs',
      'description': 'ضغط-شد-أرجل',
      'daysOptions': [5],
      'sessions': ['PUSH', 'PULL', 'Lower A', 'Upper', 'Lower B'],
    },
    'CUSTOM': {
      'id': 'CUSTOM',
      'name': 'برنامج مخصص',
      'description': 'أضف تمارينك وجلساتك بنفسك',
      'daysOptions': [3, 4, 5, 6],
      'sessions': [],
    },
  };

  // ── Warmup Exercises ──
  static const List<Map<String, dynamic>> warmupExercises = [
    {'name': 'Pallof Press', 'reps': '10/side', 'hasWeight': true, 'note': 'ثبّت جسمك وحرك ذراعك فقط'},
    {'name': 'Pallof Rotation', 'reps': '10/side', 'hasWeight': true, 'note': 'حوضك ثابت'},
    {'name': 'External Rotation', 'reps': '10 reps', 'hasWeight': true, 'note': 'من الكتف فقط'},
    {'name': 'Scapula Push Plus', 'reps': '10 reps', 'hasWeight': true, 'note': 'من لوح الكتف — وزن خفيف'},
    {'name': 'Neck Extension', 'reps': '12 reps', 'hasWeight': true, 'note': 'وزن خفيف جداً — أسفل الرأس'},
    {'name': 'Neck Flexion', 'reps': '12 reps', 'hasWeight': true, 'note': 'وزن خفيف — الذقن للصدر'},
  ];

  // ── Rest Timer Default (seconds) ──
  static const int defaultRestSeconds = 180;

  // ── Attendance Symbols ──
  static const Map<String, String> attendanceSymbols = {
    'present': '✓',
    'absent': '✗',
    'late': '~',
    'excused': 'E',
    'holiday': '★',
  };

  // ── Nav Items ──
  static const List<Map<String, dynamic>> navItems = [
    {'id': 'home', 'labelAr': 'الرئيسية', 'icon': 'home'},
    {'id': 'workout', 'labelAr': 'التمرين', 'icon': 'fitness_center'},
    {'id': 'nutrition', 'labelAr': 'التغذية', 'icon': 'restaurant'},
    {'id': 'attendance', 'labelAr': 'الحضور', 'icon': 'calendar_today'},
    {'id': 'progress', 'labelAr': 'التقدم', 'icon': 'trending_up'},
  ];
}

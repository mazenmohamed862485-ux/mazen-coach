# 🏋️ MAZEN COACH — تطبيق إدارة التدريب الرياضي

<div dir="rtl">

## نظرة عامة

**Mazen Coach** هو تطبيق Flutter أصلي متكامل لإدارة التدريب الرياضي باللغة العربية. تم تحويله من PWA (تطبيق ويب تقدمي مُغلّف بـ Capacitor) إلى تطبيق Flutter نيتف احترافي.

### المميزات الرئيسية

| الميزة | الوصف |
|--------|--------|
| 🔐 **نظام المصادقة** | تسجيل دخول، إنشاء حساب، دخول ضيف |
| 📋 **إدارة الاشتراكات** | خطط (خفيف/قياسي/احترافي) مع مدد متعددة |
| 🏋️ **6 برامج تدريب** | UL, AP, FB, Arnold, PPL, مخصص |
| 🥗 **تتبع التغذية** | حاسبة سعرات ذكية وقاعدة بيانات طعام |
| 📅 **تتبع الحضور** | تقويم شهري مع تمييز أيام الحضور/الغياب |
| 📊 **تتبع التقدم** | قياسات جسدية + تقدم 1RM بصيغة Epley |
| 💬 **الدردشة** | غرف دردشة مع المدرب والأعضاء |
| 🌙 **الوضع الداكن** | دعم كامل للوضع الداكن والفاتح |
| ☁️ **مزامنة سحابية** | عبر Google Apps Script (اختياري) |
| 📵 **Local-First** | يعمل بدون إنترنت — SQLite محلي |

---

## هيكل المشروع

```
mavix_flutter/
├── lib/
│   ├── main.dart                          # نقطة الدخول الرئيسية
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart            # ألوان التطبيق
│   │   │   └── app_constants.dart         # ثوابت وبيانات البرامج
│   │   └── theme/
│   │       └── app_theme.dart             # ThemeData (فاتح/داكن)
│   ├── data/
│   │   ├── local/
│   │   │   ├── database_helper.dart       # SQLite (sqflite)
│   │   │   └── preferences_helper.dart    # SharedPreferences
│   │   ├── remote/
│   │   │   └── gas_api_service.dart       # Google Apps Script API
│   │   └── models/
│   │       ├── user_model.dart
│   │       ├── workout_model.dart
│   │       ├── nutrition_model.dart
│   │       ├── attendance_model.dart
│   │       ├── measurement_model.dart
│   │       └── chat_model.dart
│   ├── domain/
│   │   └── evaluator.dart                 # Epley 1RM + كشف الركود
│   └── presentation/
│       ├── providers/
│       │   ├── auth_provider.dart
│       │   ├── workout_provider.dart
│       │   ├── nutrition_provider.dart
│       │   └── theme_provider.dart
│       ├── screens/
│       │   ├── splash/splash_screen.dart
│       │   ├── auth/login_screen.dart
│       │   ├── auth/register_screen.dart
│       │   ├── home/home_screen.dart
│       │   ├── workout/workout_screen.dart
│       │   ├── workout/session_screen.dart
│       │   ├── nutrition/nutrition_screen.dart
│       │   ├── attendance/attendance_screen.dart
│       │   ├── progress/progress_screen.dart
│       │   ├── chat/chat_screen.dart
│       │   └── settings/settings_screen.dart
│       └── widgets/
│           └── common/
│               ├── app_button.dart
│               ├── app_card.dart
│               └── app_text_field.dart
└── android/
    ├── app/
    │   ├── build.gradle
    │   └── src/main/
    │       ├── AndroidManifest.xml
    │       └── kotlin/com/mazencoach/mavix/MainActivity.kt
    └── build.gradle
```

---

## المكتبات المستخدمة

| المكتبة | الغرض |
|---------|--------|
| `provider ^6.1.2` | إدارة الحالة |
| `sqflite ^2.3.3` | قاعدة بيانات SQLite محلية |
| `shared_preferences ^2.3.3` | تخزين مفتاح-قيمة |
| `http ^1.2.2` | طلبات HTTP لـ GAS API |
| `fl_chart ^0.68.0` | رسوم بيانية للتقدم |
| `intl ^0.19.0` | تنسيق التواريخ |
| `uuid ^4.4.2` | توليد معرفات فريدة |
| `connectivity_plus ^6.0.5` | فحص الاتصال |
| `font_awesome_flutter ^10.7.0` | أيقونات إضافية |

---

## الأدوار في التطبيق

```
SuperAdmin  →  تحكم كامل في كل شيء
Admin       →  إدارة الأعضاء والاشتراكات
Coach       →  رؤية بيانات الأعضاء
User        →  وصول للبرامج والتتبع
```

---

## نظام الاشتراكات

| الخطة | الوصف | السعر الافتراضي |
|-------|--------|-----------------|
| خفيف (light) | برامج أساسية + حضور | 80 ج.م/شهر |
| قياسي (standard) | + تغذية مخصصة + تقارير | 200 ج.م/3 أشهر |
| احترافي (pro) | كل المميزات + دردشة | 350 ج.م/6 أشهر |

---

## برامج التدريب

| الكود | الاسم | أيام |
|-------|-------|------|
| UL | Upper / Lower | 4 أيام |
| AP | Anterior / Posterior | 4 أيام |
| FB | Full Body | 3 أيام |
| ARNOLD | Arnold Split | 5 أيام |
| PPL | Push / Pull / Legs | 5 أيام |
| CUSTOM | مخصص | 3-6 أيام |

---

## المزامنة السحابية (GAS)

التطبيق يعمل **local-first** — جميع البيانات تُخزَّن في SQLite أولاً، ثم تُرسَل للـ GAS عند توفر الاتصال.

لإعداد المزامنة:
1. ارفع نص GAS المُرفق على Google Apps Script
2. انسخ رابط النشر (Deploy → Web App URL)
3. أدخله في إعدادات التطبيق أو عند تسجيل الدخول

</div>

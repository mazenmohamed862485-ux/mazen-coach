# 🚀 دليل النشر والتثبيت — Mazen Coach

<div dir="rtl">

## المتطلبات المسبقة

### أدوات التطوير

| الأداة | الإصدار المطلوب | رابط التحميل |
|--------|-----------------|--------------|
| Flutter SDK | ≥ 3.19.0 (stable) | https://flutter.dev/docs/get-started/install |
| Dart SDK | ≥ 3.3.0 (مُضمَّن مع Flutter) | - |
| Android Studio | ≥ 2023.1 (Hedgehog) | https://developer.android.com/studio |
| Java JDK | ≥ 17 (LTS) | https://adoptium.net/ |
| Git | أي إصدار حديث | https://git-scm.com/ |

### متطلبات Android
- Android SDK (API 34 مُثبَّت)
- Android Build Tools ≥ 34.0.0
- Android Emulator أو جهاز حقيقي (API 21+)

---

## الخطوة 1: إعداد البيئة

### تثبيت Flutter

```bash
# Linux / macOS
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

```powershell
# Windows (PowerShell)
git clone https://github.com/flutter/flutter.git -b stable
$env:PATH += ";$(pwd)\flutter\bin"
flutter doctor
```

### التحقق من البيئة
```bash
flutter doctor -v
# يجب أن تظهر جميع العناصر بعلامة ✓
```

---

## الخطوة 2: فتح المشروع

```bash
# 1. انتقل إلى مجلد المشروع
cd mavix_flutter

# 2. تحديث الـ local.properties (Android)
echo "sdk.dir=/path/to/android/sdk" > android/local.properties
echo "flutter.sdk=/path/to/flutter/sdk" >> android/local.properties

# 3. تحميل المكتبات
flutter pub get

# 4. التحقق من صحة المشروع
flutter analyze
```

---

## الخطوة 3: إضافة الخطوط

⚠️ **مهم:** خط Cairo غير مُدرَج في المشروع لأسباب الترخيص.

```bash
# قم بإنشاء مجلد الخطوط
mkdir -p assets/fonts

# حمّل خط Cairo من Google Fonts:
# https://fonts.google.com/specimen/Cairo
# اختر: Variable font — Cairo[slnt,wght].ttf
# أو الملفات المنفصلة:
# Cairo-Regular.ttf, Cairo-Medium.ttf, Cairo-SemiBold.ttf
# Cairo-Bold.ttf, Cairo-ExtraBold.ttf, Cairo-Black.ttf
```

**أو استخدام google_fonts بدلاً من ذلك (أسهل):**

في `pubspec.yaml` أضف:
```yaml
dependencies:
  google_fonts: ^6.2.1
```

في `app_theme.dart` غيّر `fontFamily: 'Cairo'` إلى:
```dart
import 'package:google_fonts/google_fonts.dart';
// ...
textTheme: GoogleFonts.cairoTextTheme(...)
```

---

## الخطوة 4: إضافة أصول الصور

```bash
mkdir -p assets/images assets/icons
# أضف أي صور أو أيقونات تحتاجها هنا
# مثال: logo.png، splash.png
```

---

## الخطوة 5: بناء التطبيق

### للتطوير (Debug)
```bash
# على محاكي Android
flutter run

# على جهاز متصل
flutter run --release

# لعرض قائمة الأجهزة
flutter devices
```

### للإنتاج (APK)
```bash
# بناء APK موحد (لجميع المعماريات)
flutter build apk --release

# بناء APK مُقسَّم حسب المعمارية (حجم أصغر)
flutter build apk --split-per-abi --release

# الملفات تُولَّد في:
# build/app/outputs/flutter-apk/
# - app-armeabi-v7a-release.apk  (للأجهزة القديمة)
# - app-arm64-v8a-release.apk    (للأجهزة الحديثة) ← الأشهر
# - app-x86_64-release.apk       (للمحاكيات)
```

### لـ Google Play (AAB)
```bash
flutter build appbundle --release
# الملف في: build/app/outputs/bundle/release/app-release.aab
```

---

## الخطوة 6: توقيع التطبيق (للنشر الإنتاجي)

```bash
# 1. إنشاء keystore
keytool -genkey -v \
  -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=Mazen Coach, OU=MavixDev, O=MazenCoach, L=Cairo, S=Cairo, C=EG"

# 2. أنشئ ملف android/key.properties
echo "storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/path/to/upload-keystore.jks" > android/key.properties

# 3. في android/app/build.gradle، أضف:
# signingConfigs {
#     release {
#         keyAlias keystoreProperties['keyAlias']
#         keyPassword keystoreProperties['keyPassword']
#         storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
#         storePassword keystoreProperties['storePassword']
#     }
# }
```

---

## الخطوة 7: إعداد Google Apps Script (مزامنة سحابية)

### إنشاء مشروع GAS

1. اذهب إلى https://script.google.com/
2. أنشئ مشروع جديد
3. ارفع ملف `gas_backend.js` (يجب إعداده يدوياً حسب بنيانات البيانات)
4. اذهب إلى **Deploy → Manage Deployments → New Deployment**
5. اختر **Type: Web app**
6. اضبط **Execute as: Me**, **Who has access: Anyone**
7. انسخ رابط النشر

### إعداد الرابط في التطبيق

في التطبيق، اذهب إلى **الإعدادات → رابط الخادم** وأدخل الرابط.

---

## الخطوة 8: تثبيت APK على الجهاز

```bash
# تثبيت مباشر عبر ADB
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# أو أرسل ملف APK للجهاز عبر واتساب/بريد/أي طريقة
# وشغّل "تثبيت من مصادر مجهولة" على الجهاز
```

---

## حل المشاكل الشائعة

| المشكلة | الحل |
|---------|------|
| `flutter pub get` يفشل | تحقق من اتصال الإنترنت وإصدار Dart |
| خطأ Gradle | تشغيل `cd android && ./gradlew clean` |
| لا يظهر جهاز Android | تفعيل وضع المطور و USB debugging |
| APK لا يُثبَّت | تفعيل "تثبيت من مصادر مجهولة" |
| الخطوط لا تظهر | التحقق من مسارات الخطوط في pubspec.yaml |
| شاشة بيضاء | تشغيل `flutter clean && flutter pub get` |

---

## الحد الأدنى لمتطلبات الجهاز

| المتطلب | الحد الأدنى |
|---------|-------------|
| Android | 5.0 (API 21) |
| RAM | 2 GB |
| تخزين | 100 MB خالية |
| اتصال | اختياري (local-first) |

</div>

# CalSnap — تطبيق Flutter 📸🥗

تحويل كامل لموقع CalSnap إلى تطبيق أندرويد و iOS بنفس التصميم (كحلي داكن + برتقالي) ونفس قاعدة بيانات Supabase الحالية — حساباتك وبياناتك على الموقع ستعمل في التطبيق مباشرة.

## المتطلبات
- Flutter **3.27 أو أحدث** (الكود يستخدم `withValues`)
- حساب Supabase الحالي نفسه (نفس المشروع المستخدم في الموقع)

## التشغيل من VS Code
1. ثبّت إضافتي **Flutter** و**Dart** من المتجر (VS Code سيقترحهما تلقائياً عند فتح المجلد بفضل `.vscode/extensions.json`).
2. نفّذ خطوات "خطوات التشغيل" أدناه أولاً (مفتاح Supabase + توليد مجلدات المنصات).
3. افتح تبويب **Run and Debug** (`Ctrl+Shift+D`) واختر من القائمة أعلى الشاشة أحد الإعدادات الجاهزة (`calsnap (Debug)` مثلاً)، أو اضغط `F5` مباشرة.
4. لاختيار الجهاز/المحاكي: من شريط الحالة أسفل VS Code اضغط على اسم الجهاز، أو نفّذ من لوحة الأوامر (`Ctrl+Shift+P`) أمر **Flutter: Select Device**.

## خطوات التشغيل

### 1) مفتاح Supabase
افتح `lib/main.dart` وضع مفتاح anon مكان `ضع_مفتاح_ANON_هنا`
(نفس قيمة `VITE_SUPABASE_ANON_KEY` الموجودة في ملف `.env` بمشروع الويب).

### 2) توليد مجلدات المنصات وتشغيل التطبيق
```bash
cd calsnap_flutter
flutter create . --platforms=android,ios,web
flutter pub get
flutter run
```
> هذا الأمر آمن ولا يمس أي كود موجود — فقط يضيف مجلدات `android/` و`ios/` و`web/` الناقصة (أيقونات، Gradle، Xcode...) دون التأثير على `lib/` أو `pubspec.yaml`.

### 3) أذونات الكاميرا
**أندرويد** — أضف داخل `android/app/src/main/AndroidManifest.xml` قبل `<application>`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```
> حزمة `camera` تتطلب `minSdkVersion 21` أو أعلى — القيمة الافتراضية من `flutter create` كافية.

**iOS** — أضف داخل `ios/Runner/Info.plist` (قبل `</dict>` الأخيرة):
```xml
<key>NSCameraUsageDescription</key>
<string>نستخدم الكاميرا لتصوير وجباتك وتحليلها</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>نستخدم المعرض لاختيار صور الوجبات</string>
```

### 4) نشر دوال الذكاء الاصطناعي (مرة واحدة)
الموقع كان يشغّل تحليل الصور والمدرب على السيرفر. للموبايل نقلناها إلى Supabase Edge Functions (موجودة في مجلد `supabase/functions/`):
```bash
supabase link --project-ref bslzeadleuvqunzzsrum
supabase secrets set LOVABLE_API_KEY=مفتاحك_من_Lovable
supabase functions deploy analyze-food
supabase functions deploy coach
```
> مفتاح `LOVABLE_API_KEY` هو نفسه المستخدم في الموقع (موجود في إعدادات مشروع Lovable). لا تضعه أبداً داخل كود التطبيق.

### 5) مخزن الصور
تأكد من وجود bucket باسم `food-images` في Supabase Storage (موجود أصلاً إذا كان الموقع يرفع صوراً). إن لم يوجد أنشئه واجعله Public.

## تصميم ACLEE (المرحلة 1 + 2)
- نظام توكنز موحد (مسافات/زوايا/حركة) + زجاج حقيقي بـ BackdropFilter + خلفية محيطية متوهجة
- كاميرا حية داخل التطبيق (فلاش، معرض، غالق فاخر) ← مسح ذكي بشعاع وأقواس وكشف تدريجي ← نتيجة فاخرة بحلقات وMiniRings ورؤية AI ← حفظ بنجاح متحرك
- استوديو الستوري: مؤشرات زجاجية قابلة للسحب والتكبير والتدوير على صورة الوجبة أو أي صورة من المعرض، وتصدير PNG ومشاركة
- شريط تنقل سفلي عائم زجاجي وحركات دخول متدرجة في كل الشاشات

## ما تم بناؤه في هذه المرحلة
- تسجيل دخول / إنشاء حساب (نفس مستخدمي الموقع)
- الرئيسية: حلقة السعرات المتحركة، متتبع الماء، سلسلة الأيام، بطاقات الماكروز، وجبات اليوم
- التحليل: كاميرا/معرض ← Gemini 2.5 Pro ← نتيجة قابلة للتعديل ← تسجيل + نقاط
- المدرب الذكي "أليكس" مع سياق آخر 7 أيام من وجباتك
- التقدم: رسم بياني أسبوعي مع خط الهدف
- السجل (آخر 30 يوم) مع حذف
- الإنجازات: المستوى والتقدم والشارات
- الإعدادات: الاسم، هدف السعرات، اللغة (عربي/إنجليزي مع RTL كامل)، تسجيل الخروج

## المرحلة الثانية (غير منقولة بعد)
المتجر والسلة والطلبات، Story Studio، التحديات اليومية التفاعلية، المتصدرون، الإشعارات.

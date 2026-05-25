# إعداد تطبيق الأماني - Flutter

## خطوات البدء

### 1. إعداد بيئة Flutter
تأكد من تثبيت Flutter SDK: https://flutter.dev/docs/get-started/install

### 2. استنساخ المشروع وإنشاء ملفات المنصة
```bash
git clone <repo-url>
cd Mj
flutter create . --project-name amani_quotation
flutter pub get
```

### 3. نشر Code.gs كـ Web App
1. افتح مشروع Google Apps Script
2. اضغط **نشر** → **نشر جديد** → **تطبيق ويب**
3. اضبط التنفيذ على "أنا" والوصول على "أي شخص"
4. انسخ الرابط الناتج

### 4. إضافة رابط GAS في التطبيق
افتح `lib/config.dart` وضع الرابط:
```dart
static const String gasUrl = 'https://script.google.com/macros/s/YOUR_ID/exec';
```

### 5. تشغيل التطبيق
```bash
flutter run
```

## الميزات
- إنشاء عروض أسعار رسمية من الموبايل
- بحث تلقائي للمنتجات مع صورها
- حفظ العروض في Google Sheets
- تصدير PDF جاهز للطباعة (صفحتان)
- إدارة قاعدة بيانات المنتجات
- يعمل على Android و iOS

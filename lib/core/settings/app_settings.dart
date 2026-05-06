import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { en, ar }

class AppSettingsController extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language_code';

  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.en;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  Locale get locale => Locale(_language == AppLanguage.ar ? 'ar' : 'en');
  TextDirection get textDirection =>
      _language == AppLanguage.ar ? TextDirection.rtl : TextDirection.ltr;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    final savedLanguage = prefs.getString(_languageKey);
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _language = savedLanguage == 'ar' ? AppLanguage.ar : AppLanguage.en;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _languageKey,
      language == AppLanguage.ar ? 'ar' : 'en',
    );
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}

extension AppSettingsX on BuildContext {
  AppSettingsController get settings => AppSettingsScope.of(this);
  String t(String key) => AppStrings.translate(settings.language, key);
}

class AppStrings {
  const AppStrings._();

  static const _en = <String, String>{
    'menu': 'Menu',
    'settings': 'Settings',
    'account_settings': 'Account settings',
    'appearance': 'Appearance',
    'light': 'Light',
    'dark': 'Dark',
    'language': 'Language',
    'english': 'English',
    'arabic': 'Arabic',
    'sign_out': 'Sign out',
    'account_info': 'Account information',
    'full_name': 'Full name',
    'email': 'Email',
    'phone': 'Phone number',
    'new_password': 'New password',
    'leave_blank': 'Leave blank to keep current password',
    'save_changes': 'Save changes',
    'saved': 'Changes saved.',
    'reauth_required': 'For email/password changes, sign in again then retry.',
    'jobs_near_you': 'Jobs near you',
    'my_orders': 'My orders',
    'new_order': 'New Order',
    'dashboard': 'Dashboard',
    'users': 'Users',
    'clients': 'Clients',
    'drivers': 'Drivers',
    'all': 'All',
    'no_users': 'No users',
    'no_users_found': 'No users found.',
    'create_order': 'Create Order',
    'order': 'Order',
    'place_bid': 'Place Bid',
    'back': 'Back',
    'sign_in_subtitle': 'Sign in to manage deliveries and bids.',
    'sign_in': 'Sign In',
    'create_account': 'Create account',
    'already_have_account': 'I already have an account',
    'client': 'Client',
    'driver': 'Driver',
    'password': 'Password',
    'vehicle': 'Vehicle',
    'bike': 'Bike',
    'car': 'Car',
    'truck': 'Truck',
    'upload_vehicle_photo': 'Upload vehicle photo',
    'contact_phone': 'Contact phone',
    'describe_item': 'Describe the item',
    'description': 'Description',
    'publish_request': 'Publish Request',
    'tap_map_pin': 'Tap the map to set the selected pin.',
    'pickup': 'Pickup',
    'dropoff': 'Drop-off',
    'from': 'From',
    'to': 'To',
    'bids': 'Bids',
    'no_orders_yet': 'No orders yet',
    'create_first_order': 'Create your first Veloce Express request.',
    'order_not_found': 'Order not found',
    'order_missing': 'This request no longer exists.',
    'no_bids_yet': 'No bids yet',
    'drivers_bid_realtime': 'Approved drivers will bid in real time.',
    'rating': 'Rating',
    'reject': 'Reject',
    'accept': 'Accept',
    'bid_amount': 'Bid amount',
    'amount': 'Amount',
    'valid_amount': 'Enter a valid amount',
    'send_bid': 'Send Bid',
    'no_jobs_available': 'No jobs available',
    'open_requests_appear': 'Open Veloce Express requests will appear here.',
    'active_trip': 'Active trip',
    'you': 'You',
    'live': 'LIVE',
    'in_transit': 'In transit',
    'driver_en_route': 'Driver en route',
    'your_driver': 'Your Driver',
    'agreed_fare': 'Agreed Fare',
    'confirm_trip': 'Confirm Trip',
    'trip_completed': 'Trip completed.',
    'leave_active_trip': 'Leave active trip?',
    'leave_active_trip_body':
        'The trip is still in progress. You can return to it anytime.',
    'stay': 'Stay',
    'leave': 'Leave',
    'confirm_trip_question': 'Confirm Trip?',
    'confirm_trip_body': 'Confirm only after handing the item to the client.',
    'yes_completed': 'Yes, Completed',
    'cancel': 'Cancel',
    'rate_experience': 'Rate your experience',
    'how_was': 'How was',
    'submit_rating': 'Submit Rating',
    'skip': 'Skip',
    'approvals': 'Approvals',
    'orders': 'Orders',
    'all_caught_up': 'All caught up!',
    'no_pending_approvals': 'No pending approvals.',
    'vehicle_photo': 'Vehicle Photo',
    'approve': 'Approve',
    'no_orders': 'No orders',
    'no_orders_filter': 'No orders match this filter.',
    'approved': 'Approved',
    'blocked': 'Blocked',
    'verify_email': 'Verify your email',
    'verify_email_body':
        'We sent a verification link to {email}. The app will continue automatically after verification.',
    'i_verified_email': 'I Verified My Email',
    'resend_email': 'Resend email',
    'waiting_approval': 'Waiting for approval',
    'driver_approval_body':
        'Your account and vehicle photo are under admin review.',
    'client_approval_body': 'Your account is under admin review.',
    'refresh_status': 'Refresh Status',
  };

  static const _ar = <String, String>{
    'menu': 'القائمة',
    'settings': 'الإعدادات',
    'account_settings': 'إعدادات الحساب',
    'appearance': 'المظهر',
    'light': 'نهار',
    'dark': 'داكن',
    'language': 'اللغة',
    'english': 'الإنجليزية',
    'arabic': 'العربية',
    'sign_out': 'تسجيل الخروج',
    'account_info': 'معلومات الحساب',
    'full_name': 'الإسم واللقب',
    'email': 'البريد الإلكتروني',
    'phone': 'رقم الهاتف',
    'new_password': 'كلمة سر جديدة',
    'leave_blank': 'اتركها فارغة للإبقاء على كلمة السر الحالية',
    'save_changes': 'حفظ التغييرات',
    'saved': 'تم حفظ التغييرات.',
    'reauth_required':
        'لتغيير البريد أو كلمة السر، سجل الدخول مرة أخرى ثم أعد المحاولة.',
    'jobs_near_you': 'الطلبات القريبة',
    'my_orders': 'طلباتي',
    'new_order': 'طلب جديد',
    'dashboard': 'لوحة التحكم',
    'users': 'المستخدمون',
    'clients': 'الزبائن',
    'drivers': 'السائقون',
    'all': 'الكل',
    'no_users': 'لا يوجد مستخدمون',
    'no_users_found': 'لم يتم العثور على مستخدمين.',
    'create_order': 'إنشاء طلب',
    'order': 'الطلب',
    'place_bid': 'إرسال عرض',
    'back': 'رجوع',
    'sign_in_subtitle': 'سجل الدخول لإدارة الطلبات والعروض.',
    'sign_in': 'تسجيل الدخول',
    'create_account': 'إنشاء حساب',
    'already_have_account': 'لدي حساب بالفعل',
    'client': 'زبون',
    'driver': 'سائق',
    'password': 'كلمة السر',
    'vehicle': 'المركبة',
    'bike': 'دراجة',
    'car': 'سيارة',
    'truck': 'شاحنة',
    'upload_vehicle_photo': 'رفع صورة المركبة',
    'contact_phone': 'رقم التواصل',
    'describe_item': 'صف الشيء المراد توصيله',
    'description': 'الوصف',
    'publish_request': 'نشر الطلب',
    'tap_map_pin': 'اضغط على الخريطة لتحديد النقطة المختارة.',
    'pickup': 'نقطة الانطلاق',
    'dropoff': 'نقطة الوصول',
    'from': 'من',
    'to': 'إلى',
    'bids': 'العروض',
    'no_orders_yet': 'لا توجد طلبات بعد',
    'create_first_order': 'أنشئ أول طلب في Veloce Express.',
    'order_not_found': 'الطلب غير موجود',
    'order_missing': 'هذا الطلب لم يعد موجودًا.',
    'no_bids_yet': 'لا توجد عروض بعد',
    'drivers_bid_realtime': 'ستظهر عروض السائقين المقبولين مباشرة.',
    'rating': 'التقييم',
    'reject': 'رفض',
    'accept': 'قبول',
    'bid_amount': 'قيمة العرض',
    'amount': 'المبلغ',
    'valid_amount': 'أدخل مبلغًا صحيحًا',
    'send_bid': 'إرسال العرض',
    'no_jobs_available': 'لا توجد طلبات متاحة',
    'open_requests_appear': 'ستظهر طلبات Veloce Express المفتوحة هنا.',
    'active_trip': 'رحلة نشطة',
    'you': 'أنت',
    'live': 'مباشر',
    'in_transit': 'قيد التوصيل',
    'driver_en_route': 'السائق في الطريق',
    'your_driver': 'سائقك',
    'agreed_fare': 'السعر المتفق عليه',
    'confirm_trip': 'تأكيد الرحلة',
    'trip_completed': 'تم إكمال الرحلة.',
    'leave_active_trip': 'مغادرة الرحلة النشطة؟',
    'leave_active_trip_body':
        'الرحلة ما زالت قيد التنفيذ. يمكنك العودة إليها لاحقًا.',
    'stay': 'البقاء',
    'leave': 'مغادرة',
    'confirm_trip_question': 'تأكيد الرحلة؟',
    'confirm_trip_body': 'أكد فقط بعد تسليم الشيء إلى الزبون.',
    'yes_completed': 'نعم، تم التسليم',
    'cancel': 'إلغاء',
    'rate_experience': 'قيّم تجربتك',
    'how_was': 'كيف كان',
    'submit_rating': 'إرسال التقييم',
    'skip': 'تخطي',
    'approvals': 'الموافقات',
    'orders': 'الطلبات',
    'all_caught_up': 'كل شيء مكتمل!',
    'no_pending_approvals': 'لا توجد موافقات معلقة.',
    'vehicle_photo': 'صورة المركبة',
    'approve': 'قبول',
    'no_orders': 'لا توجد طلبات',
    'no_orders_filter': 'لا توجد طلبات تطابق هذا الفلتر.',
    'approved': 'مقبول',
    'blocked': 'محظور',
    'verify_email': 'تحقق من بريدك الإلكتروني',
    'verify_email_body':
        'أرسلنا رابط تحقق إلى {email}. سيكمل التطبيق تلقائيًا بعد التحقق.',
    'i_verified_email': 'تحققت من بريدي',
    'resend_email': 'إعادة إرسال البريد',
    'waiting_approval': 'في انتظار الموافقة',
    'driver_approval_body': 'حسابك وصورة المركبة قيد مراجعة الأدمن.',
    'client_approval_body': 'حسابك قيد مراجعة الأدمن.',
    'refresh_status': 'تحديث الحالة',
  };

  static String translate(AppLanguage language, String key) {
    final source = language == AppLanguage.ar ? _ar : _en;
    return source[key] ?? _en[key] ?? key;
  }
}

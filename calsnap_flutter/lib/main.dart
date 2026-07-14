import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/i18n/app_translations.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/supabase_service.dart';

// ⚠️ عدّل هذه القيم لمشروعك على Supabase (نفس قيم .env في مشروع الويب)
const supabaseUrl = 'https://bslzeadleuvqunzzsrum.supabase.co';
const supabaseAnonKey = 'ضع_مفتاح_ANON_هنا';

/// وضع تجريبي تلقائي: يعمل التطبيق ببيانات وهمية محلية بدون أي اتصال
/// حقيقي بـ Supabase طالما لم يُستبدل مفتاح anon أعلاه بعد.
/// بمجرد وضع مفتاحك الحقيقي، يتوقف هذا الوضع تلقائياً.
const kDemoMode = supabaseAnonKey == 'ضع_مفتاح_ANON_هنا';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  SupabaseService.demoMode = kDemoMode;
  if (!kDemoMode) {
    await Supabase.initialize(
        url: supabaseUrl, publishableKey: supabaseAnonKey);
  }
  runApp(const CalSnapApp());
}

class CalSnapApp extends StatelessWidget {
  const CalSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: Consumer<LanguageProvider>(
        builder: (context, lang, _) => MaterialApp(
          title: 'ACLEE',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(arabic: lang.isArabic),
          builder: (context, child) => Directionality(
            textDirection: lang.direction,
            child: child!,
          ),
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Splash + auth routing: listens to Supabase auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    if (kDemoMode) {
      return const Banner(
        message: 'DEMO',
        location: BannerLocation.topEnd,
        color: AppColors.primary,
        child: MainShell(),
      );
    }
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final session = Supabase.instance.client.auth.currentSession;
        return session != null ? const MainShell() : const LoginScreen();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.4,
            colors: [Color(0xFF2A2138), AppColors.background],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppShadows.glow,
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 44, color: AppColors.background),
              ),
              const SizedBox(height: 20),
              const Text('ACLEE',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_translations.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/fade_up.dart';
import '../../widgets/glass_card.dart';

/// ACLEE sign-up — same glass language as sign-in,
/// with clear success guidance (email confirmation).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = context.read<LanguageProvider>().t;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService.instance
          .signUp(_name.text.trim(), _email.text.trim(), _password.text);
      if (!mounted) return;
      // إن كان تأكيد البريد مفعلاً في Supabase فلن تُنشأ جلسة تلقائياً
      final hasSession =
          Supabase.instance.client.auth.currentSession != null;
      if (!hasSession) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('check_inbox'))));
        Navigator.of(context).pop();
      }
      // مع وجود جلسة: _AuthGate سينقل مباشرة للتطبيق
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (mounted) {
        setState(() => _error = m.contains('already registered')
            ? t('err_signup_exists')
            : e.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = t('error_generic'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.lg * 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 19, color: AppColors.foreground),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FadeUp(
                      index: 0,
                      child: Column(
                        children: [
                          Text(t('signup_title'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4)),
                          const SizedBox(height: AppSpacing.xs + 2),
                          Text(t('signup_subtitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedForeground)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),

                    FadeUp(
                      index: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: GlassCard(
                          premiumShadow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                decoration: InputDecoration(
                                  hintText: t('name'),
                                  prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 19,
                                      color: AppColors.mutedForeground),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: InputDecoration(
                                  hintText: t('email'),
                                  prefixIcon: const Icon(
                                      Icons.alternate_email_rounded,
                                      size: 19,
                                      color: AppColors.mutedForeground),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                controller: _password,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                onSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: t('password'),
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 19,
                                      color: AppColors.mutedForeground),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons
                                                .visibility_off_outlined,
                                        size: 19,
                                        color:
                                            AppColors.mutedForeground),
                                    onPressed: () => setState(
                                        () => _obscure = !_obscure),
                                  ),
                                ),
                              ),
                              AnimatedSize(
                                duration: AppMotion.base,
                                curve: AppMotion.easeOutExpo,
                                child: _error == null
                                    ? const SizedBox(
                                        width: double.infinity)
                                    : Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                            top: AppSpacing.md),
                                        padding: const EdgeInsets.all(
                                            AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: AppColors.destructive
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppRadius.md),
                                          border: Border.all(
                                              color: AppColors.destructive
                                                  .withValues(
                                                      alpha: 0.35)),
                                        ),
                                        child: Text(_error!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                height: 1.45,
                                                color:
                                                    AppColors.destructive,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              GestureDetector(
                                onTap: _loading ? null : _submit,
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.gradientPrimary,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.pill),
                                    boxShadow:
                                        _loading ? null : AppShadows.glow,
                                  ),
                                  alignment: Alignment.center,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: AppColors
                                                      .background))
                                      : Text(t('sign_up'),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  AppColors.background)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

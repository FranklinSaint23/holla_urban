import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/holla_background.dart';
import '../../../core/widgets/holla_button.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      await _redirectByRole();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialLogin(Future<void> Function() fn) async {
    setState(() { _loading = true; _error = null; });
    try {
      await fn();
      if (!mounted) return;
      await _redirectByRole();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Saisissez votre email pour réinitialiser le mot de passe.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email envoyé à $email. Vérifiez votre boîte de réception.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _redirectByRole() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || !mounted) { context.go('/role-selection'); return; }
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      if (mounted) navigateByRole(context, row?['role'] as String?);
    } catch (_) {
      if (mounted) context.go('/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: HollaBackground(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            SizedBox(
              height: 310,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=700&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.8)),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.authHeaderGradient,
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo réel
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 14,
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo.jpeg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.welcomeBack,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            l.loginSubtitle,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Form ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF12121C)
                      : AppColors.light,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(_error!,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.error)),
                        ),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l.emailOrPhone,
                          hintText: l.emailHint,
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: l.password,
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: Text(l.forgotPassword,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      HollaButton(
                        label: l.signIn,
                        onPressed: _login,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 24),
                      AuthDivider(label: l.orConnectWith),
                      const SizedBox(height: 20),
                      SocialButtonsRow(
                        onGoogle: () =>
                            _socialLogin(AuthService.signInWithGoogle),
                        onFacebook: () =>
                            _socialLogin(AuthService.signInWithFacebook),
                        onApple: () =>
                            _socialLogin(AuthService.signInWithApple),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color),
                            children: [
                              TextSpan(text: l.noAccount),
                              TextSpan(
                                text: l.signUp,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

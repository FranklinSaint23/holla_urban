import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/app_router.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Email envoyé à $email. Vérifiez votre boîte.',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
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
          .from('profiles').select('role').eq('id', uid).maybeSingle();
      if (mounted) navigateByRole(context, row?['role'] as String?);
    } catch (_) {
      if (mounted) context.go('/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.sizeOf(context).width;
    final isWide = w > 750;

    if (isWide) return _wideLayout(l, isDark);
    return _narrowLayout(l, isDark);
  }

  // ── Wide layout (PC / tablette landscape) ─────────────────────────────────

  Widget _wideLayout(AppLocalizations l, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFF),
      body: Row(
        children: [
          // Left branding panel
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF7B5EA7)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Text('HOLLA',
                            style: GoogleFonts.poppins(
                                fontSize: 22, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: 2)),
                      ]),
                      const Spacer(),
                      Text('Bon retour\nparmi nous 👋',
                          style: GoogleFonts.poppins(
                              fontSize: 36, fontWeight: FontWeight.w800,
                              color: Colors.white, height: 1.2)),
                      const SizedBox(height: 16),
                      Text('Commandez, suivez et payez — tout depuis une seule app.',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.6)),
                      const SizedBox(height: 40),
                      ...[
                        (Icons.location_on_rounded, 'Suivi GPS en temps réel'),
                        (Icons.payment_rounded, 'Mobile Money intégré'),
                        (Icons.notifications_active_rounded, 'Notifications instantanées'),
                      ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.$1, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(item.$2,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      )),
                      const Spacer(),
                      Text('© 2026 HOLLA · Fait au Cameroun 🇨🇲',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right form panel
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF12121C) : Colors.white,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _formContent(l, isDark, isWide: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Narrow layout (mobile / tablette portrait) ─────────────────────────────

  Widget _narrowLayout(AppLocalizations l, bool isDark) {
    return Scaffold(
      body: Column(
        children: [
          // Header image
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=700&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.primary.withValues(alpha: 0.8)),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x40000000), Color(0xCC000000)],
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 14)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(l.welcomeBack,
                          style: GoogleFonts.poppins(
                              fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(l.loginSubtitle,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF12121C) : AppColors.light,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: _formContent(l, isDark, isWide: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form content (shared) ─────────────────────────────────────────────────

  Widget _formContent(AppLocalizations l, bool isDark, {required bool isWide}) {
    final textColor = isDark ? Colors.white : const Color(0xFF0D0D1A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWide) ...[
          Text(l.welcomeBack,
              style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 6),
          Text(l.loginSubtitle,
              style: GoogleFonts.poppins(fontSize: 14, color: subtextColor)),
          const SizedBox(height: 32),
        ],
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Text(_error!,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.error)),
          ),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l.emailOrPhone,
            hintText: l.emailHint,
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: l.password,
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.grey,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            child: Text(l.forgotPassword,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 4),
        HollaButton(label: l.signIn, onPressed: _login, isLoading: _loading),
        const SizedBox(height: 24),
        AuthDivider(label: l.orConnectWith),
        const SizedBox(height: 20),
        SocialButtonsRow(
          onGoogle: () => _socialLogin(AuthService.signInWithGoogle),
          onFacebook: () => _socialLogin(AuthService.signInWithFacebook),
          onApple: () => _socialLogin(AuthService.signInWithApple),
        ),
        const SizedBox(height: 28),
        Center(
          child: GestureDetector(
            onTap: () => context.push('/register'),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
                children: [
                  TextSpan(text: l.noAccount),
                  TextSpan(
                    text: l.signUp,
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

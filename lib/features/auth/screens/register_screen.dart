import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/holla_button.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) context.go('/role-selection');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
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

  // ── Wide layout ────────────────────────────────────────────────────────────

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
                  colors: [Color(0xFF00B4DB), AppColors.primary],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text('Rejoignez\ndes milliers\nde Camerounais 🇨🇲',
                          style: GoogleFonts.poppins(
                              fontSize: 34, fontWeight: FontWeight.w800,
                              color: Colors.white, height: 1.2)),
                      const SizedBox(height: 16),
                      Text('Inscription gratuite · Aucun engagement · Annulable à tout moment.',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.6)),
                      const SizedBox(height: 40),
                      ...[
                        (Icons.person_rounded, 'Client — Commandez en 30 sec'),
                        (Icons.store_rounded, 'Partenaire — Gérez votre business'),
                        (Icons.delivery_dining_rounded, 'Livreur — Gagnez plus'),
                        (Icons.handyman_rounded, 'Prestataire — Trouvez des clients'),
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
                                  fontSize: 13, color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      )),
                      const Spacer(),
                      Text('© 2026 HOLLA · Fait au Cameroun',
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

  // ── Narrow layout ──────────────────────────────────────────────────────────

  Widget _narrowLayout(AppLocalizations l, bool isDark) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=700&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.secondary.withValues(alpha: 0.7)),
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
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(l.createAccount,
                          style: GoogleFonts.poppins(
                              fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(l.registerSubtitle,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF12121C) : AppColors.light,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
          Text(l.createAccount,
              style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 6),
          Text(l.registerSubtitle,
              style: GoogleFonts.poppins(fontSize: 14, color: subtextColor)),
          const SizedBox(height: 32),
        ],
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Text(_error!,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.error)),
          ),
        _Field(ctrl: _nameCtrl, label: l.fullName, hint: l.fullNameHint, icon: Icons.person_outline_rounded),
        const SizedBox(height: 14),
        _Field(ctrl: _emailCtrl, label: l.email, hint: 'alex@exemple.cm',
            icon: Icons.email_outlined, type: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _Field(ctrl: _phoneCtrl, label: l.phoneNumber, hint: l.phoneHint,
            icon: Icons.phone_outlined, type: TextInputType.phone),
        const SizedBox(height: 14),
        TextField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          decoration: InputDecoration(
            labelText: l.password,
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.grey),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: l.confirmPassword,
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.secondary),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.grey),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 22),
        HollaButton(label: l.signUp, onPressed: _register, isLoading: _loading),
        const SizedBox(height: 20),
        AuthDivider(label: l.orRegisterWith),
        const SizedBox(height: 16),
        SocialButtonsRow(
          onGoogle: () async {
            try { await AuthService.signInWithGoogle(); if (mounted) context.go('/client/home'); } catch (_) {}
          },
          onFacebook: () async {
            try { await AuthService.signInWithFacebook(); if (mounted) context.go('/client/home'); } catch (_) {}
          },
          onApple: () async {
            try { await AuthService.signInWithApple(); if (mounted) context.go('/client/home'); } catch (_) {}
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => context.pop(),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 14, color: subtextColor),
                children: [
                  TextSpan(text: l.alreadyAccount),
                  TextSpan(
                    text: l.signIn,
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType type;
  const _Field({required this.ctrl, required this.label, required this.hint,
      required this.icon, this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

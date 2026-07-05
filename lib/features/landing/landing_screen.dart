import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';

// ── Landing screen ────────────────────────────────────────────────────────────

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});
  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.sizeOf(context).width;
    final isWide = w > 900;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Navbar(onLogin: () => context.go('/login'), isDark: isDark),
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: isWide
                    ? _HeroWide(onStart: () => context.go('/register'), isDark: isDark)
                    : _HeroNarrow(onStart: () => context.go('/register'), isDark: isDark),
              ),
            ),
            _StatsBar(isDark: isDark),
            _HowItWorksSection(isDark: isDark),
            _FeaturesSection(isDark: isDark),
            _RolesSection(isDark: isDark),
            _CtaSection(onRegister: () => context.go('/register'), isDark: isDark),
            _Footer(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ── Navbar ────────────────────────────────────────────────────────────────────

class _Navbar extends StatelessWidget {
  final VoidCallback onLogin;
  final bool isDark;
  const _Navbar({required this.onLogin, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFF)).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text('HOLLA',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0D0D1A),
                      letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          if (MediaQuery.sizeOf(context).width > 700) ...[
            _NavLink('Fonctionnalités', isDark, () {}),
            _NavLink('Comment ça marche', isDark, () {}),
            _NavLink('À propos', isDark, () {}),
            const SizedBox(width: 20),
          ],
          OutlinedButton(
            onPressed: onLogin,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            ),
            child: Text('Connexion',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            ),
            child: Text('S\'inscrire',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _NavLink(this.label, this.isDark, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF4B5563),
              fontWeight: FontWeight.w500)),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroWide extends StatelessWidget {
  final VoidCallback onStart;
  final bool isDark;
  const _HeroWide({required this.onStart, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 90),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Badge('🇨🇲  Fait pour le Cameroun', isDark),
                    const SizedBox(height: 24),
                    Text(
                      'Commandez, faites livrer\net faites réparer',
                      style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0D0D1A),
                          height: 1.15),
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                      child: Text('Partout au Cameroun',
                          style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Repas, services à domicile, taxi — tout en un. '
                      'HOLLA connecte clients, partenaires et livreurs '
                      'à travers tout le pays en quelques secondes.',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : const Color(0xFF6B7280),
                          height: 1.65),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        _PrimaryBtn('Commencer gratuitement', onStart),
                        const SizedBox(width: 16),
                        _GhostBtn('En savoir plus', isDark, () {}),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _SocialProof(isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              Expanded(child: _HeroIllustration(isDark: isDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroNarrow extends StatelessWidget {
  final VoidCallback onStart;
  final bool isDark;
  const _HeroNarrow({required this.onStart, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          _Badge('🇨🇲  Fait pour le Cameroun', isDark),
          const SizedBox(height: 20),
          Text('Commandez, faites livrer\net faites réparer',
              style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0D0D1A),
                  height: 1.2),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: Text('Partout au Cameroun',
                style: GoogleFonts.poppins(
                    fontSize: 32, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.2),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          Text(
            'Repas, services à domicile, taxi — tout en un, '
            'en quelques secondes à travers tout le Cameroun.',
            style: GoogleFonts.poppins(
                fontSize: 15,
                color: isDark ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF6B7280),
                height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: _PrimaryBtn('Commencer gratuitement', onStart)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: _GhostBtn('En savoir plus', isDark, () {})),
          const SizedBox(height: 40),
          _HeroIllustration(isDark: isDark),
          const SizedBox(height: 40),
          _SocialProof(isDark: isDark),
        ],
      ),
    );
  }
}

// ── Hero illustration ─────────────────────────────────────────────────────────

class _HeroIllustration extends StatelessWidget {
  final bool isDark;
  const _HeroIllustration({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 220,
              height: 380,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E1E30), const Color(0xFF252540)]
                      : [const Color(0xFFFFFFFF), const Color(0xFFF0F2FF)],
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.07),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.15),
                    blurRadius: 60,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('HOLLA',
                      style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0D0D1A),
                          letterSpacing: 3)),
                  const SizedBox(height: 6),
                  Text('Livraison · Services · Taxi',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.45)
                              : const Color(0xFF9CA3AF))),
                  const SizedBox(height: 28),
                  _MiniCard(
                    icon: Icons.restaurant_rounded,
                    label: 'Pizza commandée',
                    sub: 'En préparation…',
                    color: AppColors.secondary,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _MiniCard(
                    icon: Icons.delivery_dining_rounded,
                    label: 'Livreur en route',
                    sub: 'Arrivée dans 8 min',
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40, right: 10,
            child: _FloatingBadge(
              icon: Icons.star_rounded,
              color: const Color(0xFFFDCB6E),
              label: '4.9 ★',
              sub: '2 000+ avis',
              isDark: isDark,
            ),
          ),
          Positioned(
            bottom: 50, left: 0,
            child: _FloatingBadge(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              label: 'Livré !',
              sub: '12 min chrono',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final bool isDark;
  const _MiniCard({required this.icon, required this.label, required this.sub,
      required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0D0D1A))),
              Text(sub,
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, sub;
  final bool isDark;
  const _FloatingBadge({required this.icon, required this.color,
      required this.label, required this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0D0D1A))),
              Text(sub,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.55)
                          : const Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final bool isDark;
  const _StatsBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('5 000+', 'Utilisateurs actifs'),
      ('200+', 'Partenaires'),
      ('10 villes', 'Au Cameroun'),
      ('< 30 min', 'Livraison moyenne'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        gradient: LinearGradient(colors: [
          AppColors.primary.withValues(alpha: isDark ? 0.07 : 0.05),
          AppColors.secondary.withValues(alpha: isDark ? 0.07 : 0.05),
        ]),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 24,
        spacing: 32,
        children: stats.map((s) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.$1,
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(s.$2,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : const Color(0xFF6B7280))),
          ],
        )).toList(),
      ),
    );
  }
}

// ── How it works ──────────────────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  final bool isDark;
  const _HowItWorksSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.search_rounded, AppColors.primary, '1', 'Choisissez',
          'Parcourez restaurants, prestataires ou taxis disponibles près de chez vous.'),
      (Icons.receipt_long_rounded, AppColors.secondary, '2', 'Commandez',
          'Sélectionnez vos articles, confirmez votre adresse et payez par Mobile Money en 2 touches.'),
      (Icons.local_shipping_rounded, AppColors.success, '3', 'Recevez',
          'Suivez votre livreur en direct sur la carte. Livraison en moins de 30 minutes.'),
    ];

    final textPrimary = isDark ? Colors.white : const Color(0xFF0D0D1A);
    final textSub = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF13131F) : Colors.white;
    final altBg = isDark ? const Color(0xFF0A0A16) : const Color(0xFFF0F2FF);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: altBg,
      child: Column(
        children: [
          _Badge('Comment ça marche', isDark),
          const SizedBox(height: 16),
          Text('Simple comme bonjour',
              style: GoogleFonts.poppins(
                  fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Trois étapes pour être livré ou dépanné.',
              style: GoogleFonts.poppins(fontSize: 15, color: textSub),
              textAlign: TextAlign.center),
          const SizedBox(height: 56),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: steps.map((s) => SizedBox(
              width: 300,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: isDark
                      ? Border.all(color: Colors.white.withValues(alpha: 0.07))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: s.$2.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(s.$1, color: s.$2, size: 24),
                        ),
                        const Spacer(),
                        Text(s.$3,
                            style: GoogleFonts.poppins(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: s.$2.withValues(alpha: 0.15),
                                height: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(s.$4,
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary)),
                    const SizedBox(height: 8),
                    Text(s.$5,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: textSub, height: 1.6)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Features section ──────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final bool isDark;
  const _FeaturesSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.location_on_rounded, AppColors.primary, 'Suivi GPS en temps réel',
          'Regardez votre livreur avancer sur la carte jusqu\'à votre porte, à la seconde près.'),
      (Icons.payment_rounded, const Color(0xFF00B894), 'Mobile Money intégré',
          'MTN Mobile Money et Orange Money natifs. Payez en 2 touches, zéro cash requis.'),
      (Icons.notifications_active_rounded, AppColors.secondary, 'Notifications en direct',
          'Chaque changement de statut vous est notifié instantanément — commande reçue, en route, livrée.'),
      (Icons.headset_mic_rounded, AppColors.warning, 'Support 24h/24',
          'Un problème ? Notre équipe de support est disponible à toute heure via messagerie intégrée.'),
      (Icons.star_rounded, const Color(0xFFE17055), 'Avis & notation',
          'Notez vos partenaires et livreurs après chaque commande pour maintenir la qualité.'),
      (Icons.shield_rounded, const Color(0xFF6C5CE7), 'Litiges résolus',
          'Ouvrez un litige directement dans l\'app. Notre équipe traite chaque cas sous 24h.'),
    ];

    final textPrimary = isDark ? Colors.white : const Color(0xFF0D0D1A);
    final textSub = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF13131F) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          _Badge('Fonctionnalités', isDark),
          const SizedBox(height: 16),
          Text('Tout ce dont vous avez besoin',
              style: GoogleFonts.poppins(
                  fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Une plateforme complète, pensée pour le marché camerounais.',
              style: GoogleFonts.poppins(fontSize: 15, color: textSub),
              textAlign: TextAlign.center),
          const SizedBox(height: 56),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: features.map((f) => SizedBox(
              width: 340,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: f.$2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(f.$1, color: f.$2, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(f.$3,
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                    const SizedBox(height: 8),
                    Text(f.$4,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: textSub, height: 1.6)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Roles section ─────────────────────────────────────────────────────────────

class _RolesSection extends StatelessWidget {
  final bool isDark;
  const _RolesSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final roles = [
      (Icons.person_rounded, AppColors.primary, 'Client',
          'Commandez repas, services ou taxi. Suivez en temps réel et payez par Mobile Money.'),
      (Icons.store_rounded, AppColors.secondary, 'Partenaire',
          'Gérez vos commandes, votre menu et vos statistiques depuis un tableau de bord dédié.'),
      (Icons.delivery_dining_rounded, AppColors.success, 'Livreur',
          'Acceptez des livraisons, suivez vos gains quotidiens et optimisez vos trajets.'),
      (Icons.handyman_rounded, AppColors.warning, 'Prestataire',
          'Proposez vos services (plomberie, électricité…) et gérez vos demandes simplement.'),
    ];

    final textPrimary = isDark ? Colors.white : const Color(0xFF0D0D1A);
    final textSub = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF6B7280);
    final altBg = isDark ? const Color(0xFF0A0A16) : const Color(0xFFF0F2FF);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: altBg,
      child: Column(
        children: [
          _Badge('Pour tout le monde', isDark),
          const SizedBox(height: 16),
          Text('Une app, quatre rôles',
              style: GoogleFonts.poppins(
                  fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Que vous soyez client, commerçant, livreur ou prestataire — HOLLA est fait pour vous.',
              style: GoogleFonts.poppins(fontSize: 15, color: textSub),
              textAlign: TextAlign.center),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: roles.map((r) => SizedBox(
              width: 260,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: r.$2.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      r.$2.withValues(alpha: isDark ? 0.1 : 0.07),
                      isDark ? Colors.transparent : const Color(0xFFF8FAFF),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: r.$2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(r.$1, color: r.$2, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(r.$3,
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary)),
                    const SizedBox(height: 8),
                    Text(r.$4,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: textSub, height: 1.55)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── CTA final ─────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  final VoidCallback onRegister;
  final bool isDark;
  const _CtaSection({required this.onRegister, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF7B5EA7)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('Rejoignez des milliers de Camerounais',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          const SizedBox(height: 20),
          Text('Prêt à démarrer ?',
              style: GoogleFonts.poppins(
                  fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Text(
            'Inscription gratuite en moins de 2 minutes.\nAucun engagement, annulable à tout moment.',
            style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text('Créer un compte gratuitement',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final bool isDark;
  const _Footer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSub = isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF9CA3AF);
    final textLink = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF6B7280);
    final footerBg = isDark ? const Color(0xFF070710) : const Color(0xFFF0F2FF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      color: footerBg,
      child: Column(
        children: [
          // Logo + tagline
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('HOLLA',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0D0D1A),
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Livraison & Services — Fait au Cameroun 🇨🇲',
              style: GoogleFonts.poppins(fontSize: 13, color: textSub)),
          const SizedBox(height: 28),
          // Links
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 10,
            children: ['CGU', 'Confidentialité', 'Contact', 'Partenaires', 'Carrières']
                .map((l) => TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2)),
                      child: Text(l,
                          style: GoogleFonts.poppins(fontSize: 12, color: textLink)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.07),
          ),
          const SizedBox(height: 16),
          Text('© 2026 HOLLA. Tous droits réservés.',
              style: GoogleFonts.poppins(fontSize: 12, color: textSub)),
        ],
      ),
    );
  }
}

// ── Composants réutilisables ──────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final bool isDark;
  const _Badge(this.label, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(30),
        color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.08),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
    );
  }
}

class _SocialProof extends StatelessWidget {
  final bool isDark;
  const _SocialProof({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSub = isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF6B7280);
    const avatarColors = [AppColors.primary, AppColors.secondary, AppColors.success, AppColors.warning];

    return Row(
      children: [
        SizedBox(
          width: 80, height: 30,
          child: Stack(
            children: [
              for (int i = 0; i < 4; i++)
                Positioned(
                  left: i * 18.0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avatarColors[i],
                      border: Border.all(
                        color: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF8FAFF),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.person_rounded, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: List.generate(5,
                (_) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFDCB6E)))),
            Text('5 000+ utilisateurs satisfaits',
                style: GoogleFonts.poppins(fontSize: 12, color: textSub)),
          ],
        ),
      ],
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _GhostBtn(this.label, this.isDark, this.onTap);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : const Color(0xFF374151),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
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
    final w = MediaQuery.sizeOf(context).width;
    final isWide = w > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Navbar ──────────────────────────────────────────────────
            _Navbar(onLogin: () => context.go('/login')),

            // ── Hero ────────────────────────────────────────────────────
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: isWide
                    ? _HeroWide(onStart: () => context.go('/register'))
                    : _HeroNarrow(onStart: () => context.go('/register')),
              ),
            ),

            // ── Stats ────────────────────────────────────────────────────
            _StatsBar(),

            // ── Features ─────────────────────────────────────────────────
            _FeaturesSection(),

            // ── Roles ────────────────────────────────────────────────────
            _RolesSection(),

            // ── CTA final ────────────────────────────────────────────────
            _CtaSection(onRegister: () => context.go('/register')),

            // ── Footer ───────────────────────────────────────────────────
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// ── Navbar ────────────────────────────────────────────────────────────────────

class _Navbar extends StatelessWidget {
  final VoidCallback onLogin;
  const _Navbar({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text('HOLLA',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          // Liens nav (masqués sur mobile)
          if (MediaQuery.sizeOf(context).width > 700) ...[
            _NavLink('Fonctionnalités', () {}),
            _NavLink('Tarifs', () {}),
            _NavLink('À propos', () {}),
            const SizedBox(width: 20),
          ],
          // Bouton connexion
          OutlinedButton(
            onPressed: onLogin,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: Text('Connexion',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500)),
    );
  }
}

// ── Hero large écran ──────────────────────────────────────────────────────────

class _HeroWide extends StatelessWidget {
  final VoidCallback onStart;
  const _HeroWide({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 90),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Texte gauche
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Badge('🇨🇲  Fait pour le Cameroun'),
                const SizedBox(height: 24),
                Text('Livraison & Services\nurbains intelligents',
                    style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15)),
                const SizedBox(height: 10),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.primaryGradient.createShader(b),
                  child: Text('Alimenté par l\'IA',
                      style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Commandez de la nourriture, des services à domicile ou un taxi '
                  'en quelques secondes. HOLLA connecte clients, partenaires et '
                  'livreurs à travers tout le Cameroun.',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.65),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    _PrimaryBtn('Commencer gratuitement', onStart),
                    const SizedBox(width: 16),
                    _GhostBtn('Voir une démo', () {}),
                  ],
                ),
                const SizedBox(height: 40),
                _SocialProof(),
              ],
            ),
          ),
          const SizedBox(width: 60),
          // Illustration droite
          const Expanded(child: _HeroIllustration()),
        ],
      ),
    );
  }
}

// ── Hero petit écran ──────────────────────────────────────────────────────────

class _HeroNarrow extends StatelessWidget {
  final VoidCallback onStart;
  const _HeroNarrow({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          _Badge('🇨🇲  Fait pour le Cameroun'),
          const SizedBox(height: 20),
          Text('Livraison & Services\nurbains intelligents',
              style: GoogleFonts.poppins(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (b) =>
                AppColors.primaryGradient.createShader(b),
            child: Text('Alimenté par l\'IA',
                style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          Text(
            'Commandez de la nourriture, des services à domicile ou un taxi '
            'en quelques secondes à travers tout le Cameroun.',
            style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.65),
                height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: _PrimaryBtn('Commencer gratuitement', onStart),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _GhostBtn('Voir une démo', () {}),
          ),
          const SizedBox(height: 40),
          const _HeroIllustration(),
          const SizedBox(height: 40),
          _SocialProof(),
        ],
      ),
    );
  }
}

// ── Hero illustration (cartes animées) ───────────────────────────────────────

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          // Fond glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Carte centrale — téléphone
          Center(
            child: Container(
              width: 220,
              height: 380,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1E30), Color(0xFF252540)],
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 60,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('HOLLA',
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 3)),
                  const SizedBox(height: 8),
                  Text('Livraison · Services · IA',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 28),
                  _MiniOrderCard(
                      icon: Icons.restaurant_rounded,
                      label: 'Pizza commandée',
                      sub: 'En préparation…',
                      color: AppColors.secondary),
                  const SizedBox(height: 10),
                  _MiniOrderCard(
                      icon: Icons.delivery_dining_rounded,
                      label: 'Livreur en route',
                      sub: 'Arrivée dans 8 min',
                      color: AppColors.primary),
                ],
              ),
            ),
          ),
          // Badge flottant haut-droite
          Positioned(
            top: 40,
            right: 10,
            child: _FloatingBadge(
              icon: Icons.star_rounded,
              color: const Color(0xFFFDCB6E),
              label: '4.9★',
              sub: '2 000+ avis',
            ),
          ),
          // Badge flottant bas-gauche
          Positioned(
            bottom: 50,
            left: 0,
            child: _FloatingBadge(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              label: 'Livré !',
              sub: '12 min',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniOrderCard extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  const _MiniOrderCard(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
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
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              Text(sub,
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.5))),
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
  const _FloatingBadge(
      {required this.icon,
      required this.color,
      required this.label,
      required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text(sub,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.55))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
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
              color: Colors.white.withValues(alpha: 0.06)),
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.secondary.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 24,
        spacing: 32,
        children: stats
            .map((s) => Column(
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
                            color:
                                Colors.white.withValues(alpha: 0.55))),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

// ── Features section ──────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.smart_toy_rounded, AppColors.primary, 'Chatbot IA',
          'Assistant intelligent disponible 24h/24 pour commander, trouver un service ou suivre votre livraison.'),
      (Icons.location_on_rounded, AppColors.secondary, 'Suivi GPS en temps réel',
          'Regardez votre livreur avancer sur la carte jusqu\'à votre porte, à la seconde près.'),
      (Icons.payment_rounded, const Color(0xFF00B894), 'Paiement Mobile Money',
          'MTN Mobile Money et Orange Money intégrés. Payez en 2 touches, sans cash.'),
      (Icons.notifications_active_rounded, AppColors.warning, 'Notifications instantanées',
          'Chaque changement de statut vous est notifié en temps réel, sans rafraîchir.'),
      (Icons.star_rounded, const Color(0xFFE17055), 'Avis & notation',
          'Notez vos partenaires et livreurs après chaque commande pour améliorer la qualité.'),
      (Icons.shield_rounded, const Color(0xFF6C5CE7), 'Litiges résolus',
          'Un problème ? Ouvrez un litige directement dans l\'app. L\'admin traite sous 24h.'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          _Badge('Fonctionnalités'),
          const SizedBox(height: 16),
          Text('Tout ce dont vous avez besoin',
              style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Une plateforme complète, pensée pour le marché camerounais.',
            style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.55)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: features
                .map((f) => SizedBox(
                      width: 340,
                      child: _FeatureCard(
                        icon: f.$1,
                        color: f.$2,
                        title: f.$3,
                        desc: f.$4,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, desc;
  const _FeatureCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(desc,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.6)),
        ],
      ),
    );
  }
}

// ── Roles section ─────────────────────────────────────────────────────────────

class _RolesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final roles = [
      (Icons.person_rounded, AppColors.primary, 'Client',
          'Commandez repas, services ou taxi. Suivez en temps réel et payez par Mobile Money.'),
      (Icons.store_rounded, AppColors.secondary, 'Partenaire',
          'Gérez vos commandes, votre menu et vos analytics depuis un tableau de bord dédié.'),
      (Icons.delivery_dining_rounded, AppColors.success, 'Livreur',
          'Acceptez des livraisons, suivez vos gains et optimisez vos trajets avec l\'IA.'),
      (Icons.handyman_rounded, AppColors.warning, 'Prestataire',
          'Proposez vos services (plomberie, électricité…) et gérez vos demandes simplement.'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: const Color(0xFF0A0A16),
      child: Column(
        children: [
          _Badge('Pour tout le monde'),
          const SizedBox(height: 16),
          Text('Une app, quatre rôles',
              style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: roles
                .map((r) => SizedBox(
                      width: 260,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: r.$2.withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              r.$2.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(r.$1, color: r.$2, size: 32),
                            const SizedBox(height: 14),
                            Text(r.$3,
                                style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(r.$4,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white
                                        .withValues(alpha: 0.55),
                                    height: 1.55)),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── CTA final ─────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  final VoidCallback onRegister;
  const _CtaSection({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Column(
        children: [
          Text('Prêt à démarrer ?',
              style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Text(
            'Rejoignez des milliers d\'utilisateurs au Cameroun.\nC\'est gratuit, rapide et sans engagement.',
            style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          _PrimaryBtn('Créer un compte gratuitement', onRegister),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      color: const Color(0xFF070710),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text('HOLLA',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 12),
          Text('© 2026 HOLLA · Fait au Cameroun 🇨🇲',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.35))),
        ],
      ),
    );
  }
}

// ── Composants réutilisables ──────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(30),
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary)),
    );
  }
}

class _SocialProof extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatars empilés
        SizedBox(
          width: 80,
          height: 30,
          child: Stack(
            children: [
              for (int i = 0; i < 4; i++)
                Positioned(
                  left: i * 18.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.success,
                        AppColors.warning,
                      ][i],
                      border: Border.all(
                          color: const Color(0xFF0D0D1A), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (_) => const Icon(Icons.star_rounded,
                    size: 14, color: Color(0xFFFDCB6E)),
              ),
            ),
            Text('5 000+ utilisateurs satisfaits',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55))),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

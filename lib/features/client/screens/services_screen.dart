import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

// ── Tab definition ────────────────────────────────────────────────────────────

class _Tab {
  final String label;
  final String? specialty; // null = tous
  final IconData icon;
  const _Tab(this.label, this.specialty, this.icon);
}

const List<_Tab> _tabs = [
  _Tab('Tous', null, Icons.apps_rounded),
  _Tab('Plombier', 'plombier', Icons.plumbing_rounded),
  _Tab('Électricien', 'electricien', Icons.bolt_rounded),
  _Tab('Nettoyage', 'nettoyage', Icons.cleaning_services_rounded),
  _Tab('Climatisation', 'climatisation', Icons.ac_unit_rounded),
  _Tab('Taxi', 'taxi', Icons.local_taxi_rounded),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;

  late final TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _allProviders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadProviders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    try {
      final data = await _client
          .from('service_providers')
          .select('*, profiles!service_providers_id_fkey(full_name, avatar_url, city)')
          .eq('is_available', true)
          .order('rating', ascending: false) as List;

      setState(() {
        _allProviders = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du chargement des prestataires',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final tab = _tabs[_tabController.index];
    if (tab.specialty == null) return _allProviders;
    return _allProviders
        .where((p) =>
            (p['specialty'] as String?)?.toLowerCase() == tab.specialty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(l.navServices,
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.color)),
                    const Spacer(),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLight,
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.jpeg',
                            width: 36, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── TabBar ──────────────────────────────────────────────
              SizedBox(
                height: 42,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: context.subtextColor,
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: _tabs
                      .map((t) => Tab(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(t.icon, size: 14),
                                  const SizedBox(width: 5),
                                  Text(t.label),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Body ────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? _ShimmerProviderList()
                    : RefreshIndicator(
                        onRefresh: _loadProviders,
                        color: AppColors.primary,
                        child: _filtered.isEmpty
                            ? _EmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 4, 20, 24),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (_, i) =>
                                    _ProviderCard(provider: _filtered[i]),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Provider Card ─────────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  const _ProviderCard({required this.provider});

  String get _name =>
      (provider['profiles']?['full_name'] as String?) ?? 'Prestataire';
  String get _city =>
      (provider['profiles']?['city'] as String?) ?? '';
  String? get _avatarUrl =>
      provider['profiles']?['avatar_url'] as String?;
  String get _specialty =>
      _capitalize(provider['specialty'] as String? ?? '');
  double get _rating =>
      ((provider['rating'] as num?) ?? 0).toDouble();
  String get _hourlyRate {
    final r = provider['hourly_rate'];
    if (r == null) return '—';
    final n = (r as num).toInt();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf FCFA/h';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          // ── Top row ─────────────────────────────────────────────────
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: _avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null
                    ? Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.color)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_specialty,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500)),
                        ),
                        if (_city.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.location_on_rounded,
                              size: 12, color: context.subtextColor),
                          const SizedBox(width: 2),
                          Text(_city,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: context.subtextColor)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Rating pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDCB6E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFDCB6E), size: 14),
                    const SizedBox(width: 3),
                    Text(_rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE17055))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Star row ────────────────────────────────────────────────
          Row(
            children: [
              ...List.generate(5, (i) {
                final full = i < _rating.floor();
                final half = !full && i < _rating;
                return Icon(
                  full
                      ? Icons.star_rounded
                      : half
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded,
                  color: const Color(0xFFFDCB6E),
                  size: 16,
                );
              }),
              const SizedBox(width: 6),
              Text('($_rating)',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: context.subtextColor)),
              const Spacer(),
              Text(_hourlyRate,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),

          // ── Action buttons ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/provider/home'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: AppColors.primary),
                  label: Text('Contacter',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/client/order'),
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      size: 14, color: Colors.white),
                  label: Text('Demander',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.engineering_rounded,
              size: 64, color: context.subtextColor),
          const SizedBox(height: 16),
          Text(
            'Aucun prestataire disponible',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleSmall?.color),
          ),
          const SizedBox(height: 6),
          Text(
            'Revenez plus tard ou changez de catégorie',
            style: GoogleFonts.poppins(
                fontSize: 12, color: context.subtextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ShimmerProviderList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

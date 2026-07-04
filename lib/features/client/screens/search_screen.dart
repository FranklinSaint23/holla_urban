import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool _isLoading = false;
  String _query = '';

  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _providers = [];

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    // Auto-focus déclenché après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _searchCtrl.text.trim();
    if (value == _query) return;

    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() {
        _query = '';
        _partners = [];
        _providers = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _query = query;
      _isLoading = true;
    });

    try {
      // Recherche parallèle dans partners et service_providers
      final results = await Future.wait([
        _searchPartners(query),
        _searchProviders(query),
      ]);

      if (mounted) {
        setState(() {
          _partners = results[0];
          _providers = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _partners = [];
          _providers = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _searchPartners(String query) async {
    final response = await _supabase
        .from('partners')
        .select('id, business_name, category, logo_url, rating')
        .ilike('business_name', '%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> _searchProviders(String query) async {
    final response = await _supabase
        .from('service_providers')
        .select('id, specialty, rating, profiles(full_name, avatar_url)')
        .or('specialty.ilike.%$query%,profiles.full_name.ilike.%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(response as List);
  }

  bool get _hasResults => _partners.isNotEmpty || _providers.isNotEmpty;
  bool get _showEmpty => !_isLoading && _query.isNotEmpty && !_hasResults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header + SearchBar ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _focusNode,
                          autofocus: true,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'Restaurants, services, prestataires...',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 13,
                              color: context.subtextColor,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppColors.grey, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchCtrl.clear();
                                      setState(() {
                                        _partners = [];
                                        _providers = [];
                                        _query = '';
                                      });
                                    },
                                    child: const Icon(Icons.close_rounded,
                                        color: AppColors.grey, size: 18),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Corps ─────────────────────────────────────────────
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return _buildIdleState();
    }
    if (_isLoading) {
      return _buildShimmer();
    }
    if (_showEmpty) {
      return _buildEmptyState();
    }
    return _buildResults();
  }

  Widget _buildIdleState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('Que cherchez-vous ?',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color)),
          const SizedBox(height: 8),
          Text('Tapez un nom de restaurant, spécialité ou prestataire',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.subtextColor),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _shimmerSection('Partenaires', 3),
        const SizedBox(height: 20),
        _shimmerSection('Prestataires', 2),
      ],
    );
  }

  Widget _shimmerSection(String title, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: context.isDark
              ? const Color(0xFF252535)
              : Colors.grey.shade200,
          highlightColor: context.isDark
              ? const Color(0xFF2E2E42)
              : Colors.grey.shade100,
          child: Container(
            width: 120,
            height: 16,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        ...List.generate(
          count,
          (_) => Shimmer.fromColors(
            baseColor: context.isDark
                ? const Color(0xFF252535)
                : Colors.grey.shade200,
            highlightColor: context.isDark
                ? const Color(0xFF2E2E42)
                : Colors.grey.shade100,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Illustration SVG-like avec icônes Flutter
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(Icons.search_off_rounded,
                  size: 52, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          Text('Aucun résultat',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).textTheme.titleMedium?.color)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Aucun partenaire ou prestataire trouvé pour « $_query »',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: context.subtextColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchCtrl.clear();
              _focusNode.requestFocus();
            },
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.primary, size: 18),
            label: Text('Nouvelle recherche',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // ── Section Partenaires ──────────────────────────────────
        if (_partners.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.store_rounded,
            title: 'Partenaires',
            count: _partners.length,
          ),
          const SizedBox(height: 8),
          ..._partners.map((p) => _PartnerTile(
                partner: p,
                onTap: () => context.push('/client/order'),
              )),
          const SizedBox(height: 20),
        ],

        // ── Section Prestataires ─────────────────────────────────
        if (_providers.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.handyman_rounded,
            title: 'Prestataires',
            count: _providers.length,
          ),
          const SizedBox(height: 8),
          ..._providers.map((p) => _ProviderTile(
                provider: p,
                onTap: () => context.push('/client/order'),
              )),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

// ── Section header ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleMedium?.color)),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ),
      ],
    );
  }
}

// ── Partner tile ──────────────────────────────────────────────────────

class _PartnerTile extends StatelessWidget {
  final Map<String, dynamic> partner;
  final VoidCallback onTap;

  const _PartnerTile({required this.partner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = partner['business_name'] as String? ?? 'Partenaire';
    final category = partner['category'] as String? ?? '';
    final rating = partner['rating'];
    final logoUrl = partner['logo_url'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.store_rounded,
                              color: AppColors.primary)),
                    )
                  : const Icon(Icons.store_rounded,
                      color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (category.isNotEmpty)
                    Text(category,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: context.subtextColor)),
                ],
              ),
            ),
            if (rating != null) ...[
              const Icon(Icons.star_rounded,
                  color: AppColors.warning, size: 14),
              const SizedBox(width: 3),
              Text(rating.toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.color)),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Provider tile ─────────────────────────────────────────────────────

class _ProviderTile extends StatelessWidget {
  final Map<String, dynamic> provider;
  final VoidCallback onTap;

  const _ProviderTile({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profiles = provider['profiles'] as Map<String, dynamic>?;
    final fullName = profiles?['full_name'] as String? ?? 'Prestataire';
    final avatarUrl = profiles?['avatar_url'] as String?;
    final specialty = provider['specialty'] as String? ?? '';
    final rating = provider['rating'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                shape: BoxShape.circle,
              ),
              child: avatarUrl != null
                  ? ClipOval(
                      child: Image.network(avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: AppColors.secondary)),
                    )
                  : const Icon(Icons.person_rounded,
                      color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (specialty.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.handyman_rounded,
                            size: 11, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(specialty,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: context.subtextColor)),
                      ],
                    ),
                ],
              ),
            ),
            if (rating != null) ...[
              const Icon(Icons.star_rounded,
                  color: AppColors.warning, size: 14),
              const SizedBox(width: 3),
              Text(rating.toString(),
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.color)),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  final _client = Supabase.instance.client;

  List<Map<String, dynamic>> _partners = [];
  bool _loading = true;
  String? _selectedCategory;

  static const _catData = [
    ('Restaurant', Icons.restaurant_rounded, AppColors.secondary),
    ('Livraison', Icons.delivery_dining_rounded, AppColors.primary),
    ('Boutique', Icons.shopping_bag_rounded, Color(0xFF6C5CE7)),
    ('Plombier', Icons.plumbing_rounded, Color(0xFFE17055)),
    ('Électricien', Icons.bolt_rounded, Color(0xFFFDCB6E)),
    ('Santé', Icons.local_hospital_rounded, Color(0xFFFF7675)),
    ('Taxi', Icons.local_taxi_rounded, Color(0xFF00B894)),
    ('Tout', Icons.grid_view_rounded, AppColors.grey),
  ];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _loading = true);
    try {
      var query = _client
          .from('partners')
          .select('id, business_name, category, rating, image_url, is_open, min_order');
      if (_selectedCategory != null && _selectedCategory != 'Tout') {
        query = query.eq('category', _selectedCategory!);
      }
      final data = await query
          .eq('is_open', true)
          .order('rating', ascending: false)
          .limit(20) as List;
      if (mounted) {
        setState(() {
          _partners = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onCategoryTap(String name) {
    final next = (name == 'Tout' || name == _selectedCategory) ? null : name;
    setState(() => _selectedCategory = next);
    _loadPartners();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = _client.auth.currentUser;
    final userName =
        user?.userMetadata?['full_name'] as String? ?? 'Utilisateur';
    final userCity =
        user?.userMetadata?['city'] as String? ?? 'Cameroun';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/client/ai-chat'),
        backgroundColor: const Color(0xFF6C5CE7),
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
        label: Text('Holla AI',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
      body: HollaBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadPartners,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryLight,
                          child: ClipOval(
                            child: Image.asset('assets/images/logo.jpeg',
                                width: 44, height: 44, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.color)),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 13, color: AppColors.secondary),
                                  const SizedBox(width: 2),
                                  Text(userCity,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: context.subtextColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _IconBtn(Icons.notifications_none_rounded, () {}),
                        const SizedBox(width: 8),
                        _IconBtn(Icons.tune_rounded, () {}),
                      ],
                    ),
                  ),
                ),

                // ── Search ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GestureDetector(
                      onTap: () => context.push('/client/search'),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 14),
                              child: Icon(Icons.search_rounded,
                                  color: AppColors.grey),
                            ),
                            Expanded(
                              child: Text(l.searchHint,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: context.subtextColor)),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.tune_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Categories ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _catData.length,
                      itemBuilder: (_, i) {
                        final cat = _catData[i];
                        final active = _selectedCategory == cat.$1 ||
                            (cat.$1 == 'Tout' &&
                                _selectedCategory == null);
                        return GestureDetector(
                          onTap: () => _onCategoryTap(cat.$1),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: active
                                      ? cat.$3
                                          .withValues(alpha: 0.35)
                                      : cat.$3
                                          .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: active
                                      ? Border.all(
                                          color: cat.$3, width: 1.5)
                                      : null,
                                ),
                                child: Icon(cat.$2,
                                    color: cat.$3, size: 26),
                              ),
                              const SizedBox(height: 6),
                              Text(cat.$1,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active
                                          ? cat.$3
                                          : Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Promo banner ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF00D2D3)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 140,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(18)),
                              child: CachedNetworkImage(
                                imageUrl:
                                    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300',
                                fit: BoxFit.cover,
                                color:
                                    Colors.black.withValues(alpha: 0.25),
                                colorBlendMode: BlendMode.darken,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.25),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(l.specialOffer,
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ),
                                const SizedBox(height: 8),
                                Text('Cuisine locale\nà -20%',
                                    style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.2)),
                                const SizedBox(height: 6),
                                Text(
                                    'Savourez les plats\nlocaux du Cameroun',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Section header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 24, 20, 14),
                    child: Row(
                      children: [
                        Text(l.popularIn,
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.color)),
                        const Spacer(),
                        GestureDetector(
                          onTap: _loadPartners,
                          child: Text(l.seeAll,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Partners grid ───────────────────────────────────
                if (_loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    ),
                  )
                else if (_partners.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.store_mall_directory_outlined,
                                size: 56,
                                color: context.subtextColor),
                            const SizedBox(height: 12),
                            Text('Aucun partenaire disponible',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: context.subtextColor)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _PartnerCard(
                          partner: _partners[i],
                          onTap: () => context.push('/client/order',
                              extra: _partners[i]['id'] as String),
                        ),
                        childCount: _partners.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6)
          ],
        ),
        child: Icon(icon,
            size: 20, color: Theme.of(context).iconTheme.color),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final Map<String, dynamic> partner;
  final VoidCallback onTap;
  const _PartnerCard({required this.partner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = partner['business_name'] as String? ?? 'Partenaire';
    final category = partner['category'] as String? ?? '';
    final rating =
        (partner['rating'] as num?)?.toDouble() ?? 0.0;
    final minOrder = (partner['min_order'] as num?)?.toInt();
    final imageUrl = partner['image_url'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) =>
                            Container(color: AppColors.primaryLight),
                        errorWidget: (_, __, ___) =>
                            _PlaceholderImg(name: name),
                      )
                    : _PlaceholderImg(name: name),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(category,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: context.subtextColor)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFDCB6E)),
                      const SizedBox(width: 3),
                      Text(
                          rating > 0
                              ? rating.toStringAsFixed(1)
                              : '-',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.subtextColor)),
                      const Spacer(),
                      if (minOrder != null)
                        Text('$minOrder FCFA',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  final String name;
  const _PlaceholderImg({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.primary),
        ),
      ),
    );
  }
}

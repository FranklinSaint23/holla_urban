import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] as String? ?? 'Utilisateur';
    final userCity = user?.userMetadata?['city'] as String? ?? 'Cameroun';

    final categories = [
      _Cat(l.catRestaurant, Icons.restaurant_rounded, AppColors.secondary),
      _Cat(l.catDelivery, Icons.delivery_dining_rounded, AppColors.primary),
      _Cat(l.catShop, Icons.shopping_bag_rounded, const Color(0xFF6C5CE7)),
      _Cat(l.catPlumber, Icons.plumbing_rounded, const Color(0xFFE17055)),
      _Cat(l.catElectrician, Icons.bolt_rounded, const Color(0xFFFDCB6E)),
      _Cat(l.catHealth, Icons.local_hospital_rounded, const Color(0xFFFF7675)),
      _Cat(l.catTaxi, Icons.local_taxi_rounded, const Color(0xFF00B894)),
      _Cat(l.catMore, Icons.grid_view_rounded, AppColors.grey),
    ];

    final popular = [
      _Popular('Pizzeria La Casa', 'Pizza 🍕', 4.8, '12 500', 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400'),
      _Popular('Mama Africa', 'Cuisine locale 🍲', 4.9, '3 500', 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400'),
      _Popular('Burger Town', 'Burgers 🍔', 4.6, '5 000', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400'),
      _Popular('Sushi Ya', 'Japonais 🍱', 4.7, '8 000', 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400'),
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/client/ai-chat'),
        backgroundColor: const Color(0xFF6C5CE7),
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
        label: Text('Holla AI',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
      body: HollaBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── App Bar ────────────────────────────────────────────
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

              // ── Search ─────────────────────────────────────────────
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
                            padding: EdgeInsets.symmetric(horizontal: 14),
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

              // ── Categories ─────────────────────────────────────────
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
                    itemCount: categories.length,
                    itemBuilder: (_, i) => _CatItem(categories[i]),
                  ),
                ),
              ),

              // ── Banner promo ────────────────────────────────────────
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
                              color: Colors.black.withValues(alpha: 0.25),
                              colorBlendMode: BlendMode.darken,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
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
                              Text('Savourez les plats\nlocaux du Cameroun',
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

              // ── Popular section header ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
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
                        onTap: () {},
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

              // ── Popular cards ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PopularCard(popular[i],
                        onTap: () => context.push('/client/order')),
                    childCount: popular.length,
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)
          ],
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
      ),
    );
  }
}

class _Cat {
  final String label;
  final IconData icon;
  final Color color;
  const _Cat(this.label, this.icon, this.color);
}

class _CatItem extends StatelessWidget {
  final _Cat cat;
  const _CatItem(this.cat);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: cat.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(cat.icon, color: cat.color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(cat.label,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _Popular {
  final String name, category, price, imageUrl;
  final double rating;
  const _Popular(this.name, this.category, this.rating, this.price, this.imageUrl);
}

class _PopularCard extends StatelessWidget {
  final _Popular item;
  final VoidCallback onTap;
  const _PopularCard(this.item, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                      color: AppColors.primaryLight),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.primaryLight),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
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
                  Text(item.category,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: context.subtextColor)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFFDCB6E)),
                      const SizedBox(width: 3),
                      Text('${item.rating}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.subtextColor)),
                      const Spacer(),
                      Text('${item.price} FCFA',
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

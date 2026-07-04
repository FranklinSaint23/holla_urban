import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class PartnerAnalyticsScreen extends StatefulWidget {
  const PartnerAnalyticsScreen({super.key});

  @override
  State<PartnerAnalyticsScreen> createState() =>
      _PartnerAnalyticsScreenState();
}

class _PartnerAnalyticsScreenState extends State<PartnerAnalyticsScreen> {
  final _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  // Données agrégées
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _avgRating = 0;
  int _totalReviews = 0;

  // Revenus par jour (7 jours) — index 0 = il y a 6 jours, index 6 = aujourd'hui
  final List<_DayRevenue> _dailyRevenues = [];

  // Top articles
  final List<_TopItem> _topItems = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = _client.auth.currentUser!.id;
      final now = DateTime.now();
      final sevenDaysAgo = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6))
          .toIso8601String();

      // Commandes des 7 derniers jours (livrées)
      final ordersRaw = await _client
          .from('orders')
          .select('id, total, created_at, status, order_items(*)')
          .eq('partner_id', uid)
          .gte('created_at', sevenDaysAgo)
          .order('created_at', ascending: true) as List;

      final orders = ordersRaw.cast<Map<String, dynamic>>();

      // Revenus par jour
      final Map<String, double> revenueByDay = {};
      for (var i = 0; i < 7; i++) {
        final d = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 6 - i));
        revenueByDay['${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'] =
            0;
      }

      double totalRevenue = 0;
      int totalOrders = 0;

      // Comptage articles
      final Map<String, int> itemCount = {};

      for (final o in orders) {
        final createdAt = o['created_at'] as String? ?? '';
        final status = o['status'] as String? ?? '';
        final total = (o['total'] as num?)?.toDouble() ?? 0;

        // Compter tous les articles (quelle que soit status)
        final items = (o['order_items'] as List?) ?? [];
        for (final item in items) {
          final name = item['product_name'] as String? ?? 'Article';
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          itemCount[name] = (itemCount[name] ?? 0) + qty;
        }

        if (status == 'delivered') {
          totalRevenue += total;
          totalOrders++;

          try {
            final dt = DateTime.parse(createdAt).toLocal();
            final key =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            if (revenueByDay.containsKey(key)) {
              revenueByDay[key] = (revenueByDay[key] ?? 0) + total;
            }
          } catch (_) {}
        }
      }

      // Récupérer rating partenaire
      final partnerData = await _client
          .from('partners')
          .select('rating, total_orders')
          .eq('id', uid)
          .maybeSingle();

      final avgRating =
          (partnerData?['rating'] as num?)?.toDouble() ?? 0.0;
      final totalRevPartner =
          (partnerData?['total_orders'] as num?)?.toInt() ?? totalOrders;

      // Construire liste journalière
      final dailyRevenues = revenueByDay.entries.map((e) {
        final parts = e.key.split('-');
        final day = int.tryParse(parts.last) ?? 0;
        return _DayRevenue(dayNum: day, revenue: e.value);
      }).toList();

      // Top 3 articles
      final sortedItems = itemCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topItems = sortedItems
          .take(3)
          .map((e) => _TopItem(name: e.key, count: e.value))
          .toList();

      if (mounted) {
        setState(() {
          _totalRevenue = totalRevenue;
          _totalOrders = totalOrders;
          _avgRating = avgRating;
          _totalReviews = totalRevPartner;
          _dailyRevenues
            ..clear()
            ..addAll(dailyRevenues);
          _topItems
            ..clear()
            ..addAll(topItems);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatRevenue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
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
                    Text('Analytiques',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.color)),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadAnalytics,
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.primary),
                      tooltip: 'Rafraîchir',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('7 derniers jours',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: context.subtextColor)),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    size: 48, color: AppColors.error),
                                const SizedBox(height: 12),
                                Text('Erreur de chargement',
                                    style: GoogleFonts.poppins(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _loadAnalytics,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Réessayer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAnalytics,
                            color: AppColors.primary,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              children: [
                                // ── Carte revenus totaux (gradient) ─────
                                _RevenueCard(
                                  revenue: _totalRevenue,
                                  orders: _totalOrders,
                                  formatRevenue: _formatRevenue,
                                ),
                                const SizedBox(height: 20),

                                // ── Graphique barres 7 jours ─────────────
                                _BarChartCard(
                                  dailyRevenues: _dailyRevenues,
                                  formatRevenue: _formatRevenue,
                                ),
                                const SizedBox(height: 20),

                                // ── Top articles ─────────────────────────
                                _TopItemsCard(topItems: _topItems),
                                const SizedBox(height: 20),

                                // ── Note moyenne ─────────────────────────
                                _RatingCard(
                                  rating: _avgRating,
                                  totalReviews: _totalReviews,
                                ),
                                const SizedBox(height: 30),
                              ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _DayRevenue {
  final int dayNum;
  final double revenue;
  const _DayRevenue({required this.dayNum, required this.revenue});
}

class _TopItem {
  final String name;
  final int count;
  const _TopItem({required this.name, required this.count});
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  final double revenue;
  final int orders;
  final String Function(double) formatRevenue;

  const _RevenueCard({
    required this.revenue,
    required this.orders,
    required this.formatRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Revenus totaux',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85))),
            ],
          ),
          const SizedBox(height: 16),
          Text('${formatRevenue(revenue)} FCFA',
              style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text('sur 7 jours · $orders commandes livrées',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<_DayRevenue> dailyRevenues;
  final String Function(double) formatRevenue;

  const _BarChartCard({
    required this.dailyRevenues,
    required this.formatRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final maxRevenue = dailyRevenues.isEmpty
        ? 1.0
        : dailyRevenues
            .map((d) => d.revenue)
            .reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxRevenue <= 0 ? 1.0 : maxRevenue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenus par jour',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).textTheme.titleMedium?.color)),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyRevenues.map((d) {
                final ratio =
                    effectiveMax > 0 ? d.revenue / effectiveMax : 0.0;
                final isToday = d == dailyRevenues.last;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Valeur au dessus
                        if (d.revenue > 0)
                          Text(
                            formatRevenue(d.revenue),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? AppColors.primary
                                  : context.subtextColor,
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Barre
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: ratio > 0
                              ? (ratio * 100).clamp(6.0, 100.0)
                              : 6,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : d.revenue > 0
                                    ? AppColors.primary
                                        .withValues(alpha: 0.4)
                                    : context.borderColor,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Label jour
                        Text(
                          '${d.dayNum}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isToday
                                ? AppColors.primary
                                : context.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopItemsCard extends StatelessWidget {
  final List<_TopItem> topItems;

  const _TopItemsCard({required this.topItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top articles commandés',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).textTheme.titleMedium?.color)),
          const SizedBox(height: 16),
          if (topItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Aucune donnée disponible',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: context.subtextColor)),
              ),
            )
          else
            ...topItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final medals = ['🥇', '🥈', '🥉'];
              final colors = [
                AppColors.warning,
                AppColors.grey,
                const Color(0xFFCD7F32),
              ];
              final maxCount = topItems.first.count;
              final ratio = maxCount > 0 ? item.count / maxCount : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(medals[i],
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
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
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor:
                                  colors[i].withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colors[i]),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${item.count}x',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors[i])),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final double rating;
  final int totalReviews;

  const _RatingCard({required this.rating, required this.totalReviews});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Note & Avis',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).textTheme.titleMedium?.color)),
          const SizedBox(height: 16),
          Row(
            children: [
              // Note en grand
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rating > 0 ? rating.toStringAsFixed(1) : '--',
                    style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning),
                  ),
                  Text('/ 5.0',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: context.subtextColor)),
                ],
              ),
              const SizedBox(width: 24),
              // Étoiles + avis
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < rating.round();
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.warning,
                          size: 26,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text('$totalReviews commandes totales',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: context.subtextColor)),
                    const SizedBox(height: 4),
                    if (rating >= 4.5)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Excellent partenaire',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      )
                    else if (rating >= 3.5)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Bon partenaire',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

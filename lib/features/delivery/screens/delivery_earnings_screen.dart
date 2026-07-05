import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class DeliveryEarningsScreen extends StatefulWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  State<DeliveryEarningsScreen> createState() => _DeliveryEarningsScreenState();
}

class _DeliveryEarningsScreenState extends State<DeliveryEarningsScreen> {
  final _client = Supabase.instance.client;

  int _weeklyTotal = 0;
  int _weeklyDeliveries = 0;
  double _rating = 0.0;
  int _activeMinutes = 0;
  List<Map<String, dynamic>> _recentDeliveries = [];
  List<int> _weeklyValues = List.filled(7, 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }

    try {
      // Start of current week (Monday)
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      // Load all delivered orders this week for this agent
      final weekOrders = await _client
          .from('orders')
          .select('id, delivery_fee, total_amount, created_at, delivery_address, partners!orders_partner_id_fkey(business_name)')
          .eq('delivery_agent_id', uid)
          .eq('status', 'delivered')
          .gte('created_at', weekStartStr)
          .order('created_at', ascending: false) as List;

      // Load delivery agent rating
      final agentProfile = await _client
          .from('delivery_agents')
          .select('rating, total_deliveries')
          .eq('id', uid)
          .maybeSingle();

      // Compute per-day totals for the chart (Mon=0 .. Sun=6)
      final dayTotals = List.filled(7, 0);
      int weekTotal = 0;
      for (final o in weekOrders) {
        final fee = (o['delivery_fee'] as num?)?.toInt() ?? 0;
        weekTotal += fee;
        final dt = DateTime.tryParse(o['created_at'] as String? ?? '')?.toLocal();
        if (dt != null) {
          final dayIndex = dt.weekday - 1; // Mon=0
          dayTotals[dayIndex] += fee;
        }
      }

      if (mounted) {
        setState(() {
          _weeklyTotal = weekTotal;
          _weeklyDeliveries = weekOrders.length;
          _weeklyValues = dayTotals;
          _rating = ((agentProfile?['rating'] as num?) ?? 0).toDouble();
          _recentDeliveries = weekOrders.take(10).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: _loadEarnings,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(l.navEarnings,
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.titleLarge?.color)),
                        const SizedBox(height: 20),

                        // ── Total semaine ────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Text(l.weeklyEarnings,
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                              const SizedBox(height: 8),
                              Text('${_formatAmount(_weeklyTotal)} FCFA',
                                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _MiniStat('$_weeklyDeliveries', l.deliveries),
                                  Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3)),
                                  _MiniStat(_rating > 0 ? '${_rating.toStringAsFixed(1)} ★' : '— ★', l.rating),
                                  Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3)),
                                  _MiniStat('${_activeMinutes ~/ 60}h', l.activeTime),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Barres journalières ──────────────────────────────
                        Text(l.thisWeek,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.titleMedium?.color)),
                        const SizedBox(height: 14),
                        _WeekChart(values: _weeklyValues),
                        const SizedBox(height: 24),

                        // ── Détail journalier ────────────────────────────────
                        Text(l.todayDetail,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.titleMedium?.color)),
                        const SizedBox(height: 12),

                        if (_recentDeliveries.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text('Aucune livraison cette semaine',
                                  style: GoogleFonts.poppins(fontSize: 13, color: context.subtextColor)),
                            ),
                          )
                        else
                          ..._recentDeliveries.map((o) {
                            final id = (o['id'] as String).substring(0, 8).toUpperCase();
                            final fee = (o['delivery_fee'] as num?)?.toInt() ?? 0;
                            final address = o['delivery_address'] as String? ?? '—';
                            final partner = (o['partners'] as Map?)?['business_name'] as String? ?? 'Partenaire';
                            final createdAt = o['created_at'] as String? ?? '';
                            final time = createdAt.length > 15 ? createdAt.substring(11, 16) : '--:--';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: const Icon(Icons.local_shipping_rounded, color: AppColors.success, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('#$id',
                                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12,
                                                  color: AppColors.primary)),
                                          Text('$partner → $address',
                                              style: GoogleFonts.poppins(fontSize: 11, color: context.subtextColor),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text(time, style: GoogleFonts.poppins(fontSize: 10, color: context.subtextColor)),
                                        ],
                                      ),
                                    ),
                                    Text('+${_formatAmount(fee)} FCFA',
                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700,
                                            color: AppColors.success)),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withValues(alpha: 0.75))),
    ],
  );
}

class _WeekChart extends StatelessWidget {
  final List<int> values;
  static const _days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  const _WeekChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final today = DateTime.now().weekday - 1; // Mon=0

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final h = maxVal > 0 ? (values[i] / maxVal * 100) : 0.0;
          final isToday = i == today;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isToday && values[i] > 0)
                Text('${values[i] ~/ 1000}k',
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 28,
                height: h.toDouble().clamp(4, 100),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(_days[i],
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isToday ? AppColors.primary : context.subtextColor,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
            ],
          );
        }),
      ),
    );
  }
}

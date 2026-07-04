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

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _client = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _ongoing = [];
  List<Map<String, dynamic>> _previous = [];

  static const _ongoingStatuses = {'pending', 'confirmed', 'preparing', 'on_the_way'};
  static const _previousStatuses = {'delivered', 'cancelled'};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await _client
          .from('orders')
          .select('*, profiles!orders_client_id_fkey(full_name)')
          .eq('client_id', uid)
          .order('created_at', ascending: false) as List;

      final all = List<Map<String, dynamic>>.from(data);

      setState(() {
        _ongoing = all
            .where((o) => _ongoingStatuses.contains(o['status'] as String?))
            .toList();
        _previous = all
            .where((o) => _previousStatuses.contains(o['status'] as String?))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du chargement des commandes',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    final hm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (d == today) return "Aujourd'hui, $hm";
    if (d == yesterday) return 'Hier, $hm';
    return '${dt.day.toString().padLeft(2, '0')} '
        '${_monthName(dt.month)} ${dt.year}, $hm';
  }

  String _monthName(int m) {
    const names = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return names[m];
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'preparing':
        return 'En préparation';
      case 'on_the_way':
        return 'En route';
      case 'delivered':
        return 'LIVRÉ';
      case 'cancelled':
        return 'ANNULÉ';
      default:
        return status ?? '';
    }
  }

  String _formatPrice(dynamic total) {
    if (total == null) return '0';
    final n = (total as num).toInt();
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
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
                    Text(l.historyTitle,
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.color)),
                    const Spacer(),
                    const Icon(Icons.translate_rounded,
                        color: AppColors.grey, size: 20),
                    const SizedBox(width: 12),
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
              const SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? _ShimmerList()
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        color: AppColors.primary,
                        child: ListView(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            // ── Ongoing ──────────────────────────────
                            Row(
                              children: [
                                Text(l.ongoing,
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.color)),
                                const SizedBox(width: 10),
                                if (_ongoing.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_ongoing.length} Commande${_ongoing.length > 1 ? 's' : ''}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text('0 Commande',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.w500)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_ongoing.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    'Aucune commande en cours',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: context.subtextColor),
                                  ),
                                ),
                              )
                            else
                              ..._ongoing.map((order) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: _OngoingCard(
                                      name: (order['profiles']
                                                  ?['full_name'] as String?) ??
                                          'Commande #${order['order_number'] ?? order['id']}',
                                      time:
                                          _formatDate(order['created_at'] as String?),
                                      price: _formatPrice(order['total']),
                                      status:
                                          _statusLabel(order['status'] as String?),
                                      onTrack: () => context.push(
                                          '/client/track/${order['id']}'),
                                      onDetails: () => context.push(
                                          '/client/order-details/${order['id']}',
                                          extra: true),
                                    ),
                                  )),
                            const SizedBox(height: 12),

                            // ── Previous ─────────────────────────────
                            Row(
                              children: [
                                Text(l.previous,
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.color)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {},
                                  child: Row(
                                    children: [
                                      Text(l.filter,
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: AppColors.primary,
                                              fontWeight:
                                                  FontWeight.w500)),
                                      const Icon(Icons.tune_rounded,
                                          color: AppColors.primary,
                                          size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_previous.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    'Aucune commande précédente',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: context.subtextColor),
                                  ),
                                ),
                              )
                            else
                              ..._previous.map((order) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: _PreviousCard(
                                      name: (order['profiles']
                                                  ?['full_name'] as String?) ??
                                          'Commande #${order['order_number'] ?? order['id']}',
                                      time:
                                          _formatDate(order['created_at'] as String?),
                                      price: _formatPrice(order['total']),
                                      status:
                                          _statusLabel(order['status'] as String?),
                                      onReorder: () =>
                                          context.push('/client/order'),
                                    ),
                                  )),
                            const SizedBox(height: 24),
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

// ── Shimmer placeholder ──────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
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
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ── Cards ────────────────────────────────────────────────────────────────────

class _OngoingCard extends StatelessWidget {
  final String name, time, price, status;
  final VoidCallback onTrack, onDetails;

  const _OngoingCard({
    required this.name,
    required this.time,
    required this.price,
    required this.status,
    required this.onTrack,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_pizza_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.color)),
                    Text(time,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: context.subtextColor)),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: AppColors.success, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$price FCFA',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.primary)),
              const Spacer(),
              Text(status,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTrack,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(l.track,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(l.details,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviousCard extends StatelessWidget {
  final String name, time, price, status;
  final VoidCallback onReorder;

  const _PreviousCard({
    required this.name,
    required this.time,
    required this.price,
    required this.status,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isCancelled = status == 'ANNULÉ';
    final statusColor = isCancelled ? Colors.redAccent : AppColors.success;

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
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_rounded,
                    color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.color)),
                    Text(time,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: context.subtextColor)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$price FCFA',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.color)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onReorder,
                icon: const Icon(Icons.replay_rounded,
                    size: 14, color: AppColors.primary),
                label: Text(l.reorder,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

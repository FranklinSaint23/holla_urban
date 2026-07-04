import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class PartnerHomeScreen extends ConsumerStatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  ConsumerState<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends ConsumerState<PartnerHomeScreen> {
  final _client = Supabase.instance.client;

  bool _isOpen = true;
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _allOrders = [];
  int _todayOrders = 0;
  double _todayRevenue = 0;
  int _pendingCount = 0;
  double _rating = 0;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = _client.auth.currentUser!.id;

      // Chargement du statut ouvert/fermé et du rating du partenaire
      final partnerData = await _client
          .from('partners')
          .select('is_open, rating')
          .eq('id', uid)
          .maybeSingle();

      if (partnerData != null) {
        _isOpen = partnerData['is_open'] as bool? ?? true;
        _rating = (partnerData['rating'] as num?)?.toDouble() ?? 0.0;
      }

      // Commandes du jour
      final today = DateTime.now();
      final startOfDay =
          DateTime(today.year, today.month, today.day).toIso8601String();

      final orders = await _client
          .from('orders')
          .select('*, order_items(*), profiles!orders_client_id_fkey(full_name, phone)')
          .eq('partner_id', uid)
          .gte('created_at', startOfDay)
          .order('created_at', ascending: false) as List;

      _processOrders(orders);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _processOrders(List orders) {
    final list = orders.cast<Map<String, dynamic>>();
    _allOrders = list;
    _todayOrders = list.length;
    _pendingCount =
        list.where((o) => o['status'] == 'pending').length;
    _todayRevenue = list
        .where((o) => o['status'] == 'delivered')
        .fold(0.0, (sum, o) => sum + ((o['total'] as num?)?.toDouble() ?? 0));
  }

  void _subscribeRealtime() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();

    _sub = _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('partner_id', uid)
        .order('created_at', ascending: false)
        .listen((data) {
      // Filtrer côté client pour le jour en cours
      final todayData = data
          .where((o) =>
              (o['created_at'] as String? ?? '').compareTo(startOfDay) >= 0)
          .toList();
      if (mounted) {
        setState(() => _processOrders(todayData));
      }
    });
  }

  Future<void> _toggleOpen() async {
    final newVal = !_isOpen;
    setState(() => _isOpen = newVal);
    try {
      await _client
          .from('partners')
          .update({'is_open': newVal}).eq('id', _client.auth.currentUser!.id);
    } catch (_) {
      // Rollback
      if (mounted) setState(() => _isOpen = !newVal);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _client
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return "à l'instant";
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _itemsSummary(List items) {
    if (items.isEmpty) return 'Aucun article';
    return items
        .map((i) => '${i['product_name']} x${i['quantity']}')
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = _client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? 'Partenaire';

    final pendingOrders = _allOrders
        .where((o) => o['status'] == 'pending')
        .toList();
    final activeOrders = _allOrders
        .where((o) =>
            o['status'] == 'confirmed' || o['status'] == 'preparing')
        .toList();

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadInitialData,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 16),

                // ── Header ──────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.partnerWelcome,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: context.subtextColor)),
                          Text(name,
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color)),
                        ],
                      ),
                    ),
                    // Badge commandes en attente
                    if (_pendingCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_pendingCount',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    GestureDetector(
                      onTap: _toggleOpen,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isOpen ? AppColors.success : AppColors.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                                _isOpen
                                    ? Icons.storefront_rounded
                                    : Icons.store_outlined,
                                color: Colors.white,
                                size: 16),
                            const SizedBox(width: 6),
                            Text(_isOpen ? l.storeOpen : l.storeClosed,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Stats cards ─────────────────────────────────────────
                if (_loading)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ))
                else if (_error != null)
                  _ErrorBanner(message: _error!, onRetry: _loadInitialData)
                else ...[
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                        icon: Icons.receipt_long_rounded,
                        label: l.todayOrders,
                        value: '$_todayOrders',
                        color: AppColors.primary,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        icon: Icons.payments_rounded,
                        label: l.todayRevenue,
                        value: _todayRevenue >= 1000
                            ? '${(_todayRevenue / 1000).toStringAsFixed(1)}k'
                            : _todayRevenue.toStringAsFixed(0),
                        suffix: 'FCFA',
                        color: AppColors.success,
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                        icon: Icons.star_rounded,
                        label: l.rating,
                        value: _rating > 0 ? _rating.toStringAsFixed(1) : '--',
                        color: AppColors.warning,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        icon: Icons.pending_rounded,
                        label: l.pending,
                        value: '$_pendingCount',
                        color: AppColors.error,
                      )),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Commandes en attente ─────────────────────────────
                  if (pendingOrders.isNotEmpty) ...[
                    _SectionHeader(
                      title: l.newOrders,
                      count: pendingOrders.length,
                      onSeeAll: () => context.go('/partner/orders'),
                    ),
                    const SizedBox(height: 12),
                    ...pendingOrders.map((order) {
                      final items =
                          (order['order_items'] as List?) ?? [];
                      final profile = order['profiles'] as Map?;
                      final clientName =
                          profile?['full_name'] as String? ?? 'Client';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OrderCard(
                          orderNum:
                              order['order_number'] as String? ?? '---',
                          client: clientName,
                          items: _itemsSummary(items),
                          total:
                              (order['total'] as num?)?.toInt() ?? 0,
                          time: _formatTime(
                              order['created_at'] as String?),
                          statusLabel: 'NOUVEAU',
                          statusColor: AppColors.primary,
                          actionLabel: 'Accepter',
                          actionColor: AppColors.primary,
                          onAction: () => _updateOrderStatus(
                              order['id'] as String, 'confirmed'),
                          onDecline: () => _updateOrderStatus(
                              order['id'] as String, 'cancelled'),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // ── Commandes en cours ───────────────────────────────
                  if (activeOrders.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'En préparation',
                      count: activeOrders.length,
                      onSeeAll: () => context.go('/partner/orders'),
                    ),
                    const SizedBox(height: 12),
                    ...activeOrders.map((order) {
                      final items =
                          (order['order_items'] as List?) ?? [];
                      final profile = order['profiles'] as Map?;
                      final clientName =
                          profile?['full_name'] as String? ?? 'Client';
                      final status =
                          order['status'] as String? ?? 'confirmed';
                      final statusLabel = status == 'preparing'
                          ? 'EN PRÉPARATION'
                          : 'CONFIRMÉ';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OrderCard(
                          orderNum:
                              order['order_number'] as String? ?? '---',
                          client: clientName,
                          items: _itemsSummary(items),
                          total:
                              (order['total'] as num?)?.toInt() ?? 0,
                          time: _formatTime(
                              order['created_at'] as String?),
                          statusLabel: statusLabel,
                          statusColor: AppColors.warning,
                          actionLabel: 'Prêt',
                          actionColor: AppColors.success,
                          onAction: () => _updateOrderStatus(
                              order['id'] as String, 'on_the_way'),
                          onDecline: null,
                        ),
                      );
                    }),
                  ],

                  if (pendingOrders.isEmpty && activeOrders.isEmpty)
                    _EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      message: 'Aucune commande en attente',
                    ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internes
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.titleMedium?.color)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
          ],
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text('Tout voir',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.primary)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? suffix;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(suffix!,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: context.subtextColor)),
                ),
              ],
            ],
          ),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: context.subtextColor)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderNum, client, items, time, statusLabel, actionLabel;
  final Color statusColor, actionColor;
  final int total;
  final VoidCallback onAction;
  final VoidCallback? onDecline;

  const _OrderCard({
    required this.orderNum,
    required this.client,
    required this.items,
    required this.total,
    required this.time,
    required this.statusLabel,
    required this.statusColor,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: statusColor == AppColors.primary
                ? AppColors.primary.withValues(alpha: 0.25)
                : context.borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(orderNum,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
              const Spacer(),
              Text(time,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: context.subtextColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text(client,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Theme.of(context).textTheme.titleSmall?.color)),
          const SizedBox(height: 2),
          Text(items,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: context.subtextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$total FCFA',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const Spacer(),
              if (onDecline != null) ...[
                OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Refuser',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.error)),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(actionLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: context.subtextColor),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: context.subtextColor)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Erreur de chargement',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: AppColors.error)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            label: Text('Réessayer',
                style:
                    GoogleFonts.poppins(fontSize: 13, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

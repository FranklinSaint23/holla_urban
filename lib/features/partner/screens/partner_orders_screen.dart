import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class PartnerOrdersScreen extends StatefulWidget {
  const PartnerOrdersScreen({super.key});

  @override
  State<PartnerOrdersScreen> createState() => _PartnerOrdersScreenState();
}

class _PartnerOrdersScreenState extends State<PartnerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _client = Supabase.instance.client;

  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  // Mapping onglet -> statuts
  static const _tabStatuses = [
    ['pending'],                    // Nouveau
    ['confirmed', 'preparing'],     // Préparation
    ['on_the_way'],                 // Prêt / En route
    ['delivered'],                  // Livré
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = _client.auth.currentUser!.id;
      final data = await _client
          .from('orders')
          .select('*, order_items(*), profiles!orders_client_id_fkey(full_name, phone)')
          .eq('partner_id', uid)
          .order('created_at', ascending: false) as List;

      if (mounted) {
        setState(() {
          _orders = data.cast<Map<String, dynamic>>();
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

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await _client
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);
      await _loadOrders();

      if (newStatus == 'delivered' && mounted) {
        _showRatingDialog(orderId);
      }
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

  void _showRatingDialog(String orderId) {
    int selectedRating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Commande livrée !',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Comment s\'est passée cette commande ?',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: context.subtextColor),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.warning,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Ignorer',
                  style: GoogleFonts.poppins(color: context.subtextColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Envoyer',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredOrders(int tabIndex) {
    final statuses = _tabStatuses[tabIndex];
    return _orders.where((o) => statuses.contains(o['status'])).toList();
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
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(l.navOrders,
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.color)),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadOrders,
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── TabBar ────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: context.subtextColor,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: l.statusNew),
                    Tab(text: l.statusPreparing),
                    Tab(text: l.statusReady),
                    const Tab(text: 'Livré'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Content ───────────────────────────────────────────
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
                                TextButton.icon(
                                  onPressed: _loadOrders,
                                  icon: const Icon(Icons.refresh_rounded,
                                      color: AppColors.primary),
                                  label: Text(l.retry,
                                      style: GoogleFonts.poppins(
                                          color: AppColors.primary)),
                                ),
                              ],
                            ),
                          )
                        : TabBarView(
                            controller: _tab,
                            children: List.generate(4, (tabIndex) {
                              final orders = _filteredOrders(tabIndex);
                              if (orders.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.receipt_outlined,
                                          size: 56, color: context.subtextColor),
                                      const SizedBox(height: 12),
                                      Text('Aucune commande',
                                          style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: context.subtextColor)),
                                    ],
                                  ),
                                );
                              }
                              return RefreshIndicator(
                                onRefresh: _loadOrders,
                                color: AppColors.primary,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  itemCount: orders.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _OrderTile(
                                    order: orders[i],
                                    onUpdateStatus: _updateStatus,
                                    formatTime: _formatTime,
                                  ),
                                ),
                              );
                            }),
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

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(String orderId, String newStatus) onUpdateStatus;
  final String Function(String?) formatTime;

  const _OrderTile({
    required this.order,
    required this.onUpdateStatus,
    required this.formatTime,
  });

  String _itemsSummary() {
    final items = (order['order_items'] as List?) ?? [];
    if (items.isEmpty) return 'Aucun article';
    return items
        .map((i) => '${i['product_name']} x${i['quantity']}')
        .join(', ');
  }

  // Renvoie le label et la couleur du bouton d'action principale
  ({String label, Color color, String nextStatus})? _nextAction() {
    final status = order['status'] as String? ?? '';
    switch (status) {
      case 'pending':
        return (label: 'Accepter', color: AppColors.primary, nextStatus: 'confirmed');
      case 'confirmed':
        return (label: 'Préparer', color: AppColors.warning, nextStatus: 'preparing');
      case 'preparing':
        return (label: 'Prêt', color: AppColors.success, nextStatus: 'on_the_way');
      case 'on_the_way':
        return (label: 'Livré', color: AppColors.secondary, nextStatus: 'delivered');
      default:
        return null;
    }
  }

  bool _canCancel() {
    final status = order['status'] as String? ?? '';
    return status == 'pending' || status == 'confirmed';
  }

  Color _statusColor() {
    switch (order['status']) {
      case 'pending':
        return AppColors.primary;
      case 'confirmed':
        return AppColors.warning;
      case 'preparing':
        return AppColors.warning;
      case 'on_the_way':
        return AppColors.secondary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _statusLabel() {
    switch (order['status']) {
      case 'pending':
        return 'NOUVEAU';
      case 'confirmed':
        return 'CONFIRMÉ';
      case 'preparing':
        return 'PRÉPARATION';
      case 'on_the_way':
        return 'EN ROUTE';
      case 'delivered':
        return 'LIVRÉ';
      case 'cancelled':
        return 'ANNULÉ';
      default:
        return (order['status'] as String? ?? '').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = order['profiles'] as Map?;
    final clientName = profile?['full_name'] as String? ?? 'Client';
    final clientPhone = profile?['phone'] as String? ?? '';
    final orderNum = order['order_number'] as String? ?? '---';
    final total = (order['total'] as num?)?.toInt() ?? 0;
    final time = formatTime(order['created_at'] as String?);
    final items = _itemsSummary();
    final action = _nextAction();
    final sColor = _statusColor();

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
          // ── Ligne 1 : Numéro + badge statut + heure ──────────────
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
                    color: sColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_statusLabel(),
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: sColor)),
              ),
              const Spacer(),
              Text(time,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: context.subtextColor)),
            ],
          ),
          const SizedBox(height: 6),

          // ── Client ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clientName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.color)),
                    if (clientPhone.isNotEmpty)
                      Text(clientPhone,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: context.subtextColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Articles ──────────────────────────────────────────────
          Text(items,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: context.subtextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),

          // ── Total + Boutons ────────────────────────────────────────
          Row(
            children: [
              Text('$total FCFA',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const Spacer(),
              if (_canCancel()) ...[
                OutlinedButton(
                  onPressed: () => onUpdateStatus(
                      order['id'] as String, 'cancelled'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Annuler',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.error)),
                ),
                const SizedBox(width: 8),
              ],
              if (action != null)
                ElevatedButton(
                  onPressed: () =>
                      onUpdateStatus(order['id'] as String, action.nextStatus),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action.color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(action.label,
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

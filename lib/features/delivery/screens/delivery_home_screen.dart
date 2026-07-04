import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class DeliveryHomeScreen extends ConsumerStatefulWidget {
  const DeliveryHomeScreen({super.key});
  @override
  ConsumerState<DeliveryHomeScreen> createState() =>
      _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState
    extends ConsumerState<DeliveryHomeScreen> {
  bool _isAvailable = false;
  final _client = Supabase.instance.client;

  // ── State ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _availableOrders = [];
  Map<String, dynamic>? _activeOrder;

  int _todayDeliveries = 0;
  int _todayEarnings = 0;
  double _rating = 0.0;

  bool _loadingOrders = true;
  String? _acceptingOrderId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Data fetching ─────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _loadingOrders = true);
    try {
      await Future.wait([
        _loadAvailableOrders(),
        _loadActiveOrder(),
        _loadStats(),
        _loadAgentInfo(),
      ]);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  Future<void> _loadAvailableOrders() async {
    final data = await _client
        .from('orders')
        .select(
            '*, profiles!orders_client_id_fkey(full_name, phone), partners!orders_partner_id_fkey(business_name, address)')
        .eq('status', 'confirmed')
        .isFilter('delivery_agent_id', null)
        .order('created_at', ascending: false) as List;

    if (mounted) {
      setState(() {
        _availableOrders =
            List<Map<String, dynamic>>.from(data);
      });
    }
  }

  Future<void> _loadActiveOrder() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final data = await _client
        .from('orders')
        .select(
            '*, profiles!orders_client_id_fkey(full_name, phone)')
        .eq('status', 'on_the_way')
        .eq('delivery_agent_id', uid)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _activeOrder = data != null
            ? Map<String, dynamic>.from(data as Map)
            : null;
      });
    }
  }

  Future<void> _loadStats() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final startOfDay = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0);

    final orders = await _client
        .from('orders')
        .select('id, delivery_fee, total')
        .eq('delivery_agent_id', uid)
        .eq('status', 'delivered')
        .gte('created_at', startOfDay.toIso8601String()) as List;

    int earnings = 0;
    for (final o in orders) {
      final fee = (o['delivery_fee'] as num?)?.toInt() ?? 0;
      earnings += fee;
    }

    if (mounted) {
      setState(() {
        _todayDeliveries = orders.length;
        _todayEarnings = earnings;
      });
    }
  }

  Future<void> _loadAgentInfo() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final data = await _client
        .from('delivery_agents')
        .select('is_available, rating, today_earnings')
        .eq('id', uid)
        .maybeSingle();

    if (data != null && mounted) {
      setState(() {
        _isAvailable = (data['is_available'] as bool?) ?? false;
        _rating = ((data['rating'] as num?) ?? 0).toDouble();
        // Fallback : today_earnings depuis la table agent si dispo
        if (_todayEarnings == 0) {
          _todayEarnings =
              (data['today_earnings'] as num?)?.toInt() ?? 0;
        }
      });
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> _toggle() async {
    setState(() => _isAvailable = !_isAvailable);
    try {
      await _client
          .from('delivery_agents')
          .update({'is_available': _isAvailable}).eq(
              'id', _client.auth.currentUser!.id);
    } catch (_) {
      // Rollback en cas d'erreur
      if (mounted) setState(() => _isAvailable = !_isAvailable);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _acceptingOrderId = orderId);
    try {
      await _client.from('orders').update({
        'delivery_agent_id': uid,
        'status': 'on_the_way',
      }).eq('id', orderId);

      // Recharger tout
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur : ${e.toString()}',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _acceptingOrderId = null);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name =
        _client.auth.currentUser?.userMetadata?['full_name'] ?? 'Livreur';

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 16),

                // ── Header ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.deliveryWelcome,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: context.subtextColor),
                          ),
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadData,
                      child: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.grey,
                          size: 24),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.notifications_none_rounded,
                        color: AppColors.grey, size: 26),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Status toggle ──────────────────────────────────
                GestureDetector(
                  onTap: _toggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isAvailable
                            ? [AppColors.secondary, const Color(0xFF00B894)]
                            : [AppColors.grey, const Color(0xFF636E72)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: (_isAvailable
                                  ? AppColors.secondary
                                  : AppColors.grey)
                              .withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isAvailable
                                ? Icons.delivery_dining_rounded
                                : Icons.bedtime_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isAvailable
                                    ? l.youAreOnline
                                    : l.youAreOffline,
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                              Text(
                                _isAvailable
                                    ? l.availableForOrders
                                    : l.tapToGoOnline,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white
                                        .withValues(alpha: 0.85)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isAvailable ? l.online : l.offline,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Stats du jour ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        icon: Icons.local_shipping_rounded,
                        label: l.todayDeliveries,
                        value: '$_todayDeliveries',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        icon: Icons.account_balance_wallet_rounded,
                        label: l.todayEarnings,
                        value: _todayEarnings >= 1000
                            ? '${(_todayEarnings / 1000).toStringAsFixed(1)}k'
                            : '$_todayEarnings',
                        suffix: 'FCFA',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        icon: Icons.star_rounded,
                        label: l.rating,
                        value: _rating > 0
                            ? _rating.toStringAsFixed(1)
                            : '-',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Livraison en cours ─────────────────────────────
                if (_activeOrder != null) ...[
                  Text(
                    l.currentDelivery,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.color),
                  ),
                  const SizedBox(height: 12),
                  _ActiveDeliveryCard(
                    orderNum: _activeOrder!['order_number']?.toString() ??
                        _activeOrder!['id'].toString().substring(0, 8),
                    client: (_activeOrder!['profiles']
                            as Map<String, dynamic>?)?['full_name'] ??
                        'Client',
                    address:
                        _activeOrder!['delivery_address'] as String? ??
                            'Adresse non spécifiée',
                    total: (_activeOrder!['total'] as num?)?.toInt() ?? 0,
                    onNavigate: () {},
                    onChat: () {
                      final clientName =
                          (_activeOrder!['profiles']
                                  as Map<String, dynamic>?)?['full_name'] ??
                              'Client';
                      context.push('/client/chat/$clientName');
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Commandes disponibles ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.availableOrders,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.color),
                    ),
                    Text(
                      '${_availableOrders.length} ${l.nearby}',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_loadingOrders)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  )
                else if (_availableOrders.isEmpty)
                  _EmptyOrdersCard()
                else
                  ..._availableOrders.map((order) {
                    final orderId = order['id'] as String;
                    final partner = order['partners']
                            as Map<String, dynamic>?;
                    final partnerName =
                        partner?['business_name'] as String? ??
                            'Partenaire';
                    final partnerAddress =
                        partner?['address'] as String? ?? '';
                    final deliveryAddress =
                        order['delivery_address'] as String? ?? '';
                    final fee = (order['delivery_fee'] as num?)?.toInt() ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AvailableOrderCard(
                        orderNum: order['order_number']?.toString() ??
                            orderId.substring(0, 8).toUpperCase(),
                        partner: partnerName,
                        address: partnerAddress.isNotEmpty &&
                                deliveryAddress.isNotEmpty
                            ? '$partnerAddress → $deliveryAddress'
                            : deliveryAddress.isNotEmpty
                                ? deliveryAddress
                                : partnerName,
                        distance: '- km',
                        price: fee,
                        isAccepting: _acceptingOrderId == orderId,
                        onAccept: () => _acceptOrder(orderId),
                      ),
                    );
                  }),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? suffix;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          if (suffix != null)
            Text(
              suffix!,
              style: GoogleFonts.poppins(
                  fontSize: 8, color: context.subtextColor),
            ),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: context.subtextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  final String orderNum, client, address;
  final int total;
  final VoidCallback onNavigate, onChat;

  const _ActiveDeliveryCard({
    required this.orderNum,
    required this.client,
    required this.address,
    required this.total,
    required this.onNavigate,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF8E7CF0)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delivery_dining_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                orderNum,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'EN ROUTE',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            client,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            address,
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$total FCFA',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                label: const Text('Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onNavigate,
                icon:
                    const Icon(Icons.navigation_rounded, size: 14),
                label: const Text('Naviguer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailableOrderCard extends StatelessWidget {
  final String orderNum, partner, address, distance;
  final int price;
  final bool isAccepting;
  final VoidCallback onAccept;

  const _AvailableOrderCard({
    required this.orderNum,
    required this.partner,
    required this.address,
    required this.distance,
    required this.price,
    required this.isAccepting,
    required this.onAccept,
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.store_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.color),
                ),
                Text(
                  address,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: context.subtextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        size: 12, color: AppColors.secondary),
                    Text(
                      ' $distance',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.payments_rounded,
                        size: 12, color: AppColors.success),
                    Text(
                      ' ${price > 0 ? price : '-'} FCFA',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: ElevatedButton(
              onPressed: isAccepting ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                disabledBackgroundColor:
                    AppColors.secondary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: isAccepting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Accepter',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrdersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
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
          Icon(Icons.inbox_rounded,
              size: 48, color: context.subtextColor),
          const SizedBox(height: 12),
          Text(
            'Aucune commande disponible',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleSmall?.color),
          ),
          const SizedBox(height: 6),
          Text(
            'Les nouvelles commandes apparaîtront ici',
            style: GoogleFonts.poppins(
                fontSize: 12, color: context.subtextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

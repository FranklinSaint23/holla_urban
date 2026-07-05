import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';
import '../../../core/widgets/holla_button.dart';

class OrderScreen extends ConsumerStatefulWidget {
  final String? partnerId;
  const OrderScreen({super.key, this.partnerId});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  final _client = Supabase.instance.client;
  final _addressCtrl = TextEditingController();

  Map<String, dynamic>? _partner;
  List<Map<String, dynamic>> _items = [];
  final Map<String, int> _cart = {}; // item id → quantity
  bool _loading = true;
  bool _submitting = false;

  static const int _deliveryFee = 1500;

  @override
  void initState() {
    super.initState();
    // Pre-fill address from user metadata
    final user = _client.auth.currentUser;
    _addressCtrl.text =
        user?.userMetadata?['address'] as String? ?? '';
    _loadData();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      if (widget.partnerId != null) {
        // Load partner info
        final partnerData = await _client
            .from('partners')
            .select('id, business_name, category, rating, address')
            .eq('id', widget.partnerId!)
            .maybeSingle();
        _partner = partnerData != null
            ? Map<String, dynamic>.from(partnerData as Map)
            : null;

        // Load menu items for this partner
        final menuData = await _client
            .from('menu_items')
            .select('id, name, description, price, category, image_url')
            .eq('partner_id', widget.partnerId!)
            .eq('is_available', true)
            .order('category')
            .order('name') as List;

        _items = List<Map<String, dynamic>>.from(menuData);
      }
    } catch (_) {
      // Show empty state gracefully
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _subtotal => _cart.entries.fold(0, (sum, entry) {
        final item = _items.firstWhere(
          (i) => i['id'] == entry.key,
          orElse: () => {},
        );
        final price = (item['price'] as num?)?.toInt() ?? 0;
        return sum + price * entry.value;
      });

  int get _total => _subtotal + _deliveryFee;

  void _increment(String itemId) =>
      setState(() => _cart[itemId] = (_cart[itemId] ?? 0) + 1);

  void _decrement(String itemId) {
    setState(() {
      final current = _cart[itemId] ?? 0;
      if (current <= 1) {
        _cart.remove(itemId);
      } else {
        _cart[itemId] = current - 1;
      }
    });
  }

  Future<void> _confirmOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ajoutez au moins un article',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez saisir une adresse de livraison',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final uid = _client.auth.currentUser!.id;
      final orderNum =
          'HL-${DateTime.now().millisecondsSinceEpoch % 100000}';

      // Insert order
      final orderResp = await _client.from('orders').insert({
        'client_id': uid,
        'partner_id': widget.partnerId,
        'status': 'pending',
        'total': _total,
        'delivery_fee': _deliveryFee,
        'delivery_address': address,
        'order_number': orderNum,
      }).select('id').single();

      final orderId = orderResp['id'] as String;

      // Insert order items
      final itemsToInsert = _cart.entries.map((entry) {
        final item = _items.firstWhere((i) => i['id'] == entry.key);
        return {
          'order_id': orderId,
          'product_name': item['name'] as String,
          'quantity': entry.value,
          'price': (item['price'] as num).toInt(),
        };
      }).toList();

      await _client.from('order_items').insert(itemsToInsert);

      if (!mounted) return;
      context.push('/client/payment',
          extra: {'total': _total, 'orderId': orderId});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}',
                style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final partnerName =
        _partner?['business_name'] as String? ?? l.orderTitle;

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                        child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(partnerName,
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (_cart.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_cart.values.fold(0, (a, b) => a + b)} articles',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : ListView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // ── Delivery address ──────────────────────
                          Row(
                            children: [
                              Text(l.deliveryAddress,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.color)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.05),
                                    blurRadius: 8)
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _addressCtrl,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Ex : Rue 1.742, Bastos, Yaoundé',
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      hintStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: context.subtextColor),
                                    ),
                                    style: GoogleFonts.poppins(
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Menu items ────────────────────────────
                          Text(l.selectedServices,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.color)),
                          const SizedBox(height: 12),

                          if (_items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24),
                              child: Center(
                                child: Text(
                                  'Aucun article disponible',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: context.subtextColor),
                                ),
                              ),
                            )
                          else
                            ..._items.map((item) {
                              final itemId = item['id'] as String;
                              final qty = _cart[itemId] ?? 0;
                              final price =
                                  (item['price'] as num?)?.toInt() ??
                                      0;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: qty > 0
                                        ? Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.4),
                                            width: 1.5)
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.04),
                                          blurRadius: 6)
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                            Icons.restaurant_menu_rounded,
                                            color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                item['name'] as String? ??
                                                    '',
                                                style:
                                                    GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                        color: Theme.of(
                                                                context)
                                                            .textTheme
                                                            .titleSmall
                                                            ?.color)),
                                            if (item['description'] !=
                                                null)
                                              Text(
                                                  item['description']
                                                      as String,
                                                  style:
                                                      GoogleFonts.poppins(
                                                          fontSize: 11,
                                                          color: context
                                                              .subtextColor),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis),
                                            Text('$price FCFA',
                                                style:
                                                    GoogleFonts.poppins(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors
                                                            .primary)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (qty > 0) ...[
                                            _CircleBtn(
                                              icon: Icons.remove,
                                              onTap: () =>
                                                  _decrement(itemId),
                                              color: AppColors.error,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8),
                                              child: Text('$qty',
                                                  style:
                                                      GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                          fontSize: 15,
                                                          color:
                                                              AppColors
                                                                  .primary)),
                                            ),
                                          ],
                                          _CircleBtn(
                                            icon: Icons.add,
                                            onTap: () =>
                                                _increment(itemId),
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                          if (_cart.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            // ── Totals ────────────────────────────
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  _TotalRow(
                                      label: l.subtotal,
                                      value: '$_subtotal FCFA'),
                                  const SizedBox(height: 8),
                                  _TotalRow(
                                      label: l.serviceFee,
                                      value: '$_deliveryFee FCFA'),
                                  Divider(
                                      height: 20,
                                      color: context.borderColor),
                                  _TotalRow(
                                    label: l.total,
                                    value: '$_total FCFA',
                                    bold: true,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),
                          HollaButton(
                            label: l.confirmOrder,
                            onPressed: _confirmOrder,
                            isLoading: _submitting,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _CircleBtn(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _TotalRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: bold ? 15 : 13,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
                color: bold
                    ? Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.color
                    : context.subtextColor)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: bold ? 16 : 13,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w500,
                color: color ??
                    Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.color)),
      ],
    );
  }
}

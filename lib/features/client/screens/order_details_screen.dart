import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';
import '../../../core/widgets/holla_button.dart';
import 'disputes_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final bool isOngoing;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.isOngoing = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final items = [
      _Item('Pizza Margherita', 1, 8500),
      _Item('Coca Cola 33cl', 2, 1000),
      _Item('Sauce BBQ', 1, 500),
    ];
    const subtotalVal = 11000;
    const serviceVal = 500;
    const deliveryVal = 2000;
    const totalVal = subtotalVal + serviceVal + deliveryVal;

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────
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
                            Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(l.orderDetails,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOngoing
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          isOngoing
                              ? l.statusOngoing
                              : l.statusDelivered,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOngoing
                                  ? AppColors.primary
                                  : AppColors.success)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Order Meta ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.04),
                                blurRadius: 8)
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                  Icons.local_pizza_rounded,
                                  color: AppColors.primary,
                                  size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Pizzeria La Casa',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.color)),
                                  const SizedBox(height: 2),
                                  Text("Aujourd'hui, 10:30",
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: context.subtextColor)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(l.orderNumber,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: context.subtextColor)),
                                Text('#$orderId',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Delivery Address ────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.04),
                                blurRadius: 8)
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryLight,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.secondary,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(l.deliveryAddress,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: context.subtextColor)),
                                  Text(
                                      'Adresse de livraison, Cameroun',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.color)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Items ───────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.04),
                                blurRadius: 8)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.orderItems,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.color)),
                            const SizedBox(height: 12),
                            ...items.map((item) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text('${item.qty}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color:
                                                      AppColors.primary)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(item.name,
                                            style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color)),
                                      ),
                                      Text(
                                          '${_fmt(item.qty * item.unitPrice)} FCFA',
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.color)),
                                    ],
                                  ),
                                )),
                            Divider(
                                height: 1,
                                color: context.borderColor),
                            const SizedBox(height: 10),
                            _PriceLine(
                                label: l.subtotal,
                                value: '${_fmt(subtotalVal)} FCFA'),
                            const SizedBox(height: 6),
                            _PriceLine(
                                label: l.serviceFee,
                                value: '${_fmt(serviceVal)} FCFA'),
                            const SizedBox(height: 6),
                            _PriceLine(
                                label: l.deliveryFee,
                                value: '${_fmt(deliveryVal)} FCFA'),
                            const SizedBox(height: 10),
                            Divider(
                                height: 1,
                                color: context.borderColor),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(l.total,
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.color)),
                                const Spacer(),
                                Text('${_fmt(totalVal)} FCFA',
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Actions ─────────────────────────────────────
                      if (isOngoing) ...[
                        HollaButton(
                          label: l.track,
                          leading: const Icon(
                              Icons.delivery_dining_rounded,
                              color: Colors.white,
                              size: 20),
                          onPressed: () =>
                              context.push('/client/track/$orderId'),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context
                                .push('/client/chat/Jean-Baptiste'),
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
                                color: AppColors.primary),
                            label: Text(l.contactDriver,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                          ),
                        ),
                      ] else ...[
                        HollaButton(
                          label: l.reorder,
                          leading: const Icon(Icons.replay_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => context.go('/client/order'),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // ── Bouton signaler un problème ─────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DisputesScreen(
                                orderId: orderId,
                                orderNumber: orderId,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.flag_outlined,
                              color: AppColors.error, size: 18),
                          label: Text(
                            'Signaler un problème',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
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

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Item {
  final String name;
  final int qty, unitPrice;
  const _Item(this.name, this.qty, this.unitPrice);
}

class _PriceLine extends StatelessWidget {
  final String label, value;
  const _PriceLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: context.subtextColor)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color)),
      ],
    );
  }
}

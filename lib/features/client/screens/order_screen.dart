import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';
import '../../../core/widgets/holla_button.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    const items = [
      ('Express Delivery', 'Livraison en moins de 30 min',
          Icons.bolt_rounded, AppColors.primary, 2500),
      ('Grocery Pickup', 'Courses au Marché Central',
          Icons.shopping_basket_rounded, AppColors.secondary, 5000),
    ];

    const subtotal = 7500;
    const fee = 500;
    const total = subtotal + fee;

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(l.orderTitle,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    const Spacer(),
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ── Delivery address ────────────────────────────
                    Row(
                      children: [
                        Text(l.deliveryAddress,
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.titleMedium?.color)),
                        const Spacer(),
                        Text(l.modify,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.primary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: AppColors.secondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Résidence Les Palmiers',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600, fontSize: 14,
                                        color: Theme.of(context).textTheme.titleSmall?.color)),
                                Text('Rue 1.742, Bastos, Yaoundé, Cameroun',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12, color: context.subtextColor)),
                                Text('"À côté de l\'Ambassade"',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: context.subtextColor,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Selected services ────────────────────────────
                    Text(l.selectedServices,
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleMedium?.color)),
                    const SizedBox(height: 12),
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: item.$4.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.$3, color: item.$4),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.$1,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600, fontSize: 13,
                                          color: Theme.of(context).textTheme.titleSmall?.color)),
                                  Text(item.$2,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11, color: context.subtextColor)),
                                ],
                              ),
                            ),
                            Text('${item.$5} FCFA',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 16),
                    // ── Totals ────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _TotalRow(label: l.subtotal, value: '$subtotal FCFA'),
                          const SizedBox(height: 8),
                          _TotalRow(label: l.serviceFee, value: '$fee FCFA'),
                          Divider(height: 20, color: context.borderColor),
                          _TotalRow(
                            label: l.total,
                            value: '$total FCFA',
                            bold: true,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    HollaButton(
                      label: l.confirmOrder,
                      onPressed: () => context.push('/client/payment', extra: total),
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

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _TotalRow({required this.label, required this.value, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: bold
                    ? (Theme.of(context).textTheme.titleMedium?.color)
                    : context.subtextColor)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? Theme.of(context).textTheme.titleSmall?.color)),
      ],
    );
  }
}

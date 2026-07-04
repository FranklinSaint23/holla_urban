import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class DeliveryOrdersScreen extends StatelessWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final history = [
      _D('HL-4501', 'Pizzeria La Casa', 'Bastos, Yaoundé', 1500, 'Aujourd\'hui 12:45', 'LIVRÉ'),
      _D('HL-4498', 'Boutique Alpha', 'Nlongkak, Yaoundé', 2500, 'Aujourd\'hui 10:20', 'LIVRÉ'),
      _D('HL-4495', 'Healthy Bowl', 'Biyem-Assi, Yaoundé', 2000, 'Hier 16:30', 'LIVRÉ'),
      _D('HL-4490', 'Pharmacie Plus', 'Centre, Bafoussam', 1500, 'Hier 11:00', 'ANNULÉ'),
    ];

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(l.navOrders,
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${history.length} livraisons',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _DeliveryTile(d: history[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _D {
  final String num, partner, address, date, status;
  final int fee;
  const _D(this.num, this.partner, this.address, this.fee, this.date, this.status);
}

class _DeliveryTile extends StatelessWidget {
  final _D d;
  const _DeliveryTile({required this.d});

  @override
  Widget build(BuildContext context) {
    final delivered = d.status == 'LIVRÉ';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: delivered ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              delivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: delivered ? AppColors.success : AppColors.error, size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.partner, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13,
                    color: Theme.of(context).textTheme.titleSmall?.color)),
                Text('${d.num} · ${d.address}',
                    style: GoogleFonts.poppins(fontSize: 11, color: context.subtextColor)),
                Text(d.date, style: GoogleFonts.poppins(fontSize: 11, color: context.subtextColor)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(delivered ? '+${d.fee} FCFA' : '0 FCFA',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700,
                      color: delivered ? AppColors.success : AppColors.error)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: delivered ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(d.status,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700,
                        color: delivered ? AppColors.success : AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

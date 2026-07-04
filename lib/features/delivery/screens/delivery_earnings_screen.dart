import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class DeliveryEarningsScreen extends StatelessWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
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
                      Text('68 500 FCFA',
                          style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _MiniStat('23', l.deliveries),
                          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3)),
                          _MiniStat('4.9 ★', l.rating),
                          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3)),
                          _MiniStat('12h', l.activeTime),
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
                _WeekChart(),
                const SizedBox(height: 24),

                // ── Détail journalier ────────────────────────────────
                Text(l.todayDetail,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.titleMedium?.color)),
                const SizedBox(height: 12),
                ...([
                  _Earning('HL-4501', 'Pizzeria La Casa → Bastos, Yaoundé', '12:45', 1500),
                  _Earning('HL-4500', 'Boutique Alpha → Nlongkak, Yaoundé', '10:20', 2500),
                  _Earning('HL-4497', 'Healthy Bowl → Biyem-Assi, Yaoundé', '08:30', 2000),
                ].map((e) => Padding(
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
                              Text(e.num, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12,
                                  color: AppColors.primary)),
                              Text(e.route, style: GoogleFonts.poppins(fontSize: 11, color: context.subtextColor),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(e.time, style: GoogleFonts.poppins(fontSize: 10, color: context.subtextColor)),
                            ],
                          ),
                        ),
                        Text('+${e.fee} FCFA',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                      ],
                    ),
                  ),
                ))),
                const SizedBox(height: 30),
              ],
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
  final days = const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  final values = const [8500, 12000, 9500, 11000, 14000, 13500, 0];
  final maxVal = 14000;

  const _WeekChart();

  @override
  Widget build(BuildContext context) {
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
          final h = values[i] / maxVal * 100;
          final isToday = i == 4;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isToday)
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
              Text(days[i],
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

class _Earning {
  final String num, route, time;
  final int fee;
  const _Earning(this.num, this.route, this.time, this.fee);
}

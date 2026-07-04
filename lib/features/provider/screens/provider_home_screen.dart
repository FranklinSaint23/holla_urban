import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class ProviderHomeScreen extends ConsumerStatefulWidget {
  const ProviderHomeScreen({super.key});
  @override
  ConsumerState<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends ConsumerState<ProviderHomeScreen> {
  bool _isAvailable = true;
  final _client = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = _client.auth.currentUser?.userMetadata?['full_name'] ?? 'Prestataire';

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 16),

              // ── Header ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.providerWelcome, style: GoogleFonts.poppins(fontSize: 13, color: context.subtextColor)),
                        Text(name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAvailable,
                    activeColor: AppColors.success,
                    onChanged: (v) async {
                      setState(() => _isAvailable = v);
                      try {
                        await _client.from('service_providers')
                            .update({'is_available': v})
                            .eq('id', _client.auth.currentUser!.id);
                      } catch (_) {}
                    },
                  ),
                  Text(_isAvailable ? l.available : l.unavailable,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                          color: _isAvailable ? AppColors.success : AppColors.error)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Stats ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _StatTile(Icons.work_rounded, l.todayJobs, '3', AppColors.warning)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatTile(Icons.payments_rounded, l.todayRevenue, '45 000', AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatTile(Icons.star_rounded, l.rating, '4.8', AppColors.primary)),
                ],
              ),
              const SizedBox(height: 24),

              // ── Nouvelle demande urgente ─────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Text(l.urgentRequest,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.warning)),
                        const Spacer(),
                        Text('il y a 3 min', style: GoogleFonts.poppins(fontSize: 11, color: context.subtextColor)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Fuite d\'eau - Robinetterie',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14,
                            color: Theme.of(context).textTheme.titleSmall?.color)),
                    Text('Bastos, Yaoundé · Sophie K.',
                        style: GoogleFonts.poppins(fontSize: 12, color: context.subtextColor)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('~15 000 FCFA',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.success)),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: Text('Refuser', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => context.go('/provider/requests'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: Text('Accepter', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Planning du jour ─────────────────────────────────
              Text(l.todaySchedule,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleMedium?.color)),
              const SizedBox(height: 12),
              _ScheduleCard(time: '09:00', client: 'Marc Tchamba', task: 'Installation climatisation', address: 'Biyem-Assi, Yaoundé'),
              const SizedBox(height: 10),
              _ScheduleCard(time: '14:00', client: 'Anne Fouda', task: 'Réparation robinetterie', address: 'Bastos, Yaoundé'),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatTile(this.icon, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: context.subtextColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String time, client, task, address;
  const _ScheduleCard({required this.time, required this.client, required this.task, required this.address});
  @override
  Widget build(BuildContext context) {
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
            width: 50,
            child: Text(time, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
          Container(width: 2, height: 40, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13,
                    color: Theme.of(context).textTheme.titleSmall?.color)),
                Text('$client · $address', style: GoogleFonts.poppins(fontSize: 11, color: context.subtextColor)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
        ],
      ),
    );
  }
}

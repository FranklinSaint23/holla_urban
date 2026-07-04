import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/holla_background.dart';

const _kAdminColor = Color(0xFFE53935);

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _client = Supabase.instance.client;
  Map<String, int> _roleCount = {};
  Map<String, int> _statusCount = {};
  int _totalRevenue = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profiles = await _client.from('profiles').select('role');
      final orders   = await _client.from('orders').select('status, total_amount');
      final payments = await _client.from('payments').select('amount').eq('status', 'completed');

      final roleCount   = <String, int>{};
      final statusCount = <String, int>{};
      int rev = 0;

      for (final p in profiles as List) {
        final r = p['role'] as String? ?? 'client';
        roleCount[r] = (roleCount[r] ?? 0) + 1;
      }
      for (final o in orders as List) {
        final s = o['status'] as String? ?? 'pending';
        statusCount[s] = (statusCount[s] ?? 0) + 1;
      }
      for (final p in payments as List) {
        rev += (p['amount'] as num?)?.toInt() ?? 0;
      }

      if (mounted) setState(() {
        _roleCount   = roleCount;
        _statusCount = statusCount;
        _totalRevenue = rev;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kAdminColor))
              : ListView(
                  padding: EdgeInsets.all(isWide ? 32 : 20),
                  children: [
                    Row(
                      children: [
                        Text('Analytics & Rapports',
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Revenus totaux
                    _RevCard(total: _totalRevenue, isDark: isDark),
                    const SizedBox(height: 24),
                    // Répartition des rôles
                    Text('Répartition des utilisateurs',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _BarSection(data: _roleCount, colors: const {
                      'client':   AppColors.primary,
                      'partner':  Color(0xFF5C6BC0),
                      'delivery': AppColors.secondary,
                      'provider': AppColors.warning,
                      'admin':    _kAdminColor,
                    }, isDark: isDark),
                    const SizedBox(height: 24),
                    // Répartition des statuts
                    Text('Statuts des commandes',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _BarSection(data: _statusCount, colors: const {
                      'pending':    AppColors.warning,
                      'confirmed':  Color(0xFF5C6BC0),
                      'preparing':  Color(0xFFFF9800),
                      'on_the_way': AppColors.secondary,
                      'delivered':  Color(0xFF43A047),
                      'cancelled':  _kAdminColor,
                    }, isDark: isDark),
                    const SizedBox(height: 24),
                    // Zones actives
                    Text('Zones les plus actives',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _ZoneSection(isDark: isDark),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RevCard extends StatelessWidget {
  final int total;
  final bool isDark;
  const _RevCard({required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Revenus totaux validés', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text('$total FCFA',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Paiements CamPay complétés',
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.payments_rounded, color: Colors.white30, size: 56),
        ],
      ),
    );
  }
}

class _BarSection extends StatelessWidget {
  final Map<String, int> data;
  final Map<String, Color> colors;
  final bool isDark;
  const _BarSection({required this.data, required this.colors, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text('Aucune donnée disponible',
          style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 13));
    }

    final maxVal = data.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: data.entries.map((e) {
          final pct = maxVal > 0 ? e.value / maxVal : 0.0;
          final color = colors[e.key] ?? AppColors.grey;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(e.key,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 14,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 32,
                  child: Text('${e.value}',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                      textAlign: TextAlign.right),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ZoneSection extends StatelessWidget {
  final bool isDark;
  const _ZoneSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Zones actives à travers tout le Cameroun
    final zones = [
      ('Bastos, Yaoundé', 142, AppColors.primary),
      ('Centre-ville, Douala', 124, AppColors.secondary),
      ('Nlongkak, Yaoundé', 98, const Color(0xFF5C6BC0)),
      ('Centre, Bafoussam', 67, AppColors.warning),
      ('Garoua-Centre', 54, _kAdminColor),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: zones.asMap().entries.map((e) {
          final i = e.key;
          final zone = e.value;
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: zone.$3.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: zone.$3)),
                  ),
                ),
                title: Text(zone.$1, style: GoogleFonts.poppins(fontSize: 13)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: zone.$3.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('${zone.$2} cmd',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: zone.$3)),
                ),
              ),
              if (i < zones.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

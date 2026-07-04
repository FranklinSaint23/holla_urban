import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/holla_background.dart';

const _kAdminColor = Color(0xFFE53935);

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  final _client = Supabase.instance.client;

  int _totalUsers = 0;
  int _totalOrders = 0;
  int _activeDeliveries = 0;
  int _totalRevenue = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final users    = await _client.from('profiles').select('id') as List;
      final orders   = await _client.from('orders').select('id') as List;
      final active   = await _client.from('orders').select('id')
                          .inFilter('status', ['confirmed', 'preparing', 'on_the_way']) as List;
      final payments = await _client.from('payments').select('amount').eq('status', 'completed') as List;

      int rev = 0;
      for (final p in payments) {
        rev += (p['amount'] as num?)?.toInt() ?? 0;
      }

      if (mounted) setState(() {
        _totalUsers       = users.length;
        _totalOrders      = orders.length;
        _activeDeliveries = active.length;
        _totalRevenue     = rev;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kAdminColor))
              : ListView(
                  padding: EdgeInsets.all(isWide ? 32 : 20),
                  children: [
                    _Header(),
                    const SizedBox(height: 28),
                    // KPI grid
                    isWide
                        ? Row(
                            children: [
                              Expanded(child: _KpiCard(icon: Icons.people_alt_rounded, label: 'Utilisateurs', value: '$_totalUsers', color: const Color(0xFF5C6BC0))),
                              const SizedBox(width: 16),
                              Expanded(child: _KpiCard(icon: Icons.receipt_long_rounded, label: 'Commandes totales', value: '$_totalOrders', color: AppColors.primary)),
                              const SizedBox(width: 16),
                              Expanded(child: _KpiCard(icon: Icons.delivery_dining_rounded, label: 'En cours', value: '$_activeDeliveries', color: AppColors.secondary)),
                              const SizedBox(width: 16),
                              Expanded(child: _KpiCard(icon: Icons.payments_rounded, label: 'Revenus (FCFA)', value: '$_totalRevenue', color: _kAdminColor)),
                            ],
                          )
                        : Column(
                            children: [
                              Row(children: [
                                Expanded(child: _KpiCard(icon: Icons.people_alt_rounded, label: 'Utilisateurs', value: '$_totalUsers', color: const Color(0xFF5C6BC0))),
                                const SizedBox(width: 12),
                                Expanded(child: _KpiCard(icon: Icons.receipt_long_rounded, label: 'Commandes', value: '$_totalOrders', color: AppColors.primary)),
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: _KpiCard(icon: Icons.delivery_dining_rounded, label: 'En cours', value: '$_activeDeliveries', color: AppColors.secondary)),
                                const SizedBox(width: 12),
                                Expanded(child: _KpiCard(icon: Icons.payments_rounded, label: 'Revenus', value: '$_totalRevenue F', color: _kAdminColor)),
                              ]),
                            ],
                          ),
                    const SizedBox(height: 28),
                    // Accès rapides
                    Text('Accès rapides',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    _QuickGrid(isWide: isWide),
                    const SizedBox(height: 28),
                    // Activité récente
                    Text('Activité récente',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    _RecentActivity(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? 'Administrateur';

    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFB71C1C)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, $name',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Panneau d\'administration HOLLA',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey)),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  final bool isWide;
  const _QuickGrid({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.people_alt_rounded,   'Gérer les\nutilisateurs', '/admin/users',     const Color(0xFF5C6BC0)),
      (Icons.receipt_long_rounded, 'Superviser les\ncommandes', '/admin/orders',  AppColors.primary),
      (Icons.bar_chart_rounded,    'Analytics &\nrapports', '/admin/analytics',   _kAdminColor),
      (Icons.settings_rounded,     'Paramètres\nsystème', '/admin/settings',      AppColors.secondary),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isWide) {
      return Row(
        children: items.map((item) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _QuickCard(item: item, isDark: isDark),
          ),
        )).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items.map((item) => _QuickCard(item: item, isDark: isDark)).toList(),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final (IconData, String, String, Color) item;
  final bool isDark;
  const _QuickCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.$3),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [item.$4.withValues(alpha: 0.15), item.$4.withValues(alpha: 0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.$4.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.$1, color: item.$4, size: 26),
            const SizedBox(height: 8),
            Text(item.$2,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final events = [
      (Icons.person_add_rounded,       'Nouveau compte client inscrit',     '2 min',  const Color(0xFF5C6BC0)),
      (Icons.receipt_long_rounded,     'Commande #1042 validée',            '8 min',  AppColors.primary),
      (Icons.delivery_dining_rounded,  'Livraison #0983 terminée',          '15 min', AppColors.secondary),
      (Icons.payment_rounded,          'Paiement MTN 5 000 FCFA reçu',      '23 min', const Color(0xFF43A047)),
      (Icons.warning_amber_rounded,    'Litige commande #1038 signalé',     '1h',     _kAdminColor),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: events.asMap().entries.map((e) {
          final i = e.key;
          final ev = e.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: ev.$4.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(ev.$1, color: ev.$4, size: 18),
                ),
                title: Text(ev.$2, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                trailing: Text('il y a ${ev.$3}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey)),
              ),
              if (i < events.length - 1) const Divider(height: 1, indent: 60),
            ],
          );
        }).toList(),
      ),
    );
  }
}

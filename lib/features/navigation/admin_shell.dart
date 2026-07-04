import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

// Admin rouge/orange selon rapport : "Interface desktop/web avancée"
const _kAdminColor = Color(0xFFE53935);

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/admin/users'))     return 1;
    if (loc.startsWith('/admin/orders'))    return 2;
    if (loc.startsWith('/admin/analytics')) return 3;
    if (loc.startsWith('/admin/settings'))  return 4;
    return 0;
  }

  void _go(BuildContext context, int i) {
    const paths = [
      '/admin/home',
      '/admin/users',
      '/admin/orders',
      '/admin/analytics',
      '/admin/settings',
    ];
    context.go(paths[i]);
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 700;

    final items = const [
      (Icons.dashboard_rounded,       'Dashboard'),
      (Icons.people_alt_rounded,      'Utilisateurs'),
      (Icons.receipt_long_rounded,    'Commandes'),
      (Icons.bar_chart_rounded,       'Analytics'),
      (Icons.settings_rounded,        'Paramètres'),
    ];

    if (isWide) {
      // Layout web : sidebar fixe à gauche
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(idx: idx, items: items, isDark: isDark, onTap: (i) => _go(context, i)),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Layout mobile : bottom nav
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final active = idx == i;
                return GestureDetector(
                  onTap: () => _go(context, i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: EdgeInsets.symmetric(horizontal: active ? 14 : 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? _kAdminColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].$1,
                            color: active ? Colors.white : isDark ? const Color(0xFF9090A0) : AppColors.grey,
                            size: 22),
                        if (active) ...[
                          const SizedBox(width: 6),
                          Text(items[i].$2,
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int idx;
  final List<(IconData, String)> items;
  final bool isDark;
  final void Function(int) onTap;

  const _Sidebar({required this.idx, required this.items, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF12121E) : const Color(0xFF1A1A2E);

    return Container(
      width: 220,
      color: bg,
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _kAdminColor, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text('HOLLA Admin',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Nav items
          ...List.generate(items.length, (i) {
            final active = idx == i;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: active ? _kAdminColor.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: active ? Border.all(color: _kAdminColor.withValues(alpha: 0.35)) : null,
                ),
                child: Row(
                  children: [
                    Icon(items[i].$1,
                        color: active ? _kAdminColor : Colors.white54,
                        size: 20),
                    const SizedBox(width: 12),
                    Text(items[i].$2,
                        style: GoogleFonts.poppins(
                            color: active ? Colors.white : Colors.white60,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          // Déconnexion
          GestureDetector(
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Text('Déconnexion',
                      style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

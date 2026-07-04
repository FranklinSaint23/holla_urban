import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class PartnerShell extends StatelessWidget {
  final Widget child;
  const PartnerShell({super.key, required this.child});

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/partner/orders'))    return 1;
    if (loc.startsWith('/partner/menu'))      return 2;
    if (loc.startsWith('/partner/analytics')) return 3;
    if (loc.startsWith('/partner/messages'))  return 4;
    if (loc.startsWith('/partner/profile'))   return 5;
    return 0;
  }

  void _go(BuildContext context, int i) {
    const paths = [
      '/partner/home',
      '/partner/orders',
      '/partner/menu',
      '/partner/analytics',
      '/partner/messages',
      '/partner/profile',
    ];
    context.go(paths[i]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final idx = _index(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (Icons.dashboard_rounded,           l.navHome),
      (Icons.receipt_long_rounded,        l.navOrders),
      (Icons.restaurant_menu_rounded,     l.navMenu),
      (Icons.bar_chart_rounded,           'Stats'),
      (Icons.chat_bubble_outline_rounded, l.navMessages),
      (Icons.person_outline_rounded,      l.navProfile),
    ];

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
                      color: active ? AppColors.primary : Colors.transparent,
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
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
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

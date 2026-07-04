import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';

class ClientShell extends StatefulWidget {
  final Widget child;
  const ClientShell({super.key, required this.child});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  RealtimeChannel? _channel;

  // Badge "commande active" sur l'onglet Historique (index 1)
  bool _hasActiveOrder = false;

  @override
  void initState() {
    super.initState();
    _subscribeToOrders();
  }

  void _subscribeToOrders() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    _channel = Supabase.instance.client
        .channel('orders-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: uid,
          ),
          callback: (payload) {
            final newStatus =
                payload.newRecord['status'] as String?;
            _showOrderNotification(newStatus);

            // Activer le badge si commande en cours
            if (mounted) {
              setState(() {
                _hasActiveOrder = newStatus == 'on_the_way' ||
                    newStatus == 'confirmed';
              });
            }
          },
        )
        .subscribe();
  }

  void _showOrderNotification(String? status) {
    if (!mounted || status == null) return;

    final messages = {
      'confirmed': '✅ Votre commande a été confirmée !',
      'preparing': '👨‍🍳 Votre commande est en préparation',
      'on_the_way': '🛵 Votre livreur est en route !',
      'delivered': '📦 Commande livrée ! Donnez votre avis',
    };

    final message = messages[status];
    if (message == null) return;

    final colors = {
      'confirmed': AppColors.primary,
      'preparing': AppColors.warning,
      'on_the_way': AppColors.secondary,
      'delivered': AppColors.success,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: colors[status] ?? AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
        elevation: 6,
      ),
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/client/history')) return 1;
    if (loc.startsWith('/client/services')) return 2;
    if (loc.startsWith('/client/messages')) return 3;
    if (loc.startsWith('/client/profile')) return 4;
    return 0;
  }

  void _go(BuildContext context, int i) {
    const paths = [
      '/client/home',
      '/client/history',
      '/client/services',
      '/client/messages',
      '/client/profile',
    ];
    // Désactiver le badge quand on navigue vers Historique
    if (i == 1 && _hasActiveOrder) {
      setState(() => _hasActiveOrder = false);
    }
    context.go(paths[i]);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final idx = _index(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (Icons.home_rounded, l.navHome),
      (Icons.history_rounded, l.navHistory),
      (Icons.apps_rounded, l.navServices),
      (Icons.chat_bubble_outline_rounded, l.navMessages),
      (Icons.person_outline_rounded, l.navProfile),
    ];

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final active = idx == i;
                final isHistory = i == 1;

                return GestureDetector(
                  onTap: () => _go(context, i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: EdgeInsets.symmetric(
                        horizontal: active ? 16 : 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge animé sur l'icône Historique
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              items[i].$1,
                              color: active
                                  ? Colors.white
                                  : isDark
                                      ? const Color(0xFF9090A0)
                                      : AppColors.grey,
                              size: 22,
                            ),
                            if (isHistory && _hasActiveOrder && !active)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: _PulseBadge(),
                              ),
                          ],
                        ),
                        if (active) ...[
                          const SizedBox(width: 6),
                          Text(
                            items[i].$2,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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

// ── Badge rouge animé ─────────────────────────────────────────────────────

class _PulseBadge extends StatefulWidget {
  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C2A)
                : Colors.white,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

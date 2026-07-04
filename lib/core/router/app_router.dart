import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/landing/landing_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/client/screens/history_screen.dart';
import '../../features/client/screens/order_screen.dart';
import '../../features/client/screens/order_details_screen.dart';
import '../../features/client/screens/payment_screen.dart';
import '../../features/client/screens/services_screen.dart';
import '../../features/client/screens/track_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/navigation/client_shell.dart';
import '../../features/partner/screens/partner_home_screen.dart';
import '../../features/partner/screens/partner_orders_screen.dart';
import '../../features/partner/screens/partner_menu_screen.dart';
import '../../features/partner/screens/partner_analytics_screen.dart';
import '../../features/navigation/partner_shell.dart';
import '../../features/delivery/screens/delivery_home_screen.dart';
import '../../features/delivery/screens/delivery_orders_screen.dart';
import '../../features/delivery/screens/delivery_earnings_screen.dart';
import '../../features/navigation/delivery_shell.dart';
import '../../features/provider/screens/provider_home_screen.dart';
import '../../features/provider/screens/provider_requests_screen.dart';
import '../../features/navigation/provider_shell.dart';
import '../../features/ai/screens/ai_chat_screen.dart';
import '../../features/client/screens/search_screen.dart';
import '../../features/navigation/admin_shell.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../providers/auth_provider.dart';

// ChangeNotifier used as refreshListenable so GoRouter is NOT recreated on
// auth changes — only the redirect is re-evaluated.
class _RouterNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier();

  // ref.listen (not ref.watch) so this provider never rebuilds.
  // Rebuilding would create a new GoRouter and reset navigation to '/'.
  ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, __) {
    notifier.refresh();
  });
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final loc = state.matchedLocation;

      const publicPaths = {'/', '/login', '/register', '/role-selection'};
      final isPublicPage = publicPaths.contains(loc);

      // Non connecté → pages publiques seulement
      if (!isAuth && !isPublicPage) return '/';
      return null;
    },
    routes: [
      // ── Public ────────────────────────────────────────────────
      GoRoute(path: '/',               builder: (_, __) => const LandingScreen()),
      // ── Auth ──────────────────────────────────────────────────
      GoRoute(path: '/login',          builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',       builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/role-selection', builder: (_, __) => const RoleSelectionScreen()),

      // ── Client ────────────────────────────────────────────────
      ShellRoute(
        builder: (_, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(path: '/client/home',     builder: (_, __) => const ClientHomeScreen()),
          GoRoute(path: '/client/history',  builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/client/services', builder: (_, __) => const ServicesScreen()),
          GoRoute(path: '/client/messages', builder: (_, __) => const MessagesScreen()),
          GoRoute(path: '/client/profile',  builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/client/ai-chat',      builder: (_, __) => const AiChatScreen()),
      GoRoute(path: '/client/search',       builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/client/order',        builder: (_, __) => const OrderScreen()),
      GoRoute(path: '/client/payment',      builder: (_, s) => PaymentScreen(total: s.extra as int? ?? 0)),
      GoRoute(path: '/client/chat/:id',     builder: (_, s) => ChatScreen(contactName: s.pathParameters['id'] ?? '')),
      GoRoute(path: '/client/order-details/:id',
              builder: (_, s) => OrderDetailsScreen(orderId: s.pathParameters['id'] ?? '0', isOngoing: s.extra as bool? ?? false)),
      GoRoute(path: '/client/track/:id',    builder: (_, s) => TrackScreen(orderId: s.pathParameters['id'] ?? '0')),

      // ── Partenaire ────────────────────────────────────────────
      ShellRoute(
        builder: (_, state, child) => PartnerShell(child: child),
        routes: [
          GoRoute(path: '/partner/home',      builder: (_, __) => const PartnerHomeScreen()),
          GoRoute(path: '/partner/orders',    builder: (_, __) => const PartnerOrdersScreen()),
          GoRoute(path: '/partner/menu',      builder: (_, __) => const PartnerMenuScreen()),
          GoRoute(path: '/partner/analytics', builder: (_, __) => const PartnerAnalyticsScreen()),
          GoRoute(path: '/partner/messages',  builder: (_, __) => const MessagesScreen()),
          GoRoute(path: '/partner/profile',   builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Livreur ───────────────────────────────────────────────
      ShellRoute(
        builder: (_, state, child) => DeliveryShell(child: child),
        routes: [
          GoRoute(path: '/delivery/home',     builder: (_, __) => const DeliveryHomeScreen()),
          GoRoute(path: '/delivery/orders',   builder: (_, __) => const DeliveryOrdersScreen()),
          GoRoute(path: '/delivery/earnings', builder: (_, __) => const DeliveryEarningsScreen()),
          GoRoute(path: '/delivery/messages', builder: (_, __) => const MessagesScreen()),
          GoRoute(path: '/delivery/profile',  builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Prestataire ───────────────────────────────────────────
      ShellRoute(
        builder: (_, state, child) => ProviderShell(child: child),
        routes: [
          GoRoute(path: '/provider/home',     builder: (_, __) => const ProviderHomeScreen()),
          GoRoute(path: '/provider/requests', builder: (_, __) => const ProviderRequestsScreen()),
          GoRoute(path: '/provider/messages', builder: (_, __) => const MessagesScreen()),
          GoRoute(path: '/provider/profile',  builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Administrateur ────────────────────────────────────────
      ShellRoute(
        builder: (_, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/home',      builder: (_, __) => const AdminHomeScreen()),
          GoRoute(path: '/admin/users',     builder: (_, __) => const AdminUsersScreen()),
          GoRoute(path: '/admin/orders',    builder: (_, __) => const AdminOrdersScreen()),
          GoRoute(path: '/admin/analytics', builder: (_, __) => const AdminAnalyticsScreen()),
          GoRoute(path: '/admin/settings',  builder: (_, __) => const AdminSettingsScreen()),
        ],
      ),
    ],
  );
});

/// Navigate to the correct dashboard based on user role.
/// Call this after successful login / registration.
void navigateByRole(BuildContext context, String? role) {
  switch (role) {
    case 'client':
      context.go('/client/home');
    case 'partner':
      context.go('/partner/home');
    case 'delivery':
      context.go('/delivery/home');
    case 'provider':
      context.go('/provider/home');
    case 'admin':
      context.go('/admin/home');
    default:
      context.go('/role-selection');
  }
}

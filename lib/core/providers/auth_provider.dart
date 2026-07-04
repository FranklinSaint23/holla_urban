import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _client = Supabase.instance.client;

// Stream des changements d'auth
final authStateProvider = StreamProvider<AuthState>((ref) {
  return _client.auth.onAuthStateChange;
});

// Utilisateur courant
final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (s) => s.session?.user,
    loading: () => _client.auth.currentUser,
    error: (_, __) => null,
  );
});

// Rôle de l'utilisateur (depuis la table profiles)
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  try {
    final row = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    return row['role'] as String?;
  } catch (_) {
    return null;
  }
});

// Helper: est-ce que l'utilisateur est connecté ?
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/holla_background.dart';

const _kAdminColor = Color(0xFFE53935);

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tab;
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _search = '';

  final _roles = ['Tous', 'client', 'partner', 'delivery', 'provider', 'admin'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _roles.length, vsync: this);
    _tab.addListener(() => setState(() {}));
    _loadUsers();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final data = await _client.from('profiles').select('*').order('created_at', ascending: false);
      if (mounted) setState(() { _users = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _users;
    final role = _roles[_tab.index];
    if (role != 'Tous') list = list.where((u) => u['role'] == role).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((u) =>
          (u['full_name'] ?? '').toString().toLowerCase().contains(q) ||
          (u['email'] ?? '').toString().toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<void> _changeRole(Map<String, dynamic> user, String newRole) async {
    await _client.from('profiles').update({'role': newRole}).eq('id', user['id']);
    await _loadUsers();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer ${user['full_name'] ?? user['email']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _client.from('profiles').delete().eq('id', user['id']);
      await _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Text('Gestion des utilisateurs',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh_rounded)),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un utilisateur...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C1C2A) : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tab,
                isScrollable: true,
                labelColor: _kAdminColor,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: _kAdminColor,
                tabs: _roles.map((r) => Tab(text: r)).toList(),
              ),
              // Liste
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _kAdminColor))
                    : _filtered.isEmpty
                        ? Center(child: Text('Aucun utilisateur',
                            style: GoogleFonts.poppins(color: AppColors.grey)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _UserTile(
                              user: _filtered[i],
                              isDark: isDark,
                              onChangeRole: _changeRole,
                              onDelete: _deleteUser,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final Function(Map<String, dynamic>, String) onChangeRole;
  final Function(Map<String, dynamic>) onDelete;

  const _UserTile({required this.user, required this.isDark, required this.onChangeRole, required this.onDelete});

  Color _roleColor(String? role) {
    return switch (role) {
      'client'   => AppColors.primary,
      'partner'  => const Color(0xFF5C6BC0),
      'delivery' => AppColors.secondary,
      'provider' => AppColors.warning,
      'admin'    => _kAdminColor,
      _          => AppColors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final role = user['role'] as String? ?? 'client';
    final name = user['full_name'] as String? ?? 'Utilisateur';
    final email = user['email'] as String? ?? '';
    final phone = user['phone'] as String? ?? '';
    final avatar = user['avatar_url'] as String?;
    final createdAt = user['created_at'] as String? ?? '';
    final date = createdAt.isNotEmpty ? createdAt.substring(0, 10) : '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
          backgroundColor: _roleColor(role).withValues(alpha: 0.15),
          child: avatar == null
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.w700))
              : null,
        ),
        title: Text(name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty) Text(email, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey)),
            if (phone.isNotEmpty) Text(phone, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey)),
            if (date.isNotEmpty) Text('Inscrit le $date', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(role).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(role,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: _roleColor(role))),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18),
              onSelected: (v) {
                if (v == 'delete') {
                  onDelete(user);
                } else {
                  onChangeRole(user, v);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'client',   child: Text('Rôle: Client')),
                const PopupMenuItem(value: 'partner',  child: Text('Rôle: Partenaire')),
                const PopupMenuItem(value: 'delivery', child: Text('Rôle: Livreur')),
                const PopupMenuItem(value: 'provider', child: Text('Rôle: Prestataire')),
                const PopupMenuItem(value: 'admin',    child: Text('Rôle: Admin')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'delete',
                    child: Text('Supprimer', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

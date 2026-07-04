import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/holla_background.dart';

const _kAdminColor = Color(0xFFE53935);

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] ?? 'Administrateur';
    final email = user?.email ?? '';

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Paramètres système',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              // Profil admin
              _Section(
                title: 'Profil administrateur',
                isDark: isDark,
                children: [
                  _InfoTile(icon: Icons.person_rounded, label: 'Nom', value: name),
                  _InfoTile(icon: Icons.email_rounded, label: 'Email', value: email),
                  _InfoTile(icon: Icons.shield_rounded, label: 'Rôle', value: 'Administrateur système'),
                ],
              ),
              const SizedBox(height: 16),
              // Plateforme
              _Section(
                title: 'Configuration plateforme',
                isDark: isDark,
                children: [
                  _ToggleTile(icon: Icons.notifications_active_rounded, label: 'Notifications push', value: true),
                  _ToggleTile(icon: Icons.smart_toy_rounded, label: 'Module IA actif', value: true),
                  _ToggleTile(icon: Icons.payments_rounded, label: 'Paiements CamPay', value: true),
                ],
              ),
              const SizedBox(height: 16),
              // Informations techniques
              _Section(
                title: 'Informations techniques',
                isDark: isDark,
                children: [
                  _InfoTile(icon: Icons.storage_rounded, label: 'Base de données', value: 'Supabase PostgreSQL'),
                  _InfoTile(icon: Icons.cloud_rounded, label: 'Backend', value: 'Supabase + FastAPI/Groq'),
                  _InfoTile(icon: Icons.phone_android_rounded, label: 'Frontend', value: 'Flutter 3.41.0'),
                  _InfoTile(icon: Icons.map_rounded, label: 'Cartographie', value: 'Google Maps API'),
                ],
              ),
              const SizedBox(height: 24),
              // Déconnexion
              ElevatedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Se déconnecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAdminColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;
  const _Section({required this.title, required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kAdminColor)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C2A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: children.asMap().entries.map((e) => Column(
              children: [
                e.value,
                if (e.key < children.length - 1) const Divider(height: 1, indent: 56),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey, size: 20),
      title: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey)),
      subtitle: Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _ToggleTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool value;
  const _ToggleTile({required this.icon, required this.label, required this.value});
  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late bool _val;
  @override
  void initState() { super.initState(); _val = widget.value; }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon, color: _val ? _kAdminColor : AppColors.grey, size: 20),
      title: Text(widget.label, style: GoogleFonts.poppins(fontSize: 13)),
      trailing: Switch(
        value: _val,
        onChanged: (v) => setState(() => _val = v),
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? _kAdminColor : null),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? _kAdminColor.withValues(alpha: 0.4) : null),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/holla_background.dart';
import '../../../core/widgets/holla_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selected;
  bool _loading = false;

  static const _homeRoutes = {
    'client':   '/client/home',
    'partner':  '/partner/home',
    'delivery': '/delivery/home',
    'provider': '/provider/home',
    'admin':    '/admin/home',
  };

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'role': _selected})
            .eq('id', uid);

        // Créer l'entrée dans la table du rôle
        if (_selected == 'partner') {
          await Supabase.instance.client.from('partners').upsert({'id': uid});
        } else if (_selected == 'delivery') {
          await Supabase.instance.client.from('delivery_agents').upsert({'id': uid});
        } else if (_selected == 'provider') {
          await Supabase.instance.client.from('service_providers')
              .upsert({'id': uid, 'specialty': 'Non spécifié'});
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      context.go(_homeRoutes[_selected!]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final roles = [
      _RoleItem('client', l.roleClient, l.roleClientSub,
          Icons.shopping_bag_outlined, AppColors.primary),
      _RoleItem('partner', l.rolePartner, l.rolePartnerSub,
          Icons.store_outlined, AppColors.secondary),
      _RoleItem('delivery', l.roleDelivery, l.roleDeliverySub,
          Icons.delivery_dining_outlined, AppColors.warning),
      _RoleItem('provider', l.roleProvider, l.roleProviderSub,
          Icons.handyman_outlined, AppColors.error),
    ];

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/images/logo.jpeg',
                        width: 72, height: 72, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l.welcomeTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.chooseRoleSubtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.55),
                      height: 1.5),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.separated(
                    itemCount: roles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final r = roles[i];
                      final active = _selected == r.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = r.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primaryLight
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : Theme.of(context).dividerColor,
                              width: active ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: active
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: r.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(r.icon, color: r.color, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.label,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: active
                                              ? AppColors.primary
                                              : Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.color,
                                        )),
                                    Text(r.subtitle,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5))),
                                  ],
                                ),
                              ),
                              Icon(
                                active
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: active
                                    ? AppColors.primary
                                    : Theme.of(context).dividerColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                HollaButton(
                  label: l.continueBtn,
                  onPressed: _selected != null ? _confirm : null,
                  isLoading: _loading,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleItem {
  final String id, label, subtitle;
  final IconData icon;
  final Color color;
  const _RoleItem(this.id, this.label, this.subtitle, this.icon, this.color);
}

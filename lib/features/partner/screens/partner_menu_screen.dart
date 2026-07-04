import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class PartnerMenuScreen extends StatelessWidget {
  const PartnerMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      _MenuItem('Pizza Margherita', 8500, true),
      _MenuItem('Burger Spécial',   9000, true),
      _MenuItem('Salade César',     5500, true),
      _MenuItem('Coca Cola 33cl',   1000, true),
      _MenuItem('Eau Minérale',      500, false),
      _MenuItem('Tiramisu',         3500, false),
    ];

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(l.navMenu,
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color)),
                    const Spacer(),
                    FloatingActionButton.small(
                      onPressed: () {},
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _MenuTile(item: items[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String name;
  final int price;
  bool available;
  _MenuItem(this.name, this.price, this.available);
}

class _MenuTile extends StatefulWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});
  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14,
                        color: Theme.of(context).textTheme.titleSmall?.color)),
                Text('${widget.item.price} FCFA',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Switch(
            value: widget.item.available,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => widget.item.available = v),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

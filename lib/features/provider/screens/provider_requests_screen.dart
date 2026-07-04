import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});
  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(l.navRequests,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.titleLarge?.color)),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: context.cardBg, borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tab,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(10)),
                  labelColor: Colors.white,
                  unselectedLabelColor: context.subtextColor,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: [Tab(text: l.statusNew), Tab(text: 'En cours'), Tab(text: 'Terminé')],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _RequestList(status: 'new'),
                    _RequestList(status: 'in_progress'),
                    _RequestList(status: 'done'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Req {
  final String id, client, task, address, time;
  final int estimatedPrice;
  const _Req(this.id, this.client, this.task, this.address, this.time, this.estimatedPrice);
}

class _RequestList extends StatelessWidget {
  final String status;
  const _RequestList({required this.status});

  @override
  Widget build(BuildContext context) {
    final reqs = status == 'new'
        ? [
            _Req('REQ-501', 'Sophie K.', 'Fuite d\'eau - Robinetterie', 'Bastos, Yaoundé', 'il y a 3 min', 15000),
            _Req('REQ-499', 'Paul T.', 'Panne électrique - tableau', 'Nlongkak, Yaoundé', 'il y a 1h', 25000),
          ]
        : status == 'in_progress'
            ? [_Req('REQ-498', 'Marc T.', 'Installation climatisation', 'Biyem-Assi, Yaoundé', 'Depuis 09:00', 45000)]
            : [
                _Req('REQ-495', 'Anne F.', 'Réparation robinetterie', 'Centre, Bafoussam', 'Hier', 12000),
                _Req('REQ-490', 'Jean B.', 'Câblage prise électrique', 'Etoudi, Yaoundé', 'Lundi', 8000),
              ];

    if (reqs.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.work_off_rounded, size: 56, color: context.subtextColor),
          const SizedBox(height: 12),
          Text('Aucune demande', style: GoogleFonts.poppins(fontSize: 14, color: context.subtextColor)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: reqs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RequestTile(req: reqs[i], status: status),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final _Req req;
  final String status;
  const _RequestTile({required this.req, required this.status});

  @override
  Widget build(BuildContext context) {
    final isNew = status == 'new';
    final isDone = status == 'done';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isNew ? Border.all(color: AppColors.warning.withValues(alpha: 0.4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(req.id, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.warning)),
              const Spacer(),
              Text(req.time, style: GoogleFonts.poppins(fontSize: 11, color: context.subtextColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text(req.task, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14,
              color: Theme.of(context).textTheme.titleSmall?.color)),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.grey),
              Text(' ${req.client}', style: GoogleFonts.poppins(fontSize: 12, color: context.subtextColor)),
              const SizedBox(width: 10),
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.grey),
              Text(' ${req.address}', style: GoogleFonts.poppins(fontSize: 12, color: context.subtextColor)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('~${req.estimatedPrice} FCFA',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.success, fontSize: 14)),
              const Spacer(),
              if (isNew) ...[
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: Text('Refuser', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: Text('Accepter', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                ),
              ] else if (!isDone)
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: Text('Terminer', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('TERMINÉ', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

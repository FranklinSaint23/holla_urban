import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static final _convos = [
    _Convo('Livreur - Jean', 'Je suis en route pour la livraison...', '10:45', 2, true),
    _Convo('Support Client Holla', 'Votre demande #4502 a été traitée.', 'Hier', 0, false),
    _Convo('Boutique Artisanale', 'Merci pour votre commande ! Elle es...', 'Lun.', 0, false),
    _Convo('Marie - Conciergerie', 'Avons-nous validé le planning de...', '12 Jan', 1, false),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(l.messagesTitle,
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.color)),
                    const Spacer(),
                    const Icon(Icons.translate_rounded,
                        color: AppColors.grey, size: 20),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLight,
                      child: ClipOval(
                        child: Image.asset('assets/images/logo.jpeg',
                            width: 36, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Search ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.search_rounded,
                              color: AppColors.grey, size: 20)),
                      Expanded(
                        child: Text(l.searchConversation,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: context.subtextColor)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── List ───────────────────────────────────────────────
              Expanded(
                child: _convos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 56, color: context.subtextColor),
                            const SizedBox(height: 12),
                            Text(l.startDiscussion,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: context.subtextColor)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        itemCount: _convos.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: context.borderColor),
                        itemBuilder: (_, i) => _ConvoTile(
                          convo: _convos[i],
                          onTap: () =>
                              context.push('/client/chat/${_convos[i].name}'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }
}

class _Convo {
  final String name, lastMsg, time;
  final int unread;
  final bool online;
  const _Convo(this.name, this.lastMsg, this.time, this.unread, this.online);
}

class _ConvoTile extends StatelessWidget {
  final _Convo convo;
  final VoidCallback onTap;
  const _ConvoTile({required this.convo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            child: Text(convo.name[0],
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 18)),
          ),
          if (convo.online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(convo.name,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).textTheme.titleSmall?.color)),
      subtitle: Text(convo.lastMsg,
          style: GoogleFonts.poppins(
              fontSize: 12, color: context.subtextColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(convo.time,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: context.subtextColor)),
          if (convo.unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: Center(
                child: Text('${convo.unread}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

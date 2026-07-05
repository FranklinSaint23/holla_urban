import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _client = Supabase.instance.client;
  late String _myId;

  List<_ConvoSummary> _convos = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _myId = _client.auth.currentUser!.id;
    _loadConversations();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    try {
      // Get all messages involving current user with partner profile
      final data = await _client
          .from('messages')
          .select(
              'id, sender_id, receiver_id, content, created_at, is_read,'
              'sender:profiles!messages_sender_id_fkey(id, full_name),'
              'receiver:profiles!messages_receiver_id_fkey(id, full_name)')
          .or('sender_id.eq.$_myId,receiver_id.eq.$_myId')
          .order('created_at', ascending: false) as List;

      final messages = List<Map<String, dynamic>>.from(data);

      // Group by conversation partner, keep latest message
      final Map<String, _ConvoSummary> convosMap = {};
      for (final msg in messages) {
        final senderId = msg['sender_id'] as String;
        final receiverId = msg['receiver_id'] as String;

        String partnerId;
        String partnerName;

        if (senderId == _myId) {
          partnerId = receiverId;
          final receiver = msg['receiver'] as Map?;
          partnerName =
              receiver?['full_name'] as String? ?? receiverId;
        } else {
          partnerId = senderId;
          final sender = msg['sender'] as Map?;
          partnerName =
              sender?['full_name'] as String? ?? senderId;
        }

        if (!convosMap.containsKey(partnerId)) {
          final isUnread = !(msg['is_read'] as bool? ?? true) &&
              receiverId == _myId;
          convosMap[partnerId] = _ConvoSummary(
            partnerId: partnerId,
            partnerName: partnerName,
            lastMsg: msg['content'] as String? ?? '',
            time: _formatTime(msg['created_at'] as String?),
            unread: isUnread ? 1 : 0,
          );
        } else {
          // Count unread
          if (!(msg['is_read'] as bool? ?? true) &&
              receiverId == _myId) {
            final existing = convosMap[partnerId]!;
            convosMap[partnerId] = _ConvoSummary(
              partnerId: existing.partnerId,
              partnerName: existing.partnerName,
              lastMsg: existing.lastMsg,
              time: existing.time,
              unread: existing.unread + 1,
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _convos = convosMap.values.toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    _sub = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((_) => _loadConversations());
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == yesterday) return 'Hier';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
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

              // ── Search bar (decorative) ─────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(Icons.search_rounded,
                              color: AppColors.grey, size: 20)),
                      Expanded(
                        child: Text(l.searchConversation,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: context.subtextColor)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Conversations ───────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : _convos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                    Icons
                                        .chat_bubble_outline_rounded,
                                    size: 56,
                                    color: context.subtextColor),
                                const SizedBox(height: 12),
                                Text(l.startDiscussion,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color:
                                            context.subtextColor)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadConversations,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              itemCount: _convos.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: context.borderColor),
                              itemBuilder: (_, i) => _ConvoTile(
                                convo: _convos[i],
                                onTap: () => context.push(
                                  '/client/chat/${_convos[i].partnerId}',
                                  extra: _convos[i].partnerName,
                                ),
                              ),
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

class _ConvoSummary {
  final String partnerId, partnerName, lastMsg, time;
  final int unread;
  const _ConvoSummary({
    required this.partnerId,
    required this.partnerName,
    required this.lastMsg,
    required this.time,
    required this.unread,
  });
}

class _ConvoTile extends StatelessWidget {
  final _ConvoSummary convo;
  final VoidCallback onTap;
  const _ConvoTile({required this.convo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = convo.partnerName.isNotEmpty
        ? convo.partnerName[0].toUpperCase()
        : '?';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primaryLight,
        child: Text(initial,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 18)),
      ),
      title: Text(convo.partnerName,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color:
                  Theme.of(context).textTheme.titleSmall?.color)),
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
                  color: AppColors.primary,
                  shape: BoxShape.circle),
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

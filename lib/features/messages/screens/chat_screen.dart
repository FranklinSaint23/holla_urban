import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

class ChatScreen extends StatefulWidget {
  /// UUID of the other user in the conversation.
  final String contactId;
  final String contactName;
  const ChatScreen(
      {super.key, required this.contactId, required this.contactName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = Supabase.instance.client;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  late String _myId;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _myId = _client.auth.currentUser!.id;
    _loadMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final data = await _client
          .from('messages')
          .select('id, sender_id, receiver_id, content, created_at')
          .or('and(sender_id.eq.$_myId,receiver_id.eq.${widget.contactId}),and(sender_id.eq.${widget.contactId},receiver_id.eq.$_myId)')
          .order('created_at') as List;

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }

      // Mark as read
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', widget.contactId)
          .eq('receiver_id', _myId)
          .eq('is_read', false);

      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    _sub = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) {
      // Filter to only messages in this conversation
      final filtered = data.where((m) {
        final sender = m['sender_id'] as String?;
        final receiver = m['receiver_id'] as String?;
        return (sender == _myId && receiver == widget.contactId) ||
            (sender == widget.contactId && receiver == _myId);
      }).toList();

      if (mounted) {
        setState(() => _messages = filtered);
        _scrollToBottom();
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _ctrl.clear();

    try {
      await _client.from('messages').insert({
        'sender_id': _myId,
        'receiver_id': widget.contactId,
        'content': text,
        'is_read': false,
      });
    } catch (_) {
      // Realtime will not refresh on error; show nothing
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients &&
          _scroll.position.maxScrollExtent > 0) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final initial = widget.contactName.isNotEmpty
        ? widget.contactName[0].toUpperCase()
        : '?';

    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6)
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(initial,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(widget.contactName,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.color)),
                          Text(l.online,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.call_outlined,
                            color: AppColors.primary)),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                            Icons.more_vert_rounded)),
                  ],
                ),
              ),

              // ── Messages ──────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : _messages.isEmpty
                        ? Center(
                            child: Text('Démarrez la conversation',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: context.subtextColor)),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final msg = _messages[i];
                              final isMine =
                                  msg['sender_id'] == _myId;
                              final time = _formatTime(
                                  msg['created_at'] as String?);
                              return _Bubble(
                                text: msg['content'] as String? ??
                                    '',
                                time: time,
                                isMine: isMine,
                              );
                            },
                          ),
              ),

              // ── Input ─────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6)
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14),
                        decoration: BoxDecoration(
                          color: context.bgColor,
                          borderRadius:
                              BorderRadius.circular(22),
                          border: Border.all(
                              color: context.borderColor),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: l.typeMessage,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    vertical: 10),
                          ),
                          style:
                              GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                      ),
                    ),
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

class _Bubble extends StatelessWidget {
  final String text, time;
  final bool isMine;
  const _Bubble(
      {required this.text,
      required this.time,
      required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment:
            isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient:
                    isMine ? AppColors.primaryGradient : null,
                color: isMine ? null : context.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      Radius.circular(isMine ? 16 : 4),
                  bottomRight:
                      Radius.circular(isMine ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6)
                ],
              ),
              child: Text(text,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isMine
                          ? Colors.white
                          : Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color)),
            ),
            const SizedBox(height: 3),
            Text(time,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: context.subtextColor)),
          ],
        ),
      ),
    );
  }
}

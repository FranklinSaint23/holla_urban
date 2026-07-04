import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/holla_background.dart';

const _kAiColor = Color(0xFF6C5CE7);
const _kAiBaseUrl = 'https://holla-ai.onrender.com';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _loading = false;
  List<String> _suggestions = [
    'Passer une commande',
    'Suivre ma livraison',
    'Modes de paiement ?',
    'Trouver un prestataire',
  ];

  String get _userRole {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['role'] as String? ?? 'client';
  }

  @override
  void initState() {
    super.initState();
    // Message d'accueil initial
    _messages.add(const _Msg(
      text: "Bonjour ! 👋 Je suis Holla AI, votre assistant intelligent.\n\nJe suis là pour vous aider à commander, suivre vos livraisons, trouver des prestataires, ou répondre à vos questions sur HOLLA au Cameroun.",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_Msg(text: text, isUser: true));
      _loading = true;
      _suggestions = [];
    });
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => m.text != _messages.first.text || _messages.first.isUser)
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList();

      final res = await http.post(
        Uri.parse('$_kAiBaseUrl/ai/chatbot/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': history,
          'user_role': _userRole,
          'language': 'fr',
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reply = data['reply'] as String? ?? 'Désolé, je n\'ai pas pu répondre.';
        final suggs = (data['suggestions'] as List?)?.cast<String>() ?? [];
        setState(() {
          _messages.add(_Msg(text: reply, isUser: false));
          _suggestions = suggs;
          _loading = false;
        });
      } else {
        _onError();
      }
    } catch (_) {
      _onError();
    }
    _scrollToBottom();
  }

  void _onError() {
    setState(() {
      _messages.add(const _Msg(
        text: 'Désolé, je ne suis pas disponible pour le moment. Veuillez réessayer.',
        isUser: false,
        isError: true,
      ));
      _loading = false;
      _suggestions = ['Réessayer', 'Contacter le support'];
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HollaBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _kAiColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _kAiColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFFA855F7)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Holla AI',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                          Row(
                            children: [
                              Container(width: 7, height: 7,
                                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text('Assistant IA · Cameroun',
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _messages.clear();
                        _messages.add(const _Msg(
                          text: "Nouvelle conversation. Comment puis-je vous aider ?",
                          isUser: false,
                        ));
                        _suggestions = ['Passer une commande', 'Suivre ma livraison', 'Modes de paiement ?'];
                      }),
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.grey, size: 20),
                      tooltip: 'Nouvelle conversation',
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) return const _TypingIndicator();
                    return _BubbleWidget(_messages[i]);
                  },
                ),
              ),

              // Suggestions
              if (_suggestions.isNotEmpty && !_loading)
                Container(
                  height: 44,
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _send(_suggestions[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _kAiColor.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(20),
                          color: _kAiColor.withValues(alpha: 0.06),
                        ),
                        child: Text(_suggestions[i],
                            style: GoogleFonts.poppins(fontSize: 12, color: _kAiColor, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),

              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: context.bgColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          decoration: InputDecoration(
                            hintText: 'Posez votre question…',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.grey),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                          onSubmitted: (_) => _send(),
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _loading ? null : _send,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _loading
                                ? [AppColors.grey, AppColors.grey]
                                : [const Color(0xFF6C5CE7), const Color(0xFFA855F7)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _loading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                          color: Colors.white, size: 18,
                        ),
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

class _Msg {
  final String text;
  final bool isUser;
  final bool isError;
  const _Msg({required this.text, required this.isUser, this.isError = false});
}

class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  const _BubbleWidget(this.msg);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA855F7)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: msg.isUser
                  ? const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA855F7)])
                  : null,
              color: msg.isError
                  ? AppColors.error.withValues(alpha: 0.1)
                  : msg.isUser ? null : context.cardBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
              ],
              border: msg.isError ? Border.all(color: AppColors.error.withValues(alpha: 0.3)) : null,
            ),
            child: Text(msg.text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.5,
                  color: msg.isUser
                      ? Colors.white
                      : msg.isError
                          ? AppColors.error
                          : Theme.of(context).textTheme.bodyMedium?.color,
                )),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA855F7)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
                bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.33;
                  final t = (_ctrl.value - delay).clamp(0.0, 1.0);
                  final opacity = t < 0.5 ? t * 2 : (1 - t) * 2;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: _kAiColor.withValues(alpha: opacity.clamp(0.2, 1.0)),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

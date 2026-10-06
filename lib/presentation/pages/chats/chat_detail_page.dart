import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/chat_notification_manager.dart';
import '../../../core/utils/name_display.dart';
import '../../../injection/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/chat_detail/chat_detail_bloc.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId, chatName, userId, userName;
  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  bool get _isAI      => widget.chatId == '__ai_assistant__';
  bool get _isSupport => widget.chatId == '__support__';

  @override
  void initState() {
    super.initState();
    if (!_isAI && !_isSupport) {
      ChatNotificationManager().activeChatId = widget.chatId;
    }
  }

  @override
  void dispose() {
    if (!_isAI && !_isSupport) {
      ChatNotificationManager().activeChatId = null;
    }
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Asistente IA local
    if (_isAI)      return _AiAssistantChat(userId: widget.userId);
    // Soporte técnico
    if (_isSupport) return _SupportPage(chatName: widget.chatName);
    // Chat privado con stream real desde SQLite
    return BlocProvider(
      create: (_) => ChatDetailBloc(
        repo: getIt(),
        currentUserId: widget.userId,
        chatName: widget.chatName,
      )..add(ChatMessagesLoadRequested(widget.chatId)),
      child: _PrivateChat(
        chatId: widget.chatId,
        chatName: widget.chatName,
        userId: widget.userId,
      ),
    );
  }
}

// ── Chat privado (stream real) ──────────────────────────────────────────────

class _PrivateChat extends StatelessWidget {
  final String chatId, chatName, userId;
  const _PrivateChat({
    required this.chatId, required this.chatName, required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController();
    final scroll = ScrollController();

    void scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              nameInitials(chatName),
              style: TextStyle(color: AppColors.primary, fontSize: 14)),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(chatName,
              overflow: TextOverflow.ellipsis)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: BlocConsumer<ChatDetailBloc, ChatDetailState>(
            listener: (_, __) => scrollDown(),
            builder: (_, state) {
              if (state is ChatDetailLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ChatDetailError) {
                return Center(child: Text(AppLocalizations.of(context).errorPrefix(state.message ?? '')));
              }
              if (state is ChatDetailReady) {
                final msgs = state.messages;
                if (msgs.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context).noMessagesYet));
                }
                return ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(AppSizes.screenPaddingH),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final isMe = m.senderId == userId;
                    return _MsgBubble(
                      text: m.text,
                      isUser: isMe,
                      isDark: isDark,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        _InputBar(
          ctrl: ctrl,
          isDark: isDark,
          onSend: () {
            final t = ctrl.text.trim();
            if (t.isEmpty) return;
            ctrl.clear();
            context.read<ChatDetailBloc>().add(ChatMessageSent(
              chatId: chatId,
              senderId: userId,
              text: t,
            ));
          },
        ),
      ]),
    );
  }
}

class _MsgBubble extends StatelessWidget {
  final String text;
  final bool isUser, isDark;
  const _MsgBubble({required this.text, required this.isUser, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(Icons.person_outline_rounded,
                color: AppColors.primary, size: 16)),
          const SizedBox(width: AppSizes.sm),
        ],
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.sm),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSizes.radiusLg),
              topRight: const Radius.circular(AppSizes.radiusLg),
              bottomLeft: Radius.circular(isUser ? AppSizes.radiusLg : 4),
              bottomRight: Radius.circular(isUser ? 4 : AppSizes.radiusLg),
            ),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: isUser ? Colors.white : null, height: 1.5)),
        )),
        if (isUser) const SizedBox(width: AppSizes.sm),
      ],
    ),
  );
}

// ── Asistente IA local ────────────────────────────────────────────────────────

class _AiMsg { final String text; final bool isUser;
  _AiMsg({required this.text, required this.isUser}); }

class _AiAssistantChat extends StatefulWidget {
  final String userId;
  const _AiAssistantChat({required this.userId});
  @override State<_AiAssistantChat> createState() => _AiAssistantChatState();
}

class _AiAssistantChatState extends State<_AiAssistantChat> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final _msgs   = <_AiMsg>[];
  bool _typing  = false;

  @override
  void initState() {
    super.initState();
    // El welcome se añade en didChangeDependencies para acceder a l10n
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_msgs.isEmpty) {
      _msgs.add(_AiMsg(
        text: AppLocalizations.of(context).aiWelcome,
        isUser: false,
      ));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    setState(() { _msgs.add(_AiMsg(text: t, isUser: true)); _typing = true; });
    _scrollDown();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final reply = _reply(t.toLowerCase(), AppLocalizations.of(context));
      setState(() { _msgs.add(_AiMsg(text: reply, isUser: false)); _typing = false; });
      _scrollDown();
    });
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  });

  bool _has(String q, List<String> kw) => kw.any(q.contains);

  String _reply(String q, AppLocalizations l10n) {
    if (_has(q, ['playa','beach','verano','calor','caribe','bali','ibiza','mallorca'])) {
      return l10n.aiReplyBeach;
    }
    if (_has(q, ['montaña','senderismo','hiking','frío','frio','nieve','alpes','pirineos'])) {
      return l10n.aiReplyMountain;
    }
    if (_has(q, ['ciudad','city','turismo','paris','roma','madrid','berlin','amsterdam'])) {
      return l10n.aiReplyCity;
    }
    if (_has(q, ['negocios','business','trabajo','congreso','reunión'])) {
      return l10n.aiReplyBusiness;
    }
    if (_has(q, ['avión','avion','vuelo','volar','aeropuerto','maleta de mano'])) {
      return l10n.aiReplyFlight;
    }
    if (_has(q, ['medicamento','medicina','botiquín','salud','alergia'])) {
      return l10n.aiReplyMedicine;
    }
    if (_has(q, ['pasaporte','documento','visa','visado','dni'])) {
      return l10n.aiReplyDocuments;
    }
    if (_has(q, ['días','dias','semana','noches','cuanto'])) {
      return l10n.aiReplyDays;
    }
    if (_has(q, ['hola','buenas','hello','hi'])) {
      return l10n.aiReplyHello;
    }
    if (_has(q, ['gracias','thanks','perfecto','genial'])) {
      return l10n.aiReplyThanks;
    }
    return l10n.aiReplyFallback;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 20)),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(AppLocalizations.of(context).assistantChatTitle,
              overflow: TextOverflow.ellipsis)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSizes.screenPaddingH),
            itemCount: _msgs.length + (_typing ? 1 : 0),
            itemBuilder: (_, i) {
              if (_typing && i == _msgs.length) {
                return _TypingDots(isDark: isDark);
              }
              final m = _msgs[i];
              return _AiBubble(text: m.text, isUser: m.isUser, isDark: isDark);
            },
          ),
        ),
        _InputBar(ctrl: _ctrl, isDark: isDark, onSend: _send),
      ]),
    );
  }
}

// ── Página de soporte ─────────────────────────────────────────────────────────

class _SupportPage extends StatelessWidget {
  final String chatName;
  const _SupportPage({required this.chatName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
            child: const Text('🛠️',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20))),
          const SizedBox(width: AppSizes.sm),
          Text(AppLocalizations.of(context).supportChatTitle),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        child: Column(children: [
          const SizedBox(height: AppSizes.xl),

          // Icono
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
              shape: BoxShape.circle),
            child: const Text('🛠️',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: AppSizes.md),
          Text(l10n.supportHowCanWeHelp,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSizes.sm),
          Text(
            l10n.supportAvailability,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xxxl),

          // Opciones
          _SupportOption(
            icon: Icons.email_outlined,
            title: l10n.supportEmailTitle,
            subtitle: l10n.supportEmailSubtitle,
            color: AppColors.primary,
            onTap: () async {
              final uri = Uri.parse(
                  'mailto:${l10n.supportEmailSubtitle}?subject=Soporte TravelReady!');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
          ),
          const SizedBox(height: AppSizes.md),
          _SupportOption(
            icon: Icons.help_outline_rounded,
            title: l10n.supportHelpCenter,
            subtitle: l10n.supportHelpCenterSubtitle,
            color: const Color(0xFF0E9AA7),
            onTap: () async {
              final uri = Uri.parse('https://travelready.app/ayuda');
              if (await canLaunchUrl(uri)) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: AppSizes.md),
          _SupportOption(
            icon: Icons.bug_report_outlined,
            title: l10n.supportReportProblem,
            subtitle: l10n.supportReportProblemSubtitle,
            color: AppColors.error,
            onTap: () async {
              final uri = Uri.parse(
                  'mailto:${l10n.supportEmailSubtitle}?subject=Bug Report - TravelReady!');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
          ),

          const SizedBox(height: AppSizes.xxxl),
          Text(AppStrings.appVersion,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryLight)),
        ]),
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SupportOption({
    required this.icon, required this.title,
    required this.subtitle, required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleSmall),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          )),
          const Icon(Icons.chevron_right_rounded, size: 20,
              color: AppColors.textSecondaryLight),
        ]),
      ),
    );
  }
}

// ── Widgets compartidos ───────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final VoidCallback onSend;
  const _InputBar(
      {required this.ctrl, required this.isDark, required this.onSend});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      AppSizes.screenPaddingH, AppSizes.sm, AppSizes.sm,
      AppSizes.sm + MediaQuery.of(context).padding.bottom),
    decoration: BoxDecoration(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      border: Border(top: BorderSide(
        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight))),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller: ctrl,
          textInputAction: TextInputAction.send,
          maxLines: 4, minLines: 1,
          onSubmitted: (_) => onSend(),
          decoration: const InputDecoration(
              hintText: 'Escribe un mensaje...'),
        ),
      ),
      const SizedBox(width: AppSizes.sm),
      GestureDetector(
        onTap: onSend,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
          child: const Icon(Icons.send_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    ]),
  );
}

class _AiBubble extends StatelessWidget {
  final String text;
  final bool isUser, isDark;
  const _AiBubble(
      {required this.text, required this.isUser, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18)),
          const SizedBox(width: AppSizes.sm),
        ],
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.sm),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSizes.radiusLg),
              topRight: const Radius.circular(AppSizes.radiusLg),
              bottomLeft: Radius.circular(isUser ? AppSizes.radiusLg : 4),
              bottomRight: Radius.circular(isUser ? 4 : AppSizes.radiusLg),
            ),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: isUser ? Colors.white : null, height: 1.5)),
        )),
        if (isUser) const SizedBox(width: AppSizes.sm),
      ],
    ),
  );
}

class _TypingDots extends StatefulWidget {
  final bool isDark;
  const _TypingDots({required this.isDark});
  @override State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 18)),
        const SizedBox(width: AppSizes.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (int i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _ac,
                builder: (_, __) {
                  final offset = (i * 0.33);
                  final t = ((_ac.value - offset) % 1.0);
                  final opacity = t < 0.5 ? 0.3 + t * 1.4 : 1.0 - (t - 0.5) * 1.4;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: opacity.clamp(0.3, 1.0),
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle)),
                    ),
                  );
                },
              ),
          ]),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/name_display.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/chat.dart';
import '../../../injection/injection.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/chats/chats_bloc.dart';

/// Página de chats: privados + IA + Soporte + nuevo chat.
class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  ChatsBloc? _chatsBloc;
  String? _loadedForUserId;

  @override
  void dispose() {
    _chatsBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          // Crear el ChatsBloc solo una vez (o si cambió el usuario)
          if (_chatsBloc == null || _loadedForUserId != state.user.id) {
            _chatsBloc?.close();
            _loadedForUserId = state.user.id;
            _chatsBloc = ChatsBloc(repo: getIt())
              ..add(ChatsLoadRequested(state.user.id));
          }

          return BlocProvider.value(
            value: _chatsBloc!,
            child: _ChatsContent(
                userId: state.user.id, userName: state.user.name),
          );
        }

        // AuthUnauthenticated / AuthRegistered → router redirige,
        // pero por seguridad cerramos el bloc si existía
        _chatsBloc?.close();
        _chatsBloc = null;
        _loadedForUserId = null;

        return Scaffold(
          body: Center(
            child: Text(AppLocalizations.of(context).signInRequired),
          ),
        );
      },
    );
  }
}

class _ChatsContent extends StatelessWidget {
  final String userId, userName;
  const _ChatsContent({required this.userId, required this.userName});

  void _openChat(BuildContext context, String chatId, String chatName) {
    context.push(AppRoutes.chatDetail, extra: {
      'chatId':   chatId,
      'chatName': chatName,
      'userId':   userId,
      'userName': userName,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverAppBar(
            title: Text(AppLocalizations.of(context).messagesTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            pinned: true,
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.group_add_outlined),
                tooltip: 'Nuevo grupo',
                onPressed: () => context.push(AppRoutes.createGroup),
              ),
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                tooltip: AppLocalizations.of(context).newChatTitle,
                onPressed: () => context.push(AppRoutes.users),
              ),
            ],
          ),

          // ── IA + Soporte (siempre visibles) ─────────────────────────
          SliverToBoxAdapter(
            child: Column(children: [
              _PinnedTile(
                emoji: '🤖',
                name: AppLocalizations.of(context).assistantChatTitle,
                subtitle: AppLocalizations.of(context).aiAssistant,
                badgeLabel: 'IA',
                badgeColor: AppColors.primary,
                onTap: () => _openChat(
                    context, '__ai_assistant__', AppLocalizations.of(context).assistantChatTitle),
              ),
              _PinnedTile(
                emoji: '🛠️',
                name: AppLocalizations.of(context).supportChatTitle,
                subtitle: AppLocalizations.of(context).support,
                badgeLabel: AppLocalizations.of(context).support,
                badgeColor: const Color(0xFF7C4DFF),
                onTap: () => _openChat(
                    context, '__support__', AppLocalizations.of(context).supportChatTitle),
              ),
            ]),
          ),

          // ── Chats privados ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPaddingH, AppSizes.md,
                  AppSizes.screenPaddingH, AppSizes.sm),
              child: Text(AppLocalizations.of(context).conversationsLabel,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),

          BlocBuilder<ChatsBloc, ChatsState>(
            builder: (_, state) {
              if (state is ChatsLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is ChatsError) {
                return SliverFillRemaining(
                  child: Center(child: Text(
                    'Error al cargar chats. Comprueba tu conexión.',
                    textAlign: TextAlign.center,
                  )),
                );
              }
              if (state is ChatsReady) {
                final privates = state.chats.where((c) => c.type == ChatType.private).toList();
                final groups   = state.chats.where((c) => c.type == ChatType.group).toList();

                if (privates.isEmpty && groups.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 56, color: AppColors.primary),
                          const SizedBox(height: 12),
                          Text(AppLocalizations.of(context).noPrivateChats,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text('Toca + para iniciar un chat o crear un grupo',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  );
                }

                final items = <Widget>[];

                // ── Grupos ──────────────────────────────────────────────
                if (groups.isNotEmpty) {
                  items.add(_SectionHeader(label: 'Grupos'));
                  for (final c in groups) {
                    items.add(_ChatTile(
                      chat: c,
                      isGroup: true,
                      onTap: () => _openChat(context, c.chatId, c.name),
                      formatTime: _formatTime,
                    ));
                  }
                }

                // ── Privados ─────────────────────────────────────────────
                if (privates.isNotEmpty) {
                  if (groups.isNotEmpty) items.add(_SectionHeader(label: 'Mensajes directos'));
                  for (final c in privates) {
                    items.add(_ChatTile(
                      chat: c,
                      isGroup: false,
                      onTap: () => _openChat(context, c.chatId, c.name),
                      formatTime: _formatTime,
                    ));
                  }
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => items[i],
                    childCount: items.length,
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ]),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}

// ── Cabecera de sección ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSizes.screenPaddingH, 12, AppSizes.screenPaddingH, 4),
    child: Text(label,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600)),
  );
}

// ── Tile de chat (privado o grupo) ──────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatSummary chat;
  final bool isGroup;
  final VoidCallback onTap;
  final String Function(DateTime) formatTime;
  const _ChatTile({
    required this.chat,
    required this.isGroup,
    required this.onTap,
    required this.formatTime,
  });
  @override
  Widget build(BuildContext context) {
    final name = chat.name;
    final unreadCount = chat.unreadCount;
    final hasUnread = unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPaddingH, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isGroup
            ? const Color(0xFF7C4DFF).withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.15),
        child: isGroup
            ? Icon(Icons.group_rounded,
                color: const Color(0xFF7C4DFF), size: 20)
            : Text(
                nameInitials(name),
                style: TextStyle(color: AppColors.primary),
              ),
      ),
      title: Text(
        name,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        chat.lastMessage ?? 'Sin mensajes',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: hasUnread
              ? AppColors.primary
              : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chat.lastMessageAt != null)
            Text(
              formatTime(chat.lastMessageAt as DateTime),
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondaryLight),
            ),
          if (hasUnread) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

// ── Tile fijo (IA / Soporte) ─────────────────────────────────────────────────

class _PinnedTile extends StatelessWidget {
  final String emoji, name, subtitle, badgeLabel;
  final Color badgeColor;
  final VoidCallback onTap;
  const _PinnedTile({
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPaddingH, vertical: 4),
    leading: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        shape: BoxShape.circle),
      child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 22))),
    ),
    title: Text(name, style: Theme.of(context).textTheme.titleSmall),
    subtitle: Text(subtitle,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
      child: Text(badgeLabel,
          style: TextStyle(
              color: badgeColor, fontSize: 10,
              fontWeight: FontWeight.w700)),
    ),
    onTap: onTap,
  );
}

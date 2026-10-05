import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/name_display.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/repositories/chats_repository.dart';
import '../../../domain/usecases/chats/create_group_chat_usecase.dart';
import '../../../injection/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/auth/auth_bloc.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameCtrl      = TextEditingController();
  final _formKey       = GlobalKey<FormState>();
  final _repo          = getIt<ChatsRepository>();
  final _createGroup   = getIt<CreateGroupChatUseCase>();

  StreamSubscription<List<Map<String, dynamic>>>? _usersSub;
  List<Map<String, dynamic>> _allUsers   = [];
  final Set<String>          _selected   = {};
  bool _loadingUsers  = true;
  bool _creating      = false;

  @override
  void initState() {
    super.initState();
    _subscribeUsers();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _subscribeUsers() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    _usersSub = _repo.watchUsersExcept(auth.user.id).listen(
      (users) {
        if (!mounted) return;
        setState(() { _allUsers = users; _loadingUsers = false; });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _loadingUsers = false);
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona al menos un participante.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _creating = true);
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    final result = await _createGroup(
      creatorId: auth.user.id,
      groupName: _nameCtrl.text.trim(),
      memberIds: _selected.toList(),
    );

    if (!mounted) return;
    setState(() => _creating = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${f.message}'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      )),
      (chat) => context.pushReplacement(AppRoutes.chatDetail, extra: {
        'chatId':   chat.id,
        'chatName': chat.name ?? _nameCtrl.text.trim(),
        'userId':   auth.user.id,
        'userName': auth.user.name,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo grupo'),
        actions: [
          if (_creating)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Crear',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nombre del grupo ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del grupo',
                  prefixIcon: Icon(Icons.group_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Escribe un nombre para el grupo' : null,
              ),
            ),

            // ── Participantes seleccionados (chips) ───────────────────────
            if (_selected.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _selected.map((id) {
                    final user = _allUsers.firstWhere(
                      (u) => u['id'] == id,
                      orElse: () => {'name': id, 'id': id},
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            nameInitials(user['name'] as String? ?? '',
                                fallback: '?'),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.primary),
                          ),
                        ),
                        label: Text(user['name'] as String? ?? 'Usuario',
                            style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _selected.remove(id)),
                      ),
                    );
                  }).toList(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '${_selected.length} participante${_selected.length == 1 ? '' : 's'} seleccionado${_selected.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.primary),
              ),
            ),

            const Divider(height: 1),

            // ── Lista de usuarios ─────────────────────────────────────────
            Expanded(
              child: _loadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : _allUsers.isEmpty
                      ? Center(child: Text(l10n.noOtherUsers))
                      : ListView.builder(
                          itemCount: _allUsers.length,
                          itemBuilder: (_, i) {
                            final u      = _allUsers[i];
                            final uid    = u['id']    as String;
                            final name   = u['name']  as String? ?? 'Usuario';
                            final email  = u['email'] as String? ?? '';
                            final isOn   = _selected.contains(uid);
                            return CheckboxListTile(
                              value: isOn,
                              activeColor: AppColors.primary,
                              onChanged: (_) => setState(() {
                                if (isOn) _selected.remove(uid);
                                else      _selected.add(uid);
                              }),
                              secondary: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                child: Text(
                                  nameInitials(name),
                                  style: const TextStyle(color: AppColors.primary),
                                ),
                              ),
                              title: Text(name,
                                  style: Theme.of(context).textTheme.titleSmall),
                              subtitle: Text(email,
                                  style: Theme.of(context).textTheme.bodySmall),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

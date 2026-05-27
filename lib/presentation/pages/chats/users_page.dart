import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/repositories/chats_repository.dart';
import '../../../domain/usecases/chats/create_private_chat_usecase.dart';
import '../../../domain/usecases/chats/find_user_by_email_usecase.dart';
import '../../../injection/injection.dart';
import '../../bloc/auth/auth_bloc.dart';

/// Regex para email completo (tiene @ y dominio con punto).
final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false);

/// Página para descubrir otros usuarios e iniciar un chat privado.
///
/// Modo búsqueda:
///   - Email completo válido → consulta remota exacta en Firestore.
///   - Texto libre           → filtra la lista en tiempo real cargada localmente.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _repo           = getIt<ChatsRepository>();
  final _createChat     = getIt<CreatePrivateChatUseCase>();
  final _findByEmail    = getIt<FindUserByEmailUseCase>();
  final _searchCtrl     = TextEditingController();

  StreamSubscription<List<Map<String, dynamic>>>? _usersSub;

  // Lista base (stream Firestore)
  List<Map<String, dynamic>> _allUsers  = [];
  // Lista mostrada (filtro local o resultado remoto)
  List<Map<String, dynamic>> _displayed = [];

  bool   _loading       = true;   // carga inicial del stream
  bool   _searching     = false;  // búsqueda remota en curso
  bool   _emailSearched = false;  // ya se hizo búsqueda remota
  String _lastQuery     = '';
  String? _streamError;           // mensaje de error del stream

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
    _subscribeUsers();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _subscribeUsers() {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    _currentUserId = auth.user.id;

    _usersSub = _repo.watchUsersExcept(auth.user.id).listen(
      (users) {
        if (!mounted) return;
        print('[UsersPage] Stream recibió ${users.length} usuarios de Firestore');
        setState(() {
          _allUsers    = users;
          _loading     = false;
          _streamError = null;
          if (!_emailSearched) _applyLocalFilter();
        });
      },
      onError: (e) {
        print('[UsersPage] Error en stream de usuarios: $e');
        if (!mounted) return;
        setState(() {
          _loading     = false;
          _streamError = 'No se pudieron cargar los usuarios. Verifica tu conexión.';
        });
      },
    );
  }

  void _onQueryChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;

    if (_emailRegex.hasMatch(q)) {
      // Búsqueda remota exacta por email
      _searchByEmail(q);
    } else {
      // Filtro local
      setState(() { _emailSearched = false; });
      _applyLocalFilter();
    }
  }

  void _applyLocalFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _displayed = List.from(_allUsers);
      } else {
        _displayed = _allUsers.where((u) {
          final name  = (u['name']  as String? ?? '').toLowerCase();
          final email = (u['email'] as String? ?? '').toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _searchByEmail(String email) async {
    if (!mounted) return;
    setState(() { _searching = true; _emailSearched = true; });

    final result = await _findByEmail(email);

    if (!mounted) return;
    result.fold(
      (_) => setState(() { _searching = false; _displayed = []; }),
      (user) {
        final filtered = user == null || user['id'] == _currentUserId
            ? <Map<String, dynamic>>[]
            : [user];
        setState(() { _searching = false; _displayed = filtered; });
      },
    );
  }

  Future<void> _startChat(Map<String, dynamic> otherUser) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    final result = await _createChat(auth.user.id, otherUser['id'] as String);
    result.fold(
      (_) {},
      (chat) {
        if (!mounted) return;
        context.push(AppRoutes.chatDetail, extra: {
          'chatId':   chat.id,
          'chatName': otherUser['name'] as String? ?? 'Chat',
          'userId':   auth.user.id,
          'userName': auth.user.name,
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _searchCtrl.text.trim();
    final isEmailMode = _emailRegex.hasMatch(query);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newChatTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Buscar por email o nombre...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _searchCtrl.clear,
                      )
                    : null,
              ),
            ),
          ),
          // Banner de estado de la conexión con Firestore
          if (!_loading)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _streamError != null
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(
                  _streamError != null
                      ? Icons.cloud_off_rounded
                      : Icons.cloud_done_rounded,
                  size: 14,
                  color: _streamError != null ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _streamError != null
                        ? 'Sin conexión con Firebase'
                        : 'Firebase conectado · ${_allUsers.length} usuario${_allUsers.length == 1 ? '' : 's'} encontrado${_allUsers.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _streamError != null ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
              ]),
            ),
          if (isEmailMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 14,
                    color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Búsqueda exacta por correo electrónico',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.primary),
                  ),
                ),
              ]),
            )
          else
            const SizedBox(height: 4),
          Expanded(child: _buildBody(l10n, query, isEmailMode)),
        ],
      ),
    );
  }

  Widget _buildBody(dynamic l10n, String query, bool isEmailMode) {
    if (_loading || _searching) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error del stream → mostrar con opción de reintentar
    if (_streamError != null && _allUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_streamError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                onPressed: () {
                  setState(() { _loading = true; _streamError = null; });
                  _usersSub?.cancel();
                  _subscribeUsers();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_displayed.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_rounded,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              isEmailMode && _emailSearched
                  ? 'No se encontró ningún usuario con ese correo electrónico.'
                  : query.isEmpty
                      ? l10n.noOtherUsers
                      : 'Sin resultados para "$query"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _displayed.length,
      itemBuilder: (_, i) {
        final u     = _displayed[i];
        final name  = u['name']  as String? ?? 'Usuario';
        final email = u['email'] as String? ?? '';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          title: Text(name),
          subtitle: Text(email,
              style: Theme.of(context).textTheme.bodySmall),
          trailing: const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.primary),
          onTap: () => _startChat(u),
        );
      },
    );
  }
}

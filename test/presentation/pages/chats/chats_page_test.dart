import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:travel_ready/domain/entities/chat.dart';
import 'package:travel_ready/domain/entities/user.dart';
import 'package:travel_ready/domain/repositories/chats_repository.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/bloc/auth/auth_bloc.dart';
import 'package:travel_ready/presentation/pages/chats/chats_page.dart';

import '../../../helpers/test_helper.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late MockChatsRepository chatsRepository;
  late _MockAuthBloc authBloc;

  setUpAll(() {
    dotenv.loadFromString(envString: '', isOptional: true);
  });

  setUp(() {
    registerFallbacks();
    chatsRepository = MockChatsRepository();
    authBloc = _MockAuthBloc();
  });

  tearDown(() async {
    if (getIt.isRegistered<ChatsRepository>()) {
      await getIt.unregister<ChatsRepository>();
    }
  });

  Future<void> pumpChats(
    WidgetTester tester, {
    String name = 'Ana Pérez',
    ChatType type = ChatType.private,
  }) async {
    when(() => authBloc.state).thenReturn(AuthAuthenticated(user: _user));
    when(() => chatsRepository.watchChats(any())).thenAnswer(
      (_) => Stream.value([
        ChatSummary(chatId: 'chat-1', type: type, name: name),
      ]),
    );
    if (getIt.isRegistered<ChatsRepository>()) {
      getIt.unregister<ChatsRepository>();
    }
    getIt.registerSingleton<ChatsRepository>(chatsRepository);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder avatarWith(String label) => find.descendant(
        of: find.byType(CircleAvatar),
        matching: find.text(label),
      );

  testWidgets('direct chat avatar handles repeated spaces', (tester) async {
    await pumpChats(tester, name: 'Ana  Pérez');

    expect(tester.takeException(), isNull);
    expect(avatarWith('AP'), findsOneWidget);
  });

  testWidgets('direct chat avatar handles a padded name', (tester) async {
    await pumpChats(tester, name: '  Ana  ');

    expect(tester.takeException(), isNull);
    expect(avatarWith('A'), findsOneWidget);
  });

  testWidgets('direct chat avatar handles a whitespace-only name',
      (tester) async {
    await pumpChats(tester, name: '   ');

    expect(tester.takeException(), isNull);
    expect(avatarWith('U'), findsOneWidget);
  });

  testWidgets('direct chat avatar handles tabs and newlines', (tester) async {
    await pumpChats(tester, name: '\tAna\tPérez\n');

    expect(tester.takeException(), isNull);
    expect(avatarWith('AP'), findsOneWidget);
  });

  testWidgets('empty chat name still renders safe initials',
      (tester) async {
    await pumpChats(tester, name: '');

    expect(tester.takeException(), isNull);
    expect(avatarWith('U'), findsOneWidget);
  });

  testWidgets('group chat shows the group icon instead of initials',
      (tester) async {
    await pumpChats(tester, name: 'Compañeros  de  piso', type: ChatType.group);

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.group_rounded), findsWidgets);
  });
}

final _user = User(
  id: 'u1',
  name: 'Test User',
  email: 't@t.com',
  createdAt: DateTime(2026),
);

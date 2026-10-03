import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/widgets/navigation/tr_bottom_nav.dart';

GoRouter _buildRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              TRBottomNav(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const Text('HOME_PAGE'),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (_, __) => const Text('DETAIL_PAGE'),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/bags',
                builder: (_, __) => const Text('BAGS_PAGE'),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/trips',
                builder: (_, __) => const Text('TRIPS_PAGE'),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/chats',
                builder: (_, __) => const Text('CHATS_PAGE'),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const Text('PROFILE_PAGE'),
              ),
            ]),
          ],
        ),
      ],
    );

Future<GoRouter> _pumpNav(WidgetTester tester) async {
  final router = _buildRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets(
      'every destination exposes its label, button role and selected state',
      (tester) async {
    await _pumpNav(tester);

    const labels = [
      'Inicio',
      'Mis maletas',
      'Mis viajes',
      'Mensajes',
      'Perfil',
    ];
    for (var i = 0; i < labels.length; i++) {
      final node = tester.getSemantics(find.bySemanticsLabel(labels[i]));
      expect(
        node,
        matchesSemantics(
          label: labels[i],
          isButton: true,
          hasSelectedState: true,
          isSelected: i == 0,
          hasTapAction: true,
        ),
        reason: 'destination "${labels[i]}"',
      );
    }
  });

  testWidgets('tapping a destination selects the expected branch',
      (tester) async {
    await _pumpNav(tester);

    expect(find.text('TRIPS_PAGE'), findsNothing);

    await tester.tap(find.text('Mis viajes'));
    await tester.pumpAndSettle();

    expect(find.text('TRIPS_PAGE'), findsOneWidget);
    expect(find.text('HOME_PAGE'), findsNothing);

    final node = tester.getSemantics(find.bySemanticsLabel('Mis viajes'));
    expect(
      node,
      matchesSemantics(
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('re-tapping the selected branch keeps initialLocation behavior',
      (tester) async {
    final router = await _pumpNav(tester);

    router.go('/home/detail');
    await tester.pumpAndSettle();
    expect(find.text('DETAIL_PAGE'), findsOneWidget);

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();

    expect(find.text('HOME_PAGE'), findsOneWidget);
    expect(find.text('DETAIL_PAGE'), findsNothing);
  });
}

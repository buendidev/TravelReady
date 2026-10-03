import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:travel_ready/domain/entities/user.dart';
import 'package:travel_ready/domain/repositories/trips_repository.dart';
import 'package:travel_ready/domain/usecases/trips/create_trip_usecase.dart';
import 'package:travel_ready/injection/injection.dart';
import 'package:travel_ready/l10n/app_localizations.dart';
import 'package:travel_ready/presentation/bloc/auth/auth_bloc.dart';
import 'package:travel_ready/presentation/pages/trips/trips_page.dart';

import '../../../helpers/fake_data.dart';
import '../../../helpers/test_helper.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

final _user = User(
  id: 'u1',
  name: 'Test User',
  email: 't@t.com',
  createdAt: DateTime(2026),
);

void main() {
  late MockTripsRepository repo;
  late _MockAuthBloc authBloc;

  setUp(() {
    registerFallbacks();
    repo = MockTripsRepository();
    authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthAuthenticated(user: _user));
    when(() => repo.watchTrips(any()))
        .thenAnswer((_) => Stream.value(Right([tTrip])));

    if (getIt.isRegistered<TripsRepository>()) {
      getIt.unregister<TripsRepository>();
    }
    if (getIt.isRegistered<CreateTripUseCase>()) {
      getIt.unregister<CreateTripUseCase>();
    }
    getIt.registerSingleton<TripsRepository>(repo);
    getIt.registerSingleton<CreateTripUseCase>(CreateTripUseCase(repo));
  });

  tearDown(() async {
    if (getIt.isRegistered<TripsRepository>()) {
      await getIt.unregister<TripsRepository>();
    }
    if (getIt.isRegistered<CreateTripUseCase>()) {
      await getIt.unregister<CreateTripUseCase>();
    }
  });

  Future<void> pumpTrips(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TripsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('add-trip and trip-row actions expose accessible tooltips',
      (tester) async {
    await pumpTrips(tester);

    expect(find.text('Viaje a París'), findsOneWidget);
    // AppBar add button + FAB, both open the new-trip sheet.
    expect(find.byTooltip('Nuevo viaje'), findsNWidgets(2));
    // Per-row delete action.
    expect(find.byTooltip('Eliminar viaje'), findsOneWidget);
  });

  testWidgets('add and delete actions keep their callbacks', (tester) async {
    await pumpTrips(tester);

    await tester.tap(find.byTooltip('Nuevo viaje').last);
    await tester.pumpAndSettle();
    expect(find.text('Nombre del viaje'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eliminar viaje'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Viaje a París'), findsWidgets);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Viaje a París'), findsOneWidget);
  });
}

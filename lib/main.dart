import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/services/chat_notification_manager.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/env_validator.dart';
import 'injection/injection.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/language/language_cubit.dart';
import 'presentation/bloc/theme/theme_cubit.dart';
import 'presentation/bloc/trips/trips_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cargar .env UNA sola vez
  await dotenv.load(fileName: '.env');
  EnvValidator.validate(dotenv.env);

  await initializeDateFormatting('es', null);
  await initializeDateFormatting('en', null);

  print('[main] Inicializando Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('[main] Firebase inicializado correctamente');

  await setupDependencies();
  await initDatabase();
  await NotificationService().init();

  runApp(const TravelReadyApp());
}

class TravelReadyApp extends StatelessWidget {
  const TravelReadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => getIt<ThemeCubit>()),
        BlocProvider<LanguageCubit>(create: (_) => getIt<LanguageCubit>()),
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
        ),
      ],
      child: const _RouterShell(),
    );
  }
}

class _RouterShell extends StatefulWidget {
  const _RouterShell();
  @override
  State<_RouterShell> createState() => _RouterShellState();
}

class _RouterShellState extends State<_RouterShell> {
  late final _router = buildAppRouter(context.read<AuthBloc>());

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (_, themeMode) => BlocBuilder<LanguageCubit, Locale>(
        builder: (_, locale) => MaterialApp.router(
          title: 'TravelReady!',
          debugShowCheckedModeBanner: false,
          theme:      AppTheme.light,
          darkTheme:  AppTheme.dark,
          themeMode:  themeMode,
          routerConfig: _router,
          locale: locale,
          supportedLocales: LanguageCubit.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (_, child) => BlocListener<AuthBloc, AuthState>(
            listener: (ctx, authState) {
              if (authState is AuthAuthenticated) {
                _TripNotificationListener.maybeStart(ctx, authState.user.id);
                ChatNotificationManager().start(
                  repo:   getIt(),
                  userId: authState.user.id,
                );
              } else if (authState is AuthUnauthenticated) {
                ChatNotificationManager().stop();
                _TripNotificationListener.reset();
              }
            },
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// Lanza notificaciones locales para viajes próximos (≤7 días).
/// Se llama una vez al autenticarse; no monta un widget permanente.
abstract final class _TripNotificationListener {
  static bool _started = false;

  static void reset() => _started = false;

  static void maybeStart(BuildContext context, String userId) {
    if (_started) return;
    _started = true;

    final tripsBloc = TripsBloc(
      createTripUseCase: getIt(),
      repo: getIt(),
    )..add(TripsLoaded(userId: userId));

    tripsBloc.stream.listen((state) {
      if (state is! TripsReady) return;
      final now = DateTime.now();
      for (final trip in state.trips) {
        final daysLeft = trip.startDate.difference(now).inDays;
        if (daysLeft >= 0 && daysLeft <= 7) {
          NotificationService().showTripReminder(
            tripName:    trip.name,
            destination: trip.destination,
            daysLeft:    daysLeft,
          );
        }
      }
      // Solo notifica una vez al arranque
      tripsBloc.close();
    });
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../core/database/database_helper.dart';
import '../core/network/connectivity_checker.dart';
import '../core/services/places/demo_places_gateway.dart';
import '../core/services/places/places_gateway.dart';
import '../data/datasources/local/itinerary/itinerary_local_datasource.dart';
import '../data/datasources/local/trips_local_datasource.dart';
import '../data/datasources/local/weather_cache_datasource.dart';
import '../data/datasources/remote/firebase_auth_datasource.dart';
import '../data/datasources/remote/firestore_chats_datasource.dart';
import '../data/datasources/remote/weather_service.dart';
import '../data/repositories/chats_repository_impl.dart';
import '../data/repositories/itinerary_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/trips_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/chats_repository.dart';
import '../domain/repositories/itinerary_repository.dart';
import '../domain/repositories/trips_repository.dart';
import '../domain/usecases/auth/sign_in_usecase.dart';
import '../domain/usecases/chats/create_private_chat_usecase.dart';
import '../domain/usecases/chats/create_group_chat_usecase.dart';
import '../domain/usecases/chats/find_user_by_email_usecase.dart';
import '../domain/usecases/auth/sign_up_usecase.dart';
import '../domain/usecases/auth/sign_out_usecase.dart';
import '../domain/usecases/itinerary/add_itinerary_item_usecase.dart';
import '../domain/usecases/itinerary/delete_itinerary_item_usecase.dart';
import '../domain/usecases/itinerary/get_itinerary_items_usecase.dart';
import '../domain/usecases/itinerary/reorder_itinerary_items_usecase.dart';
import '../domain/usecases/itinerary/update_itinerary_item_usecase.dart';
import '../domain/usecases/trips/create_trip_usecase.dart';
import '../domain/usecases/trips/get_trips_usecase.dart';
import '../presentation/bloc/auth/auth_bloc.dart';
import '../presentation/bloc/chats/chats_bloc.dart';
import '../presentation/bloc/itinerary/itinerary_bloc.dart';
import '../presentation/bloc/language/language_cubit.dart';
import '../presentation/bloc/packing/packing_bloc.dart';
import '../presentation/bloc/theme/theme_cubit.dart';
import '../presentation/bloc/trips/trips_bloc.dart';
import '../presentation/bloc/weather/weather_bloc.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // ── Core ──────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<ConnectivityChecker>(
      () => ConnectivityChecker(connectivity: getIt()));
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  getIt.registerLazySingleton<LanguageCubit>(() => LanguageCubit());

  // ── Database (SQLite) ─────────────────────────────────────────────────
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  // ── HTTP ──────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // ── Datasources ────────────────────────────────────────────────────────
  getIt.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSource(),
  );
  getIt.registerLazySingleton<TripsLocalDataSource>(
    () => TripsLocalDataSource(database: getIt()),
  );
  getIt.registerLazySingleton<WeatherCacheDataSource>(
    () => WeatherCacheDataSource(openDatabase: () => getIt<DatabaseHelper>().database),
  );
  getIt.registerLazySingleton<ItineraryLocalDataSource>(
    () => ItineraryLocalDataSource(
        openDatabase: () => getIt<DatabaseHelper>().database),
  );
  getIt.registerLazySingleton<FirestoreChatsDataSource>(
    () => FirestoreChatsDataSource(),
  );
  getIt.registerLazySingleton<WeatherService>(
      () => WeatherService(client: getIt()));

  // ── Places gateway ────────────────────────────────────────────────────
  // Fixtures locales (modo demo etiquetado en UI) hasta que el owner
  // configure un proveedor real. Nunca hay claves ni credenciales aquí.
  getIt.registerLazySingleton<PlacesGateway>(
      () => const DemoPlacesGateway());

  // ── Repositories ───────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remote: getIt()));
  getIt.registerLazySingleton<TripsRepository>(
      () => TripsRepositoryImpl(local: getIt()));
  getIt.registerLazySingleton<PackingRepository>(
      () => PackingRepositoryImpl(local: getIt()));
  getIt.registerLazySingleton<ChatsRepository>(
      () => ChatsRepositoryImpl(remote: getIt()));
  getIt.registerLazySingleton<ItineraryRepository>(
      () => ItineraryRepositoryImpl(local: getIt()));

  // ── UseCases ───────────────────────────────────────────────────────────
  getIt.registerLazySingleton(() => SignInUseCase(getIt()));
  getIt.registerLazySingleton(() => SignUpUseCase(getIt()));
  getIt.registerLazySingleton(() => SignOutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTripsUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateTripUseCase(getIt()));
  getIt.registerLazySingleton(() => CreatePrivateChatUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateGroupChatUseCase(getIt()));
  getIt.registerLazySingleton(() => FindUserByEmailUseCase(getIt()));
  getIt.registerLazySingleton(() => GetItineraryItemsUseCase(getIt()));
  getIt.registerLazySingleton(() => AddItineraryItemUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateItineraryItemUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteItineraryItemUseCase(getIt()));
  getIt.registerLazySingleton(() => ReorderItineraryItemsUseCase(getIt()));

  // ── BLoCs ─────────────────────────────────────────────────────────────
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      signInUseCase:  getIt(),
      signUpUseCase:  getIt(),
      signOutUseCase: getIt(),
      authRepository: getIt(),
    ),
  );
  getIt.registerFactory<TripsBloc>(
    () => TripsBloc(
      createTripUseCase: getIt(),
      repo:              getIt(),
    ),
  );
  getIt.registerFactory<PackingBloc>(() => PackingBloc(repo: getIt()));
  getIt.registerFactory<WeatherBloc>(
      () => WeatherBloc(service: getIt(), cache: getIt()));
  getIt.registerFactory<ChatsBloc>(() => ChatsBloc(repo: getIt()));
  getIt.registerFactory<ItineraryBloc>(() => ItineraryBloc(repo: getIt()));
  // ChatDetailBloc se instancia directamente en ChatDetailPage (requiere currentUserId y chatName)
}

/// Inicializa la base de datos SQLite.
Future<void> initDatabase() async {
  // El DatabaseHelper se inicializa lazy, pero forzamos la creación
  await getIt<DatabaseHelper>().database;
}

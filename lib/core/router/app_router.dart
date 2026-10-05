import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/trip.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/reset_password_page.dart';
import '../../presentation/pages/chats/chat_detail_page.dart';
import '../../presentation/pages/chats/chats_page.dart';
import '../../presentation/pages/chats/create_group_page.dart';
import '../../presentation/pages/chats/users_page.dart';
import '../../presentation/pages/discovery/discovery_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/itinerary/itinerary_page.dart';
import '../../presentation/pages/packing/packing_detail_page.dart';
import '../../presentation/pages/packing/packing_lists_page.dart';
import '../../presentation/pages/premium/premium_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/trips/trip_detail_page.dart';
import '../../presentation/pages/trips/trips_page.dart';
import '../../presentation/widgets/navigation/tr_bottom_nav.dart';

abstract final class AppRoutes {
  static const splash        = '/';
  static const login         = '/login';
  static const register      = '/register';
  static const resetPassword = '/reset-password';
  static const home          = '/home';
  static const packingLists  = '/packing-lists';
  static const trips         = '/trips';
  static const chats         = '/chats';
  static const chatDetail    = '/chat-detail';
  static const profile       = '/profile';
  static const users         = '/users';
  static const createGroup   = '/create-group';
  static const premium       = '/premium';

  static String packingDetailPath(String listId) => '/packing-lists/$listId';
  static String tripDetailPath(String tripId)    => '/trips/$tripId';
  static String itineraryPath(String tripId)     => '/trips/$tripId/itinerary';
  static String discoveryPath(String tripId)     => '/trips/$tripId/discovery';

  static const _protected = [home, packingLists, trips, chats, profile, premium];
  static const _authOnly  = [login, register, resetPassword];

  static bool isProtected(String loc) =>
      _protected.any((r) => loc.startsWith(r));
  static bool isAuthOnly(String loc) =>
      _authOnly.any((r) => loc.startsWith(r));
}

GoRouter buildAppRouter(AuthBloc authBloc) {
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthNotifier(authBloc),

    redirect: (context, state) {
      final auth = authBloc.state;
      final loc  = state.matchedLocation;
      if (loc == AppRoutes.splash) return null;
      final isAuth    = auth is AuthAuthenticated;
      final isPending = auth is AuthInitial || auth is AuthLoading;
      if (isPending) {
        // No sacar del login/register durante carga para que el BlocListener
        // de RegisterPage pueda recibir AuthRegistered y navegar a login.
        if (AppRoutes.isAuthOnly(loc)) return null;
        return AppRoutes.splash;
      }
      // AuthRegistered → no redirigir (RegisterPage ya navega a /login)
      if (auth is AuthRegistered) return null;
      // Si estamos en /login o /register y llega AuthUnauthenticated, no hacer nada
      if (auth is AuthUnauthenticated && AppRoutes.isAuthOnly(loc)) return null;
      if (!isAuth && AppRoutes.isProtected(loc)) return AppRoutes.login;
      if (isAuth && AppRoutes.isAuthOnly(loc))   return AppRoutes.home;
      return null;
    },

    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => BlocListener<AuthBloc, AuthState>(
          listener: (ctx, s) {
            if (s is AuthAuthenticated)   ctx.go(AppRoutes.home);
            if (s is AuthUnauthenticated) ctx.go(AppRoutes.login);
            if (s is AuthRegistered)      ctx.go(AppRoutes.login, extra: s.email);
          },
          child: const _SplashScreen(),
        ),
      ),

      // Auth — login acepta email prellenado en extra
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) => LoginPage(
          prefillEmail: state.extra as String?,
        ),
      ),
      GoRoute(path: AppRoutes.register,
          builder: (_, __) => const RegisterPage()),
      GoRoute(path: AppRoutes.resetPassword,
          builder: (_, __) => const ResetPasswordPage()),

      // Shell
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => TRBottomNav(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home,
                builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.packingLists,
              builder: (_, __) => const PackingListsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) => PackingDetailPage(
                    listId: s.pathParameters['id'] ?? '',
                    tripId: s.extra as String? ?? '',
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.trips,
              builder: (_, __) => const TripsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, s) {
                    final trip = s.extra as Trip?;
                    if (trip == null) {
                      return const Scaffold(
                          body: Center(child: Text('Viaje no encontrado')));
                    }
                    return TripDetailPage(trip: trip);
                  },
                  routes: [
                    GoRoute(
                      path: 'itinerary',
                      builder: (_, s) {
                        final trip = s.extra as Trip?;
                        if (trip == null) {
                          return const Scaffold(
                              body: Center(
                                  child: Text('Viaje no encontrado')));
                        }
                        return ItineraryPage(trip: trip);
                      },
                    ),
                    GoRoute(
                      path: 'discovery',
                      builder: (_, s) {
                        final trip = s.extra as Trip?;
                        if (trip == null) {
                          return const Scaffold(
                              body: Center(
                                  child: Text('Viaje no encontrado')));
                        }
                        return DiscoveryPage(trip: trip);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.chats,
                builder: (_, __) => const ChatsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile,
                builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),

      // Chat detail — fuera del shell
      GoRoute(
        parentNavigatorKey: rootKey,
        path: AppRoutes.chatDetail,
        builder: (_, s) {
          final e = s.extra as Map<String, dynamic>? ?? {};
          return ChatDetailPage(
            chatId:   e['chatId']   as String? ?? '',
            chatName: e['chatName'] as String? ?? 'Chat',
            userId:   e['userId']   as String? ?? '',
            userName: e['userName'] as String? ?? '',
          );
        },
      ),

      // Nuevo chat (lista de usuarios)
      GoRoute(
        parentNavigatorKey: rootKey,
        path: AppRoutes.users,
        builder: (_, __) => const UsersPage(),
      ),

      // Crear grupo
      GoRoute(
        parentNavigatorKey: rootKey,
        path: AppRoutes.createGroup,
        builder: (_, __) => const CreateGroupPage(),
      ),

      // Premium
      GoRoute(
        parentNavigatorKey: rootKey,
        path: AppRoutes.premium,
        pageBuilder: (_, __) => const MaterialPage(
            fullscreenDialog: true, child: PremiumPage()),
      ),
    ],

    errorBuilder: (ctx, __) => Scaffold(
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 56),
          const SizedBox(height: 16),
          Text('Página no encontrada',
              style: Theme.of(ctx).textTheme.headlineMedium),
          TextButton(
            onPressed: () => ctx.go(AppRoutes.home),
            child: const Text('Ir al inicio')),
        ],
      )),
    ),
  );
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthBloc bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF006571),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(
                color: const Color(0xFF006571).withOpacity(0.35),
                blurRadius: 32, offset: const Offset(0, 12))],
          ),
          child: const Icon(Icons.luggage_rounded,
              color: Colors.white, size: 52),
        ),
        const SizedBox(height: 24),
        Text('TravelReady!',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: const Color(0xFF006571),
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Tu viaje, perfectamente preparado.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 64),
        const SizedBox(width: 24, height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Color(0xFF006571))),
      ],
    )),
  );
}

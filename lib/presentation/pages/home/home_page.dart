import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/app_env.dart';
import '../../../data/models/weather_model.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/entities/user.dart';
import '../../../injection/injection.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/trips/trips_bloc.dart';
import '../../bloc/weather/weather_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      builder: (context, authState) {
        final user   = authState is AuthAuthenticated ? authState.user : null;
        final userId = user?.id ?? '';
        return MultiBlocProvider(
          providers: [
            BlocProvider<TripsBloc>(
              create: (_) => TripsBloc(
                createTripUseCase: getIt(),
                repo:              getIt(),
              )..add(TripsLoaded(userId: userId)),
            ),
            // WeatherBloc — solo si hay API key
            if (AppEnv.hasWeatherKey)
              BlocProvider<WeatherBloc>(
                create: (_) => WeatherBloc(service: getIt(), cache: getIt()),
              ),
          ],
          child: _HomeContent(user: user),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  final User? user;
  const _HomeContent({this.user});

  String _greeting(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 13) return l10n.greetingMorning;
    if (h < 20) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final firstName = user?.name.split(' ').first ?? 'viajero';
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<TripsBloc, TripsState>(
          // Solo reconstruye cuando cambia la lista de viajes
          buildWhen: (p, c) => p != c,
          builder: (context, tripsState) {
            final trips    = tripsState is TripsReady ? tripsState.trips : <Trip>[];
            final upcoming = trips.where((t) => t.startDate.isAfter(DateTime.now())).toList();
            final active   = trips.where((t) =>
                t.startDate.isBefore(DateTime.now()) &&
                t.endDate.isAfter(DateTime.now())).toList();
            final prioritizedTrip = active.isNotEmpty
                ? active.first
                : upcoming.isNotEmpty
                    ? upcoming.reduce((first, next) =>
                        first.startDate.isBefore(next.startDate) ? first : next)
                    : null;

            return CustomScrollView(
              // RepaintBoundary implícita en CustomScrollView
              slivers: [
                // ── Header ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.screenPaddingH, AppSizes.lg,
                        AppSizes.screenPaddingH, AppSizes.md),
                    child: Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_greeting(l10n)}, $firstName! 👋',
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            active.isNotEmpty
                                ? l10n.tripActive
                                : upcoming.isNotEmpty
                                    ? l10n.tripUpcoming(upcoming.length)
                                    : l10n.tripReady,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ],
                      )),
                      Semantics(
                        label: l10n.profile,
                        button: true,
                        onTap: () => context.go(AppRoutes.profile),
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.profile),
                          child: user?.photoUrl != null
                              ? CircleAvatar(radius: 22,
                                  backgroundImage: NetworkImage(user!.photoUrl!))
                              : CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: Text(_initials(user?.name ?? 'U'),
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ),
                        ),
                      ),
                    ]),
                  ),
                ),

                // ── Viaje prioritario ───────────────────────────────────
                if (prioritizedTrip != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.screenPaddingH),
                      child: _ContextualTripCard(
                        trip: prioritizedTrip,
                        isActive: active.isNotEmpty,
                      ),
                    ),
                  ),

                if (prioritizedTrip != null)
                  const SliverToBoxAdapter(child: SizedBox(height: AppSizes.md)),

                // ── Weather card (destino del viaje prioritario) ──────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPaddingH),
                    child: AppEnv.hasWeatherKey
                        ? _WeatherCard(city: prioritizedTrip?.destination)
                        : _WeatherPlaceholder(),
                  ),
                ),

                if (!isPremium) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: AppSizes.md)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.screenPaddingH),
                      child: _PremiumBanner(
                          onTap: () => context.push(AppRoutes.premium)),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: AppSizes.lg)),

                // ── Stats ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPaddingH),
                    child: Row(children: [
                      _StatChip(label: l10n.statsTrips, value: '${trips.length}',
                          icon: Icons.flight_rounded),
                      const SizedBox(width: AppSizes.sm),
                      _StatChip(label: l10n.statsUpcoming, value: '${upcoming.length}',
                          icon: Icons.event_rounded),
                      const SizedBox(width: AppSizes.sm),
                      _StatChip(label: l10n.statsActive, value: '${active.length}',
                          icon: Icons.luggage_rounded,
                          highlight: active.isNotEmpty),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSizes.lg)),

                // ── Acciones rápidas ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPaddingH),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.quickAccess,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSizes.md),
                        Row(children: [
                          Expanded(child: _QuickAction(
                            icon: Icons.add_rounded, label: l10n.newBagQuick,
                            color: AppColors.primary,
                            onTap: () => context.go(AppRoutes.packingLists))),
                          const SizedBox(width: AppSizes.md),
                          Expanded(child: _QuickAction(
                            icon: Icons.flight_takeoff_rounded, label: l10n.newTripQuick,
                            color: const Color(0xFF0E9AA7),
                            onTap: () => context.go(AppRoutes.trips))),
                          const SizedBox(width: AppSizes.md),
                          Expanded(child: _QuickAction(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: l10n.assistantQuick,
                            color: const Color(0xFF7C4DFF),
                            onTap: () => context.go(AppRoutes.chats))),
                        ]),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSizes.lg)),

                // ── Viajes recientes ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPaddingH),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.recentTrips,
                            style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.trips),
                          child: Text(l10n.seeAll)),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSizes.sm)),

                if (tripsState is TripsLoading)
                  const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2.5))))
                else if (trips.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.screenPaddingH),
                      child: _EmptyTrips(
                          onTap: () => context.go(AppRoutes.trips))))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPaddingH),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => RepaintBoundary(
                          child: _TripSummaryCard(
                            trip: trips[i],
                            onTap: () => context.push(
                              AppRoutes.tripDetailPath(trips[i].id),
                              extra: trips[i],
                            ),
                          ),
                        ),
                        childCount: trips.take(3).length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSizes.xxxl)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── WeatherCard real ──────────────────────────────────────────────────────────

class _WeatherCard extends StatefulWidget {
  final String? city;
  const _WeatherCard({this.city});
  @override State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final city = widget.city ?? 'Madrid';
    _ctrl = TextEditingController(text: city);
    context.read<WeatherBloc>().add(WeatherFetchByCity(city));
  }

  @override
  void didUpdateWidget(covariant _WeatherCard old) {
    super.didUpdateWidget(old);
    if (widget.city != null && widget.city != old.city) {
      _ctrl.text = widget.city!;
      context.read<WeatherBloc>().add(WeatherFetchByCity(widget.city!));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) => switch (state) {
        WeatherLoading() => _WeatherSkeleton(),
        WeatherLoaded(:final weather, :final isStale, :final retrievedAt) => WeatherDataCard(
          weather: weather,
          isStale: isStale,
          retrievedAt: retrievedAt,
          onRefresh: (city) =>
              context.read<WeatherBloc>().add(WeatherFetchByCity(city)),
        ),
        WeatherError(:final message) => _WeatherError(
          message: message,
          onRetry: () => context.read<WeatherBloc>()
              .add(WeatherFetchByCity(widget.city ?? 'Madrid')),
        ),
        _ => _WeatherPlaceholder(),
      },
    );
  }
}

class WeatherDataCard extends StatelessWidget {
  final WeatherModel weather;
  final bool isStale;
  final DateTime retrievedAt;
  final DateTime? currentTime;
  final ValueChanged<String> onRefresh;

  const WeatherDataCard({
    super.key,
    required this.weather,
    required this.isStale,
    required this.retrievedAt,
    required this.onRefresh,
    this.currentTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ageMinutes = (currentTime ?? DateTime.now())
        .difference(retrievedAt)
        .inMinutes
        .clamp(0, 1 << 31)
        .toInt();
    return GestureDetector(
      onTap: () => _showCitySearch(context),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: AppSizes.shadowBlur,
              offset: const Offset(0, AppSizes.shadowOffset))],
        ),
        child: Row(children: [
          Text(weather.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: AppSizes.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${weather.city}, ${weather.country}',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 15)),
              Text(weather.descriptionCapitalized,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13)),
              if (isStale)
                Text(l10n.weatherStaleAge(ageMinutes),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11)),
              const SizedBox(height: 4),
              Text('💧 ${weather.humidity}%   💨 ${weather.windSpeed.toStringAsFixed(1)} m/s',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(weather.tempDisplay,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 28)),
            Text('ST: ${weather.feelsLikeDisplay}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11)),
          ]),
        ]),
      ),
    );
  }

  void _showCitySearch(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.searchCity),
        content: TextField(
          controller: ctrl, autofocus: true,
          decoration: InputDecoration(hintText: l10n.cityHint),
          textInputAction: TextInputAction.search,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) onRefresh(v.trim());
            Navigator.pop(d);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) onRefresh(ctrl.text.trim());
              Navigator.pop(d);
            },
            child: Text(l10n.search),
          ),
        ],
      ),
    );
  }
}

class _WeatherSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 88,
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
    child: Row(children: [
      Container(width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle)),
      const SizedBox(width: AppSizes.md),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ]),
    ]),
  );
}

class _WeatherError extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _WeatherError({this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
    child: Row(children: [
      const Icon(Icons.cloud_off_rounded, color: AppColors.primary, size: 36),
      const SizedBox(width: AppSizes.md),
      Expanded(child: Text(message ?? l10n.weatherNotAvailable,
          style: Theme.of(context).textTheme.bodySmall)),
      TextButton(onPressed: onRetry, child: Text(l10n.retry)),
    ]),
  );
  }
}

class _WeatherPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
    child: Row(children: [
      const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 48),
      const SizedBox(width: AppSizes.md),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.weather, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 15)),
          Text(l10n.weatherSetup,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11)),
        ],
      )),
    ]),
  );
  }
}

// ── Resto de widgets (sin cambios pero con RepaintBoundary) ───────────────────

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumBanner({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0B3D45), Color(0xFF006571)]),
        borderRadius: BorderRadius.circular(AppSizes.radiusDefault)),
      child: Row(children: [
        const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD4A017), size: 22),
        const SizedBox(width: AppSizes.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.goPremiumTitle, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 14)),
          Text(l10n.premiumDesc,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
      ]),
    ),
  );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool highlight;
  const _StatChip({required this.label, required this.value,
      required this.icon, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withValues(alpha: 0.12)
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
        border: highlight ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null),
      child: Column(children: [
        Icon(icon, color: highlight ? AppColors.primary : AppColors.textSecondaryLight,
            size: 20),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: highlight ? AppColors.primary : null,
            fontWeight: FontWeight.w700)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ]),
    ));
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md, horizontal: AppSizes.sm),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault)),
      child: Column(children: [
        Icon(icon, color: color, size: AppSizes.iconLg),
        const SizedBox(height: AppSizes.xs),
        Text(label, style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _TripSummaryCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const _TripSummaryCard({required this.trip, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final l10n     = AppLocalizations.of(context);
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final isActive = trip.startDate.isBefore(DateTime.now()) &&
        trip.endDate.isAfter(DateTime.now());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.md),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: AppSizes.shadowBlur,
              offset: const Offset(0, AppSizes.shadowOffset))]),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(isActive ? Icons.flight_rounded : Icons.flight_takeoff_rounded,
                color: isActive ? Colors.white : AppColors.primary, size: 22)),
          const SizedBox(width: AppSizes.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(trip.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
                  child: Text(l10n.inProgress, style: const TextStyle(color: AppColors.success,
                      fontSize: 10, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 3),
            Text(trip.destination, style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('${trip.durationDays} ${l10n.days} · ${trip.progress}% ${l10n.progress}',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.primary)),
          ])),
          const Icon(Icons.chevron_right_rounded, size: 20,
              color: AppColors.textSecondaryLight),
        ]),
      ),
    );
  }
}

// ── Próximo viaje destacado ────────────────────────────────────────────────────

class _ContextualTripCard extends StatelessWidget {
  final Trip trip;
  final bool isActive;
  const _ContextualTripCard({required this.trip, required this.isActive});

  int get _daysLeft {
    final now = DateTime.now();
    final start = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return start.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final days = _daysLeft;
    return Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: AppSizes.shadowBlur,
              offset: const Offset(0, AppSizes.shadowOffset))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
              child: Text(
                isActive
                    ? l10n.inProgress
                    : days == 0
                        ? l10n.todayTrip
                        : days == 1
                            ? l10n.dayLeft
                            : l10n.daysLeft(days),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Icon(isActive ? Icons.flight_rounded : Icons.flight_takeoff_rounded,
                color: Colors.white, size: 20),
          ]),
          const SizedBox(height: AppSizes.md),
          Text(trip.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(trip.destination,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: AppSizes.md),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.luggagePrep,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  child: LinearProgressIndicator(
                    value: trip.progress / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: AppSizes.md),
            Text('${trip.progress}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(
                AppRoutes.tripDetailPath(trip.id),
                extra: trip,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.luggagePrep),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ]),
      );
  }
}

class _EmptyTrips extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyTrips({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
            blurRadius: AppSizes.shadowBlur,
            offset: const Offset(0, AppSizes.shadowOffset))]),
      child: Column(children: [
        Icon(Icons.flight_outlined, size: 56,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        const SizedBox(height: AppSizes.md),
        Text(l10n.noTripsYet, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSizes.xs),
        Text(l10n.noTripsHint,
            style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: AppSizes.lg),
        ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.createTripBtn),
          style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44))),
      ]),
    );
  }
}

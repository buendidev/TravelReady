import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/name_display.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../injection/injection.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/language/language_cubit.dart';
import '../../bloc/packing/packing_bloc.dart';
import '../../bloc/theme/theme_cubit.dart';
import '../../bloc/trips/trips_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_text_field.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (_, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        return MultiBlocProvider(
          providers: [
            BlocProvider<TripsBloc>(
              create: (_) => TripsBloc(
                createTripUseCase: getIt(),
                repo:              getIt(),
              )..add(TripsLoaded(userId: user?.id ?? '')),
            ),
            BlocProvider<PackingBloc>(
              create: (_) => PackingBloc(repo: getIt())
                ..add(PackingListsLoaded(tripId: user?.id ?? '')),
            ),
          ],
          child: _ProfileContent(user: user),
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final User? user;
  const _ProfileContent({this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverAppBar(
            title: Text(l10n.myProfile,
                style: Theme.of(context).textTheme.headlineMedium),
            pinned: true,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.screenPaddingH),
              child: Column(children: [

                // ── Avatar ──────────────────────────────────────────────
                GestureDetector(
                  onTap: () => _showEditProfile(context),
                  child: Stack(alignment: Alignment.bottomRight, children: [
                    user?.photoUrl != null
                        ? CircleAvatar(
                            radius: 44,
                            backgroundImage: NetworkImage(user!.photoUrl!))
                        : CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            child: Text(nameInitials(user?.name ?? ''),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: AppColors.primary))),
                    Container(
                      width: 26, height: 26,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ]),
                ),

                const SizedBox(height: AppSizes.md),
                Text(user?.name ?? l10n.userDefault,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight)),
                const SizedBox(height: AppSizes.sm),

                // Plan badge
                _PlanBadge(isPremium: isPremium),

                const SizedBox(height: AppSizes.xl),

                // ── Stats reales ──────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: BlocBuilder<TripsBloc, TripsState>(
                      builder: (_, s) => _StatCard(
                        label: l10n.statsTrips,
                        value: s is TripsReady ? '${s.trips.length}' : '–',
                        icon: Icons.flight_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: BlocBuilder<PackingBloc, PackingState>(
                      builder: (_, s) => _StatCard(
                        label: l10n.packingLists,
                        value: s is PackingListsReady ? '${s.lists.length}' : '–',
                        icon: Icons.luggage_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: BlocBuilder<PackingBloc, PackingState>(
                      builder: (_, s) {
                        int packed = 0;
                        if (s is PackingListsReady) {
                          for (final l in s.lists) packed += l.packedItems;
                        }
                        return _StatCard(
                          label: '${l10n.itemPacked} ✓',
                          value: s is PackingListsReady ? '$packed' : '–',
                          icon: Icons.checklist_rounded,
                        );
                      },
                    ),
                  ),
                ]),

                const SizedBox(height: AppSizes.xl),

                // ── Menú ──────────────────────────────────────────────
                if (!isPremium)
                  _MenuItem(
                    icon: Icons.workspace_premium_rounded,
                    label: '✨ ${l10n.goPremium}',
                    onTap: () => context.push(AppRoutes.premium),
                    highlight: true,
                  ),

                _MenuItem(
                  icon: isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  label: isDark ? l10n.lightMode : l10n.darkMode,
                  onTap: () => context.read<ThemeCubit>().toggleTheme(),
                ),

                BlocBuilder<LanguageCubit, Locale>(
                  builder: (context, locale) {
                    final isSpanish = locale.languageCode == 'es';
                    return _MenuItem(
                      icon: Icons.language_rounded,
                      label: isSpanish
                          ? '🇪🇸 ${l10n.spanish}'
                          : '🇬🇧 ${l10n.english}',
                      onTap: () => context.read<LanguageCubit>().toggle(),
                    );
                  },
                ),

                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: l10n.editProfile,
                  onTap: () => _showEditProfile(context),
                ),

                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: l10n.notifications,
                  onTap: () => _snackComingSoon(context, l10n.notifications),
                ),

                _MenuItem(
                  icon: Icons.support_agent_rounded,
                  label: l10n.support,
                  onTap: () => context.push(AppRoutes.chatDetail, extra: {
                    'chatId':   '__support__',
                    'chatName': l10n.supportChatTitle,
                    'userId':   user?.id ?? '',
                    'userName': user?.name ?? '',
                  }),
                ),

                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: l10n.aiAssistant,
                  onTap: () => context.push(AppRoutes.chatDetail, extra: {
                    'chatId':   '__ai_assistant__',
                    'chatName': l10n.assistantChatTitle,
                    'userId':   user?.id ?? '',
                    'userName': user?.name ?? '',
                  }),
                ),

                const SizedBox(height: AppSizes.md),
                const Divider(),
                const SizedBox(height: AppSizes.sm),

                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: l10n.logout,
                  onTap: () => _confirmLogout(context, l10n),
                  isDestructive: true,
                ),

                const SizedBox(height: AppSizes.xl),
                Text('TravelReady! v1.0 · TravelReady 2026',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryLight)),
                const SizedBox(height: AppSizes.md),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutConfirm),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(d);
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: Text(l10n.logout,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    final l10n     = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            AppSizes.screenPaddingH, AppSizes.md,
            AppSizes.screenPaddingH,
            MediaQuery.of(ctx).viewInsets.bottom + AppSizes.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: AppSizes.md),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
          )),
          Text(l10n.editProfile,
              style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: AppSizes.lg),
          TRTextField(
            label: l10n.name,
            controller: nameCtrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSizes.lg),
          TRButton(
            label: l10n.saveChanges,
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await getIt<AuthRepository>().signUp(
                  name: name, email: '', password: '');
              } catch (_) {}
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.profileUpdated),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
        ]),
      ),
    );
  }

  void _snackComingSoon(BuildContext context, String feature) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — ${l10n.comingSoon}'),
      behavior: SnackBarBehavior.floating));
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  final bool isPremium;
  const _PlanBadge({required this.isPremium});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
    padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md, vertical: 6),
    decoration: BoxDecoration(
      color: isPremium
          ? const Color(0xFFD4A017).withValues(alpha: 0.15)
          : AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        isPremium
            ? Icons.workspace_premium_rounded
            : Icons.person_outline_rounded,
        size: 16,
        color: isPremium ? const Color(0xFFD4A017) : AppColors.primary,
      ),
      const SizedBox(width: 4),
      Text(
        isPremium ? l10n.premiumPlan : l10n.freePlan,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isPremium
              ? const Color(0xFFD4A017) : AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ]),
  );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md, horizontal: AppSizes.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: AppColors.primary)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight, isDestructive;
  const _MenuItem({
    required this.icon, required this.label, required this.onTap,
    this.highlight = false, this.isDestructive = false,
  });
  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : highlight ? AppColors.primary : null;
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: highlight ? FontWeight.w600 : null)),
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right_rounded, size: 20,
              color: AppColors.textSecondaryLight),
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault)),
    );
  }
}

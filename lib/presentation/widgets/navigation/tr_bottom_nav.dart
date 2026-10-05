import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../l10n/app_localizations.dart';

class TRBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const TRBottomNav({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final unselColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final items = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, l10n.home),
      _NavItem(
          Icons.luggage_outlined, Icons.luggage_rounded, l10n.packingLists),
      _NavItem(Icons.flight_outlined, Icons.flight_rounded, l10n.myTrips),
      _NavItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded,
          l10n.chats),
      _NavItem(
          Icons.person_outline_rounded, Icons.person_rounded, l10n.profile),
    ];

    return Scaffold(
      // Sin extendBody: el cuerpo de cada tab termina donde empieza la barra.
      // Con extendBody el cuerpo llega hasta el borde de la pantalla y todo lo
      // que una página ancle abajo —los FloatingActionButton, por ejemplo—
      // queda dibujado detrás de la barra y el usuario no puede tocarlo. No se
      // puede compensar con MediaQuery: Scaffold coloca el FAB con
      // viewInsets.bottom, no con el padding.
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: _GlassNav(
        isDark: isDark,
        selectedIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: items,
        selColor: selColor,
        unselColor: unselColor,
      ),
    );
  }
}

class _GlassNav extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;
  final Color selColor, unselColor;

  const _GlassNav({
    required this.isDark,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    required this.selColor,
    required this.unselColor,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: AppSizes.bottomNavHeight + bottomPad,
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassDark : AppColors.glassLight,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.glassBorderDark
                    : AppColors.glassBorderLight,
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: Row(
              children: List.generate(items.length, (i) {
                final sel = i == selectedIndex;
                return Expanded(
                  child: Semantics(
                    label: items[i].label,
                    button: true,
                    selected: sel,
                    onTap: () => onTap(i),
                    excludeSemantics: true,
                    child: GestureDetector(
                      // GestureDetector en vez de InkWell — sin ripple que cause flash
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: SizedBox(
                        height: AppSizes.bottomNavHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Línea indicadora animada
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              width: sel ? 32 : 0,
                              height: 3,
                              decoration: BoxDecoration(
                                color: selColor,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Icono — sin AnimatedSwitcher para evitar rebuild innecesario
                            Icon(
                              sel ? items[i].activeIcon : items[i].icon,
                              size: AppSizes.iconMd,
                              color: sel ? selColor : unselColor,
                            ),
                            const SizedBox(height: 3),
                            // Label
                            Text(
                              items[i].label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? selColor : unselColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

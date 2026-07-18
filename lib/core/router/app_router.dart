import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/home_dashboard_screen.dart';
import '../../features/scan/magic_scan_screen.dart';
import '../../features/closet/closet_hub_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/discover/ai_discover_screen.dart';
import '../../features/stylist/ai_stylist_chat_screen.dart';
import '../../features/pack/packing_planner_screen.dart';
import '../../features/pack/screens/trip_calendar_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/profile/screens/app_settings_screen.dart';
import '../../features/profile/screens/style_preferences_screen.dart';
import '../../features/profile/screens/wardrobe_insights_screen.dart';
import '../../features/profile/screens/notifications_settings_screen.dart';
import '../../features/profile/screens/beta_plan_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const AnimatedBranchContainer({super.key, required this.currentIndex, required this.children});

  @override
  State<AnimatedBranchContainer> createState() => _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this, 
    duration: const Duration(milliseconds: 300),
  );
  
  @override
  void initState() {
    super.initState();
    _controller.value = 1.0;
  }
  
  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0), 
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: IndexedStack(
        index: widget.currentIndex,
        children: widget.children,
      ),
    );
  }
}

class BreathingFab extends StatefulWidget {
  final VoidCallback onTap;
  
  const BreathingFab({super.key, required this.onTap});

  @override
  State<BreathingFab> createState() => _BreathingFabState();
}

class _BreathingFabState extends State<BreathingFab> with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        final scale = 1.0 + (_breatheController.value * 0.03); // 1.0 to 1.03 scale
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(
            LucideIcons.scan, 
            color: Theme.of(context).colorScheme.surface,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/auth',
    refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isGoingToAuth = state.matchedLocation == '/auth';
      
      if ((session == null || session.isExpired) && !isGoingToAuth) {
        return '/auth';
      }
      
      if (session != null && !session.isExpired && isGoingToAuth) {
        return '/home';
      }
      
      return null;
    },
    routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    StatefulShellRoute(
      builder: (context, state, navigationShell) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              navigationShell,
              
              // Floating Navigation Bar
              Positioned(
                left: 16,
                right: 16,
                bottom: 24 + bottomPadding,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B1B).withValues(alpha: 0.7), // AppColors.card
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AnimatedNavItem(
                        context: context,
                        navigationShell: navigationShell,
                        index: 0,
                        icon: LucideIcons.home,
                        activeIcon: LucideIcons.home,
                        label: 'Home',
                      ),
                      _AnimatedNavItem(
                        context: context,
                        navigationShell: navigationShell,
                        index: 1,
                        icon: LucideIcons.sparkles,
                        activeIcon: LucideIcons.sparkles,
                        label: 'Stylist',
                      ),
                      const SizedBox(width: 64), // Space for center FAB
                      _AnimatedNavItem(
                        context: context,
                        navigationShell: navigationShell,
                        index: 2,
                        icon: LucideIcons.archive, // The mockup uses an archive-like or layout icon, let's use archive for Wardrobe
                        activeIcon: LucideIcons.archive,
                        label: 'Wardrobe',
                      ),
                      _AnimatedNavItem(
                        context: context,
                        navigationShell: navigationShell,
                        index: 3,
                        icon: LucideIcons.user,
                        activeIcon: LucideIcons.user,
                        label: 'Profile',
                        isAvatar: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
              
              // Center FAB
              Positioned(
                left: 0,
                right: 0,
                bottom: 24 + bottomPadding + 16, // Protrudes slightly above the 64px bar
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      context.push('/magic-scan');
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7FF2F), // Primary
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD7FF2F).withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(LucideIcons.plus, color: Colors.black, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      navigatorContainerBuilder: (context, navigationShell, children) {
        return AnimatedBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) {
                debugPrint('Entering Home');
                return const HomeDashboardScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stylist',
              builder: (context, state) {
                debugPrint('Entering Stylist');
                return const AiStylistChatScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/closet',
              builder: (context, state) {
                debugPrint('Entering Wardrobe');
                return const ClosetHubScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) {
                debugPrint('Entering Profile');
                return const ProfileScreen();
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/magic-scan',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) {
        debugPrint('Entering Scan');
        return CustomTransitionPage(
          key: state.pageKey,
          child: const MagicScanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      );
    },
  ),
    GoRoute(
      path: '/discover',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AiDiscoverScreen(),
    ),
    GoRoute(
      path: '/pack',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const TripPlannerScreen(),
      routes: [
        GoRoute(
          path: 'trip/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TripCalendarScreen(tripId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/app',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const AppSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/style',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const StylePreferencesScreen(),
    ),
    GoRoute(
      path: '/settings/insights',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const WardrobeInsightsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/beta',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const BetaPlanScreen(),
    ),
  ],
);
});

class _AnimatedNavItem extends StatelessWidget {
  final BuildContext context;
  final StatefulNavigationShell navigationShell;
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isAvatar;

  const _AnimatedNavItem({
    required this.context,
    required this.navigationShell,
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = navigationShell.currentIndex == index;
    final theme = Theme.of(context);
    final avatarUrl = Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'] as String?;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 64,
          color: Colors.transparent, // hit area
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAvatar && avatarUrl != null)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    width: 1.5,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? theme.colorScheme.primary : const Color(0xFFBDBDBD),
                size: 24,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.colorScheme.primary : const Color(0xFFBDBDBD),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/notifiers/auth_notifier.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/exercises/presentation/pages/exercise_play_page.dart';
import '../../features/exercises/presentation/pages/exercises_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import 'route_names.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/achievements/presentation/pages/achievements_page.dart';
import '../../features/parent/presentation/pages/parent_dashboard_page.dart';

/// Shell scaffold with bottom navigation for main app sections.
class _MainShellScaffold extends StatelessWidget {
  const _MainShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate_rounded),
            label: 'Exercise',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provides the configured [GoRouter] instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splashPath,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnSplash = state.matchedLocation == RouteNames.splashPath;
      final isOnAuth =
          state.matchedLocation == RouteNames.loginPath ||
          state.matchedLocation == RouteNames.registerPath;

      // Don't redirect while on splash (it handles its own navigation)
      if (isOnSplash) return null;

      // If loading auth state, don't redirect
      if (authState.isLoading) return null;

      // Not logged in → redirect to login
      if (!isLoggedIn && !isOnAuth) {
        return RouteNames.loginPath;
      }

      // Logged in but on auth pages → redirect to home
      if (isLoggedIn && isOnAuth) {
        return RouteNames.homePath;
      }

      return null;
    },
    routes: [
      // ─── Splash ─────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // ─── Auth Routes ────────────────────────────────────────────
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),

      // ─── Main Shell (Bottom Navigation) ─────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Home branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.homePath,
                name: RouteNames.home,
                builder: (context, state) =>
                    const HomePage(),
              ),
            ],
          ),

          // Exercise branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.exercisePath,
                name: RouteNames.exercise,
                builder: (context, state) =>
                    const ExercisesPage(),
                routes: [
                  GoRoute(
                    path: ':topic/:difficulty',
                    name: RouteNames.exerciseTopic,
                    builder: (context, state) {
                      final topic = state.pathParameters['topic'] ?? 'general';
                      final difficulty = state.pathParameters['difficulty'] ?? 'easy';
                      return ExercisePlayPage(
                        topic: topic,
                        difficulty: difficulty,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Progress branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.progressPath,
                name: RouteNames.progress,
                builder: (context, state) =>
                    const ProgressPage(),
              ),
            ],
          ),

          // Profile branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profilePath,
                name: RouteNames.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // ─── Standalone Routes ──────────────────────────────────────
      GoRoute(
        path: RouteNames.achievementsPath,
        name: RouteNames.achievements,
        builder: (context, state) =>
            const AchievementsPage(),
      ),
      GoRoute(
        path: RouteNames.settingsPath,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteNames.parentDashboardPath,
        name: RouteNames.parentDashboard,
        builder: (context, state) =>
            const ParentDashboardPage(),
      ),
    ],

    // ─── Error Page ───────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like this page went on an adventure!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.homePath),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

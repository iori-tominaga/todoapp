import 'package:go_router/go_router.dart';

import '../features/auth/account_register_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/character/character_screen.dart';
import '../features/groups/group_create_screen.dart';
import '../features/groups/group_list_screen.dart';
import '../features/groups/group_settings_screen.dart';
import '../features/legal/legal_screen.dart';
import '../features/mytasks/mytasks_screen.dart';
import '../features/settings/profile_edit_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/tasks/task_edit_screen.dart';
import '../features/tasks/tasks_screen.dart';
import 'scaffold_with_nav_bar.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/tasks',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/groups',
      builder: (context, state) => const GroupListScreen(),
    ),
    GoRoute(
      path: '/groups/create',
      builder: (context, state) => const GroupCreateScreen(),
    ),
    GoRoute(
      path: '/groups/settings',
      builder: (context, state) => const GroupSettingsScreen(),
    ),
    GoRoute(
      path: '/tasks/add',
      builder: (context, state) => const TaskEditScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileEditScreen(),
    ),
    GoRoute(
      path: '/account/register',
      builder: (context, state) => const AccountRegisterScreen(),
    ),
    GoRoute(
      path: '/legal',
      builder: (context, state) => const LegalScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TasksScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mytasks',
              builder: (context, state) => const MyTasksScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/character',
              builder: (context, state) => const CharacterScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

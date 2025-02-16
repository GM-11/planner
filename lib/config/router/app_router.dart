import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:planner/features/journals/presentation/journal_editor_screen.dart';
import 'package:planner/features/journals/presentation/journals_screen.dart';
import 'package:planner/features/profile/presentation/profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart'
    show CalendarScreen;
import '../../features/tasks/presentation/tasks_screen.dart' show TasksScreen;
import '../../shared/models/journal.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.uri.toString() == '/login' ||
          state.uri.toString() == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/register';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/calendar';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) => '/tasks',
            builder:
                (context, state) =>
                    const SizedBox(), // This won't be used due to redirect
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/journals',
            builder: (context, state) => const JournalsScreen(),
          ),
          GoRoute(
            path: '/journals/new',
            builder: (context, state) => const JournalEditorScreen(),
          ),
          GoRoute(
            path: '/journals/:id',
            builder: (context, state) {
              final journal = state.extra as Journal?;
              return JournalEditorScreen(journal: journal);
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithBottomNavBar extends StatelessWidget {
  const ScaffoldWithBottomNavBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF4C1D95),
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Ionicons.checkbox_outline),
            activeIcon: Icon(Ionicons.checkbox),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.calendar_outline),
            activeIcon: Icon(Ionicons.calendar),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.book_outline),
            activeIcon: Icon(Ionicons.book),
            label: 'Journals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Ionicons.person_outline),
            activeIcon: Icon(Ionicons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/tasks')) return 0;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/journals')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/tasks');
        break;
      case 1:
        GoRouter.of(context).go('/calendar');
        break;
      case 2:
        GoRouter.of(context).go('/journals');
        break;
      case 3:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}

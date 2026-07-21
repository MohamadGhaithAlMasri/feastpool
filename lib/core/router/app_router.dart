import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/employee/presentation/screens/employee_shell.dart';
import '../../features/employee/presentation/screens/menu_screen.dart';
import '../../features/finance/presentation/screens/ledger_screen.dart';
import '../../features/employee/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_shell.dart';
import '../../features/admin/presentation/screens/admin_dashboard.dart';
import '../../features/admin/presentation/screens/admin_clearances.dart';
import '../../features/admin/presentation/screens/admin_meals_screen.dart';
import '../../features/admin/presentation/screens/add_person_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _employeeShellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _adminShellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    // Employee Navigation Shell
    ShellRoute(
      navigatorKey: _employeeShellNavigatorKey,
      builder: (context, state, child) {
        return EmployeeShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/employee/menu',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MenuScreen(),
          ),
        ),
        GoRoute(
          path: '/employee/ledger',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LedgerScreen(),
          ),
        ),
        GoRoute(
          path: '/employee/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
    // Admin Navigation Shell
    ShellRoute(
      navigatorKey: _adminShellNavigatorKey,
      builder: (context, state, child) {
        return AdminShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminDashboard(),
          ),
        ),
        GoRoute(
          path: '/admin/meals',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminMealsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/menu',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MenuScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/clearances',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminClearances(),
          ),
        ),
        GoRoute(
          path: '/admin/add-person',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AddPersonScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/profile',
          pageBuilder: (context, state) => NoTransitionPage(
            child: ProfileScreen(isAdmin: true),
          ),
        ),
      ],
    ),
  ],
);

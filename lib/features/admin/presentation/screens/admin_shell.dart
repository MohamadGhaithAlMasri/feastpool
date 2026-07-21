import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  @override
  void initState() {
    super.initState();
    // Initialize push notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authRepo = RepositoryProvider.of<AuthRepository>(context);
        PushNotificationService(authRepo).initializeAndRegister();
      }
    });
  }

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/admin/dashboard')) return 0;
    if (location.startsWith('/admin/meals')) return 1;
    if (location.startsWith('/admin/menu')) return 2;
    if (location.startsWith('/admin/clearances')) return 3;
    if (location.startsWith('/admin/profile')) return 4;
    return 0; // Default to Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/meals');
        break;
      case 2:
        context.go('/admin/menu');
        break;
      case 3:
        context.go('/admin/clearances');
        break;
      case 4:
        context.go('/admin/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          backgroundColor: AppColors.background,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTheme.monoStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
          unselectedLabelStyle: AppTheme.monoStyle(fontSize: 10, color: AppColors.textSecondary),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.layoutGrid, size: 20),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.chefHat, size: 20),
              label: 'Meals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant, size: 20),
              label: 'Order',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.fileSignature, size: 20),
              label: 'Ledger',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user, size: 20),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

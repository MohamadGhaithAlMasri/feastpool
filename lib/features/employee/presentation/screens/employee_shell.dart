import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/active_order_bloc.dart';
import '../widgets/active_order_sheet.dart';

class EmployeeShell extends StatefulWidget {
  final Widget child;

  const EmployeeShell({super.key, required this.child});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  StreamSubscription? _notificationSubscription;

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

    // Listen to real-time notifications in Supabase
    try {
      _notificationSubscription = Supabase.instance.client
          .from('in_app_notifications')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .listen((data) {
            if (data.isNotEmpty) {
              final notification = data.first;
              final createdAtStr = notification['created_at'];
              if (createdAtStr != null) {
                final createdAt = DateTime.parse(createdAtStr).toLocal();
                // Only show notifications created in the last 15 seconds to avoid backlog on launch
                if (DateTime.now().difference(createdAt).inSeconds.abs() < 15) {
                  final title = notification['title'] ?? 'FeastPool Update';
                  final body = notification['body'] ?? '';
                  _showNotificationBanner(title, body);
                }
              }
            }
          });
    } catch (_) {
      // Fallback if RLS or tables do not exist
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _showNotificationBanner(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              body,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int _getSelectedIndex(BuildContext context, bool isAdmin) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/employee/menu')) return 0;
    if (isAdmin) {
      if (location.startsWith('/employee/ledger')) return 2;
      if (location.startsWith('/employee/profile')) return 3;
      return 1; // Home index when Admin
    } else {
      if (location.startsWith('/employee/ledger')) return 1;
      if (location.startsWith('/employee/profile')) return 2;
    }
    return 0; // Default to Menu
  }

  void _onItemTapped(int index, BuildContext context, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0:
          context.go('/employee/menu');
          break;
        case 1:
          context.go('/employee/menu'); // Home maps to menu for now
          break;
        case 2:
          context.go('/employee/ledger');
          break;
        case 3:
          context.go('/employee/profile');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/employee/menu');
          break;
        case 1:
          context.go('/employee/ledger');
          break;
        case 2:
          context.go('/employee/profile');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final bool isAdmin =
        authState is Authenticated && authState.user.role == UserRole.admin;
    final selectedIndex = _getSelectedIndex(context, isAdmin);

    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          BlocBuilder<ActiveOrderBloc, ActiveOrderState>(
            builder: (context, state) {
              final activeOrder = state.activeOrder;
              if (activeOrder == null || state.status == ActiveOrderStatus.loading) {
                return const SizedBox.shrink();
              }

              final Map<String, int> items = Map<String, int>.from(
                activeOrder['items'] as Map? ?? {},
              );
              if (items.isEmpty) return const SizedBox.shrink();

              final shortDescription = items.entries
                  .map((e) => "${e.value}x ${e.key}")
                  .join(', ');

              return Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (context) =>
                          ActiveOrderSheet(activeOrder: activeOrder),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.shoppingBag,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Current Order (Tap to view/edit)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                shortDescription,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context, isAdmin),
          backgroundColor: AppColors.background,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTheme.monoStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          unselectedLabelStyle: AppTheme.monoStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.restaurant, size: 20),
              label: 'Menu',
            ),
            if (isAdmin)
              const BottomNavigationBarItem(
                icon: Icon(LucideIcons.layoutGrid, size: 20),
                label: 'Home',
              ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.wallet, size: 20),
              label: 'Ledger',
            ),
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.user, size: 20),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

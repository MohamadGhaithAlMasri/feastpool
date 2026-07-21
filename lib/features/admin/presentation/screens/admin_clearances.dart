import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user.dart';
import '../bloc/clearance_bloc.dart';

class AdminClearances extends StatefulWidget {
  const AdminClearances({super.key});

  @override
  State<AdminClearances> createState() => _AdminClearancesState();
}

class _AdminClearancesState extends State<AdminClearances> {
  @override
  void initState() {
    super.initState();
    context.read<ClearanceBloc>().add(ClearanceLoadRequested());
  }

  void _clearBalance(UserModel user) {
    context.read<ClearanceBloc>().add(ClearanceApproved(user.id, user.ledgerBalance));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت تسوية حساب ${user.name} بنجاح.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clearanceState = context.watch<ClearanceBloc>().state;
    final outstandingUsers = clearanceState.outstandingUsers;
    final isLoading = clearanceState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'FeastPool',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.bell, color: AppColors.textPrimary),
                        onPressed: () {},
                      ),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.surface,
                        child: Icon(LucideIcons.user, color: AppColors.primary, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Section titles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADMIN CONSOLE',
                        style: AppTheme.monoStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Outstanding Balances',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${outstandingUsers.length} PEOPLE',
                      style: AppTheme.monoStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Requests list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<ClearanceBloc>().add(ClearanceLoadRequested());
                },
                color: AppColors.primary,
                child: isLoading && outstandingUsers.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : outstandingUsers.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.6,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.checkSquare, size: 48, color: AppColors.textSecondary),
                                  const SizedBox(height: 12),
                                  Text(
                                    'جميع الحسابات تمت تسويتها!',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: outstandingUsers.length,
                            itemBuilder: (context, index) {
                              final user = outstandingUsers[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.cardBg,
                                          backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                              ? NetworkImage(user.avatarUrl!)
                                              : null,
                                          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                              ? const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 20)
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name,
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                user.department,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${user.ledgerBalance.toStringAsFixed(0)} ل.س',
                                              style: AppTheme.monoStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accentYellow,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Due',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _clearBalance(user),
                                            icon: const Icon(LucideIcons.check, size: 16),
                                            label: const Text('تم الدفع (تصفير الحساب)'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

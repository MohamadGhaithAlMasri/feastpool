import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/session_bloc.dart';
import '../bloc/distribution_bloc.dart';
import '../../domain/entities/distribution_item.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../employee/domain/repositories/menu_repository.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _showStartSessionDialog(BuildContext context) async {
    final menuRepo = context.read<MenuRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final sessionBloc = context.read<SessionBloc>();

    List<String> categories = ['All'];
    try {
      final meals = await menuRepo.getMeals();
      final uniqueCategories = meals.map((m) => m.category).toSet().toList();
      categories.addAll(uniqueCategories);
    } catch (_) {}

    if (!context.mounted) return;

    final selectedCategories = <String>{};
    int selectedDurationMinutes = 15;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Configure Order Session',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Category selector chips
                    Text(
                      'TARGET MEAL CATEGORY',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = cat == 'All'
                            ? selectedCategories.isEmpty
                            : selectedCategories.contains(cat);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.cardBg,
                          checkmarkColor: Colors.white,
                          showCheckmark: isSelected && cat != 'All',
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              if (cat == 'All') {
                                selectedCategories.clear();
                              } else {
                                if (selected) {
                                  selectedCategories.add(cat);
                                } else {
                                  selectedCategories.remove(cat);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Duration selector
                    Text(
                      'SESSION DURATION',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [10, 15, 30, 45, 60].map((mins) {
                        final isSelected = selectedDurationMinutes == mins;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? AppColors.primary : AppColors.cardBg,
                                foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  selectedDurationMinutes = mins;
                                });
                              },
                              child: Text('${mins}m', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final durationSecs = selectedDurationMinutes * 60;
                        final categoryParam = selectedCategories.isEmpty
                            ? null
                            : selectedCategories.join(', ');
                        sessionBloc.add(
                          SessionStarted(
                            durationSecs,
                            category: categoryParam,
                          ),
                        );
                        Navigator.pop(sheetContext);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              categoryParam == null
                                  ? 'Started session for All Categories ($selectedDurationMinutes mins)!'
                                  : 'Started session for category "$categoryParam" ($selectedDurationMinutes mins)!',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      child: const Text('Start Session Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<SessionBloc>().state;
    final secondsRemaining = sessionState.secondsRemaining;
    final isSessionActive = sessionState.isActive;

    final distributionState = context.watch<DistributionBloc>().state;
    final distributionList = distributionState.items;

    final Map<String, int> aggregatedItems = {};
    for (var dist in distributionList) {
      for (var entry in dist.items.entries) {
        aggregatedItems[entry.key] = (aggregatedItems[entry.key] ?? 0) + entry.value;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<SessionBloc>().add(SessionLoadRequested());
            context.read<DistributionBloc>().add(DistributionLoadRequested());
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FeastPool',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
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
              const SizedBox(height: 24),

              // Admin Aggregation Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Admin Aggregation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Coordinate team orders and manage distribution logistics efficiently.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isSessionActive) {
                          context.read<SessionBloc>().add(SessionStopped());
                        } else {
                          _showStartSessionDialog(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSessionActive ? AppColors.danger.withValues(alpha: 0.2) : AppColors.primary,
                        foregroundColor: isSessionActive ? AppColors.danger : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSessionActive ? AppColors.danger : AppColors.primary,
                            width: 2.0,
                          ),
                        ),
                      ),
                      icon: Icon(
                        isSessionActive ? LucideIcons.stopCircle : LucideIcons.clock,
                        size: 20,
                      ),
                      label: Text(
                        isSessionActive
                            ? 'Stop Order Session (${sessionState.category ?? 'All'}) (${secondsRemaining ~/ 60}:${(secondsRemaining % 60).toString().padLeft(2, '0')})'
                            : 'Start Order Session',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!isSessionActive) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await context.read<AdminRepository>().markFoodArrived();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Food marked as arrived! Everyone notified.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.checkSquare, size: 20),
                        label: const Text('Mark Food as Arrived', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showResetConfirmationDialog(context),
                        icon: const Icon(LucideIcons.trash2, size: 20, color: AppColors.danger),
                        label: const Text('Reset Daily Orders', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Order Summary Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aggregated',
                      style: AppTheme.monoStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Aggregated orders list
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (aggregatedItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'No orders placed yet in this session.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ...aggregatedItems.entries.map((entry) {
                        final isLast = entry.key == aggregatedItems.keys.last;
                        return Column(
                          children: [
                            _buildSummaryItem(
                              context,
                              icon: Icons.restaurant,
                              title: '${entry.value}x ${entry.key}',
                              subtitle: 'Ordered by Team',
                            ),
                            if (!isLast) const Divider(color: AppColors.border, height: 24),
                          ],
                        );
                      }),
                    const Divider(color: AppColors.border, height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'POOLED PROGRESS',
                              style: AppTheme.monoStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isSessionActive ? 'ACTIVE' : 'CLOSED',
                              style: AppTheme.monoStyle(fontSize: 10, color: isSessionActive ? AppColors.primary : AppColors.accentYellow, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 6,
                            child: LinearProgressIndicator(
                              value: isSessionActive ? (secondsRemaining / 900.0) : 0.0,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(isSessionActive ? AppColors.primary : AppColors.accentYellow),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Distribution List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Distribution List',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.slidersHorizontal, size: 18, color: AppColors.textSecondary),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Distribution cards list
              ...distributionList.map((dist) => _buildDistributionCard(context, dist)),

              const SizedBox(height: 16),

              // Add Person Button
              OutlinedButton.icon(
                onPressed: () {
                  context.push('/admin/add-person');
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Person'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, style: BorderStyle.solid),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
     ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionCard(BuildContext context, DistributionItem dist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.cardBg,
                    backgroundImage: dist.avatarUrl != null && dist.avatarUrl!.isNotEmpty
                        ? NetworkImage(dist.avatarUrl!)
                        : null,
                    child: dist.avatarUrl == null || dist.avatarUrl!.isEmpty
                        ? const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dist.room,
                        style: AppTheme.monoStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dist.userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.moreVertical, size: 18, color: AppColors.textSecondary),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...dist.items.entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      entry.key.contains('Falafel') ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                      color: entry.key.contains('Falafel') ? AppColors.accentYellow : AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}x ${entry.key}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          title: const Text(
            'Reset Daily Orders',
            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to reset all daily orders and clear the distribution list? This action cannot be undone.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await context.read<AdminRepository>().resetDailyOrders();
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Daily orders reset successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}



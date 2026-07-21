import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_uploader.dart';
import '../../../admin/presentation/bloc/session_bloc.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../finance/presentation/bloc/ledger_bloc.dart';

class ProfileScreen extends StatefulWidget {
  final bool isAdmin;
  const ProfileScreen({super.key, this.isAdmin = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploadingAvatar = false;

  Future<void> _updateProfilePicture() async {
    setState(() {
      _isUploadingAvatar = true;
    });
    try {
      final url = await ImageUploader.uploadImage(
        bucketName: 'avatars',
        pathPrefix: 'profiles',
      );
      if (url != null && mounted) {
        await context.read<AuthRepository>().updateAvatar(url);
        if (mounted) {
          context.read<AuthBloc>().add(AuthCheckRequested());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile picture: $e\nMake sure the public bucket "avatars" exists in Supabase Storage.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final departmentController = TextEditingController(text: user.department);
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
            'Edit Profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: departmentController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Department',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final dept = departmentController.text.trim();
                if (name.isNotEmpty && dept.isNotEmpty) {
                  await context.read<AuthRepository>().updateProfile(
                    name: name,
                    department: dept,
                  );
                  if (context.mounted) {
                    context.read<AuthBloc>().add(AuthCheckRequested());
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchOrderHistory() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final res = await client
          .from('ledger_transactions')
          .select()
          .eq('profile_id', userId)
          .eq('type', 'Lunch Pool')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<int> _fetchMealsOrderedCount() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return 0;
    try {
      final res = await client
          .from('ledger_transactions')
          .select('id')
          .eq('profile_id', userId)
          .eq('type', 'Lunch Pool');
      return res.length;
    } catch (_) {
      return 0;
    }
  }

  String _formatIsoDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Just now';
    }
  }

  Future<void> _deleteOrder(BuildContext context, Map<String, dynamic> order) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final orderId = order['id'];
    final amount = (order['amount'] as num).toDouble();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Update transaction status to CANCELLED
      await client.from('ledger_transactions').update({'status': 'CANCELLED'}).eq('id', orderId);

      // 2. Fetch profile and update
      final profile = await client.from('profiles').select().eq('id', userId).single();
      final currentBalance = (profile['ledger_balance'] as num?)?.toDouble() ?? 0.0;
      final currentMeals = (profile['meals_ordered'] as int?) ?? 0;

      await client.from('profiles').update({
        'ledger_balance': (currentBalance - amount).clamp(0.0, double.infinity),
        'meals_ordered': (currentMeals - 1).clamp(0, double.infinity),
      }).eq('id', userId);

      if (context.mounted) {
        context.read<AuthBloc>().add(AuthCheckRequested());
        context.read<LedgerBloc>().add(LedgerLoadRequested());
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showOrderHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final sessionState = BlocProvider.of<SessionBloc>(context).state;
            final bool isSessionActive = sessionState.isActive;

            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              title: const Text(
                'Order History',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchOrderHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      );
                    }
                    final orders = snapshot.data ?? [];
                    if (orders.isEmpty) {
                      return const Center(
                        child: Text(
                          'No orders placed yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final title = order['title'] ?? 'Meal Order';
                        final amount = (order['amount'] as num).toDouble();
                        final status = order['status'] ?? 'UNPAID';
                        final dateStr = order['created_at'] != null
                            ? _formatIsoDate(order['created_at'])
                            : 'Just now';

                        final bool canCancel = status == 'UNPAID' && isSessionActive;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${amount.toStringAsFixed(0)} SYP',
                                        style: AppTheme.monoStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status == 'SETTLED'
                                              ? AppColors.success.withValues(alpha: 0.2)
                                              : (status == 'CANCELLED'
                                                  ? AppColors.textSecondary.withValues(alpha: 0.2)
                                                  : AppColors.accentYellow.withValues(
                                                      alpha: 0.2,
                                                    )),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status,
                                          style: AppTheme.monoStyle(
                                            fontSize: 9,
                                            color: status == 'SETTLED'
                                                ? AppColors.success
                                                : (status == 'CANCELLED'
                                                    ? AppColors.textSecondary
                                                    : AppColors.accentYellow),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (canCancel) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        color: AppColors.danger,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (confirmContext) => AlertDialog(
                                            backgroundColor: AppColors.cardBg,
                                            title: const Text('Cancel Order', style: TextStyle(color: AppColors.textPrimary)),
                                            content: const Text('Are you sure you want to cancel this order?', style: TextStyle(color: AppColors.textSecondary)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(confirmContext, false),
                                                child: const Text('No', style: TextStyle(color: AppColors.textSecondary)),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(confirmContext, true),
                                                child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.danger)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true && dialogContext.mounted) {
                                          await _deleteOrder(dialogContext, order);
                                          if (dialogContext.mounted) {
                                            setStateDialog(() {});
                                          }
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.primary, size: 20),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 15),
          ),
          trailing: trailingText != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trailingText,
                    style: AppTheme.monoStyle(
                      fontSize: 10,
                      color: AppColors.accentYellow,
                    ),
                  ),
                )
              : const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    UserModel? user;
    if (authState is Authenticated) {
      user = authState.user;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                  const Icon(LucideIcons.wallet, color: AppColors.textPrimary),
                ],
              ),
              const SizedBox(height: 24),

              // Avatar and info
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _updateProfilePicture,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  user?.avatarUrl != null &&
                                      user!.avatarUrl!.isNotEmpty
                                  ? NetworkImage(user.avatarUrl!)
                                  : const NetworkImage(
                                          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                                        )
                                        as ImageProvider,
                              child: _isUploadingAvatar
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.edit2,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Ahmed Khalid',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.department ?? 'عام',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: user == null
                          ? null
                          : () => _showEditProfileDialog(context, user!),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'EDIT PROFILE',
                        style: AppTheme.monoStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEDGER BALANCE',
                            style: AppTheme.monoStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(user?.ledgerBalance ?? 0.0).toStringAsFixed(0)} SYP',
                            style: AppTheme.monoStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEALS ORDERED',
                            style: AppTheme.monoStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              FutureBuilder<int>(
                                future: _fetchMealsOrderedCount(),
                                builder: (context, snapshot) {
                                  final count = snapshot.data ?? 0;
                                  return Text(
                                    '$count ',
                                    style: AppTheme.monoStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                              const Icon(
                                Icons.restaurant,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Settings Sections
              // Settings Sections
              Text(
                'HISTORY',
                style: AppTheme.monoStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildListTile(
                context,
                icon: LucideIcons.history,
                title: 'Order History',
                onTap: () => _showOrderHistoryDialog(context),
              ),
              _buildListTile(
                context,
                icon: LucideIcons.fileText,
                title: 'Transaction Ledger',
                onTap: () {
                  if (widget.isAdmin) {
                    context.go('/admin/clearances');
                  } else {
                    context.go('/employee/ledger');
                  }
                },
              ),
              const SizedBox(height: 32),

              // Logout Button
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  context.go('/login');
                },
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
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
    );
  }
}

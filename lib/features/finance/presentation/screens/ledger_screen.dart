import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/ledger_bloc.dart';
import '../../domain/entities/ledger_transaction.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isMono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: isMono
                  ? AppTheme.monoStyle(
                      fontSize: 14,
                      color: valueColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    )
                  : TextStyle(
                      color: valueColor ?? AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, LedgerTransaction tx) {
    final isNegative = tx.amount < 0;
    final displayAmount = isNegative
        ? '${tx.amount.abs().toStringAsFixed(0)} SYP'
        : '${tx.amount.toStringAsFixed(0)} SYP';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تفاصيل العملية',
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('العنوان / الوجبات', tx.title),
                    const Divider(color: AppColors.border),
                    _buildDetailRow('نوع العملية', tx.type),
                    const Divider(color: AppColors.border),
                    _buildDetailRow('التاريخ والوقت', tx.date),
                    const Divider(color: AppColors.border),
                    _buildDetailRow(
                      'الحالة',
                      tx.status == 'UNPAID' ? 'غير مدفوع' : 'تمت التسوية',
                      valueColor: tx.status == 'UNPAID'
                          ? AppColors.primary
                          : AppColors.success,
                    ),
                    const Divider(color: AppColors.border),
                    _buildDetailRow(
                      'المبلغ',
                      displayAmount,
                      valueColor: isNegative
                          ? AppColors.accentYellow
                          : AppColors.textPrimary,
                    ),
                    const Divider(color: AppColors.border),
                    _buildDetailRow('رقم العملية (ID)', tx.id, isMono: true),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHistoryDialog(
    BuildContext context,
    List<LedgerTransaction> transactions,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سجل العمليات بالكامل',
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isNegative = tx.amount < 0;
                          final displayAmount = isNegative
                              ? '(${tx.amount.abs().toStringAsFixed(0)} SYP)'
                              : '${tx.amount.toStringAsFixed(0)} SYP';

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _showTransactionDetails(sheetContext, tx);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isNegative
                                          ? LucideIcons.wallet
                                          : Icons.restaurant,
                                      color: isNegative
                                          ? AppColors.accentYellow
                                          : AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tx.date,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        displayAmount,
                                        style: AppTheme.monoStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isNegative
                                              ? AppColors.accentYellow
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tx.status,
                                        style: AppTheme.monoStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: tx.status == 'UNPAID'
                                              ? AppColors.primary
                                              : AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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
    final authState = context.watch<AuthBloc>().state;
    UserModel? user;
    if (authState is Authenticated) {
      user = authState.user;
    }

    final ledgerState = context.watch<LedgerBloc>().state;
    final transactions = ledgerState.transactions;
    final double outstandingBalance = user?.ledgerBalance ?? 0.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
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
                        child: const Icon(
                          LucideIcons.wallet,
                          color: AppColors.primary,
                          size: 20,
                        ),
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
                  IconButton(
                    icon: const Icon(
                      LucideIcons.bell,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Ledger Outstanding Balance Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'OUTSTANDING BALANCE',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${outstandingBalance.toStringAsFixed(0)} SYP',
                      style: AppTheme.monoStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Due for reconciliation by Oct 31',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),



            const SizedBox(height: 24),

            // Transaction History Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showHistoryDialog(context, transactions),
                    child: Text(
                      'VIEW HISTORY',
                      style: AppTheme.monoStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transactions list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<AuthBloc>().add(AuthCheckRequested());
                  context.read<LedgerBloc>().add(LedgerLoadRequested());
                },
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isNegative = tx.amount < 0;
                    final displayAmount = isNegative
                        ? '(${tx.amount.abs().toStringAsFixed(0)} SYP)'
                        : '${tx.amount.toStringAsFixed(0)} SYP';

                    return GestureDetector(
                      onTap: () => _showTransactionDetails(context, tx),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            // Icon matching category
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isNegative
                                    ? LucideIcons.wallet
                                    : Icons.restaurant,
                                color: isNegative
                                    ? AppColors.accentYellow
                                    : AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tx.date,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Amount & Status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  displayAmount,
                                  style: AppTheme.monoStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isNegative
                                        ? AppColors.accentYellow
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tx.status,
                                  style: AppTheme.monoStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tx.status == 'UNPAID'
                                        ? AppColors.primary
                                        : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

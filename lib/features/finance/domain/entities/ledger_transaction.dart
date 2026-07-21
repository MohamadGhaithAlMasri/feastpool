class LedgerTransaction {
  final String id;
  final String title;
  final String date;
  final double amount;
  final String status; // 'UNPAID' or 'SETTLED'
  final String type; // e.g. 'Lunch Pool', 'Bank Transfer'

  LedgerTransaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.type,
  });
}

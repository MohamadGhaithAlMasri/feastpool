import '../entities/ledger_transaction.dart';

abstract class LedgerRepository {
  Stream<List<LedgerTransaction>> get ledgerStream;
  List<LedgerTransaction> get transactions;
  Future<void> addTransaction(LedgerTransaction tx);
  Future<List<LedgerTransaction>> fetchTransactions();
}

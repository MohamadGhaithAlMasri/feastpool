import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/entities/ledger_transaction.dart';
import '../../domain/repositories/ledger_repository.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final sb.SupabaseClient _client;
  List<LedgerTransaction> _cachedTransactions = [];
  final StreamController<List<LedgerTransaction>> _ledgerController =
      StreamController<List<LedgerTransaction>>.broadcast();
  StreamSubscription? _realtimeSubscription;

  LedgerRepositoryImpl(this._client) {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _client.auth.onAuthStateChange.listen((authState) {
      final session = authState.session;
      if (session != null) {
        fetchTransactions();
        _subscribeToRealtime(session.user.id);
      } else {
        _unsubscribeFromRealtime();
      }
    });

    if (_client.auth.currentUser != null) {
      fetchTransactions();
      _subscribeToRealtime(_client.auth.currentUser!.id);
    }
  }

  void _subscribeToRealtime(String userId) {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _client
        .from('ledger_transactions')
        .stream(primaryKey: ['id'])
        .eq('profile_id', userId)
        .order('created_at', ascending: false)
        .listen((data) {
          final list = data.map((json) {
            return LedgerTransaction(
              id: json['id'],
              title: json['title'],
              date: _formatDate(json['created_at']),
              amount: (json['amount'] as num).toDouble(),
              status: json['status'],
              type: json['type'],
            );
          }).toList();
          _cachedTransactions = list;
          _ledgerController.add(list);
        }, onError: (err) {
          print('Ledger stream error: $err');
        });
  }

  void _unsubscribeFromRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _cachedTransactions = [];
    _ledgerController.add([]);
  }

  @override
  Stream<List<LedgerTransaction>> get ledgerStream => _ledgerController.stream;

  @override
  List<LedgerTransaction> get transactions => _cachedTransactions;

  @override
  Future<List<LedgerTransaction>> fetchTransactions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final res = await _client
          .from('ledger_transactions')
          .select()
          .eq('profile_id', userId)
          .order('created_at', ascending: false);
      final list = res.map((json) {
        return LedgerTransaction(
          id: json['id'],
          title: json['title'],
          date: _formatDate(json['created_at']),
          amount: (json['amount'] as num).toDouble(),
          status: json['status'],
          type: json['type'],
        );
      }).toList();
      _cachedTransactions = list;
      _ledgerController.add(list);
      return list;
    } catch (e) {
      print('Error fetching transactions: $e');
      return _cachedTransactions;
    }
  }

  @override
  Future<void> addTransaction(LedgerTransaction tx) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _client.from('ledger_transactions').insert({
        'profile_id': userId,
        'title': tx.title,
        'amount': tx.amount,
        'status': tx.status,
        'type': tx.type,
      });
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Just now';
    }
  }
}

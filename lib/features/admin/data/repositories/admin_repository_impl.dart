import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/entities/clearance_request.dart';
import '../../domain/entities/distribution_item.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../auth/domain/entities/user.dart';

class AdminRepositoryImpl implements AdminRepository {
  final sb.SupabaseClient _client;

  // Local/Session state caching
  int _sessionTimeRemaining = 0;
  String? _sessionCategory;
  Timer? _sessionTimer;
  Timer? _pollingTimer;
  Timer? _clearancePollingTimer;
  Timer? _distributionPollingTimer;
  final StreamController<int> _sessionController =
      StreamController<int>.broadcast();
  StreamSubscription? _sessionStreamSubscription;
  StreamSubscription? _distributionStreamSubscription;
  final StreamController<List<ClearanceRequest>> _clearanceController =
      StreamController<List<ClearanceRequest>>.broadcast();

  final List<DistributionItem> _distributionItems = [];
  final StreamController<List<DistributionItem>> _distController =
      StreamController<List<DistributionItem>>.broadcast();

  final List<ClearanceRequest> _cachedClearanceRequests = [];

  AdminRepositoryImpl(this._client) {
    _sessionController.add(0);
    _clearanceController.add([]);
    _distController.add(_distributionItems);

    _setupSessionSync();
  }

  void _setupSessionSync() {
    _client.auth.onAuthStateChange.listen((authState) {
      final session = authState.session;
      if (session != null) {
        _subscribeToPoolSessions();
        _startClearancePolling();
        _startDistributionPolling();
      } else {
        _unsubscribeFromPoolSessions();
        _stopClearancePolling();
        _stopDistributionPolling();
      }
    });

    if (_client.auth.currentUser != null) {
      _subscribeToPoolSessions();
      _startClearancePolling();
      _startDistributionPolling();
    }
  }

  void _startClearancePolling() {
    _clearancePollingTimer?.cancel();
    syncClearanceRequests();
    _clearancePollingTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) {
      if (_client.auth.currentUser != null) {
        syncClearanceRequests();
      }
    });
  }

  void _stopClearancePolling() {
    _clearancePollingTimer?.cancel();
    _clearancePollingTimer = null;
    _cachedClearanceRequests.clear();
    _clearanceController.add([]);
  }

  void _startDistributionPolling() {
    _distributionPollingTimer?.cancel();
    _distributionStreamSubscription?.cancel();
    syncDistribution();
    _distributionPollingTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) {
      if (_client.auth.currentUser != null) {
        syncDistribution();
      }
    });
    _distributionStreamSubscription = _client
        .from('ledger_transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
          (data) {
            syncDistribution();
          },
          onError: (error) {
            print('Distribution stream error: $error');
          },
        );
  }

  void _stopDistributionPolling() {
    _distributionPollingTimer?.cancel();
    _distributionPollingTimer = null;
    _distributionStreamSubscription?.cancel();
    _distributionStreamSubscription = null;
    _distributionItems.clear();
    _distController.add([]);
  }

  void _unsubscribeFromPoolSessions() {
    _sessionStreamSubscription?.cancel();
    _sessionStreamSubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _sessionTimer?.cancel();
    _sessionTimeRemaining = 0;
    _sessionController.add(0);
  }

  Future<void> _subscribeToPoolSessions() async {
    _sessionStreamSubscription?.cancel();
    _pollingTimer?.cancel();

    // Fetch once immediately to sync state right away
    await syncSession();

    // Start periodic polling fallback (every 5 seconds) to ensure synchronization if Realtime isn't enabled
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      syncSession();
    });

    // Start stream subscription with error handling
    _sessionStreamSubscription = _client
        .from('pool_sessions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
          (data) {
            _handlePoolSessionsData(data);
          },
          onError: (error) {
            // Fallback if RLS or network issue
            print('Pool sessions stream error: $error');
          },
        );
  }

  void _handlePoolSessionsData(List<Map<String, dynamic>> data) {
    if (data.isNotEmpty) {
      final session = data.first;
      final isActive = session['is_active'] as bool? ?? false;
      final endsAtStr = session['ends_at'] as String?;
      _sessionCategory = session['category'] as String?;

      _sessionTimer?.cancel();
      if (isActive && endsAtStr != null) {
        final endsAt = DateTime.parse(endsAtStr).toLocal();
        _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final now = DateTime.now();
          final diff = endsAt.difference(now).inSeconds;
          if (diff > 0) {
            _sessionTimeRemaining = diff;
            _sessionController.add(_sessionTimeRemaining);
          } else {
            _sessionTimeRemaining = 0;
            _sessionCategory = null;
            _sessionController.add(0);
            _sessionTimer?.cancel();
          }
        });
      } else {
        _sessionTimeRemaining = 0;
        _sessionCategory = null;
        _sessionController.add(0);
      }
    } else {
      _sessionTimeRemaining = 0;
      _sessionCategory = null;
      _sessionController.add(0);
    }
  }

  @override
  Future<void> syncSession() async {
    try {
      final data = await _client
          .from('pool_sessions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data != null) {
        _handlePoolSessionsData([data]);
      } else {
        _handlePoolSessionsData([]);
      }
    } catch (e) {
      print('Error fetching active session: $e');
      _handlePoolSessionsData([]);
    }
  }

  @override
  Stream<int> get sessionStream => _sessionController.stream;

  @override
  Stream<List<ClearanceRequest>> get clearanceStream =>
      _clearanceController.stream;

  @override
  Future<void> syncClearanceRequests() async {
    try {
      final data = await _client
          .from('clearance_requests')
          .select()
          .order('created_at', ascending: false);

      final profilesData = await _client.from('profiles').select();
      final profileMap = {
        for (var p in profilesData)
          p['id'].toString(): p['avatar_url'] ?? '',
      };

      final list = data.map((json) {
        final profileId = json['profile_id']?.toString();
        final avatarUrl = profileMap[profileId];
        return ClearanceRequest(
          id: json['id'].toString(),
          userName: json['username'] ?? 'Ahmed Khalid',
          room: json['room'] ?? 'Room 101',
          reason: json['reason'] ?? 'Cash Handover',
          amount: (json['amount'] as num).toDouble(),
          timeAgo: 'Just now',
          avatarUrl: avatarUrl,
        );
      }).toList();
      _cachedClearanceRequests.clear();
      _cachedClearanceRequests.addAll(list);
      _clearanceController.add(List.unmodifiable(_cachedClearanceRequests));
    } catch (e) {
      print('Error syncing clearances: $e');
    }
  }

  @override
  Stream<List<DistributionItem>> get distributionStream =>
      _distController.stream;

  @override
  Future<void> syncDistribution() async {
    try {
      final data = await _client
          .from('ledger_transactions')
          .select()
          .order('created_at', ascending: false);

      final profilesData = await _client.from('profiles').select();
      final profileMap = {
        for (var p in profilesData)
          p['id'].toString(): {
            'name': p['name'] ?? 'Unknown User',
            'department': p['department'] ?? 'No Room',
            'avatar_url': p['avatar_url'] ?? '',
          },
      };

      final list = <DistributionItem>[];
      for (var json in data) {
        if (json['type'] == 'Lunch Pool' && json['status'] != 'CANCELLED') {
          final profileId = json['profile_id']?.toString();
          final profile = profileMap[profileId];
          var name = profile?['name'] ?? 'Unknown User';
          var room = profile?['department'] ?? 'No Room';
          final avatarUrl = profile?['avatar_url'];
          final title = json['title'] ?? '';

          // Parse manual override from title if present, e.g. [Manual: John, Room: 101]
          final manualMatch = RegExp(
            r'\[Manual:\s*([^,\]]+),\s*Room:\s*([^\]]+)\]',
          ).firstMatch(title);
          if (manualMatch != null) {
            name = manualMatch.group(1)?.trim() ?? name;
            room = manualMatch.group(2)?.trim() ?? room;
          }

          // Parse items from title: e.g., "Pooled Meal Order: 2x Beef Burger, 1x Falafel Wrap"
          final Map<String, int> items = {};
          if (title.contains(':')) {
            final itemsPart = title.split(':').last.trim();
            final itemsList = itemsPart.split(',');
            for (var itemStr in itemsList) {
              final match = RegExp(r'(\d+)x\s+(.+)').firstMatch(itemStr.trim());
              if (match != null) {
                final qty = int.tryParse(match.group(1) ?? '1') ?? 1;
                final name = match.group(2)?.trim() ?? '';
                if (name.isNotEmpty) {
                  items[name] = qty;
                }
              }
            }
          }

          list.add(
            DistributionItem(
              id: json['id'].toString(),
              room: room,
              userName: name,
              items: items,
              avatarUrl: avatarUrl,
            ),
          );
        }
      }
      _distributionItems.clear();
      _distributionItems.addAll(list);
      _distController.add(List.unmodifiable(_distributionItems));
    } catch (e) {
      print('Error syncing distribution items: $e');
    }
  }

  @override
  int get sessionTimeRemaining => _sessionTimeRemaining;

  @override
  String? get sessionCategory => _sessionCategory;

  @override
  List<ClearanceRequest> get clearanceRequests => _cachedClearanceRequests;

  @override
  List<DistributionItem> get distributionItems => _distributionItems;

  @override
  Future<void> startSession(int durationSeconds, {String? category}) async {
    // START LOCAL TIMER IMMEDIATELY FOR INSTANT UI RESPONSE
    _sessionTimer?.cancel();
    _sessionTimeRemaining = durationSeconds;
    _sessionCategory = category;
    _sessionController.add(_sessionTimeRemaining);

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionTimeRemaining > 1) {
        _sessionTimeRemaining--;
        _sessionController.add(_sessionTimeRemaining);
      } else {
        _sessionTimeRemaining = 0;
        _sessionCategory = null;
        _sessionController.add(0);
        _sessionTimer?.cancel();
      }
    });

    // 1. Deactivate any previous active sessions to prevent duplicates
    try {
      await _client
          .from('pool_sessions')
          .update({'is_active': false})
          .eq('is_active', true);
    } catch (_) {}

    // 2. Insert new session row
    final endsAt = DateTime.now()
        .add(Duration(seconds: durationSeconds))
        .toUtc()
        .toIso8601String();
    await _client.from('pool_sessions').insert({
      'is_active': true,
      'status': 'STARTED',
      'ends_at': endsAt,
      'category': category,
    });

    await _client.from('in_app_notifications').insert({
      'title': 'FeastPool Started!',
      'body': category != null && category != 'All'
          ? 'Order window is open for 15 minutes. Category: $category. Add your meals now!'
          : 'Order window is open for 15 minutes. Add your meals now!',
    });

    // 3. Trigger push notifications to all users via Edge Function
    try {
      await _client.functions.invoke(
        'send-session-notification',
        body: {
          'status': 'STARTED',
          'category': category,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering push notifications: $e');
      }
    }
  }

  @override
  Future<void> stopSession() async {
    // STOP LOCAL TIMER IMMEDIATELY FOR INSTANT UI RESPONSE
    _sessionTimer?.cancel();
    _sessionTimeRemaining = 0;
    _sessionCategory = null;
    _sessionController.add(0);

    try {
      // Find the last session row
      final lastSession = await _client
          .from('pool_sessions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (lastSession != null) {
        await _client
            .from('pool_sessions')
            .update({'is_active': false, 'status': 'CLOSED', 'ends_at': null})
            .eq('id', lastSession['id']);
      }
    } catch (_) {
      // Fallback
      await _client
          .from('pool_sessions')
          .update({'is_active': false, 'status': 'CLOSED', 'ends_at': null})
          .eq('is_active', true);
    }
  }

  @override
  Future<void> markFoodArrived() async {
    // STOP LOCAL TIMER IMMEDIATELY FOR INSTANT UI RESPONSE
    _sessionTimer?.cancel();
    _sessionTimeRemaining = 0;
    _sessionCategory = null;
    _sessionController.add(0);

    try {
      // Find the last session row
      final lastSession = await _client
          .from('pool_sessions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (lastSession != null) {
        await _client
            .from('pool_sessions')
            .update({'is_active': false, 'status': 'ARRIVED', 'ends_at': null})
            .eq('id', lastSession['id']);
      }
    } catch (_) {
      // Fallback
      await _client
          .from('pool_sessions')
          .update({'is_active': false, 'status': 'ARRIVED', 'ends_at': null})
          .eq('is_active', true);
    }

    await _client.from('in_app_notifications').insert({
      'title': 'Food Arrived!',
      'body': 'The lunch pool order has arrived. Enjoy your meal!',
    });

    // Trigger push notifications to all users via Edge Function
    try {
      await _client.functions.invoke(
        'send-session-notification',
        body: {
          'status': 'ARRIVED',
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering arrival notifications: $e');
      }
    }
  }

  @override
  Future<void> approveClearance(String id) async {
    try {
      final req = await _client
          .from('clearance_requests')
          .select()
          .eq('id', id)
          .single();
      final profileId = req['profile_id'];
      final amount = (req['amount'] as num).toDouble();
      final createdAt = req['created_at'] as String?;

      if (profileId != null) {
        // 1. Fetch current profile ledger balance and subtract the approved clearance amount
        final profile = await _client
            .from('profiles')
            .select('ledger_balance')
            .eq('id', profileId)
            .single();
        final currentBalance = (profile['ledger_balance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = (currentBalance - amount).clamp(0.0, double.infinity);

        await _client
            .from('profiles')
            .update({'ledger_balance': newBalance})
            .eq('id', profileId);

        // 2. Record Bank Transfer settlement to clear ledger
        await _client.from('ledger_transactions').insert({
          'profile_id': profileId,
          'title': 'Payment Received',
          'amount': -amount,
          'status': 'SETTLED',
          'type': 'Bank Transfer',
        });

        // 3. Mark all previous unpaid transactions created on or before this clearance request as settled
        var query = _client
            .from('ledger_transactions')
            .update({'status': 'SETTLED'})
            .eq('profile_id', profileId)
            .eq('status', 'UNPAID');
            
        if (createdAt != null) {
          query = query.lte('created_at', createdAt);
        }
        
        await query;
      }

      await _client.from('clearance_requests').delete().eq('id', id);
    } catch (_) {
      // Fallback delete if profiles query fails
      await _client.from('clearance_requests').delete().eq('id', id);
    }
  }

  @override
  Future<void> rejectClearance(String id) async {
    await _client.from('clearance_requests').delete().eq('id', id);
  }

  @override
  Future<void> addClearanceRequest(ClearanceRequest request) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _client.from('clearance_requests').insert({
        'profile_id': userId,
        'username': request.userName,
        'room': request.room,
        'reason': request.reason,
        'amount': request.amount,
      });
    }
  }

  @override
  Future<void> addDistributionItem(DistributionItem item) async {
    try {
      final adminId = _client.auth.currentUser?.id;
      if (adminId == null) throw Exception("User not authenticated");

      // Fetch meals to calculate total price
      double totalAmount = 0.0;
      try {
        final mealsData = await _client.from('meals').select();
        final mealPrices = {
          for (var m in mealsData)
            m['name'].toString().toLowerCase(): (m['price'] as num).toDouble(),
        };
        for (var entry in item.items.entries) {
          final price = mealPrices[entry.key.toLowerCase()] ?? 0.0;
          totalAmount += price * entry.value;
        }
      } catch (_) {}

      // Format items: "1x Burger, 2x Soda"
      final itemsDescription = item.items.entries
          .map((e) => "${e.value}x ${e.key}")
          .join(', ');

      // Insert transaction into Supabase
      await _client.from('ledger_transactions').insert({
        'profile_id': adminId,
        'title':
            'Pooled Meal Order [Manual: ${item.userName}, Room: ${item.room}]: $itemsDescription',
        'amount': totalAmount,
        'status': 'UNPAID',
        'type': 'Lunch Pool',
      });
    } catch (_) {
      // Local fallback
      _distributionItems.add(item);
      _distController.add(List.unmodifiable(_distributionItems));
    }
  }

  @override
  Future<void> resetDailyOrders() async {
    try {
      await _client
          .from('ledger_transactions')
          .delete()
          .eq('type', 'Lunch Pool');
      await syncDistribution();
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting daily orders: $e');
      }
      // Local fallback
      _distributionItems.clear();
      _distController.add(List.unmodifiable(_distributionItems));
    }
  }

  @override
  Future<List<UserModel>> fetchOutstandingUsers() async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .gt('ledger_balance', 0)
          .order('name');
      return res.map((doc) => UserModel(
        id: doc['id'],
        name: doc['name'] ?? 'Unknown User',
        email: doc['email'] ?? '',
        department: doc['department'] ?? 'No Department',
        role: doc['role'] == 'admin' ? UserRole.admin : UserRole.employee,
        ledgerBalance: (doc['ledger_balance'] as num).toDouble(),
        mealsOrdered: doc['meals_ordered'] as int? ?? 0,
        avatarUrl: doc['avatar_url'],
      )).toList();
    } catch (e) {
      print('Error fetching outstanding users: $e');
      return [];
    }
  }

  @override
  Future<void> clearUserBalance(String userId, double amount) async {
    try {
      // 1. Zero out the user's ledger balance in profiles
      await _client
          .from('profiles')
          .update({'ledger_balance': 0.0})
          .eq('id', userId);

      // 2. Insert a settlement transaction into ledger_transactions
      await _client.from('ledger_transactions').insert({
        'profile_id': userId,
        'title': 'Payment Received (Cleared by Admin)',
        'amount': -amount,
        'status': 'SETTLED',
        'type': 'Bank Transfer',
      });

      // 3. Mark all previous unpaid transactions as SETTLED
      await _client
          .from('ledger_transactions')
          .update({'status': 'SETTLED'})
          .eq('profile_id', userId)
          .eq('status', 'UNPAID');
    } catch (e) {
      print('Error clearing user balance: $e');
    }
  }
}

import '../entities/clearance_request.dart';
import '../entities/distribution_item.dart';
import '../../../auth/domain/entities/user.dart';

abstract class AdminRepository {
  Stream<int> get sessionStream;
  Stream<List<ClearanceRequest>> get clearanceStream;
  Stream<List<DistributionItem>> get distributionStream;
  int get sessionTimeRemaining;
  String? get sessionCategory;
  List<ClearanceRequest> get clearanceRequests;
  List<DistributionItem> get distributionItems;

  Future<void> startSession(int durationSeconds, {String? category});
  Future<void> stopSession();
  Future<void> syncSession();
  Future<void> markFoodArrived();
  Future<void> approveClearance(String id);
  Future<void> rejectClearance(String id);
  Future<void> syncClearanceRequests();
  Future<void> syncDistribution();
  Future<void> addClearanceRequest(ClearanceRequest request);
  Future<void> addDistributionItem(DistributionItem item);
  Future<void> resetDailyOrders();
  Future<List<UserModel>> fetchOutstandingUsers();
  Future<void> clearUserBalance(String userId, double amount);
}

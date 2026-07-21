class ClearanceRequest {
  final String id;
  final String userName;
  final String room;
  final String reason;
  final double amount;
  final String timeAgo;
  final String? avatarUrl;

  ClearanceRequest({
    required this.id,
    required this.userName,
    required this.room,
    required this.reason,
    required this.amount,
    required this.timeAgo,
    this.avatarUrl,
  });
}

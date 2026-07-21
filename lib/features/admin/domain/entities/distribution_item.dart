class DistributionItem {
  final String id;
  final String room;
  final String userName;
  final Map<String, int> items; // Meal Name -> Count
  final String? avatarUrl;

  DistributionItem({
    required this.id,
    required this.room,
    required this.userName,
    required this.items,
    this.avatarUrl,
  });
}

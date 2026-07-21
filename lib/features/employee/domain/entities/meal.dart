class Meal {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.category = 'General',
  });
}

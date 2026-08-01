class AdminMenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool veg;
  final bool available;
  final bool isActive;

  const AdminMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image = '',
    required this.category,
    this.veg = false,
    this.available = true,
    this.isActive = true,
  });

  factory AdminMenuItem.fromJson(Map<String, dynamic> json) {
    return AdminMenuItem(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] as String? ?? '',
      category: json['category'] as String? ?? '',
      veg: json['veg'] as bool? ?? false,
      available: json['available'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  bool get isSoldOut => !available;
  bool get isArchived => !isActive;
}

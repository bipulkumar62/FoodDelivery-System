class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool veg;
  final bool available;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image = '',
    required this.category,
    this.veg = false,
    this.available = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: _normalizeUrl(json['image'] as String? ?? ''),
      category: normalizeCategory(json['category'] as String? ?? ''),
      veg: json['veg'] as bool? ?? false,
      available: json['available'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
    );
  }

  /// Trim, collapse repeated spaces and title-case a category name so that
  /// " roll ", "ROLL" and "Roll" all behave as a single category.
  static String normalizeCategory(String category) {
    final cleaned = category.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return 'Other';
    return cleaned
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'description': description,
        'price': price,
        'image': image,
        'category': category,
        'veg': veg,
        'available': available,
        'isActive': isActive,
      };

  /// Normalize an image URL by properly encoding characters and validating it
  static String _normalizeUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return '';
    return uri.toString();
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? image,
    String? category,
    bool? veg,
    bool? available,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      veg: veg ?? this.veg,
      available: available ?? this.available,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

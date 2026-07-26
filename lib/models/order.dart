import 'food_item.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
  rejected,
}

OrderStatus orderStatusFromString(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return OrderStatus.pending;
    case 'accepted':
      return OrderStatus.accepted;
    case 'preparing':
      return OrderStatus.preparing;
    case 'out for delivery':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'rejected':
      return OrderStatus.rejected;
    default:
      return OrderStatus.pending;
  }
}

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String image;
  final String category;
  final bool veg;
  final double subtotal;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image = '',
    this.category = '',
    this.veg = false,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      image: json['image'] as String? ?? '',
      category: json['category'] as String? ?? '',
      veg: json['veg'] as bool? ?? false,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Order {
  final String id;
  final String orderId;
  final String customerName;
  final String phone;
  final String address;
  final String? landmark;
  final String? notes;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final OrderStatus orderStatus;
  final DateTime? estimatedDeliveryTime;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;

  Order({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.phone,
    required this.address,
    this.landmark,
    this.notes,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.total,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
    required this.orderStatus,
    this.estimatedDeliveryTime,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      landmark: json['landmark'] as String?,
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? 'cod',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      orderStatus: orderStatusFromString(json['orderStatus'] as String? ?? 'pending'),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.parse(json['estimatedDeliveryTime'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class DashboardStats {
  final int totalOrders;
  final int pendingOrders;
  final int acceptedOrders;
  final int preparingOrders;
  final int outForDeliveryOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int rejectedOrders;
  final int todayOrders;
  final double todayRevenue;
  final double totalRevenue;
  final int totalMenuItems;
  final int availableMenuItems;
  final int disabledMenuItems;

  const DashboardStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.acceptedOrders,
    required this.preparingOrders,
    required this.outForDeliveryOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.rejectedOrders,
    required this.todayOrders,
    required this.todayRevenue,
    required this.totalRevenue,
    required this.totalMenuItems,
    required this.availableMenuItems,
    required this.disabledMenuItems,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: json['totalOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      acceptedOrders: json['acceptedOrders'] as int? ?? 0,
      preparingOrders: json['preparingOrders'] as int? ?? 0,
      outForDeliveryOrders: json['outForDeliveryOrders'] as int? ?? 0,
      deliveredOrders: json['deliveredOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      rejectedOrders: json['rejectedOrders'] as int? ?? 0,
      todayOrders: json['todayOrders'] as int? ?? 0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalMenuItems: json['totalMenuItems'] as int? ?? 0,
      availableMenuItems: json['availableMenuItems'] as int? ?? 0,
      disabledMenuItems: json['disabledMenuItems'] as int? ?? 0,
    );
  }
}

class PaginatedOrders {
  final List<Order> orders;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedOrders({
    required this.orders,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedOrders.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return PaginatedOrders(
      orders: (data['orders'] as List<dynamic>?)
              ?.map((e) => Order.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      totalPages: data['totalPages'] as int? ?? 0,
    );
  }
}

class PaginatedMenuItems {
  final List<FoodItem> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedMenuItems({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedMenuItems.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return PaginatedMenuItems(
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? 1,
      limit: data['limit'] as int? ?? 20,
      totalPages: data['totalPages'] as int? ?? 0,
    );
  }
}

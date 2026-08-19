/// Single live-location payload for an active order.
///
/// Server contract (see backend tracking service): the payload contains only
/// orderId, riderId, latitude, longitude, accuracy and server timestamp.
class LiveLocation {
  final String orderId;
  final String riderId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  const LiveLocation({
    required this.orderId,
    required this.riderId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  factory LiveLocation.fromJson(Map<String, dynamic> json) {
    return LiveLocation(
      orderId: json['orderId'] as String? ?? '',
      riderId: json['riderId'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static LiveLocation lerp(
    LiveLocation a,
    LiveLocation b,
    double t,
  ) {
    return LiveLocation(
      orderId: b.orderId,
      riderId: b.riderId,
      latitude: a.latitude + (b.latitude - a.latitude) * t,
      longitude: a.longitude + (b.longitude - a.longitude) * t,
      accuracy: a.accuracy + (b.accuracy - a.accuracy) * t,
      timestamp: b.timestamp,
    );
  }
}
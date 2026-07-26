import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static const double restaurantLat = 26.2200986;
  static const double restaurantLng = 84.3471717;
  static const double maxDeliveryRadiusKm = 15.0;

  /// Check and request location permission
  static Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.location.status;
    return status.isPermanentlyDenied;
  }

  /// Get current position with high accuracy
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }

  /// Check if customer is within delivery radius
  static Future<bool> isWithinDeliveryRadius(double lat, double lng) async {
    final distance = calculateDistance(lat, lng, restaurantLat, restaurantLng);
    return distance <= maxDeliveryRadiusKm;
  }

  /// Get distance from restaurant to customer
  static double getDistanceFromRestaurant(double lat, double lng) {
    return calculateDistance(lat, lng, restaurantLat, restaurantLng);
  }

  /// Check if GPS is enabled
  static Future<bool> isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open app settings for location permission
  static Future<void> openLocationSettings() async {
    await openAppSettings();
  }
}
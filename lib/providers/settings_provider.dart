import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';

class RestaurantSettingsState {
  const RestaurantSettingsState({
    this.restaurantName = '',
    this.deliveryRatePerKm = 10.0,
    this.acceptingOrders = true,
    this.loaded = false,
  });

  final String restaurantName;
  final double deliveryRatePerKm;

  /// Single authoritative global availability value from the public
  /// /settings endpoint. Maps both the admin "Accepting Orders" switch
  /// and the customer-facing ordering availability.
  final bool acceptingOrders;

  /// True once the backend has been queried at least once.
  final bool loaded;
}

class RestaurantSettingsNotifier extends Notifier<RestaurantSettingsState> {
  @override
  RestaurantSettingsState build() => const RestaurantSettingsState();

  Future<void> refresh() async {
    try {
      final response = await ApiClient.instance.get('/settings');
      final data = response['data'] as Map<String, dynamic>;
      state = RestaurantSettingsState(
        restaurantName: (data['restaurantName'] as String?) ?? '',
        deliveryRatePerKm:
            ((data['deliveryRatePerKm'] as num?) ?? 10).toDouble(),
        acceptingOrders: (data['acceptingOrders'] as bool?) ?? true,
        loaded: true,
      );
    } on Exception {
      // Keep the last known state on transient errors so availability
      // never flaps because of a single failed request.
    }
  }
}

final restaurantSettingsProvider =
    NotifierProvider<RestaurantSettingsNotifier, RestaurantSettingsState>(
  RestaurantSettingsNotifier.new,
);

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawan_biryani/models/food_item.dart';
import 'package:pawan_biryani/providers/cart_provider.dart';
import 'package:pawan_biryani/providers/menu_provider.dart';
import 'package:pawan_biryani/providers/settings_provider.dart';
import 'package:pawan_biryani/screens/checkout/checkout_screen.dart';

const MethodChannel _permissionsChannel =
    MethodChannel('flutter.baseflow.com/permissions/methods');
const MethodChannel _geolocatorChannel =
    MethodChannel('flutter.baseflow.com/geolocator');

class _FakeSettingsNotifier extends RestaurantSettingsNotifier {
  @override
  RestaurantSettingsState build() => const RestaurantSettingsState(
        restaurantName: 'Pawan Biryani',
        acceptingOrders: true,
        loaded: true,
      );
}

Widget _harness() {
  return ProviderScope(
    overrides: [
      restaurantSettingsProvider.overrideWith(_FakeSettingsNotifier.new),
      menuProvider.overrideWith((ref) async => <FoodItem>[]),
      deliveryRateProvider.overrideWith((ref) async => 10.0),
    ],
    child: const MaterialApp(home: CheckoutScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int permissionRequests;
  late int getPositionCalls;

  /// permission_handler statuses: 0=denied, 1=granted (enum order).
  void mockPermissions({required int status}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionsChannel, (call) async {
      switch (call.method) {
        case 'requestPermissions':
          permissionRequests++;
          final perms = (call.arguments as List).cast<int>();
          return {for (final p in perms) p: status};
        case 'checkPermissionStatus':
          return status;
        case 'shouldShowRequestPermissionRationale':
          return false;
        case 'openAppSettings':
          return true;
      }
      return null;
    });
  }

  void mockGeolocator() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocatorChannel, (call) async {
      if (call.method == 'getCurrentPosition') {
        getPositionCalls++;
        return {
          'latitude': 26.2200986,
          'longitude': 84.3471717,
          'accuracy': 5.0,
          'altitude': 0.0,
          'speed': 0.0,
          'speedAccuracy': 0.0,
          'heading': 0.0,
          'timestamp': DateTime(2026, 8, 19).millisecondsSinceEpoch,
        };
      }
      return null;
    });
  }

  setUp(() {
    permissionRequests = 0;
    getPositionCalls = 0;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_permissionsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocatorChannel, null);
  });

  testWidgets('opening checkout never requests location by itself',
      (tester) async {
    mockPermissions(status: 0);
    mockGeolocator();

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(permissionRequests, 0);
    expect(getPositionCalls, 0);
    expect(find.text('Use Current Location'), findsOneWidget);
  });

  testWidgets('denied permission shows message and stays at request state',
      (tester) async {
    mockPermissions(status: 0);
    mockGeolocator();

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use Current Location'));
    await tester.pumpAndSettle();

    expect(permissionRequests, 1);
    expect(
      find.text(
        'Location permission is required for delivery. Please enable it in settings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Location verified - within delivery range'), findsNothing);
  });

  testWidgets('granted permission fetches position and flags within range',
      (tester) async {
    mockPermissions(status: 1);
    mockGeolocator();

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use Current Location'));
    // Flush the geolocator 15s timeLimit timer so no timer is left pending.
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();

    expect(permissionRequests, 2); // requestPermission + getCurrentLocation
    expect(getPositionCalls, 1);
    expect(
      find.text('Location verified - within delivery range'),
      findsOneWidget,
    );
  });
}
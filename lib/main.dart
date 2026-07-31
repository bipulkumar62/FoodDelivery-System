import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'models/food_item.dart';
import 'network/api_client.dart';
import 'services/location_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/product_details/product_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/order_success/order_success_screen.dart';
import 'screens/my_orders/my_orders_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_orders_screen.dart';
import 'screens/admin/edit_restaurant_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.instance.init();
  
  // Restore admin token if exists
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('admin_token');
  if (token != null && token.isNotEmpty) {
    ApiClient.instance.setToken(token);
  }
  
  runApp(const ProviderScope(child: PawanBiryaniApp()));
}

class PawanBiryaniApp extends StatelessWidget {
  const PawanBiryaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawan Biryani',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShell(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/product-details':
        final item = settings.arguments as FoodItem;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(item: item),
        );
      case '/cart':
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case '/checkout':
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case '/order-success':
        return MaterialPageRoute(
            builder: (_) => const OrderSuccessScreen());
      case '/my-orders':
        return MaterialPageRoute(builder: (_) => const MyOrdersScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/admin-login':
        return MaterialPageRoute(
            builder: (_) => const AdminLoginScreen());
      case '/admin-orders':
        return MaterialPageRoute(
            builder: (_) => const AdminOrdersScreen());
      case '/edit-restaurant-menu':
        return MaterialPageRoute(
            builder: (_) =>
                const _AdminRouteGuard(child: EditRestaurantMenuScreen()));
      default:
        return MaterialPageRoute(builder: (_) => const MainShell());
    }
  }
}

class _AdminRouteGuard extends StatefulWidget {
  const _AdminRouteGuard({required this.child});

  final Widget child;

  @override
  State<_AdminRouteGuard> createState() => _AdminRouteGuardState();
}

class _AdminRouteGuardState extends State<_AdminRouteGuard> {
  bool? _isAuthorized;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn = await isAdminLoggedIn();
    if (!mounted) return;
    if (!loggedIn) {
      pendingAdminRedirect = '/edit-restaurant-menu';
      Navigator.pushReplacementNamed(context, '/admin-login');
      return;
    }
    setState(() => _isAuthorized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthorized != true) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MyOrdersScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionAtStart();
  }

  Future<void> _requestLocationPermissionAtStart() async {
    final granted = await LocationService.requestPermission();
    if (!mounted) return;
    if (!granted) {
      final permanentlyDenied = await LocationService.isPermissionPermanentlyDenied();
      if (!mounted) return;
      if (permanentlyDenied) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Location permission is required for delivery. Please enable it in app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  LocationService.openLocationSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'models/food_item.dart';
import 'network/api_client.dart';
import 'screens/home/home_screen.dart';
import 'screens/product_details/product_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/order_success/order_success_screen.dart';
import 'screens/my_orders/my_orders_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_orders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.instance.init();
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
      default:
        return MaterialPageRoute(builder: (_) => const MainShell());
    }
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

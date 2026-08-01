import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/food_item.dart';
import '../../providers/menu_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/socket_service.dart';
import '../../widgets/availability_banner.dart';
import '../../widgets/floating_cart_button.dart';
import '../../widgets/empty_state.dart';
import 'widgets/restaurant_header.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/full_menu_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  String _searchQuery = '';
  Timer? _pollTimer;
  bool _appInForeground = true;

  static const _pollInterval = Duration(seconds: 5);

  bool get _shouldPoll => widget.isActive && _appInForeground;

  List<FoodItem> _filterItems(List<FoodItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((item) =>
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SocketService.instance.onMenuAvailabilityUpdated(_handleMenuUpdated);
    SocketService.instance.onMenuCreated(_handleMenuUpdated);
    SocketService.instance.onMenuUpdated(_handleMenuUpdated);
    SocketService.instance.onMenuDeleted(_handleMenuUpdated);
    _refreshAll();
    _schedulePolling();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _refreshAll();
      }
      _schedulePolling();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appInForeground = true;
      _refreshAll();
      _schedulePolling();
    } else {
      _appInForeground = false;
      _cancelPolling();
    }
  }

  @override
  void dispose() {
    _cancelPolling();
    SocketService.instance.offMenuAvailabilityUpdated();
    SocketService.instance.offMenuCreated();
    SocketService.instance.offMenuUpdated();
    SocketService.instance.offMenuDeleted();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleMenuUpdated(dynamic _) {
    if (mounted) _refreshAll();
  }

  void _refreshAll() {
    ref.invalidate(menuProvider);
    ref.read(restaurantSettingsProvider.notifier).refresh();
  }

  void _schedulePolling() {
    _cancelPolling();
    if (_shouldPoll) {
      _pollTimer = Timer.periodic(_pollInterval, (_) => _refreshAll());
    }
  }

  void _cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final settings = ref.watch(restaurantSettingsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!settings.acceptingOrders) const AvailabilityBanner(),
            const RestaurantHeader(),
            SearchBarWidget(
              onSearch: (query) => setState(() => _searchQuery = query),
            ),
            const SizedBox(height: 16),
            menuAsync.when(
              data: (items) {
                final filtered = _filterItems(items);

                return _searchQuery.isEmpty
                    ? FullMenuSection(items: filtered)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Search Results',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FullMenuSection(items: filtered),
                        ],
                      );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load menu',
                subtitle: e.toString(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const FloatingCartButton(),
    );
  }
}

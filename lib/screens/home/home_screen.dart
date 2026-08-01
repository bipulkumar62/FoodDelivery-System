import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/food_item.dart';
import '../../providers/menu_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/socket_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/floating_cart_button.dart';
import '../../widgets/offline_state.dart';
import 'widgets/category_selector.dart';
import 'widgets/full_menu_section.dart';
import 'widgets/restaurant_header.dart';
import 'widgets/search_bar_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.isActive = true});

  final bool isActive;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const _allCategory = '';
  String _searchQuery = '';
  String _selectedCategory = _allCategory;
  Timer? _pollTimer;
  bool _appInForeground = true;

  static const _pollInterval = Duration(seconds: 5);

  bool get _shouldPoll => widget.isActive && _appInForeground;

  List<FoodItem> _filterItems(List<FoodItem> items) {
    var filtered = items;
    if (_selectedCategory != _allCategory) {
      filtered = filtered
          .where((item) => item.category == _selectedCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  /// "All" first, then every unique category in first-appearance order.
  static List<String> _buildCategories(List<FoodItem> items) {
    final categories = <String>['All'];
    final seen = <String>{};
    for (final item in items) {
      if (seen.add(item.category)) {
        categories.add(item.category);
      }
    }
    return categories;
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
    final items = menuAsync.value ?? const <FoodItem>[];
    final categories = _buildCategories(items);

    if (_selectedCategory != _allCategory &&
        !categories.contains(_selectedCategory)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedCategory != _allCategory) {
          setState(() => _selectedCategory = _allCategory);
        }
      });
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!settings.acceptingOrders) const OfflineState(),
            const RestaurantHeader(),
            SearchBarWidget(
              onSearch: (query) => setState(() => _searchQuery = query),
            ),
            const SizedBox(height: 12),
            CategorySelector(
              categories: categories,
              selected: _selectedCategory,
              onSelected: (category) =>
                  setState(() => _selectedCategory = category),
            ),
            const SizedBox(height: 16),
            menuAsync.when(
              data: (data) {
                final filtered = _filterItems(data);

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

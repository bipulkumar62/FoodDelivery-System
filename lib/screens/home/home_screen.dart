import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/food_item.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/floating_cart_button.dart';
import '../../widgets/empty_state.dart';
import 'widgets/restaurant_header.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/full_menu_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';

  List<FoodItem> _filterItems(List<FoodItem> items) {
    if (_searchQuery.isEmpty) return items;
    return items
        .where((item) =>
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
import 'package:flutter/material.dart';
import '../../../models/food_item.dart';
import '../../../widgets/food_card.dart';
import '../../../config/routes.dart';

class RecommendedSection extends StatelessWidget {
  final List<FoodItem> items;

  const RecommendedSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Recommended',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return FoodCard(
              item: item,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.productDetails,
                arguments: item,
              ),
            );
          },
        ),
      ],
    );
  }
}

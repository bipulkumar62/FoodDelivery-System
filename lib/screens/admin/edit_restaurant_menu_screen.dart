import 'package:flutter/material.dart';
import '../../config/theme.dart';

class EditRestaurantMenuScreen extends StatelessWidget {
  const EditRestaurantMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Restaurant & Menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPlaceholderCard(
            icon: Icons.storefront_outlined,
            title: 'Restaurant Settings',
            subtitle: 'Update restaurant details, timings and delivery information',
          ),
          _buildPlaceholderCard(
            icon: Icons.restaurant_menu,
            title: 'Menu Management',
            subtitle: 'Add, edit or remove items from the menu',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        enabled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Coming soon',
            style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

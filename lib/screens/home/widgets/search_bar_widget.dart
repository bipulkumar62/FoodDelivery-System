import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String> onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Search for food...',
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
          filled: true,
          fillColor: AppTheme.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

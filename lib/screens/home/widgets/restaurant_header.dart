import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';

class RestaurantHeader extends StatelessWidget {
  const RestaurantHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    final logoSize = isSmall ? 64.0 : 80.0;
    final titleSize = isSmall ? 24.0 : 28.0;
    final bannerHeight = isSmall ? 180.0 : 200.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 4,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          height: bannerHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'PB',
                        style: TextStyle(
                          fontSize: isSmall ? 26 : 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                ),
                SizedBox(height: isSmall ? 8 : 12),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.tagline,
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

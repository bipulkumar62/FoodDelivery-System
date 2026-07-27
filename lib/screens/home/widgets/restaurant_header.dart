import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';

class RestaurantHeader extends StatelessWidget {
  const RestaurantHeader({super.key});

  static const String _bannerImageUrl = 'https://images.pexels.com/photos/4439740/pexels-photo-4439740.jpeg?cs=srgb&dl=pexels-satyam-verma-2901977-4439740.jpg&fm=jpg';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;
    final logoSize = isSmall ? 64.0 : 80.0;
    final titleSize = isSmall ? 24.0 : 28.0;
    final bannerHeight = isSmall ? 200.0 : 240.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          height: bannerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Biryani background image
              CachedNetworkImage(
                imageUrl: _bannerImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Dark overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Branding content
              Center(
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
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
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
                    SizedBox(height: isSmall ? 10 : 14),
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppConstants.tagline,
                      style: TextStyle(
                        fontSize: isSmall ? 13 : 15,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

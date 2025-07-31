import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/presentation/theme/app_theme.dart';

/// Widget for displaying a country in a card format
class CountryCard extends StatelessWidget {
  const CountryCard({
    required this.country,
    required this.isInWishlist,
    required this.onTap,
    required this.onWishlistToggle,
    super.key,
  });

  final Country country;
  final bool isInWishlist;
  final VoidCallback onTap;
  final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        onTap: onTap,
        child: Padding(
          padding: AppStyles.cardPadding,
          child: Row(
            children: [
              // Flag
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: country.flagUrl,
                  width: 60,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 40,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.flag),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 40,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Country info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country.name,
                      style: AppStyles.titleStyle.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capital: ${country.capital}',
                      style: AppStyles.subtitleStyle.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Population: ${_formatPopulation(country.population)}',
                      style: AppStyles.captionStyle.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Region: ${country.region}',
                      style: AppStyles.captionStyle.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Wishlist button
              IconButton(
                onPressed: onWishlistToggle,
                icon: Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist 
                      ? theme.colorScheme.error 
                      : theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: isInWishlist ? 'Remove from wishlist' : 'Add to wishlist',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPopulation(int population) {
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)}M';
    } else if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(1)}K';
    }
    return population.toString();
  }
}
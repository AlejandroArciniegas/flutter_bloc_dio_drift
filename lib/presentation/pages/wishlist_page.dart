import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/injection_container.dart';
import 'package:euro_explorer/presentation/blocs/wishlist/wishlist_cubit.dart';
import 'package:euro_explorer/presentation/pages/country_detail_page.dart';
import 'package:euro_explorer/presentation/theme/app_theme.dart';
import 'package:euro_explorer/presentation/widgets/error_widget.dart';
import 'package:euro_explorer/presentation/widgets/loading_widget.dart';
import 'package:euro_explorer/presentation/widgets/smart_flag_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page displaying user's wishlist of countries
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<WishlistCubit>()..loadWishlist(),
      child: const WishlistView(),
    );
  }
}

class WishlistView extends StatefulWidget {
  const WishlistView({super.key});

  @override
  State<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends State<WishlistView> {
  bool _flagsPreloaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, state) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Refresh'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if ((state is WishlistLoaded && state.items.isNotEmpty) ||
                      (state is WishlistStressTestCompleted && state.items.isNotEmpty))
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: ListTile(
                        leading: Icon(Icons.clear_all, color: Colors.red),
                        title: Text('Clear All', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'stress_test',
                    child: ListTile(
                      leading: Icon(Icons.speed),
                      title: Text('Run Stress Test'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<WishlistCubit, WishlistState>(
        listener: (context, state) {
          if (state is WishlistError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          } else if (state is WishlistStressTestCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Stress test completed in ${state.duration.inMilliseconds}ms. '
                  'Added ${state.items.length} entries. Total: ${state.items.length} items.',
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            WishlistInitial() => const LoadingWidget(
                message: 'Initializing...',
              ),
            WishlistLoading() => const LoadingWidget(
                message: 'Loading wishlist...',
              ),
            WishlistStressTestRunning() => const LoadingWidget(
                message: 'Running performance stress test...',
              ),
            WishlistLoaded() => _buildWishlist(context, state.items),
            WishlistStressTestCompleted() => _buildWishlist(context, state.items),
            WishlistError() => ErrorDisplayWidget(
                message: state.message,
                onRetry: () => context.read<WishlistCubit>().refresh(),
              ),
          };
        },
      ),
    );
  }

  Widget _buildWishlist(BuildContext context, List<WishlistItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Your wishlist is empty',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add countries from the main list to see them here',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Preload flag images for better scroll performance
    _preloadWishlistFlags(context, items);

    return RefreshIndicator(
      onRefresh: () => context.read<WishlistCubit>().refresh(),
      child: ListView.builder(
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        cacheExtent: 1000, // Prerender more items offscreen for smoother scrolling
        itemExtent: 120, // Fixed height estimation for better performance
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildWishlistItem(context, item);
        },
      ),
    );
  }

  void _preloadWishlistFlags(BuildContext context, List<WishlistItem> items) {
    if (_flagsPreloaded) return;
    _flagsPreloaded = true;

    // Extract flag URLs from wishlist items
    final flagUrls = items.map((item) => item.flagUrl).toList();
    
    // Prioritize immediate precaching of visible items using Flutter's precacheImage
    _precacheVisibleFlags(context, flagUrls.take(8).toList());
  }

  void _precacheVisibleFlags(BuildContext context, List<String> flagUrls) {
    // Use Flutter's built-in precacheImage for immediate caching of visible items
    for (final url in flagUrls) {
      if (!url.toLowerCase().endsWith('.svg')) {
        precacheImage(
          NetworkImage(url),
          context,
          onError: (exception, stackTrace) {
            debugPrint('Failed to precache wishlist flag $url: $exception');
          },
        );
      }
    }
  }

  Widget _buildWishlistItem(BuildContext context, WishlistItem item) {
    final theme = Theme.of(context);
    
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: theme.colorScheme.error,
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmation(context, item),
      onDismissed: (direction) {
        context.read<WishlistCubit>().removeItem(item.id);
      },
      child: Card(
        child: ListTile(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => CountryDetailPage(
                countryName: item.name,
              ),
            ),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SmartFlagImage(
              imageUrl: item.flagUrl,
              width: 40,
              height: 30,
            ),
          ),
          title: Text(
            item.name,
            style: AppStyles.titleStyle.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Added ${_formatDate(item.addedAt)}',
            style: AppStyles.captionStyle.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            onPressed: () async {
              final confirmed = await _showDeleteConfirmation(context, item);
              if (!context.mounted) return;
              if (confirmed ?? false) {
                await context.read<WishlistCubit>().removeItem(item.id);
              }
            },
            tooltip: 'Remove from wishlist',
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    WishlistItem item,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Wishlist'),
        content: Text('Are you sure you want to remove ${item.name} from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'refresh':
        context.read<WishlistCubit>().refresh();
      case 'clear_all':
        _showClearAllConfirmation(context);
      case 'stress_test':
        _showStressTestConfirmation(context);
    }
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Items'),
        content: const Text(
          'Are you sure you want to remove all items from your wishlist? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<WishlistCubit>().clearWishlist();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showStressTestConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Performance Stress Test'),
        content: const Text(
          'This will add all European countries to the wishlist to test performance. '
          'The operation will run in batches to prevent UI blocking. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<WishlistCubit>().runStressTest();
            },
            child: const Text('Run Test'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

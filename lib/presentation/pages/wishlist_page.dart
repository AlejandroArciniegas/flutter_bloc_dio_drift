import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:euro_explorer/domain/entities/wishlist_item.dart';
import 'package:euro_explorer/injection_container.dart';
import 'package:euro_explorer/presentation/blocs/wishlist/wishlist_cubit.dart';
import 'package:euro_explorer/presentation/theme/app_theme.dart';
import 'package:euro_explorer/presentation/widgets/error_widget.dart';
import 'package:euro_explorer/presentation/widgets/loading_widget.dart';

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

class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

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
                  'Added 5,000 entries. Total: ${state.items.length} items.',
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

    return RefreshIndicator(
      onRefresh: () => context.read<WishlistCubit>().refresh(),
      child: ListView.builder(
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildWishlistItem(context, item);
        },
      ),
    );
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
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: item.flagUrl,
              width: 40,
              height: 30,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 40,
                height: 30,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.flag, size: 16),
              ),
              errorWidget: (context, url, error) => Container(
                width: 40,
                height: 30,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image, size: 16),
              ),
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
            onPressed: () => _showDeleteConfirmation(context, item).then(
              (confirmed) {
                if (confirmed == true) {
                  context.read<WishlistCubit>().removeItem(item.id);
                }
              },
            ),
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
      case 'stress_test':
        _showStressTestConfirmation(context);
    }
  }

  void _showStressTestConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Stress Test'),
        content: const Text(
          'This will add 5,000 fake entries to test performance. '
          'The operation will run off the UI thread to prevent frame drops. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
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
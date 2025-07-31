import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Smart flag image widget that automatically handles both SVG and PNG formats
/// Optimized to prevent shader compilation jank with RepaintBoundary and preloading
class SmartFlagImage extends StatefulWidget {
  const SmartFlagImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableShaderWarmup = true,
    this.loadingDelay,
    super.key,
  });

  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final bool enableShaderWarmup;
  final Duration? loadingDelay;

  bool get _isSvg => imageUrl.toLowerCase().endsWith('.svg');

  @override
  State<SmartFlagImage> createState() => _SmartFlagImageState();
}

class _SmartFlagImageState extends State<SmartFlagImage>
    with AutomaticKeepAliveClientMixin {
  bool _shouldLoad = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeLoading();
  }

  void _initializeLoading() {
    if (widget.loadingDelay != null) {
      // Staggered loading to prevent simultaneous shader compilation
      Future.delayed(widget.loadingDelay!, () {
        if (mounted) {
          setState(() {
            _shouldLoad = true;
          });
        }
      });
    } else {
      _shouldLoad = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    
    final defaultPlaceholder = Container(
      width: widget.width,
      height: widget.height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.flag,
        size: widget.width > 60 ? 48 : 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    final defaultErrorWidget = Container(
      width: widget.width,
      height: widget.height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image,
        size: widget.width > 60 ? 48 : 16,
        color: theme.colorScheme.error,
      ),
    );

    // Don't load image until delay has passed (for staggered loading)
    if (!_shouldLoad) {
      return widget.placeholder?.call(context, widget.imageUrl) ?? defaultPlaceholder;
    }

    // Wrap in RepaintBoundary to isolate repaints and reduce shader compilation impact
    return RepaintBoundary(
      child: widget._isSvg ? _buildSvgImage(defaultPlaceholder, defaultErrorWidget) 
                           : _buildPngImage(defaultPlaceholder, defaultErrorWidget),
    );
  }

  Widget _buildSvgImage(Widget defaultPlaceholder, Widget defaultErrorWidget) {
    return SvgPicture.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholderBuilder: (context) => 
          widget.placeholder?.call(context, widget.imageUrl) ?? defaultPlaceholder,
    );
  }

  Widget _buildPngImage(Widget defaultPlaceholder, Widget defaultErrorWidget) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: widget.placeholder ?? (context, url) => defaultPlaceholder,
      errorWidget: widget.errorWidget ?? (context, url, error) => defaultErrorWidget,
      // Optimized memory caching for better performance
      memCacheWidth: (widget.width * devicePixelRatio).round(),
      memCacheHeight: (widget.height * devicePixelRatio).round(),
      maxWidthDiskCache: (widget.width * devicePixelRatio * 2).round(), // 2x for better quality
      maxHeightDiskCache: (widget.height * devicePixelRatio * 2).round(),
      // Enable fade in animation for smoother loading
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Use better cache key for consistency
      cacheKey: widget.imageUrl,
    );
  }


}

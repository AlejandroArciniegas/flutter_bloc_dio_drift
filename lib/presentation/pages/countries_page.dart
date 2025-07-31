// ignore_for_file: lines_longer_than_80_chars

import 'package:euro_explorer/injection_container.dart';
import 'package:euro_explorer/presentation/blocs/countries/countries_cubit.dart';
import 'package:euro_explorer/presentation/pages/country_detail_page.dart';
import 'package:euro_explorer/presentation/pages/wishlist_page.dart';
import 'package:euro_explorer/presentation/widgets/country_card.dart';
import 'package:euro_explorer/presentation/widgets/error_widget.dart';
import 'package:euro_explorer/presentation/widgets/loading_widget.dart';
import 'package:euro_explorer/utils/flag_performance_optimizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Main page displaying list of European countries
class CountriesPage extends StatelessWidget {
  const CountriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CountriesCubit>()..loadCountries(),
      child: const CountriesView(),
    );
  }
}

class CountriesView extends StatefulWidget {
  const CountriesView({super.key});

  @override
  State<CountriesView> createState() => _CountriesViewState();
}

class _CountriesViewState extends State<CountriesView> {
  bool _flagsPreloaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EuroExplorer'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const WishlistPage(),
              ),
            ),
            icon: const Icon(Icons.favorite),
            tooltip: 'View Wishlist',
          ),
        ],
      ),
      body: BlocBuilder<CountriesCubit, CountriesState>(
        builder: (context, state) {
          return switch (state) {
            CountriesInitial() => const LoadingWidget(
                message: 'Initializing...',
              ),
            CountriesLoading() => const LoadingWidget(
                message: 'Loading European countries...',
              ),
            CountriesLoaded() => _buildCountriesList(context, state),
            CountriesError() => ErrorDisplayWidget(
                message: state.message,
                onRetry: () => context.read<CountriesCubit>().refresh(),
              ),
          };
        },
      ),
    );
  }

  Widget _buildCountriesList(BuildContext context, CountriesLoaded state) {
    if (state.countries.isEmpty) {
      return const Center(
        child: Text('No countries found'),
      );
    }

    // Preload flags in background for better performance
    _preloadFlags(context, state);

    return RefreshIndicator(
      onRefresh: () => context.read<CountriesCubit>().refresh(),
      child: ListView.builder(
        itemCount: state.countries.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        cacheExtent:
            1000, // Prerender more items offscreen for smoother scrolling
        itemExtent: 140, // Fixed height estimation for better performance
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          final country = state.countries[index];
          final isInWishlist = state.wishlistStatus[country.name] ?? false;

          return RepaintBoundary(
            child: CountryCard(
              country: country,
              isInWishlist: isInWishlist,
              index: index,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => CountryDetailPage(
                    countryName: country.name,
                  ),
                ),
              ),
              onWishlistToggle: () =>
                  context.read<CountriesCubit>().toggleWishlist(country),
            ),
          );
        },
      ),
    );
  }

  void _preloadFlags(BuildContext context, CountriesLoaded state) {
    if (_flagsPreloaded) return;
    _flagsPreloaded = true;

    // Extract all flag URLs
    final flagUrls = state.countries.map((country) => country.flagUrl).toList();

    // Prioritize immediate precaching of visible items
    // using Flutter's precacheImage
    _precacheVisibleFlags(context, flagUrls.take(8).toList());

    // Use comprehensive flag optimization for the rest
    FlagPerformanceOptimizer.optimizeFlagBatch(
      context,
      flagUrls,
      onComplete: () {
        final report = FlagPerformanceOptimizer.getOptimizationReport();
        debugPrint(
          'Flag optimization completed: ${report.totalFlagsWarmedUp} flags optimized',
        );
        debugPrint(
          'Average load time: ${report.averageLoadTime.toStringAsFixed(1)}ms',
        );
      },
    ).catchError((error) {
      debugPrint('Error optimizing flags: $error');
    });

    // Also preload critical flags (first few visible items) immediately
    final criticalUrls =
        flagUrls.take(6).toList(); // First 6 items likely visible
    FlagPerformanceOptimizer.preloadCriticalFlags(context, criticalUrls);
  }

  void _precacheVisibleFlags(BuildContext context, List<String> flagUrls) {
    // Use Flutter's built-in precacheImage for immediate caching of visible items
    for (final url in flagUrls) {
      if (!url.toLowerCase().endsWith('.svg')) {
        precacheImage(
          NetworkImage(url),
          context,
          onError: (exception, stackTrace) {
            debugPrint('Failed to precache flag $url: $exception');
          },
        );
      }
    }
  }
}

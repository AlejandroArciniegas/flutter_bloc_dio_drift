import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:euro_explorer/injection_container.dart';
import 'package:euro_explorer/presentation/blocs/countries/countries_cubit.dart';
import 'package:euro_explorer/presentation/widgets/country_card.dart';
import 'package:euro_explorer/presentation/widgets/error_widget.dart';
import 'package:euro_explorer/presentation/widgets/loading_widget.dart';
import 'package:euro_explorer/presentation/pages/country_detail_page.dart';
import 'package:euro_explorer/presentation/pages/wishlist_page.dart';

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

class CountriesView extends StatelessWidget {
  const CountriesView({super.key});

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

    return RefreshIndicator(
      onRefresh: () => context.read<CountriesCubit>().refresh(),
      child: ListView.builder(
        itemCount: state.countries.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final country = state.countries[index];
          final isInWishlist = state.wishlistStatus[country.name] ?? false;

          return CountryCard(
            country: country,
            isInWishlist: isInWishlist,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => CountryDetailPage(
                  countryName: country.name,
                ),
              ),
            ),
            onWishlistToggle: () => context
                .read<CountriesCubit>()
                .toggleWishlist(country),
          );
        },
      ),
    );
  }
}
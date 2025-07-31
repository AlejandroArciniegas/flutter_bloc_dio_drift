import 'package:euro_explorer/domain/entities/country.dart';
import 'package:euro_explorer/injection_container.dart';
import 'package:euro_explorer/presentation/blocs/country_detail/country_detail_cubit.dart';
import 'package:euro_explorer/presentation/theme/app_theme.dart';
import 'package:euro_explorer/presentation/widgets/error_widget.dart';
import 'package:euro_explorer/presentation/widgets/loading_widget.dart';
import 'package:euro_explorer/presentation/widgets/smart_flag_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page displaying detailed information about a country
class CountryDetailPage extends StatelessWidget {
  const CountryDetailPage({
    required this.countryName,
    super.key,
  });

  final String countryName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CountryDetailCubit>()
        ..loadCountryDetails(countryName),
      child: CountryDetailView(countryName: countryName),
    );
  }
}

class CountryDetailView extends StatelessWidget {
  const CountryDetailView({
    required this.countryName,
    super.key,
  });

  final String countryName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(countryName),
        actions: [
          BlocBuilder<CountryDetailCubit, CountryDetailState>(
            builder: (context, state) {
              if (state is CountryDetailLoaded) {
                return IconButton(
                  onPressed: () => context
                      .read<CountryDetailCubit>()
                      .toggleWishlist(),
                  icon: Icon(
                    state.isInWishlist 
                        ? Icons.favorite 
                        : Icons.favorite_border,
                  ),
                  tooltip: state.isInWishlist 
                      ? 'Remove from wishlist' 
                      : 'Add to wishlist',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<CountryDetailCubit, CountryDetailState>(
        builder: (context, state) {
          return switch (state) {
            CountryDetailInitial() => const LoadingWidget(
                message: 'Initializing...',
              ),
            CountryDetailLoading() => const LoadingWidget(
                message: 'Loading country details...',
              ),
            CountryDetailLoaded() => _buildCountryDetails(context, state),
            CountryDetailError() => ErrorDisplayWidget(
                message: state.message,
                onRetry: () => context
                    .read<CountryDetailCubit>()
                    .loadCountryDetails(countryName),
              ),
          };
        },
      ),
    );
  }

  Widget _buildCountryDetails(BuildContext context, CountryDetailLoaded state) {
    final country = state.country;

    return SingleChildScrollView(
      padding: AppStyles.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flag
          _buildFlagSection(context, country),
          
          const SizedBox(height: 24),
          
          // Basic Information
          _buildInfoCard(
            context,
            'Basic Information',
            [
              _InfoRow('Official Name', country.name),
              _InfoRow('Capital', country.capital),
              _InfoRow('Region', country.region),
              _InfoRow('Sub-region', country.subregion),
              _InfoRow('Population', _formatPopulation(country.population)),
              _InfoRow('Area', '${_formatArea(country.area)} km²'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Native Names
          if (country.nativeNames.isNotEmpty)
            _buildInfoCard(
              context,
              'Native Names',
              country.nativeNames.entries
                  .map((entry) => _InfoRow(entry.key.toUpperCase(), entry.value))
                  .toList(),
            ),
          
          const SizedBox(height: 16),
          
          // Currencies
          if (country.currencies.isNotEmpty)
            _buildInfoCard(
              context,
              'Currencies',
              country.currencies.entries
                  .map((entry) => _InfoRow(entry.key, entry.value))
                  .toList(),
            ),
          
          const SizedBox(height: 16),
          
          // Languages
          if (country.languages.isNotEmpty)
            _buildInfoCard(
              context,
              'Languages',
              country.languages.entries
                  .map((entry) => _InfoRow(entry.key, entry.value))
                  .toList(),
            ),
          
          const SizedBox(height: 16),
          
          // Timezones
          if (country.timezones.isNotEmpty)
            _buildInfoCard(
              context,
              'Timezones',
              [
                _InfoRow('Zones', country.timezones.join(', ')),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Maps
          if (country.mapsUrl.isNotEmpty)
            _buildMapsCard(context, country.mapsUrl),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFlagSection(BuildContext context, Country country) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SmartFlagImage(
              imageUrl: country.flagUrl,
              width: 200,
              height: 120,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<_InfoRow> rows,
  ) {
    return Card(
      child: Padding(
        padding: AppStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppStyles.titleStyle.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...rows.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${row.label}:',
                      style: AppStyles.subtitleStyle.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: AppStyles.bodyStyle.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),),
          ],
        ),
      ),
    );
  }

  Widget _buildMapsCard(BuildContext context, String mapsUrl) {
    return Card(
      child: Padding(
        padding: AppStyles.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maps',
              style: AppStyles.titleStyle.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(mapsUrl),
                icon: const Icon(Icons.map),
                label: const Text('View on Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatPopulation(int population) {
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)} million';
    } else if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(1)} thousand';
    }
    return population.toString();
  }

  String _formatArea(double area) {
    if (area >= 1000000) {
      return '${(area / 1000000).toStringAsFixed(1)}M';
    } else if (area >= 1000) {
      return '${(area / 1000).toStringAsFixed(1)}K';
    }
    return area.toStringAsFixed(0);
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  
  final String label;
  final String value;
}

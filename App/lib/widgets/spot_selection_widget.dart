import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/colors/ui_colors.dart';
import '../design_system/colors/color_aliases.dart';
import '../models/core/spot.dart';
import '../providers/spots_provider.dart';
import '../utils/constants.dart';

/// Widget for selecting spots to include in a post
///
/// This screen allows users to:
/// - Search through available spots
/// - Filter by category
/// - Select/deselect spots (with maximum limit)
/// - See which spots are already selected
/// - Save selection and return to post creation
class SpotSelectionWidget extends StatefulWidget {
  /// Currently selected spots
  final List<Spot> selectedSpots;

  /// Maximum number of spots that can be selected
  final int maxSpots;

  /// Callback when spots selection changes
  final Function(List<Spot>) onSpotsSelected;

  const SpotSelectionWidget({
    Key? key,
    required this.selectedSpots,
    required this.maxSpots,
    required this.onSpotsSelected,
  }) : super(key: key);

  @override
  State<SpotSelectionWidget> createState() => _SpotSelectionWidgetState();
}

class _SpotSelectionWidgetState extends State<SpotSelectionWidget> {
  // Search and filter state
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  // Working copy of selected spots (until user confirms)
  late List<Spot> _workingSelectedSpots;

  // UI state
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Create working copy of selected spots
    _workingSelectedSpots = List.from(widget.selectedSpots);

    // Load spots when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSpots();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.surfacePrimary,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Builds the app bar with save/cancel actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Select Spots (${_workingSelectedSpots.length}/${widget.maxSpots})',
      ),
      backgroundColor: ColorAliases.primaryDefault,
      foregroundColor: UIColors.textOnAction,
      leading: IconButton(icon: const Icon(Icons.close), onPressed: _onCancel),
      actions: [
        TextButton(
          onPressed: _hasChanges() ? _onSave : null,
          child: Text(
            'Save',
            style: TextStyle(
              color:
                  _hasChanges()
                      ? UIColors.textOnAction
                      : UIColors.textOnAction.withOpacity(0.5),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
      elevation: 0,
    );
  }

  /// Builds the main body content
  Widget _buildBody() {
    return Column(
      children: [
        // Search and filter section
        _buildSearchAndFilter(),

        // Selected spots summary (if any)
        if (_workingSelectedSpots.isNotEmpty) _buildSelectedSummary(),

        // Spots list
        Expanded(
          child: Consumer<SpotsProvider>(
            builder: (context, spotsProvider, child) {
              if (_isLoading || spotsProvider.isLoadingSpots) {
                return _buildLoadingState();
              }

              if (_errorMessage != null) {
                return _buildErrorState();
              }

              final filteredSpots = _getFilteredSpots(spotsProvider.allSpots);

              if (filteredSpots.isEmpty) {
                return _buildEmptyState();
              }

              return _buildSpotsList(filteredSpots);
            },
          ),
        ),
      ],
    );
  }

  /// Builds search bar and category filter
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: ColorAliases.white,
        border: Border(bottom: BorderSide(color: UIColors.borderPrimary)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search spots...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                      : null,
            ),
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to filter results
            },
          ),

          const SizedBox(height: 12),

          // Category filter
          _buildCategoryFilter(),
        ],
      ),
    );
  }

  /// Builds category filter chips
  Widget _buildCategoryFilter() {
    final categories = [
      'All',
      'Praia',
      'Cachoeira',
      'Montanha',
      'Parque Nacional',
      'Centro Histórico',
      'Museu',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: EdgeInsets.only(
              right: index < categories.length - 1 ? 8 : 0,
            ),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: ColorAliases.white,
              selectedColor: ColorAliases.primary100,
              checkmarkColor: ColorAliases.primaryDefault,
              labelStyle: TextStyle(
                color:
                    isSelected
                        ? ColorAliases.primaryDefault
                        : UIColors.textBody,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds selected spots summary bar
  Widget _buildSelectedSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: ColorAliases.primary100,
        border: Border(bottom: BorderSide(color: UIColors.borderPrimary)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: ColorAliases.primaryDefault,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_workingSelectedSpots.length} spot${_workingSelectedSpots.length == 1 ? '' : 's'} selected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColorAliases.primaryDefault,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_workingSelectedSpots.isNotEmpty)
            TextButton(
              onPressed: _onClearAll,
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: ColorAliases.primaryDefault,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the spots list
  Widget _buildSpotsList(List<Spot> spots) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final spot = spots[index];
        final isSelected = _isSpotSelected(spot);
        final canSelect =
            !isSelected && _workingSelectedSpots.length < widget.maxSpots;

        return _buildSpotItem(spot, isSelected, canSelect);
      },
    );
  }

  /// Builds an individual spot item
  Widget _buildSpotItem(Spot spot, bool isSelected, bool canSelect) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? ColorAliases.primary100 : ColorAliases.white,
        border: Border.all(
          color:
              isSelected ? ColorAliases.primaryDefault : UIColors.borderPrimary,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _onSpotTap(spot, isSelected, canSelect),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Spot image/icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ColorAliases.neutral100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: UIColors.borderPrimary),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child:
                      spot.hasValidImageUrl
                          ? Image.network(
                            spot.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildSpotIcon(spot.category);
                            },
                          )
                          : _buildSpotIcon(spot.category),
                ),
              ),

              const SizedBox(width: 12),

              // Spot info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.spot_name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected
                                ? ColorAliases.primaryDefault
                                : UIColors.textHeadings,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot.fullLocation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            isSelected
                                ? ColorAliases.primary600
                                : UIColors.textDisabled,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? ColorAliases.primaryDefault
                                : ColorAliases.neutral100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        spot.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isSelected
                                  ? UIColors.textOnAction
                                  : UIColors.textBody,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color:
                    isSelected
                        ? ColorAliases.primaryDefault
                        : (canSelect
                            ? UIColors.iconPrimary
                            : UIColors.iconPrimary.withOpacity(0.3)),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds spot category icon
  Widget _buildSpotIcon(String category) {
    return Icon(
      _getCategoryIcon(category),
      color: ColorAliases.primaryDefault,
      size: 24,
    );
  }

  /// Builds loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              ColorAliases.primaryDefault,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading spots...',
            style: TextStyle(color: UIColors.textDisabled),
          ),
        ],
      ),
    );
  }

  /// Builds error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: UIColors.iconError,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load spots',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: UIColors.textDisabled),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadSpots, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  /// Builds empty state
  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    final hasFilter = _selectedCategory != 'All';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch || hasFilter ? Icons.search_off : Icons.place_outlined,
              color: UIColors.iconPrimary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch || hasFilter ? 'No spots found' : 'No spots available',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch || hasFilter
                  ? 'Try adjusting your search or filter'
                  : 'There are no spots to display',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: UIColors.textDisabled),
              textAlign: TextAlign.center,
            ),
            if (hasSearch || hasFilter) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // DATA METHODS
  // =============================================================================

  /// Loads spots from the provider
  Future<void> _loadSpots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
      await spotsProvider.loadSpots();
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load spots. Please check your connection.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Filters spots based on search and category
  List<Spot> _getFilteredSpots(List<Spot> allSpots) {
    List<Spot> filtered = allSpots;

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered =
          filtered.where((spot) {
            return spot.spot_name.toLowerCase().contains(query) ||
                spot.city.toLowerCase().contains(query) ||
                spot.country.toLowerCase().contains(query) ||
                spot.category.toLowerCase().contains(query) ||
                (spot.description?.toLowerCase().contains(query) ?? false);
          }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((spot) {
            return spot.category == _selectedCategory;
          }).toList();
    }

    return filtered;
  }

  /// Checks if a spot is currently selected
  bool _isSpotSelected(Spot spot) {
    return _workingSelectedSpots.any((s) => s.spot_id == spot.spot_id);
  }

  /// Checks if there are changes from initial selection
  bool _hasChanges() {
    if (_workingSelectedSpots.length != widget.selectedSpots.length) {
      return true;
    }

    for (final spot in _workingSelectedSpots) {
      if (!widget.selectedSpots.any((s) => s.spot_id == spot.spot_id)) {
        return true;
      }
    }

    return false;
  }

  // =============================================================================
  // EVENT HANDLERS
  // =============================================================================

  /// Handles spot tap (select/deselect)
  void _onSpotTap(Spot spot, bool isSelected, bool canSelect) {
    if (isSelected) {
      // Deselect spot
      setState(() {
        _workingSelectedSpots.removeWhere((s) => s.spot_id == spot.spot_id);
      });
    } else if (canSelect) {
      // Select spot
      setState(() {
        _workingSelectedSpots.add(spot);
      });
    } else {
      // Show max limit message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxSpots} spots allowed'),
          backgroundColor: UIColors.surfaceWarning,
        ),
      );
    }
  }

  /// Handles clear all selection
  void _onClearAll() {
    setState(() {
      _workingSelectedSpots.clear();
    });
  }

  /// Handles save action
  void _onSave() {
    widget.onSpotsSelected(_workingSelectedSpots);
    Navigator.of(context).pop();
  }

  /// Handles cancel action
  void _onCancel() {
    if (_hasChanges()) {
      _showCancelDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Clears all filters
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
    });
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Shows cancel confirmation dialog
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Your selection changes will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue editing'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close screen
                },
                child: const Text('Discard'),
              ),
            ],
          ),
    );
  }

  /// Gets icon for spot category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'praia':
        return Icons.beach_access;
      case 'cachoeira':
        return Icons.water;
      case 'montanha':
        return Icons.landscape;
      case 'parque nacional':
        return Icons.park;
      case 'centro histórico':
        return Icons.account_balance;
      case 'museu':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }
}

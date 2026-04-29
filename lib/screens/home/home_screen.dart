import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/book_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../listing/book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();
    final listings = bookProvider.filteredListings;
    final hasFilters = bookProvider.selectedDepartment != 'All' ||
        bookProvider.selectedType != 'All' ||
        bookProvider.searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BookXchange'),
        actions: [
          IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _showFilters,
              tooltip: 'Filters'),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: bookProvider.setSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by title, author, ISBN...',
                hintStyle: const TextStyle(
                    color: Colors.white70, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white70),
                        onPressed: () {
                          _searchCtrl.clear();
                          bookProvider.setSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                    label: bookProvider.sortBy,
                    icon: Icons.sort,
                    onTap: _showFilters),
                const SizedBox(width: 8),
                for (final type in ['All', 'Sell', 'Exchange'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: bookProvider.selectedType == type,
                      onSelected: (_) =>
                          bookProvider.setTypeFilter(type),
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: bookProvider.selectedType == type
                            ? Colors.white
                            : AppTheme.textDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (hasFilters)
                  TextButton.icon(
                    onPressed: () {
                      bookProvider.clearFilters();
                      _searchCtrl.clear();
                    },
                    icon: const Icon(Icons.clear, size: 14),
                    label: const Text('Clear',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        padding: EdgeInsets.zero),
                  ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${listings.length} book${listings.length == 1 ? '' : 's'} found',
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 13),
                ),
                if (bookProvider.selectedDepartment != 'All') ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(bookProvider.selectedDepartment,
                        style: const TextStyle(fontSize: 11)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () =>
                        bookProvider.setDepartmentFilter('All'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Grid
          Expanded(
            child: listings.isEmpty
                ? _EmptyState(hasFilters: hasFilters)
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (ctx, i) => BookCard(
                      listing: listings[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookDetailScreen(listing: listings[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textGrey),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textDark)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                size: 16, color: AppTheme.textGrey),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters
                ? Icons.search_off
                : Icons.menu_book_outlined,
            size: 64,
            color: AppTheme.textGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No books match your filters'
                : 'No listings yet',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGrey),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your search or filters'
                : 'Be the first to list a book!',
            style: const TextStyle(
                color: AppTheme.textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

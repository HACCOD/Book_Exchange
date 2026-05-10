import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/book_listing_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../services/asset_service.dart';
import '../../utils/app_theme.dart';
import '../listing/book_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final bookProvider = context.watch<BookProvider>();
    final myListings = bookProvider.listingsForUser(user.id);
    final reviews = bookProvider.reviewsForUser(user.id);
    final transactions = bookProvider.transactionsForUser(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                user: user,
                listingsCount: myListings.length,
                transactionsCount: transactions.length,
                reviewsCount: reviews.length,
              ),
            ),
            const SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textGrey,
                  indicatorColor: AppTheme.primary,
                  tabs: [
                    Tab(text: 'My Listings'),
                    Tab(text: 'Transactions'),
                    Tab(text: 'Reviews'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _MyListingsTab(listings: myListings),
              _TransactionsTab(transactions: transactions),
              _ReviewsTab(reviews: reviews),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child:
                const Text('Sign Out', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final int listingsCount;
  final int transactionsCount;
  final int reviewsCount;

  const _ProfileHeader({
    required this.user,
    required this.listingsCount,
    required this.transactionsCount,
    required this.reviewsCount,
  });

  Widget _buildAvatar(dynamic user) {
    if (user.profileImage != null) {
      final img = user.profileImage as String;
      if (img.startsWith('/')) {
        return ClipOval(
          child:
              Image.file(File(img), width: 88, height: 88, fit: BoxFit.cover),
        );
      }
      return ClipOval(
        child: Image.network(img,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                )),
      );
    }
    return Text(
      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
      style: const TextStyle(
          color: AppTheme.primary, fontSize: 36, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            child: _buildAvatar(user),
          ),
          const SizedBox(height: 12),
          Text(user.name,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(user.email,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_outlined,
                  size: 14, color: AppTheme.textGrey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${user.university} • ${user.department}',
                  style:
                      const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user.rating > 0) ...[
            RatingBarIndicator(
              rating: user.rating,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 20,
            ),
            const SizedBox(height: 4),
            Text(
              '${user.rating.toStringAsFixed(1)} (${user.totalRatings} reviews)',
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(label: 'Listings', value: '$listingsCount'),
              Container(width: 1, height: 30, color: AppTheme.divider),
              _StatItem(label: 'Transactions', value: '$transactionsCount'),
              Container(width: 1, height: 30, color: AppTheme.divider),
              _StatItem(label: 'Reviews', value: '$reviewsCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          Text(label,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        ],
      );
}

class _MyListingsTab extends StatelessWidget {
  final List<BookListingModel> listings;
  const _MyListingsTab({required this.listings});

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: AppTheme.textGrey),
            SizedBox(height: 12),
            Text('No listings yet',
                style: TextStyle(
                    color: AppTheme.textGrey, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Tap the Sell tab to create your first listing',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: listings.length,
      itemBuilder: (ctx, i) {
        final book = listings[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 56,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: book.images.isNotEmpty
                  ? Image.file(File(AssetService().resolve(book.images.first)),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.menu_book, color: AppTheme.primary))
                  : const Icon(Icons.menu_book, color: AppTheme.primary),
            ),
            title: Text(book.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.author,
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Badge(
                        text: book.listingType,
                        color: book.listingType == 'Exchange'
                            ? AppTheme.accent
                            : AppTheme.primary),
                    const SizedBox(width: 6),
                    _Badge(
                        text: book.isAvailable ? 'Available' : 'Sold',
                        color: book.isAvailable
                            ? AppTheme.success
                            : AppTheme.textGrey),
                    const SizedBox(width: 6),
                    Text(book.priceDisplay,
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BookDetailScreen(listing: book)),
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}

class _TransactionsTab extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _TransactionsTab({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppTheme.textGrey),
            SizedBox(height: 12),
            Text('No transactions yet',
                style: TextStyle(
                    color: AppTheme.textGrey, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: transactions.length,
      itemBuilder: (ctx, i) {
        final t = transactions[i];
        final userId = context.read<AuthProvider>().currentUser!.id;
        final isSeller = t.sellerId == userId;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSeller
                  ? AppTheme.success.withValues(alpha: 0.15)
                  : AppTheme.accent.withValues(alpha: 0.15),
              child: Icon(
                isSeller ? Icons.arrow_upward : Icons.arrow_downward,
                color: isSeller ? AppTheme.success : AppTheme.accent,
              ),
            ),
            title: Text(t.bookTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              isSeller
                  ? 'Sold to ${t.buyerName}'
                  : 'Bought from ${t.sellerName}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t.price != null
                      ? 'Rs. ${t.price!.toStringAsFixed(0)}'
                      : 'Exchange',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSeller ? AppTheme.success : AppTheme.error),
                ),
                Text(
                  '${t.completedAt.day}/${t.completedAt.month}/${t.completedAt.year}',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final List<ReviewModel> reviews;
  const _ReviewsTab({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 48, color: AppTheme.textGrey),
            SizedBox(height: 12),
            Text('No reviews yet',
                style: TextStyle(
                    color: AppTheme.textGrey, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reviews.length,
      itemBuilder: (ctx, i) {
        final r = reviews[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        r.reviewerName[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.reviewerName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('For: ${r.bookTitle}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textGrey)),
                        ],
                      ),
                    ),
                    RatingBarIndicator(
                      rating: r.rating,
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r.comment,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 4),
                Text(
                  '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: Colors.white, child: tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/book_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_theme.dart';
import '../messaging/chat_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final BookListingModel listing;
  const BookDetailScreen({super.key, required this.listing});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().incrementViews(widget.listing.id);
    });
  }

  void _startChat() {
    final user = context.read<AuthProvider>().currentUser!;
    if (user.id == widget.listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own listing')),
      );
      return;
    }
    final chat = context.read<ChatProvider>().startChat(
          bookId: widget.listing.id,
          bookTitle: widget.listing.title,
          buyerId: user.id,
          buyerName: user.name,
          sellerId: widget.listing.sellerId,
          sellerName: widget.listing.sellerName,
        );
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
  }

  Future<void> _handleMenuAction(String val) async {
    final bookProvider = context.read<BookProvider>();
    if (val == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Listing'),
          content:
              const Text('Are you sure you want to delete this listing?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(color: AppTheme.error))),
          ],
        ),
      );
      if (confirm == true) {
        await bookProvider.deleteListing(widget.listing.id);
        if (mounted) Navigator.pop(context);
      }
    } else if (val == 'sold') {
      await bookProvider.markAsSold(widget.listing.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final user = context.watch<AuthProvider>().currentUser;
    final isOwner = user?.id == listing.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'sold', child: Text('Mark as Sold')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Listing',
                        style: TextStyle(color: AppTheme.error))),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book image
            Container(
              height: 220,
              width: double.infinity,
              color: AppTheme.primary.withValues(alpha: 0.1),
              child: listing.images.isNotEmpty
                  ? Image.network(listing.images.first,
                      fit: BoxFit.cover)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book,
                              size: 80,
                              color:
                                  AppTheme.primary.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24),
                            child: Text(
                              listing.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(listing.title,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      _TypeBadge(type: listing.listingType),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(listing.author,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 15)),
                  if (listing.isbn != null) ...[
                    const SizedBox(height: 2),
                    Text('ISBN: ${listing.isbn}',
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),

                  // Price box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sell_outlined,
                            color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          listing.priceDisplay,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _DetailItem(
                          icon: Icons.star_outline,
                          label: 'Condition',
                          value:
                              '${listing.conditionEmoji} ${listing.condition}'),
                      _DetailItem(
                          icon: Icons.school_outlined,
                          label: 'Department',
                          value: listing.department),
                      _DetailItem(
                          icon: Icons.book_outlined,
                          label: 'Course',
                          value: listing.course),
                      _DetailItem(
                          icon: Icons.category_outlined,
                          label: 'Type',
                          value: listing.listingType),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Exchange preference
                  if (listing.exchangePreference != null &&
                      listing.exchangePreference!.isNotEmpty) ...[
                    const Text('Exchange Preference',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz,
                              color: AppTheme.accent),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  listing.exchangePreference!,
                                  style:
                                      const TextStyle(fontSize: 14))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(listing.description,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 16),

                  // Seller
                  const Text('Seller',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.2),
                          child: Text(
                            listing.sellerName.isNotEmpty
                                ? listing.sellerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(listing.sellerName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 14,
                                      color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    listing.sellerRating > 0
                                        ? listing.sellerRating
                                            .toStringAsFixed(1)
                                        : 'New',
                                    style: const TextStyle(
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        'Posted ${timeago.format(listing.createdAt)}',
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.remove_red_eye_outlined,
                          size: 14, color: AppTheme.textGrey),
                      const SizedBox(width: 4),
                      Text('${listing.views} views',
                          style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isOwner && listing.isAvailable
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _startChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(listing.listingType == 'Exchange'
                      ? 'Propose Exchange'
                      : 'Contact Seller'),
                ),
              ),
            )
          : isOwner
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('This is your listing'),
                    ),
                  ),
                )
              : null,
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case 'Sell':
        color = AppTheme.primary;
        break;
      case 'Exchange':
        color = AppTheme.accent;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(type,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9, color: AppTheme.textGrey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

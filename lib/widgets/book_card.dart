import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book_listing_model.dart';
import '../services/asset_service.dart';
import '../utils/app_theme.dart';

class BookCard extends StatelessWidget {
  final BookListingModel listing;
  final VoidCallback onTap;

  const BookCard({super.key, required this.listing, required this.onTap});

  Color get _conditionColor {
    switch (listing.condition) {
      case 'Like New':
        return const Color(0xFF2E7D32);
      case 'Very Good':
        return const Color(0xFF388E3C);
      case 'Good':
        return const Color(0xFF1976D2);
      case 'Acceptable':
        return const Color(0xFFF57C00);
      case 'Poor':
        return const Color(0xFFD32F2F);
      default:
        return AppTheme.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _BookImage(listing: listing),
                  // Type badge top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _TypeBadge(type: listing.listingType),
                  ),
                  // Condition badge top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        listing.condition,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _conditionColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ───────────────────────────────────────────
            Expanded(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.textDark,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      listing.author,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          listing.priceDisplay,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye_outlined,
                                size: 11, color: AppTheme.textGrey),
                            const SizedBox(width: 2),
                            Text(
                              '${listing.views}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      listing.course,
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookImage extends StatelessWidget {
  final BookListingModel listing;
  const _BookImage({required this.listing});

  @override
  Widget build(BuildContext context) {
    if (listing.images.isNotEmpty) {
      final raw = listing.images.first;
      final img = AssetService().resolve(raw);
      // Local file path
      if (img.startsWith('/')) {
        return Image.file(File(img),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _Placeholder(title: listing.title));
      }
      // Network URL
      return Image.network(img,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Placeholder(title: listing.title));
    }
    return _Placeholder(title: listing.title);
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  static const _colors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFBF360C),
    Color(0xFF00695C),
    Color(0xFF4527A0),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[title.length % _colors.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded,
                size: 38, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
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
        color = const Color(0xFF1976D2);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

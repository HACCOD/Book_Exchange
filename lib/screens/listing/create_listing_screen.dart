import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/book_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _exchangePrefCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedDepartment = AppConstants.departments.first;
  String _selectedCondition = AppConstants.conditions.first;
  String _selectedType = 'Sell';
  final List<File> _pickedImages = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _isbnCtrl.dispose();
    _courseCtrl.dispose();
    _priceCtrl.dispose();
    _exchangePrefCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _pickedImages.add(File(picked.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    if (_pickedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 photos allowed')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Add Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  // ── Submit ─────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().currentUser!;

    final listing = BookListingModel(
      id: const Uuid().v4(),
      sellerId: user.id,
      sellerName: user.name,
      sellerImage: user.profileImage,
      sellerRating: user.rating,
      title: _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
      isbn: _isbnCtrl.text.trim().isEmpty ? null : _isbnCtrl.text.trim(),
      department: _selectedDepartment,
      course: _courseCtrl.text.trim(),
      condition: _selectedCondition,
      listingType: _selectedType,
      price: _priceCtrl.text.isEmpty ? null : double.tryParse(_priceCtrl.text),
      exchangePreference: _exchangePrefCtrl.text.trim().isEmpty
          ? null
          : _exchangePrefCtrl.text.trim(),
      images: _pickedImages.map((f) => f.path).toList(),
      description: _descCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await context.read<BookProvider>().addListing(listing);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing posted successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      _clearForm();
    }
  }

  void _clearForm() {
    _titleCtrl.clear();
    _authorCtrl.clear();
    _isbnCtrl.clear();
    _courseCtrl.clear();
    _priceCtrl.clear();
    _exchangePrefCtrl.clear();
    _descCtrl.clear();
    setState(() {
      _selectedDepartment = AppConstants.departments.first;
      _selectedCondition = AppConstants.conditions.first;
      _selectedType = 'Sell';
      _pickedImages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<BookProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo section ──────────────────────────────────
              const _SectionHeader(
                  icon: Icons.photo_camera_outlined, title: 'Book Photos'),
              const SizedBox(height: 10),
              _PhotoGrid(
                images: _pickedImages,
                onAdd: _showImageSourceSheet,
                onRemove: _removeImage,
              ),
              const SizedBox(height: 24),

              // ── Listing type ───────────────────────────────────
              const _SectionHeader(icon: Icons.sell_outlined, title: 'Listing Type'),
              const SizedBox(height: 10),
              Row(
                children: AppConstants.listingTypes
                    .map((type) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedType = type),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedType == type
                                      ? AppTheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedType == type
                                        ? AppTheme.primary
                                        : AppTheme.divider,
                                  ),
                                  boxShadow: _selectedType == type
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  type,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedType == type
                                        ? Colors.white
                                        : AppTheme.textDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // ── Book details ───────────────────────────────────
              const _SectionHeader(
                  icon: Icons.menu_book_outlined, title: 'Book Details'),
              const SizedBox(height: 10),

              _label('Title *'),
              TextFormField(
                controller: _titleCtrl,
                validator: (v) => Validators.required(v, 'Title'),
                decoration: const InputDecoration(
                    hintText: 'e.g. Introduction to Algorithms'),
              ),
              const SizedBox(height: 14),

              _label('Author *'),
              TextFormField(
                controller: _authorCtrl,
                validator: (v) => Validators.required(v, 'Author'),
                decoration:
                    const InputDecoration(hintText: 'e.g. Thomas H. Cormen'),
              ),
              const SizedBox(height: 14),

              _label('ISBN (Optional)'),
              TextFormField(
                controller: _isbnCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(hintText: 'e.g. 978-0262033848'),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Department *'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDepartment,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14)),
                          items: AppConstants.departments
                              .map((d) => DropdownMenuItem(
                                  value: d,
                                  child:
                                      Text(d, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedDepartment = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Condition *'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCondition,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14)),
                          items: AppConstants.conditions
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCondition = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _label('Course *'),
              TextFormField(
                controller: _courseCtrl,
                validator: (v) => Validators.required(v, 'Course'),
                decoration: const InputDecoration(
                    hintText: 'e.g. CS301 - Data Structures'),
              ),
              const SizedBox(height: 24),

              // ── Pricing ────────────────────────────────────────
              const _SectionHeader(
                  icon: Icons.currency_rupee, title: 'Pricing & Exchange'),
              const SizedBox(height: 10),

              if (_selectedType != 'Exchange') ...[
                _label(_selectedType == 'Both'
                    ? 'Price (Rs.) — Optional if also exchanging'
                    : 'Price (Rs.) *'),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  validator: _selectedType == 'Sell'
                      ? (v) => Validators.required(v, 'Price')
                      : Validators.price,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 500',
                    prefixIcon: Icon(Icons.currency_rupee, size: 18),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (_selectedType != 'Sell') ...[
                _label('Exchange Preference'),
                TextFormField(
                  controller: _exchangePrefCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Looking for Linear Algebra or Physics book',
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Description ────────────────────────────────────
              const _SectionHeader(
                  icon: Icons.description_outlined, title: 'Description'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                validator: (v) => Validators.required(v, 'Description'),
                decoration: const InputDecoration(
                  hintText:
                      'Describe the condition, any highlights, missing pages, etc.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Post Listing'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textDark)),
      );
}

// ── Photo grid widget ──────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<File> images;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _PhotoGrid(
      {required this.images, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          if (images.length < 4)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 28,
                        color: AppTheme.primary.withValues(alpha: 0.6)),
                    const SizedBox(height: 4),
                    Text(
                      images.isEmpty ? 'Add Photo' : 'Add More',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${images.length}/4',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ),
          // Image thumbnails
          ...images.asMap().entries.map((entry) {
            final i = entry.key;
            final file = entry.value;
            return Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(file, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 4,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
                if (i == 0)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Cover',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
      ],
    );
  }
}

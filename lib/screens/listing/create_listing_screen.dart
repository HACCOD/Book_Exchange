import 'package:flutter/material.dart';
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
      price: _priceCtrl.text.isEmpty
          ? null
          : double.tryParse(_priceCtrl.text),
      exchangePreference: _exchangePrefCtrl.text.trim().isEmpty
          ? null
          : _exchangePrefCtrl.text.trim(),
      images: [],
      description: _descCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await context.read<BookProvider>().addListing(listing);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing created successfully!'),
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
              // Photo upload placeholder
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Image upload requires device storage permission')),
                ),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: AppTheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text('Tap to add photos',
                          style:
                              TextStyle(color: AppTheme.textGrey)),
                      const Text('(Optional)',
                          style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Listing type
              _label('Listing Type'),
              Row(
                children: AppConstants.listingTypes
                    .map((type) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _selectedType = type),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedType == type
                                      ? AppTheme.primary
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedType == type
                                        ? AppTheme.primary
                                        : AppTheme.divider,
                                  ),
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
              const SizedBox(height: 20),

              _label('Book Title *'),
              TextFormField(
                controller: _titleCtrl,
                validator: (v) => Validators.required(v, 'Book title'),
                decoration: const InputDecoration(
                    hintText: 'e.g. Introduction to Algorithms'),
              ),
              const SizedBox(height: 14),

              _label('Author *'),
              TextFormField(
                controller: _authorCtrl,
                validator: (v) => Validators.required(v, 'Author'),
                decoration: const InputDecoration(
                    hintText: 'e.g. Thomas H. Cormen'),
              ),
              const SizedBox(height: 14),

              _label('ISBN (Optional)'),
              TextFormField(
                controller: _isbnCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: 'e.g. 978-0262033848'),
              ),
              const SizedBox(height: 14),

              _label('Department *'),
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.school_outlined)),
                items: AppConstants.departments
                    .map((d) =>
                        DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedDepartment = v!),
              ),
              const SizedBox(height: 14),

              _label('Course *'),
              TextFormField(
                controller: _courseCtrl,
                validator: (v) => Validators.required(v, 'Course'),
                decoration: const InputDecoration(
                    hintText: 'e.g. CS301 - Data Structures'),
              ),
              const SizedBox(height: 14),

              _label('Book Condition *'),
              DropdownButtonFormField<String>(
                initialValue: _selectedCondition,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.star_outline)),
                items: AppConstants.conditions
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCondition = v!),
              ),
              const SizedBox(height: 14),

              if (_selectedType != 'Exchange') ...[
                _label(_selectedType == 'Both'
                    ? 'Price (Rs.) — Optional for exchange'
                    : 'Price (Rs.) *'),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  validator: _selectedType == 'Sell'
                      ? (v) => Validators.required(v, 'Price')
                      : Validators.price,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 500',
                    prefixIcon: Icon(Icons.currency_rupee),
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
                    hintText:
                        'e.g. Looking for Linear Algebra or Physics book',
                  ),
                ),
                const SizedBox(height: 14),
              ],

              _label('Description *'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                validator: (v) =>
                    Validators.required(v, 'Description'),
                decoration: const InputDecoration(
                  hintText:
                      'Describe the condition, highlights, missing pages, etc.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 28),

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
              const SizedBox(height: 20),
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
                fontWeight: FontWeight.w600, fontSize: 13)),
      );
}

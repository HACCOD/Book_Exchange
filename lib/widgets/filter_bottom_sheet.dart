import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _department;
  late String _type;
  late String _sortBy;
  late double _maxPrice;

  @override
  void initState() {
    super.initState();
    final p = context.read<BookProvider>();
    _department = p.selectedDepartment;
    _type = p.selectedType;
    _sortBy = p.sortBy;
    _maxPrice = p.maxPrice;
  }

  void _apply() {
    final p = context.read<BookProvider>();
    p.setDepartmentFilter(_department);
    p.setTypeFilter(_type);
    p.setSortBy(_sortBy);
    p.setMaxPrice(_maxPrice);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _department = 'All';
      _type = 'All';
      _sortBy = 'Newest First';
      _maxPrice = 5000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters & Sort',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                      onPressed: _reset,
                      child: const Text('Reset All',
                          style: TextStyle(color: AppTheme.error))),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  const _SectionTitle('Sort By'),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.sortOptions
                        .map((s) => ChoiceChip(
                              label: Text(s),
                              selected: _sortBy == s,
                              onSelected: (_) =>
                                  setState(() => _sortBy = s),
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                  color: _sortBy == s
                                      ? Colors.white
                                      : AppTheme.textDark,
                                  fontSize: 12),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  const _SectionTitle('Listing Type'),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Sell', 'Exchange']
                        .map((t) => ChoiceChip(
                              label: Text(t),
                              selected: _type == t,
                              onSelected: (_) =>
                                  setState(() => _type = t),
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                  color: _type == t
                                      ? Colors.white
                                      : AppTheme.textDark,
                                  fontSize: 12),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle('Max Price'),
                      Text(
                        'Rs. ${_maxPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxPrice,
                    min: 0,
                    max: 5000,
                    divisions: 50,
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setState(() => _maxPrice = v),
                  ),
                  const SizedBox(height: 20),

                  const _SectionTitle('Department'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', ...AppConstants.departments]
                        .map((d) => ChoiceChip(
                              label: Text(d),
                              selected: _department == d,
                              onSelected: (_) =>
                                  setState(() => _department = d),
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                  color: _department == d
                                      ? Colors.white
                                      : AppTheme.textDark,
                                  fontSize: 12),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                  onPressed: _apply,
                  child: const Text('Apply Filters')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
      );
}

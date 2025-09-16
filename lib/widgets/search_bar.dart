// Auto-generated for Student Dashboard — paste-ready.
import 'package:flutter/material.dart';
import '../theme.dart';

class SearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  const SearchBar({
    super.key,
    this.onChanged,
    this.onFilterTap,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Subject Filter
              Text(
                'Subject',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Physics'),
                    selected: true,
                    onSelected: (bool value) {
                      // TODO: Implement filter logic
                    },
                  ),
                  FilterChip(
                    label: const Text('Chemistry'),
                    selected: false,
                    onSelected: (bool value) {},
                  ),
                  FilterChip(
                    label: const Text('Biology'),
                    selected: false,
                    onSelected: (bool value) {},
                  ),
                  FilterChip(
                    label: const Text('Maths'),
                    selected: false,
                    onSelected: (bool value) {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Mode Filter
              Text(
                'Mode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.brandPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Online'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('In-person'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Price Range
              Text(
                'Price Range (per hour)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: const RangeValues(1000, 5000),
                min: 0,
                max: 10000,
                divisions: 20,
                labels: const RangeLabels('Rs. 1000', 'Rs. 5000'),
                onChanged: (RangeValues values) {
                  // TODO: Implement price filter
                },
              ),
              const SizedBox(height: 20),
              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Apply filters
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              decoration: const InputDecoration(
                hintText: 'Search subjects, tutors...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (_hasText)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
              },
              tooltip: 'Clear search',
            ),
          Container(
            height: 32,
            width: 1,
            color: AppTheme.borderSubtle,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: widget.onFilterTap ?? _showFilterSheet,
            tooltip: 'Filter options',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

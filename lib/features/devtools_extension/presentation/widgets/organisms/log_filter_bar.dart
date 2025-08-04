import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voo_logging/core/domain/enums/log_level.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_bloc.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_event.dart';
import 'package:voo_logging/features/devtools_extension/presentation/blocs/log_state.dart';
import 'package:voo_logging/features/devtools_extension/presentation/widgets/atoms/log_level_chip.dart';

class LogFilterBar extends StatefulWidget {
  const LogFilterBar({super.key});

  @override
  State<LogFilterBar> createState() => _LogFilterBarState();
}

class _LogFilterBarState extends State<LogFilterBar> {
  final _searchController = TextEditingController();
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<LogBloc>().state;
    _searchController.text = state.searchQuery;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<LogBloc>().add(SearchQueryChanged(_searchController.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<LogBloc, LogState>(
      builder: (context, state) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search logs...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  icon: Icon(_showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list),
                  label: Text(_showAdvancedFilters ? 'Hide Filters' : 'Show Filters'),
                  onPressed: () {
                    setState(() {
                      _showAdvancedFilters = !_showAdvancedFilters;
                    });
                  },
                ),
              ],
            ),
            if (_showAdvancedFilters) ...[
              const SizedBox(height: 16),
              _buildLevelFilters(state),
              const SizedBox(height: 12),
              _buildCategoryAndTagFilters(state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelFilters(LogState state) {
    final selectedLevels = state.selectedLevels ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LogLevel.values.map((level) {
        final isSelected = selectedLevels.contains(level);

        return LogLevelChip(
          level: level,
          selected: isSelected,
          onTap: () {
            final newLevels = List<LogLevel>.from(selectedLevels);
            if (isSelected) {
              newLevels.remove(level);
            } else {
              newLevels.add(level);
            }

            context.read<LogBloc>().add(FilterLogsChanged(levels: newLevels.isEmpty ? null : newLevels, category: state.selectedCategory));
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategoryAndTagFilters(LogState state) => Row(
    children: [
      Expanded(
        child: _buildDropdown(
          label: 'Category',
          value: state.selectedCategory,
          items: state.categories,
          onChanged: (value) {
            context.read<LogBloc>().add(FilterLogsChanged(levels: state.selectedLevels, category: value));
          },
        ),
      ),
    ],
  );

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: [
          const DropdownMenuItem(child: Text('All')),
          ...items.map((item) => DropdownMenuItem(value: item, child: Text(item))),
        ],
        onChanged: onChanged,
      );
}

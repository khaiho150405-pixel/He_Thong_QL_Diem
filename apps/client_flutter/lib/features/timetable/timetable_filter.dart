import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/widgets/app_controls.dart';

typedef TimetableFilterOption = ({num? value, String label});

/// A compact filter with full-size names and search in its selection sheet.
class TimetableFilter extends StatelessWidget {
  const TimetableFilter({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final num? value;
  final List<TimetableFilterOption> options;
  final ValueChanged<num?> onChanged;

  Future<void> _choose(BuildContext context) async {
    final result = await showModalBottomSheet<TimetableFilterOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) =>
          _FilterSheet(label: label, value: value, options: options),
    );
    if (result != null && context.mounted) onChanged(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = options
        .where((option) => option.value == value)
        .firstOrNull;
    return SizedBox(
      width: AppControlMetrics.responsiveFieldWidth(context),
      height: AppControlMetrics.height,
      child: Tooltip(
        message: selected?.label ?? label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppControlMetrics.radius),
          onTap: () => _choose(context),
          child: InputDecorator(
            decoration: AppControlMetrics.decoration(
              context,
              label: label,
              icon: icon,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected?.label ?? label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const Icon(Icons.expand_more, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.label,
    required this.value,
    required this.options,
  });
  final String label;
  final num? value;
  final List<TimetableFilterOption> options;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final items = widget.options
        .where(
          (option) =>
              option.value == null ||
              option.label.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: math.max(
          160,
          math.min(
            media.size.height * .75,
            media.size.height -
                media.viewInsets.bottom -
                media.padding.top -
                24,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lọc ${widget.label.toLowerCase()}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Tìm ${widget.label.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (text) => setState(() => query = text),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final option in items)
                    ListTile(
                      title: Text(option.label),
                      selected: option.value == widget.value,
                      trailing: option.value == widget.value
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.pop(context, option),
                    ),
                  if (!items.any((option) => option.value != null) &&
                      query.trim().isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Không có kết quả phù hợp.'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

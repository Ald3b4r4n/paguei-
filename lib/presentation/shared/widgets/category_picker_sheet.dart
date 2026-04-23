import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';
import 'package:paguei/presentation/categories/providers/categories_provider.dart';

class CategoryPickerSheet extends ConsumerWidget {
  const CategoryPickerSheet({
    super.key,
    this.selectedId,
    this.filter,
    required this.onSelected,
  });

  final String? selectedId;
  final CategoryType? filter;
  final ValueChanged<Category> onSelected;

  static Future<Category?> show(
    BuildContext context, {
    String? selectedId,
    CategoryType? filter,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CategoryPickerSheet(
        selectedId: selectedId,
        filter: filter,
        onSelected: (category) => Navigator.of(context).pop(category),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _SheetHandle(),
            _SheetHeader(),
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Erro ao carregar categorias: $e')),
                data: (categories) {
                  final filtered = filter != null
                      ? categories
                          .where((c) =>
                              c.type == filter || c.type == CategoryType.both)
                          .toList()
                      : categories;

                  if (filtered.isEmpty) {
                    return const Center(
                        child: Text('Nenhuma categoria disponível.'));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      return _CategoryTile(
                        category: category,
                        isSelected: category.id == selectedId,
                        onTap: () => onSelected(category),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        'Selecionar Categoria',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);
    return ListTile(
      key: ValueKey(category.id),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          _iconData(category.icon),
          color: color,
          size: 20,
        ),
      ),
      title: Text(category.name),
      subtitle: Text(
        category.type.label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }

  IconData _iconData(String iconName) {
    return switch (iconName) {
      'food' => Icons.restaurant,
      'transport' => Icons.directions_bus,
      'housing' => Icons.home,
      'health' => Icons.local_hospital,
      'education' => Icons.school,
      'leisure' => Icons.sports_esports,
      'clothing' => Icons.checkroom,
      'subscriptions' => Icons.subscriptions,
      'taxes' => Icons.account_balance,
      'salary' => Icons.work,
      'freelance' => Icons.laptop,
      'investments' => Icons.trending_up,
      _ => Icons.category,
    };
  }
}

import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/catalog/domain/models/category.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_icon_button.dart';
import 'package:kas_usaha/shared/widgets/cards/app_card.dart';

/// Reusable card component for displaying an individual category item.
///
/// Features color dot/avatar, icon, product count badge, active status,
/// and quick actions for edit, toggle active, and delete.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
  });

  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap ?? onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visual Icon & Color Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withAlpha(isDark ? 50 : 35),
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(
                    color: category.color.withAlpha(isDark ? 100 : 80),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            category.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: category.isActive
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Active/Inactive Indicator
                        AppBadge(
                          label: category.isActive ? 'Aktif' : 'Nonaktif',
                          variant: category.isActive
                              ? AppBadgeVariant.success
                              : AppBadgeVariant.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      category.description.isNotEmpty
                          ? category.description
                          : 'Tidak ada catatan deskripsi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: category.description.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Actions menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Pilihan Kategori',
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.roundedMd,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'toggle':
                      onToggleActive?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: AppSpacing.sm),
                        Text('Edit Kategori'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          category.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          category.isActive
                              ? 'Nonaktifkan'
                              : 'Aktifkan',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Hapus Kategori',
                          style: TextStyle(
                            color: category.productCount > 0
                                ? theme.disabledColor
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),

          // Footer info: Product Count & Quick Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBadge(
                label: '${category.productCount} Produk Terdaftar',
                variant: AppBadgeVariant.info,
                icon: Icons.inventory_2_outlined,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    size: 34.0,
                    iconSize: 18.0,
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Hapus',
                    color: AppColors.error,
                    size: 34.0,
                    iconSize: 18.0,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/catalog/domain/models/category.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_text_field.dart';

/// Preset color choices for category visual identity.
class CategoryColorPreset {
  const CategoryColorPreset(this.name, this.hex, this.color);

  final String name;
  final String hex;
  final Color color;
}

/// Modal bottom sheet form for adding or editing a category.
///
/// Features real-time visual preview, color palette selector,
/// icon picker, and validation.
class CategoryFormSheet extends StatefulWidget {
  const CategoryFormSheet({
    super.key,
    this.category,
    required this.onSave,
  });

  /// The existing category to edit, or null when creating a new category.
  final Category? category;

  /// Callback returning whether save succeeded.
  final Future<bool> Function({
    required String name,
    required String description,
    required String colorHex,
    required int iconCodePoint,
    required bool isActive,
  }) onSave;

  /// Helper method to display this sheet modally.
  static Future<bool?> show(
    BuildContext context, {
    Category? category,
    required Future<bool> Function({
      required String name,
      required String description,
      required String colorHex,
      required int iconCodePoint,
      required bool isActive,
    }) onSave,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFormSheet(
        category: category,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;

  late String _selectedColorHex;
  late int _selectedIconCodePoint;
  late bool _isActive;
  bool _isSubmitting = false;

  static const List<CategoryColorPreset> _colorPresets = [
    CategoryColorPreset('Emerald', '#137547', Color(0xFF137547)),
    CategoryColorPreset('Teal', '#0D9488', Color(0xFF0D9488)),
    CategoryColorPreset('Blue', '#2563EB', Color(0xFF2563EB)),
    CategoryColorPreset('Indigo', '#4F46E5', Color(0xFF4F46E5)),
    CategoryColorPreset('Amber', '#D97706', Color(0xFFD97706)),
    CategoryColorPreset('Orange', '#EA580C', Color(0xFFEA580C)),
    CategoryColorPreset('Rose', '#E11D48', Color(0xFFE11D48)),
    CategoryColorPreset('Purple', '#7C3AED', Color(0xFF7C3AED)),
    CategoryColorPreset('Slate', '#475569', Color(0xFF475569)),
  ];

  static final List<IconData> _iconPresets = [
    Icons.category_rounded,
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.fastfood_rounded,
    Icons.cake_rounded,
    Icons.inventory_2_rounded,
    Icons.local_mall_rounded,
    Icons.build_rounded,
    Icons.loyalty_rounded,
    Icons.local_offer_rounded,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.category;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _descController = TextEditingController(text: initial?.description ?? '');
    _selectedColorHex = initial?.colorHex ?? _colorPresets.first.hex;
    _selectedIconCodePoint =
        initial?.iconCodePoint ?? _iconPresets.first.codePoint;
    _isActive = initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Color get _currentColor {
    try {
      final clean = _selectedColorHex.replaceAll('#', '').trim();
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return AppColors.primary500;
    }
  }

  IconData get _currentIcon => IconData(
        // ignore: non_const_argument_for_const_parameter
        _selectedIconCodePoint,
        fontFamily: 'MaterialIcons',
      );

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await widget.onSave(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      colorHex: _selectedColorHex,
      iconCodePoint: _selectedIconCodePoint,
      isActive: _isActive,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditMode = widget.category != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: AppRadius.roundedFull,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Header Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditMode ? 'Edit Kategori' : 'Tambah Kategori Baru',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Live Preview Box
                _buildLivePreview(theme, isDark),
                const SizedBox(height: AppSpacing.lg),

                // Category Name Field
                AppTextField(
                  controller: _nameController,
                  label: 'Nama Kategori *',
                  hint: 'Contoh: Makanan Berat, Minuman Kopi',
                  prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                  textInputAction: TextInputAction.next,
                  autofocus: !isEditMode,
                  onChanged: (val) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama kategori wajib diisi';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama kategori minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Description Field
                AppTextField(
                  controller: _descController,
                  label: 'Deskripsi / Catatan (Opsional)',
                  hint: 'Contoh: Kelompok menu utama dan lauk pauk',
                  prefixIcon:
                      const Icon(Icons.description_outlined, size: 20),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Color Palette Selector
                Text(
                  'Warna Label Kategori',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildColorPalette(theme),
                const SizedBox(height: AppSpacing.lg),

                // Icon Selector
                Text(
                  'Ikon Visual (Untuk Grid POS Kasir)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildIconGrid(theme, isDark),
                const SizedBox(height: AppSpacing.lg),

                // Active Switch
                Material(
                  color: isDark
                      ? AppColors.darkSurfaceVariant.withAlpha(80)
                      : AppColors.lightSurfaceVariant,
                  borderRadius: AppRadius.roundedMd,
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xxs,
                    ),
                    title: const Text(
                      'Kategori Aktif',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Kategori aktif akan tampil di menu kasir',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isActive,
                    activeTrackColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Batal',
                        variant: AppButtonVariant.outlined,
                        onPressed:
                            _isSubmitting ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: isEditMode
                            ? 'Simpan Perubahan'
                            : 'Tambah Kategori',
                        leadingIcon: Icons.check_rounded,
                        variant: AppButtonVariant.primary,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _handleSubmit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreview(ThemeData theme, bool isDark) {
    final previewName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Nama Kategori';
    final previewDesc = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : 'Deskripsi kategori akan tampil di sini';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _currentColor.withAlpha(isDark ? 40 : 25),
        borderRadius: AppRadius.roundedMd,
        border: Border.all(
          color: _currentColor.withAlpha(isDark ? 90 : 70),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _currentColor,
              borderRadius: AppRadius.roundedSm,
            ),
            child: Icon(_currentIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        previewName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge(
                      label: _isActive ? 'Aktif' : 'Nonaktif',
                      variant: _isActive
                          ? AppBadgeVariant.success
                          : AppBadgeVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  previewDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colorPresets.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final preset = _colorPresets[index];
          final isSelected =
              _selectedColorHex.toLowerCase() == preset.hex.toLowerCase();

          return InkWell(
            onTap: () {
              setState(() {
                _selectedColorHex = preset.hex;
              });
            },
            borderRadius: AppRadius.roundedFull,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: preset.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: preset.color.withAlpha(140),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconGrid(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _iconPresets.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final iconData = _iconPresets[index];
          final isSelected = _selectedIconCodePoint == iconData.codePoint;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedIconCodePoint = iconData.codePoint;
              });
            },
            borderRadius: AppRadius.roundedSm,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? _currentColor.withAlpha(isDark ? 60 : 40)
                    : (isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant),
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: isSelected ? _currentColor : Colors.transparent,
                  width: 1.8,
                ),
              ),
              child: Icon(
                iconData,
                size: 22,
                color: isSelected
                    ? _currentColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}

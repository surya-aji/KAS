import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/business_settings/domain/models/business_profile.dart';
import 'package:kas_usaha/features/business_settings/presentation/providers/business_profile_provider.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/cards/app_card.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_loading.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_text_field.dart';

/// Screen for viewing and updating business profile settings.
///
/// Designed following Material 3 guidelines with iOS-responsive considerations,
/// platform-specific inputs, offline local state management, and clear form feedback.
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _currencyCodeController;
  late TextEditingController _currencySymbolController;
  late TextEditingController _taxRateController;
  late TextEditingController _discountRateController;
  late TextEditingController _receiptFooterController;

  bool _isTaxEnabled = false;
  bool _isDiscountEnabled = false;
  bool _isFormPopulated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _currencyCodeController = TextEditingController();
    _currencySymbolController = TextEditingController();
    _taxRateController = TextEditingController();
    _discountRateController = TextEditingController();
    _receiptFooterController = TextEditingController();

    // Populate state if already loaded from repository
    final currentState = ref.read(businessProfileProvider);
    if (currentState.status == BusinessProfileStatus.loaded) {
      _populateForm(currentState.profile);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ref.read(businessProfileProvider).status ==
              BusinessProfileStatus.initial) {
        ref.read(businessProfileProvider.notifier).loadProfile();
      }
    });
  }

  void _populateForm(BusinessProfile profile) {
    _nameController.text = profile.name;
    _addressController.text = profile.address;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email;
    _currencyCodeController.text = profile.currencyCode;
    _currencySymbolController.text = profile.currencySymbol;
    _taxRateController.text = profile.taxRate.toStringAsFixed(1);
    _discountRateController.text =
        profile.defaultDiscountRate.toStringAsFixed(1);
    _receiptFooterController.text = profile.receiptFooterMessage;
    _isTaxEnabled = profile.isTaxEnabled;
    _isDiscountEnabled = profile.isDiscountEnabled;
    _isFormPopulated = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currencyCodeController.dispose();
    _currencySymbolController.dispose();
    _taxRateController.dispose();
    _discountRateController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  void _submitForm() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentProfile = ref.read(businessProfileProvider).profile;
    final taxRate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;
    final discountRate =
        double.tryParse(_discountRateController.text.trim()) ?? 0.0;

    final updated = currentProfile.copyWith(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      currencyCode: _currencyCodeController.text.trim(),
      currencySymbol: _currencySymbolController.text.trim(),
      isTaxEnabled: _isTaxEnabled,
      taxRate: taxRate,
      isDiscountEnabled: _isDiscountEnabled,
      defaultDiscountRate: discountRate,
      receiptFooterMessage: _receiptFooterController.text.trim(),
    );

    ref.read(businessProfileProvider.notifier).saveProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Reactively listen to provider state changes for notifications
    ref.listen<BusinessProfileState>(businessProfileProvider, (previous, next) {
      if (next.status == BusinessProfileStatus.loaded && !_isFormPopulated) {
        setState(() {
          _populateForm(next.profile);
        });
      }

      if (next.status == BusinessProfileStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Profil usaha berhasil disimpan secara offline.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.roundedMd,
            ),
          ),
        );
        ref.read(businessProfileProvider.notifier).resetStatus();
      } else if (next.status == BusinessProfileStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.roundedMd,
            ),
          ),
        );
        ref.read(businessProfileProvider.notifier).resetStatus();
      }
    });

    final state = ref.watch(businessProfileProvider);

    if (!_isFormPopulated &&
        (state.isLoading || state.status == BusinessProfileStatus.initial)) {
      return const Scaffold(
        body: Center(
          child: AppLoading(message: 'Memuat profil usaha...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Usaha'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat Ulang',
            onPressed: () {
              ref.read(businessProfileProvider.notifier).loadProfile();
              setState(() {
                _isFormPopulated = false;
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  children: [
                    // Business Header Banner Card
                    _buildHeaderCard(theme, isDark),
                    const SizedBox(height: AppSpacing.lg),

                    // Section 1: Business Identity
                    _buildSectionHeader(
                      theme: theme,
                      title: 'Identitas Usaha',
                      subtitle: 'Informasi dasar yang dicetak pada struk',
                      icon: Icons.storefront_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildIdentitySection(theme),
                    const SizedBox(height: AppSpacing.xl),

                    // Section 2: Currency & Regional
                    _buildSectionHeader(
                      theme: theme,
                      title: 'Mata Uang & Format',
                      subtitle: 'Format penulisan harga dan transaksi',
                      icon: Icons.payments_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCurrencySection(theme),
                    const SizedBox(height: AppSpacing.xl),

                    // Section 3: Tax & Discounts
                    _buildSectionHeader(
                      theme: theme,
                      title: 'Pajak & Diskon Standar',
                      subtitle: 'Konfigurasi otomatis saat kasir checkout',
                      icon: Icons.percent_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTaxDiscountSection(theme),
                    const SizedBox(height: AppSpacing.xl),

                    // Section 4: Receipt Footer
                    _buildSectionHeader(
                      theme: theme,
                      title: 'Pengaturan Struk',
                      subtitle: 'Teks catatan kaki pada struk belanja',
                      icon: Icons.receipt_long_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildReceiptSection(theme),
                    const SizedBox(height: AppSpacing.xxl),

                    // Save Action Button
                    AppButton(
                      text: 'Simpan Profil Usaha',
                      leadingIcon: Icons.save_rounded,
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      isFullWidth: true,
                      isLoading: state.isSaving,
                      onPressed: state.isSaving ? null : _submitForm,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, bool isDark) {
    final businessName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Toko Anda';

    return AppCard(
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.primary50.withAlpha(160),
      borderColor: theme.colorScheme.primary.withAlpha(60),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(
              Icons.store_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _phoneController.text.isNotEmpty
                      ? _phoneController.text
                      : 'Belum ada nomor telepon',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const AppBadge(
            label: 'Offline-First',
            variant: AppBadgeVariant.success,
            icon: Icons.cloud_off_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentitySection(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _nameController,
            label: 'Nama Usaha / Toko *',
            hint: 'Contoh: Toko Berkah Jaya',
            prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
            textInputAction: TextInputAction.next,
            onChanged: (val) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama usaha wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _addressController,
            label: 'Alamat Usaha',
            hint: 'Contoh: Jl. Sudirman No. 45, Jakarta',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            maxLines: 2,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phoneController,
            label: 'Nomor Telepon / WhatsApp',
            hint: 'Contoh: 081234567890',
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _emailController,
            label: 'Email (Opsional)',
            hint: 'Contoh: usaha@domain.com',
            prefixIcon: const Icon(Icons.mail_outline, size: 20),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySection(ThemeData theme) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _currencyCodeController,
              label: 'Kode Mata Uang',
              hint: 'IDR',
              textInputAction: TextInputAction.next,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Wajib diisi';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppTextField(
              controller: _currencySymbolController,
              label: 'Simbol Mata Uang',
              hint: 'Rp',
              textInputAction: TextInputAction.next,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Wajib diisi';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxDiscountSection(ThemeData theme) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Terapkan Pajak (PPN)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Otomatis menambahkan pajak ke keranjang transaksi',
                style: TextStyle(fontSize: 12),
              ),
              value: _isTaxEnabled,
              activeTrackColor: theme.colorScheme.primary,
              onChanged: (val) {
                setState(() {
                  _isTaxEnabled = val;
                });
              },
            ),
          ),
          if (_isTaxEnabled) ...[
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _taxRateController,
              label: 'Persentase Pajak (%)',
              hint: '11.0',
              prefixIcon: const Icon(Icons.percent_rounded, size: 20),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Persentase pajak harus diisi';
                }
                final num = double.tryParse(val.trim());
                if (num == null || num < 0 || num > 100) {
                  return 'Nilai harus antara 0 - 100';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const Divider(height: AppSpacing.lg),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Terapkan Diskon Standar',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Potongan harga otomatis untuk semua transaksi',
                style: TextStyle(fontSize: 12),
              ),
              value: _isDiscountEnabled,
              activeTrackColor: theme.colorScheme.primary,
              onChanged: (val) {
                setState(() {
                  _isDiscountEnabled = val;
                });
              },
            ),
          ),
          if (_isDiscountEnabled) ...[
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _discountRateController,
              label: 'Persentase Diskon Standar (%)',
              hint: '5.0',
              prefixIcon: const Icon(Icons.discount_outlined, size: 20),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Persentase diskon harus diisi';
                }
                final num = double.tryParse(val.trim());
                if (num == null || num < 0 || num > 100) {
                  return 'Nilai harus antara 0 - 100';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptSection(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _receiptFooterController,
            label: 'Catatan Kaki Struk (Receipt Footer)',
            hint: 'Contoh: Terima kasih atas kunjungan Anda!',
            prefixIcon: const Icon(Icons.receipt_outlined, size: 20),
            maxLines: 2,
            helperText: 'Teks ini akan dicetak di bagian paling bawah struk.',
          ),
        ],
      ),
    );
  }
}

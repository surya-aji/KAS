import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/product_provider.dart';
import 'package:kas_usaha/features/pos/domain/models/cart_item.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';

/// State representation for the POS cashier screen.
class PosState {
  const PosState({
    this.searchQuery = '',
    this.selectedCategoryId,
    this.cartItems = const [],
    this.errorMessage,
    this.successMessage,
  });

  /// Real-time search query for products (name, SKU, barcode).
  final String searchQuery;

  /// Currently active category filter (null means all categories).
  final String? selectedCategoryId;

  /// Ordered items currently in the cashier transaction.
  final List<CartItem> cartItems;

  /// Temporary feedback error message.
  final String? errorMessage;

  /// Temporary feedback success message.
  final String? successMessage;

  /// Total units / quantity of all items in the cart.
  int get totalQuantity =>
      cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// Grand total gross amount of the active cart in integer Rupiah.
  int get totalAmount => cartItems.fold(0, (sum, item) => sum + item.subtotal);

  /// Formatted total currency string (e.g. 'Rp75.000').
  String get formattedTotalAmount =>
      CurrencyFormatter.formatRupiah(totalAmount);

  /// Quantity of a specific product currently added to cart.
  int getCartQuantity(String productId) {
    for (final item in cartItems) {
      if (item.product.id == productId) {
        return item.quantity;
      }
    }
    return 0;
  }

  /// Whether a specific product is currently in the cart.
  bool isInCart(String productId) => getCartQuantity(productId) > 0;

  /// Whether the cart currently has at least one item.
  bool get hasItems => cartItems.isNotEmpty;

  /// Creates a copy with optional updated values.
  PosState copyWith({
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategory = false,
    List<CartItem>? cartItems,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PosState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      cartItems: cartItems ?? this.cartItems,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosState &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          selectedCategoryId == other.selectedCategoryId &&
          listEquals(cartItems, other.cartItems) &&
          errorMessage == other.errorMessage &&
          successMessage == other.successMessage;

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      selectedCategoryId.hashCode ^
      cartItems.hashCode ^
      errorMessage.hashCode ^
      successMessage.hashCode;

  static bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Riverpod Notifier managing POS cashier screen interactions and temporary cart state.
class PosNotifier extends Notifier<PosState> {
  @override
  PosState build() {
    return const PosState();
  }

  /// Updates the search query text for real-time product filtering.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Selects a category to filter products (null to show all categories).
  void setCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  /// Adds a product to the cart or increments its quantity by 1.
  ///
  /// Enforces stock validations:
  /// - Product must be active.
  /// - Product must not be out of stock.
  /// - When inventory is tracked, cart quantity cannot exceed available stock.
  bool addToCart(Product product) {
    // 1. Inactive product check
    if (!product.isActive) {
      state = state.copyWith(
        errorMessage: 'Produk "${product.name}" sedang dinonaktifkan.',
      );
      return false;
    }

    // 2. Out of stock check
    if (product.isOutOfStock) {
      state = state.copyWith(
        errorMessage: 'Stok "${product.name}" telah habis.',
      );
      return false;
    }

    final currentQty = state.getCartQuantity(product.id);

    // 3. Tracked inventory quantity limit check
    if (product.trackStock && currentQty + 1 > product.stock) {
      state = state.copyWith(
        errorMessage:
            'Stok "${product.name}" tidak mencukupi (Tersisa ${product.stock} ${product.unit}).',
      );
      return false;
    }

    final updatedCart = List<CartItem>.from(state.cartItems);
    final existingIndex =
        updatedCart.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      final existingItem = updatedCart[existingIndex];
      updatedCart[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    } else {
      updatedCart.add(CartItem(product: product, quantity: 1));
    }

    state = state.copyWith(
      cartItems: updatedCart,
      clearError: true,
    );
    return true;
  }

  /// Decrements product quantity by 1, removing it if quantity reaches 0.
  void removeFromCart(String productId) {
    final updatedCart = List<CartItem>.from(state.cartItems);
    final index =
        updatedCart.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      final item = updatedCart[index];
      if (item.quantity > 1) {
        updatedCart[index] = item.copyWith(quantity: item.quantity - 1);
      } else {
        updatedCart.removeAt(index);
      }
      state = state.copyWith(cartItems: updatedCart);
    }
  }

  /// Updates product quantity directly (Task T2.2).
  ///
  /// Enforces stock validations:
  /// - If [newQuantity] <= 0, the item is removed from the cart.
  /// - If inventory is tracked and [newQuantity] exceeds stock, sets an error and returns false.
  /// - Otherwise updates the quantity and returns true.
  bool updateItemQuantity(String productId, int newQuantity) {
    final index =
        state.cartItems.indexWhere((item) => item.product.id == productId);
    if (index < 0) return false;

    final item = state.cartItems[index];

    if (newQuantity <= 0) {
      deleteItem(productId);
      return true;
    }

    if (item.product.trackStock && newQuantity > item.product.stock) {
      state = state.copyWith(
        errorMessage:
            'Stok "${item.product.name}" tidak mencukupi (Tersisa ${item.product.stock} ${item.product.unit}).',
      );
      return false;
    }

    final updatedCart = List<CartItem>.from(state.cartItems);
    updatedCart[index] = item.copyWith(quantity: newQuantity);
    state = state.copyWith(
      cartItems: updatedCart,
      clearError: true,
    );
    return true;
  }

  /// Updates custom customer notes or special requests for an item in the cart.
  void updateItemNotes(String productId, String notes) {
    final index =
        state.cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final updatedCart = List<CartItem>.from(state.cartItems);
      updatedCart[index] = updatedCart[index].copyWith(notes: notes.trim());
      state = state.copyWith(cartItems: updatedCart);
    }
  }

  /// Atomically updates both quantity and notes for an item in the cart.
  bool updateCartItemDetails(
    String productId, {
    required int quantity,
    String? notes,
  }) {
    final index =
        state.cartItems.indexWhere((item) => item.product.id == productId);
    if (index < 0) return false;

    final item = state.cartItems[index];

    if (quantity <= 0) {
      deleteItem(productId);
      return true;
    }

    if (item.product.trackStock && quantity > item.product.stock) {
      state = state.copyWith(
        errorMessage:
            'Stok "${item.product.name}" tidak mencukupi (Tersisa ${item.product.stock} ${item.product.unit}).',
      );
      return false;
    }

    final updatedCart = List<CartItem>.from(state.cartItems);
    updatedCart[index] = item.copyWith(
      quantity: quantity,
      notes: notes != null ? notes.trim() : item.notes,
    );

    state = state.copyWith(
      cartItems: updatedCart,
      clearError: true,
    );
    return true;
  }

  /// Removes an item completely from the cart regardless of its quantity.
  void deleteItem(String productId) {
    final updatedCart = state.cartItems
        .where((item) => item.product.id != productId)
        .toList();
    state = state.copyWith(cartItems: updatedCart);
  }

  /// Empties all items from the current cart.
  void clearCart() {
    state = state.copyWith(cartItems: const []);
  }

  /// Resets search query and category filters to default.
  void resetFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearCategory: true,
    );
  }

  /// Clears transient feedback messages.
  void clearMessages() {
    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
    );
  }
}

/// NotifierProvider for POS Cashier state.
final posProvider = NotifierProvider<PosNotifier, PosState>(
  PosNotifier.new,
);

/// Provider computing active catalog products filtered by search query and category.
final posFilteredProductsProvider = Provider<List<Product>>((ref) {
  final productState = ref.watch(productProvider);
  final posState = ref.watch(posProvider);

  // POS only shows active products
  final activeProducts =
      productState.products.where((p) => p.isActive).toList();

  return activeProducts.where((product) {
    // 1. Category filter
    if (posState.selectedCategoryId != null &&
        posState.selectedCategoryId!.isNotEmpty &&
        product.categoryId != posState.selectedCategoryId) {
      return false;
    }

    // 2. Search query filter (name, SKU, barcode, category name)
    final query = posState.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final nameMatches = product.name.toLowerCase().contains(query);
    final skuMatches = product.sku.toLowerCase().contains(query);
    final barcodeMatches = product.barcode.toLowerCase().contains(query);
    final categoryMatches =
        product.categoryName.toLowerCase().contains(query);

    return nameMatches || skuMatches || barcodeMatches || categoryMatches;
  }).toList();
});

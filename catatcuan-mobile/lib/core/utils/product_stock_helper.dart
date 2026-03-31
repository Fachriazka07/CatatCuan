class ProductStockHelper {
  ProductStockHelper._();

  static const int unlimitedStockValue = -1;

  static int parseStock(Object? rawValue) {
    if (rawValue is num) return rawValue.toInt();
    return int.tryParse(rawValue?.toString() ?? '') ?? 0;
  }

  static bool isUnlimited(Object? rawValue) {
    return parseStock(rawValue) == unlimitedStockValue;
  }

  static bool isOutOfStock(Object? rawValue) {
    final stock = parseStock(rawValue);
    return stock == 0;
  }

  static bool isLowStock(Object? rawValue, {required int threshold}) {
    final stock = parseStock(rawValue);
    if (isUnlimited(stock)) return false;
    return stock < threshold;
  }

  static bool canAddToCart({
    required Object? rawValue,
    required int currentQty,
  }) {
    final stock = parseStock(rawValue);
    if (isUnlimited(stock)) return true;
    if (stock <= 0) return false;
    return currentQty < stock;
  }

  static int nextStockAfterSale({
    required Object? rawValue,
    required int qtySold,
  }) {
    final stock = parseStock(rawValue);
    if (isUnlimited(stock)) return unlimitedStockValue;
    return (stock - qtySold).clamp(0, double.infinity).toInt();
  }

  static String formatStockLabel(
    Object? rawValue, {
    String unlimitedLabel = 'Unlimited',
  }) {
    if (isUnlimited(rawValue)) {
      return unlimitedLabel;
    }
    return parseStock(rawValue).toString();
  }
}

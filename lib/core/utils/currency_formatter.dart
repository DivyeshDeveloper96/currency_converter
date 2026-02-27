import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      symbol: _getSymbol(currencyCode),
      decimalDigits: amount >= 1000 ? 2 : 4,
      locale: 'en_US',
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return NumberFormat('#,##0.00').format(amount);
    }
    return NumberFormat('#,##0.0000').format(amount);
  }

  static double? parse(String text) {
    if (text.trim().isEmpty) return null;
    final cleaned = text.replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }

  static String _getSymbol(String code) {
    const symbols = {
      'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥',
      'INR': '₹', 'CNY': '¥', 'KRW': '₩', 'BTC': '₿',
      'CHF': 'Fr', 'AUD': 'A\$', 'CAD': 'C\$', 'HKD': 'HK\$',
      'SGD': 'S\$', 'SEK': 'kr', 'NOK': 'kr', 'DKK': 'kr',
      'NZD': 'NZ\$', 'MXN': 'Mex\$', 'BRL': 'R\$', 'ZAR': 'R',
    };
    return symbols[code] ?? code;
  }
}

class ExchangeRate {
  final String baseCurrency;
  final Map<String, double> rates;
  final DateTime fetchedAt;

  const ExchangeRate({
    required this.baseCurrency,
    required this.rates,
    required this.fetchedAt,
  });

  bool get isStale {
    final diff = DateTime.now().difference(fetchedAt).inMinutes;
    return diff > 60;
  }

  double? rateFor(String currencyCode) => rates[currencyCode];

  /// Cross-converts: amount in [from] → base → [to]
  double? convert({
    required double amount,
    required String from,
    required String to,
  }) {
    if (from == baseCurrency) {
      final toRate = rates[to];
      if (toRate == null) return null;
      return amount * toRate;
    }

    if (to == baseCurrency) {
      final fromRate = rates[from];
      if (fromRate == null || fromRate == 0) return null;
      return amount / fromRate;
    }

    // Cross via base
    final fromRate = rates[from];
    final toRate = rates[to];
    if (fromRate == null || fromRate == 0 || toRate == null) return null;
    return (amount / fromRate) * toRate;
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'] as Map<String, dynamic>;
    return ExchangeRate(
      baseCurrency: json['base'] as String,
      rates: rawRates.map((k, v) => MapEntry(k, (v as num).toDouble())),
      fetchedAt: DateTime.now(),
    );
  }

  /// Persist individual rate rows to SQLite
  List<Map<String, dynamic>> toRows() {
    return rates.entries.map((e) {
      return {
        'currency_code': e.key,
        'rate': e.value,
        'base_currency': baseCurrency,
        'fetched_at': fetchedAt.millisecondsSinceEpoch,
      };
    }).toList();
  }

  factory ExchangeRate.fromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) throw StateError('No rate rows provided');
    final first = rows.first;
    return ExchangeRate(
      baseCurrency: first['base_currency'] as String,
      rates: {for (final r in rows) r['currency_code'] as String: r['rate'] as double},
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(first['fetched_at'] as int),
    );
  }
}

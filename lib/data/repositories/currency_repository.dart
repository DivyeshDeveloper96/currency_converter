import '../models/currency.dart';
import '../models/exchange_rate.dart';

abstract class CurrencyRepository {
  /// Returns rates from cache if fresh, otherwise fetches from API.
  /// Falls back to stale cache if offline.
  Future<ExchangeRate> getRates(String baseCurrency);

  /// Returns currencies from cache, fetches if empty.
  Future<List<Currency>> getCurrencies();

  /// Force refresh rates from network, ignoring cache state.
  Future<ExchangeRate> refreshRates(String baseCurrency);
}

import '../models/currency.dart';
import '../models/exchange_rate.dart';
import '../datasources/local/exchange_rate_local_source.dart';
import '../datasources/remote/exchange_rate_remote_source.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/network_info.dart';
import 'currency_repository.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  final ExchangeRateRemoteSource _remote;
  final ExchangeRateLocalSource _local;
  final NetworkInfo _networkInfo;

  CurrencyRepositoryImpl({
    required ExchangeRateRemoteSource remote,
    required ExchangeRateLocalSource local,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _local = local,
        _networkInfo = networkInfo;

  @override
  Future<ExchangeRate> getRates(String baseCurrency) async {
    final cached = await _local.getCachedRates(baseCurrency);

    // Return fresh cache immediately without hitting network
    if (cached != null && !cached.isStale) return cached;

    if (!await _networkInfo.isConnected) {
      // Serve stale cache in offline mode rather than throwing
      if (cached != null) return cached;
      throw const NetworkException();
    }

    return _fetchAndCache(baseCurrency);
  }

  @override
  Future<ExchangeRate> refreshRates(String baseCurrency) async {
    if (!await _networkInfo.isConnected) {
      final cached = await _local.getCachedRates(baseCurrency);
      if (cached != null) return cached;
      throw const NetworkException();
    }
    return _fetchAndCache(baseCurrency);
  }

  @override
  Future<List<Currency>> getCurrencies() async {
    final cached = await _local.getCachedCurrencies();
    if (cached.isNotEmpty) return cached;

    if (!await _networkInfo.isConnected) throw const NetworkException();

    final currencies = await _remote.getAvailableCurrencies();
    await _local.cacheCurrencies(currencies);
    return currencies;
  }

  Future<ExchangeRate> _fetchAndCache(String baseCurrency) async {
    final rates = await _remote.getLatestRates(baseCurrency);
    await _local.cacheRates(rates);
    return rates;
  }
}

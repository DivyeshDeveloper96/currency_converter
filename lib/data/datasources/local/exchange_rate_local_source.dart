import '../../models/currency.dart';
import '../../models/exchange_rate.dart';
import '../../../core/errors/app_exception.dart';
import 'database_helper.dart';

abstract class ExchangeRateLocalSource {
  Future<ExchangeRate?> getCachedRates(String baseCurrency);
  Future<void> cacheRates(ExchangeRate rate);
  Future<List<Currency>> getCachedCurrencies();
  Future<void> cacheCurrencies(List<Currency> currencies);
}

class ExchangeRateLocalSourceImpl implements ExchangeRateLocalSource {
  final DatabaseHelper _db;

  ExchangeRateLocalSourceImpl({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  @override
  Future<ExchangeRate?> getCachedRates(String baseCurrency) async {
    try {
      final rows = await _db.query(
        'exchange_rates',
        where: 'base_currency = ?',
        whereArgs: [baseCurrency],
      );
      if (rows.isEmpty) return null;
      return ExchangeRate.fromRows(rows);
    } catch (e) {
      throw const CacheException('Failed to load cached exchange rates.');
    }
  }

  @override
  Future<void> cacheRates(ExchangeRate rate) async {
    try {
      await _db.replaceAll('exchange_rates', rate.toRows());
    } catch (e) {
      throw const CacheException('Failed to save exchange rates.');
    }
  }

  @override
  Future<List<Currency>> getCachedCurrencies() async {
    try {
      final rows = await _db.query('currencies', orderBy: 'code ASC');
      return rows.map(Currency.fromMap).toList();
    } catch (e) {
      throw const CacheException('Failed to load cached currencies.');
    }
  }

  @override
  Future<void> cacheCurrencies(List<Currency> currencies) async {
    try {
      final rows = currencies.map((c) => c.toMap()).toList();
      await _db.replaceAll('currencies', rows);
    } catch (e) {
      throw const CacheException('Failed to save currencies.');
    }
  }
}

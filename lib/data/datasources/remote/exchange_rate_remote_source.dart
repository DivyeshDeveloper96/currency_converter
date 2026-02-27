import '../../models/currency.dart';
import '../../models/exchange_rate.dart';
import '../../../core/network/dio_client.dart';

abstract class ExchangeRateRemoteSource {
  Future<ExchangeRate> getLatestRates(String baseCurrency);
  Future<List<Currency>> getAvailableCurrencies();
}

class ExchangeRateRemoteSourceImpl implements ExchangeRateRemoteSource {
  final DioClient _client;

  ExchangeRateRemoteSourceImpl({DioClient? client})
      : _client = client ?? DioClient.instance;

  @override
  Future<ExchangeRate> getLatestRates(String baseCurrency) async {
    final response = await _client.get(
      '/latest',
      queryParams: {'base': baseCurrency},
    );
    return ExchangeRate.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Currency>> getAvailableCurrencies() async {
    final response = await _client.get('/symbols');
    final symbols = (response.data['symbols'] as Map<String, dynamic>);
    return symbols.entries
        .map((e) => Currency.fromJson(e.key, e.value as String))
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }
}

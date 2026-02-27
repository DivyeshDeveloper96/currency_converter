import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:currency_converter/data/models/currency.dart';
import 'package:currency_converter/data/models/exchange_rate.dart';
import 'package:currency_converter/data/datasources/local/exchange_rate_local_source.dart';
import 'package:currency_converter/data/datasources/remote/exchange_rate_remote_source.dart';
import 'package:currency_converter/data/repositories/currency_repository_impl.dart';
import 'package:currency_converter/core/network/network_info.dart';
import 'package:currency_converter/core/errors/app_exception.dart';

@GenerateMocks([
  ExchangeRateRemoteSource,
  ExchangeRateLocalSource,
  NetworkInfo,
])
import 'currency_repository_test.mocks.dart';

void main() {
  late MockExchangeRateRemoteSource remote;
  late MockExchangeRateLocalSource local;
  late MockNetworkInfo network;
  late CurrencyRepositoryImpl repo;

  final freshRate = ExchangeRate(
    baseCurrency: 'USD',
    rates: const {'EUR': 0.92, 'GBP': 0.79},
    fetchedAt: DateTime.now(),
  );

  final staleRate = ExchangeRate(
    baseCurrency: 'USD',
    rates: const {'EUR': 0.90, 'GBP': 0.77},
    fetchedAt: DateTime.now().subtract(const Duration(hours: 3)),
  );

  final currencies = [
    const Currency(code: 'USD', name: 'United States Dollar'),
    const Currency(code: 'EUR', name: 'Euro'),
  ];

  setUp(() {
    remote = MockExchangeRateRemoteSource();
    local = MockExchangeRateLocalSource();
    network = MockNetworkInfo();

    repo = CurrencyRepositoryImpl(
      remote: remote,
      local: local,
      networkInfo: network,
    );
  });

  group('getRates', () {
    test('returns fresh cache without hitting network', () async {
      when(local.getCachedRates('USD')).thenAnswer((_) async => freshRate);

      final result = await repo.getRates('USD');

      expect(result.baseCurrency, 'USD');
      verifyNever(remote.getLatestRates(any));
    });

    test('fetches from network when cache is stale and online', () async {
      when(local.getCachedRates('USD')).thenAnswer((_) async => staleRate);
      when(network.isConnected).thenAnswer((_) async => true);
      when(remote.getLatestRates('USD')).thenAnswer((_) async => freshRate);
      when(local.cacheRates(any)).thenAnswer((_) async {});

      final result = await repo.getRates('USD');

      expect(result.fetchedAt.isAfter(staleRate.fetchedAt), isTrue);
      verify(remote.getLatestRates('USD')).called(1);
      verify(local.cacheRates(any)).called(1);
    });

    test('returns stale cache when offline rather than throwing', () async {
      when(local.getCachedRates('USD')).thenAnswer((_) async => staleRate);
      when(network.isConnected).thenAnswer((_) async => false);

      final result = await repo.getRates('USD');

      expect(result.rates['EUR'], 0.90);
      verifyNever(remote.getLatestRates(any));
    });

    test('throws NetworkException when offline and no cache exists', () async {
      when(local.getCachedRates('USD')).thenAnswer((_) async => null);
      when(network.isConnected).thenAnswer((_) async => false);

      expect(() => repo.getRates('USD'), throwsA(isA<NetworkException>()));
    });

    test('fetches from network when no cache exists and online', () async {
      when(local.getCachedRates('USD')).thenAnswer((_) async => null);
      when(network.isConnected).thenAnswer((_) async => true);
      when(remote.getLatestRates('USD')).thenAnswer((_) async => freshRate);
      when(local.cacheRates(any)).thenAnswer((_) async {});

      final result = await repo.getRates('USD');
      expect(result.baseCurrency, 'USD');
    });
  });

  group('getCurrencies', () {
    test('returns cached currencies when available', () async {
      when(local.getCachedCurrencies()).thenAnswer((_) async => currencies);

      final result = await repo.getCurrencies();

      expect(result, hasLength(2));
      verifyNever(remote.getAvailableCurrencies());
    });

    test('fetches and caches currencies when cache is empty', () async {
      when(local.getCachedCurrencies()).thenAnswer((_) async => []);
      when(network.isConnected).thenAnswer((_) async => true);
      when(remote.getAvailableCurrencies()).thenAnswer((_) async => currencies);
      when(local.cacheCurrencies(any)).thenAnswer((_) async {});

      final result = await repo.getCurrencies();

      expect(result, hasLength(2));
      verify(remote.getAvailableCurrencies()).called(1);
      verify(local.cacheCurrencies(any)).called(1);
    });

    test('throws NetworkException when offline with empty cache', () {
      when(local.getCachedCurrencies()).thenAnswer((_) async => []);
      when(network.isConnected).thenAnswer((_) async => false);

      expect(() => repo.getCurrencies(), throwsA(isA<NetworkException>()));
    });
  });

  group('refreshRates', () {
    test('forces network fetch when online', () async {
      when(network.isConnected).thenAnswer((_) async => true);
      when(remote.getLatestRates('USD')).thenAnswer((_) async => freshRate);
      when(local.cacheRates(any)).thenAnswer((_) async {});

      await repo.refreshRates('USD');

      verify(remote.getLatestRates('USD')).called(1);
    });

    test('falls back to cache when offline during refresh', () async {
      when(network.isConnected).thenAnswer((_) async => false);
      when(local.getCachedRates('USD')).thenAnswer((_) async => staleRate);

      final result = await repo.refreshRates('USD');
      expect(result.rates['EUR'], 0.90);
    });
  });
}

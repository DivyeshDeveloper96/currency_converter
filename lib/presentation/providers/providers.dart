import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/network_info.dart';
import '../../data/datasources/local/exchange_rate_local_source.dart';
import '../../data/datasources/remote/exchange_rate_remote_source.dart';
import '../../data/repositories/currency_repository.dart';
import '../../data/repositories/currency_repository_impl.dart';
import '../viewmodels/converter_viewmodel.dart';
import '../viewmodels/currencies_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';

// Infrastructure
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPrefsProvider before use');
});

final networkInfoProvider = Provider<NetworkInfo>(
  (_) => NetworkInfoImpl(),
);

final remoteSourceProvider = Provider<ExchangeRateRemoteSource>(
  (_) => ExchangeRateRemoteSourceImpl(),
);

final localSourceProvider = Provider<ExchangeRateLocalSource>(
  (_) => ExchangeRateLocalSourceImpl(),
);

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  return CurrencyRepositoryImpl(
    remote: ref.read(remoteSourceProvider),
    local: ref.read(localSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

// ViewModels
final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  return SettingsViewModel(
    prefs: ref.read(sharedPrefsProvider),
    repository: ref.read(currencyRepositoryProvider),
  );
});

final converterViewModelProvider =
    StateNotifierProvider<ConverterViewModel, ConverterState>((ref) {
  return ConverterViewModel(
    repository: ref.read(currencyRepositoryProvider),
    settingsVm: ref.read(settingsViewModelProvider.notifier),
  );
});

final currenciesViewModelProvider =
    StateNotifierProvider<CurrenciesViewModel, CurrenciesState>((ref) {
  return CurrenciesViewModel(
    repository: ref.read(currencyRepositoryProvider),
  );
});

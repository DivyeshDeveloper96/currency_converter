import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/currency.dart';
import '../../data/repositories/currency_repository.dart';
import '../../../core/constants/app_constants.dart';

class SettingsState {
  final String baseCurrency;
  final List<Currency> currencies;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.baseCurrency = AppConstants.defaultBaseCurrency,
    this.currencies = const [],
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    String? baseCurrency,
    List<Currency>? currencies,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      currencies: currencies ?? this.currencies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;
  final CurrencyRepository _repository;

  SettingsViewModel({
    required SharedPreferences prefs,
    required CurrencyRepository repository,
  })  : _prefs = prefs,
        _repository = repository,
        super(SettingsState(
          baseCurrency: prefs.getString(AppConstants.prefBaseCurrency) ??
              AppConstants.defaultBaseCurrency,
        )) {
    loadCurrencies();
  }

  String get baseCurrency => state.baseCurrency;

  Future<void> loadCurrencies() async {
    state = state.copyWith(isLoading: true);
    try {
      final currencies = await _repository.getCurrencies();
      state = state.copyWith(currencies: currencies, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setBaseCurrency(String code) async {
    await _prefs.setString(AppConstants.prefBaseCurrency, code);
    state = state.copyWith(baseCurrency: code);
  }
}

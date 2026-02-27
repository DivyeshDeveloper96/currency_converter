import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exchange_rate.dart';
import '../../data/repositories/currency_repository.dart';
import '../../core/errors/app_exception.dart';
import 'settings_viewmodel.dart';

class CurrencyEntry {
  final String id;
  final String currencyCode;
  final double? amount;

  const CurrencyEntry({
    required this.id,
    required this.currencyCode,
    this.amount,
  });

  CurrencyEntry copyWith({String? currencyCode, double? amount, bool clearAmount = false}) {
    return CurrencyEntry(
      id: id,
      currencyCode: currencyCode ?? this.currencyCode,
      amount: clearAmount ? null : (amount ?? this.amount),
    );
  }

  bool get hasValidAmount => amount != null && amount! > 0;
}

enum ConverterStatus { idle, loading, success, error }

class ConverterState {
  final List<CurrencyEntry> entries;
  final double? total;
  final ConverterStatus status;
  final String? errorMessage;
  final String? warningMessage;
  final ExchangeRate? exchangeRate;
  final bool isOffline;

  const ConverterState({
    this.entries = const [],
    this.total,
    this.status = ConverterStatus.idle,
    this.errorMessage,
    this.warningMessage,
    this.exchangeRate,
    this.isOffline = false,
  });

  ConverterState copyWith({
    List<CurrencyEntry>? entries,
    double? total,
    bool clearTotal = false,
    ConverterStatus? status,
    String? errorMessage,
    String? warningMessage,
    ExchangeRate? exchangeRate,
    bool? isOffline,
  }) {
    return ConverterState(
      entries: entries ?? this.entries,
      total: clearTotal ? null : (total ?? this.total),
      status: status ?? this.status,
      errorMessage: errorMessage,
      warningMessage: warningMessage,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class ConverterViewModel extends StateNotifier<ConverterState> {
  final CurrencyRepository _repository;
  final SettingsViewModel _settingsVm;

  int _idCounter = 0;

  ConverterViewModel({
    required CurrencyRepository repository,
    required SettingsViewModel settingsVm,
  })  : _repository = repository,
        _settingsVm = settingsVm,
        super(const ConverterState()) {
    // Start with two empty entry rows
    _addDefaultEntries();
    _loadRates();
  }

  void _addDefaultEntries() {
    state = state.copyWith(entries: [
      _newEntry('USD'),
      _newEntry('EUR'),
    ]);
  }

  CurrencyEntry _newEntry(String code) {
    return CurrencyEntry(id: '${++_idCounter}', currencyCode: code);
  }

  Future<void> _loadRates() async {
    state = state.copyWith(status: ConverterStatus.loading);
    try {
      final rates = await _repository.getRates(_settingsVm.baseCurrency);
      state = state.copyWith(
        exchangeRate: rates,
        status: ConverterStatus.idle,
        isOffline: rates.isStale,
        warningMessage: rates.isStale ? 'Showing cached rates. Pull to refresh.' : null,
      );
    } on NetworkException {
      state = state.copyWith(
        status: ConverterStatus.error,
        isOffline: true,
        errorMessage: 'No internet connection. Connect to load live rates.',
      );
    } catch (e) {
      state = state.copyWith(
        status: ConverterStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(status: ConverterStatus.loading, clearTotal: true);
    try {
      final rates = await _repository.refreshRates(_settingsVm.baseCurrency);
      state = state.copyWith(
        exchangeRate: rates,
        status: ConverterStatus.idle,
        isOffline: false,
        warningMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ConverterStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void addEntry() {
    final currencies = ['GBP', 'INR', 'JPY', 'CAD', 'AUD', 'CHF'];
    final used = state.entries.map((e) => e.currencyCode).toSet();
    final next = currencies.firstWhere((c) => !used.contains(c), orElse: () => 'CNY');

    state = state.copyWith(
      entries: [...state.entries, _newEntry(next)],
      clearTotal: true,
    );
  }

  void removeEntry(String id) {
    if (state.entries.length <= 1) return;
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
      clearTotal: true,
    );
  }

  void updateAmount(String id, double? amount) {
    state = state.copyWith(
      entries: state.entries
          .map((e) => e.id == id ? e.copyWith(amount: amount, clearAmount: amount == null) : e)
          .toList(),
      clearTotal: true,
    );
  }

  void updateCurrency(String id, String code) {
    state = state.copyWith(
      entries: state.entries
          .map((e) => e.id == id ? e.copyWith(currencyCode: code) : e)
          .toList(),
      clearTotal: true,
    );
  }

  void calculateTotal() {
    final rates = state.exchangeRate;
    final base = _settingsVm.baseCurrency;

    if (rates == null) {
      state = state.copyWith(
        errorMessage: 'Exchange rates not loaded yet. Please wait or check your connection.',
      );
      return;
    }

    final validEntries = state.entries.where((e) => e.hasValidAmount).toList();
    if (validEntries.isEmpty) {
      state = state.copyWith(errorMessage: 'Enter at least one amount to calculate.');
      return;
    }

    double total = 0.0;
    final skipped = <String>[];

    for (final entry in validEntries) {
      final inBase = rates.convert(
        amount: entry.amount!,
        from: entry.currencyCode,
        to: base,
      );
      if (inBase == null) {
        skipped.add(entry.currencyCode);
      } else {
        total += inBase;
      }
    }

    state = state.copyWith(
      total: total,
      status: ConverterStatus.success,
      warningMessage: skipped.isNotEmpty
          ? 'Could not convert: ${skipped.join(', ')}. These were excluded.'
          : null,
      errorMessage: null,
    );
  }

  Future<void> reloadForBase(String newBase) async {
    state = state.copyWith(clearTotal: true);
    await _loadRates();
  }
}

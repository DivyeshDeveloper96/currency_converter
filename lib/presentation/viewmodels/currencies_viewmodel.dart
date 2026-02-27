import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/currency.dart';
import '../../data/repositories/currency_repository.dart';

class CurrenciesState {
  final List<Currency> all;
  final List<Currency> filtered;
  final bool isLoading;
  final String? error;
  final String query;

  const CurrenciesState({
    this.all = const [],
    this.filtered = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  CurrenciesState copyWith({
    List<Currency>? all,
    List<Currency>? filtered,
    bool? isLoading,
    String? error,
    String? query,
  }) {
    return CurrenciesState(
      all: all ?? this.all,
      filtered: filtered ?? this.filtered,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
    );
  }
}

class CurrenciesViewModel extends StateNotifier<CurrenciesState> {
  final CurrencyRepository _repository;

  CurrenciesViewModel({required CurrencyRepository repository})
      : _repository = repository,
        super(const CurrenciesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final currencies = await _repository.getCurrencies();
      state = state.copyWith(
        all: currencies,
        filtered: currencies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String query) {
    final q = query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? state.all
        : state.all.where((c) {
            return c.code.toLowerCase().contains(q) ||
                c.name.toLowerCase().contains(q);
          }).toList();

    state = state.copyWith(filtered: filtered, query: query);
  }

  void clearSearch() => search('');
}

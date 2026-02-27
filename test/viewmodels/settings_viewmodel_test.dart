import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:currency_converter/data/models/currency.dart';
import 'package:currency_converter/data/repositories/currency_repository.dart';
import 'package:currency_converter/presentation/viewmodels/settings_viewmodel.dart';
import 'package:currency_converter/core/constants/app_constants.dart';

@GenerateMocks([CurrencyRepository])
import 'settings_viewmodel_test.mocks.dart';

void main() {
  late MockCurrencyRepository mockRepo;

  final mockCurrencies = [
    const Currency(code: 'USD', name: 'United States Dollar'),
    const Currency(code: 'EUR', name: 'Euro'),
    const Currency(code: 'GBP', name: 'British Pound'),
  ];

  setUp(() {
    mockRepo = MockCurrencyRepository();
    when(mockRepo.getCurrencies()).thenAnswer((_) async => mockCurrencies);
    SharedPreferences.setMockInitialValues({});
  });

  Future<SettingsViewModel> buildVm({String? savedBase}) async {
    SharedPreferences.setMockInitialValues(
      savedBase != null ? {AppConstants.prefBaseCurrency: savedBase} : {},
    );
    final prefs = await SharedPreferences.getInstance();
    return SettingsViewModel(prefs: prefs, repository: mockRepo);
  }

  group('initial state', () {
    test('defaults to USD when no preference saved', () async {
      final vm = await buildVm();
      expect(vm.state.baseCurrency, AppConstants.defaultBaseCurrency);
    });

    test('restores saved base currency on startup', () async {
      final vm = await buildVm(savedBase: 'EUR');
      expect(vm.state.baseCurrency, 'EUR');
    });
  });

  group('setBaseCurrency', () {
    test('updates state and persists to prefs', () async {
      final vm = await buildVm();
      await vm.setBaseCurrency('GBP');
      expect(vm.state.baseCurrency, 'GBP');

      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefBaseCurrency), 'GBP');
    });
  });

  group('loadCurrencies', () {
    test('populates currencies list on success', () async {
      final vm = await buildVm();
      await Future.delayed(const Duration(milliseconds: 50)); // let init settle
      expect(vm.state.currencies, isNotEmpty);
    });

    test('sets error message on failure', () async {
      when(mockRepo.getCurrencies()).thenThrow(Exception('Network error'));
      final vm = await buildVm();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(vm.state.error, isNotNull);
      expect(vm.state.isLoading, isFalse);
    });
  });
}

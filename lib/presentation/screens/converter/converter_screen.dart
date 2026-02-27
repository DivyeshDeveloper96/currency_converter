import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../viewmodels/converter_viewmodel.dart';
import '../../widgets/currency_input_card.dart';
import '../../widgets/result_display.dart';
import '../../widgets/app_error_widget.dart';

class ConverterScreen extends ConsumerWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(converterViewModelProvider);
    final vm = ref.read(converterViewModelProvider.notifier);
    final settings = ref.watch(settingsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              vm.reloadForBase(
                ref.read(settingsViewModelProvider).baseCurrency,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_outlined),
            onPressed: () => Navigator.pushNamed(context, '/currencies'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isOffline) const OfflineBanner(),
          Expanded(
            child: state.status == ConverterStatus.loading && state.exchangeRate == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: vm.refresh,
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: _Header(baseCurrency: settings.baseCurrency),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                final entry = state.entries[i];
                                return CurrencyInputCard(
                                  key: ValueKey(entry.id),
                                  currencyCode: entry.currencyCode,
                                  amount: entry.amount,
                                  currencies: settings.currencies,
                                  showRemove: state.entries.length > 1,
                                  onAmountChanged: (v) => vm.updateAmount(entry.id, v),
                                  onCurrencyChanged: (c) => vm.updateCurrency(entry.id, c),
                                  onRemove: () => vm.removeEntry(entry.id),
                                );
                              },
                              childCount: state.entries.length,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: _AddCurrencyButton(onTap: vm.addEntry),
                          ),
                        ),
                        if (state.total != null)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                            sliver: SliverToBoxAdapter(
                              child: ResultDisplay(
                                total: state.total!,
                                baseCurrency: settings.baseCurrency,
                              ),
                            ),
                          ),
                        if (state.errorMessage != null)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            sliver: SliverToBoxAdapter(
                              child: _InlineMessage(
                                message: state.errorMessage!,
                                isError: true,
                              ),
                            ),
                          ),
                        if (state.warningMessage != null)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            sliver: SliverToBoxAdapter(
                              child: _InlineMessage(
                                message: state.warningMessage!,
                                isError: false,
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _CalculateBar(
        isLoading: state.status == ConverterStatus.loading,
        onCalculate: vm.calculateTotal,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String baseCurrency;
  const _Header({required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add currencies below and hit Calculate.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                'Base: $baseCurrency',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddCurrencyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCurrencyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Currency',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculateBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCalculate;

  const _CalculateBar({required this.isLoading, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onCalculate,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Calculate Total'),
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _InlineMessage({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade50 : Colors.amber.shade50;
    final textColor = isError ? Colors.red.shade700 : Colors.amber.shade800;
    final icon = isError ? Icons.error_outline : Icons.info_outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: textColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

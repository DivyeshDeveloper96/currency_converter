import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/currency.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final vm = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(label: 'Base Currency'),
          const SizedBox(height: 8),
          _BaseCurrencyCard(
            currentCode: state.baseCurrency,
            currencies: state.currencies,
            isLoading: state.isLoading,
            onChanged: (code) async {
              await vm.setBaseCurrency(code);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Base currency updated to $code'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'About'),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _InfoRow(icon: Icons.speed_outlined, label: 'Rates cached for', value: '1 hour'),
              const Divider(height: 1),
              _InfoRow(
                  icon: Icons.cloud_outlined, label: 'Data source', value: 'apilayer.com'),
              const Divider(height: 1),
              _InfoRow(
                  icon: Icons.currency_exchange,
                  label: 'Supported currencies',
                  value: '170+'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BaseCurrencyCard extends StatelessWidget {
  final String currentCode;
  final List<Currency> currencies;
  final bool isLoading;
  final ValueChanged<String> onChanged;

  const _BaseCurrencyCard({
    required this.currentCode,
    required this.currencies,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              children: currencies.map((c) {
                final selected = c.code == currentCode;
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            c.code,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : theme.colorScheme.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      title: Text(c.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(c.code,
                          style: const TextStyle(fontSize: 12)),
                      trailing: selected
                          ? Icon(Icons.check_circle,
                              color: theme.colorScheme.primary, size: 22)
                          : null,
                      onTap: () => onChanged(c.code),
                    ),
                    if (currencies.last != c) const Divider(height: 1, indent: 64),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../util/format.dart';
import '../util/l10n.dart';
import 'results_screen.dart';

class PositionsScreen extends StatefulWidget {
  const PositionsScreen({super.key});

  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}

class _CustomRowData {
  final TextEditingController name;
  final TextEditingController amount;

  _CustomRowData({String initialName = '', double initialAmount = 0})
      : name = TextEditingController(text: initialName),
        amount = TextEditingController(
            text: initialAmount > 0 ? initialAmount.toStringAsFixed(0) : '');

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _PositionsScreenState extends State<PositionsScreen> {
  late final Map<String, TextEditingController> _amounts;
  final List<_CustomRowData> _custom = [];

  @override
  void initState() {
    super.initState();
    final draft = context.read<AppState>().draft;
    _amounts = {
      for (final e in draft.entries)
        e.category.id: TextEditingController(
            text: e.amount > 0 ? e.amount.toStringAsFixed(0) : ''),
    };
    for (final item in draft.customItems) {
      _custom.add(
          _CustomRowData(initialName: item.name, initialAmount: item.amount));
    }
  }

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    for (final r in _custom) {
      r.dispose();
    }
    super.dispose();
  }

  double get _total {
    final draft = context.read<AppState>().draft;
    var sum = 0.0;
    for (final e in draft.entries) {
      if (e.included) {
        sum += parseAmount(_amounts[e.category.id]?.text ?? '');
      }
    }
    for (final r in _custom) {
      sum += parseAmount(r.amount.text);
    }
    return sum;
  }

  void _analyze() {
    final app = context.read<AppState>();
    final draft = app.draft;
    for (final e in draft.entries) {
      e.amount = parseAmount(_amounts[e.category.id]?.text ?? '');
    }
    draft.customItems
      ..clear()
      ..addAll([
        for (final r in _custom)
          if (r.name.text.trim().isNotEmpty || parseAmount(r.amount.text) > 0)
            CustomItem(
                name: r.name.text.trim(), amount: parseAmount(r.amount.text)),
      ]);
    final hasAny = draft.entries.any((e) => e.included && e.amount > 0) ||
        draft.customItems.isNotEmpty;
    if (!hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('Enter at least one cost amount first.',
                'Bitte zuerst mindestens einen Betrag erfassen.'))),
      );
      return;
    }
    app.analyze();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ResultsScreen()),
    );
  }

  void _removeCustom(int index) {
    final removed = _custom.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<AppState>().draft;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('Cost positions · 2 of 2', 'Kostenpositionen · 2 von 2'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          children: [
            Text(
              tr(
                'Switch on every line that appears on your statement and copy its amount for the whole period.',
                'Aktivieren Sie jede Zeile, die auf Ihrer Abrechnung steht, und übertragen Sie den Betrag für den gesamten Zeitraum.',
              ),
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 14),
            for (final e in draft.entries) _positionTile(e),
            const SizedBox(height: 16),
            SectionLabel(tr('Free-text items on your statement',
                'Freitext-Positionen auf Ihrer Abrechnung')),
            for (var i = 0; i < _custom.length; i++) _customTile(i),
            OutlinedButton.icon(
              onPressed: () => setState(() => _custom.add(_CustomRowData())),
              icon: const Icon(Icons.add),
              label: Text(tr('Add item (e.g. "Verwaltungskosten")',
                  'Position hinzufügen (z. B. „Verwaltungskosten")')),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tr('TOTAL ENTERED', 'SUMME ERFASST'),
                        style: AppText.label()),
                    Text(
                      fmtEuro(_total),
                      style: AppText.mono(size: 18, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _analyze,
                  child: Text(tr('Analyze', 'Prüfen')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _positionTile(CostEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.category.nameDe,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink,
                        ),
                      ),
                      if (!AppLang.isDe)
                        Text(
                          e.category.nameEn,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: e.included,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => e.included = v),
                ),
              ],
            ),
            if (e.included) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _amounts[e.category.id],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: fieldDecoration(
                    tr('Amount for the period', 'Betrag im Zeitraum'),
                    suffix: '€'),
              ),
              if (e.category.hint.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppColors.inkSoft),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        AppLang.isDe && e.category.hintDe.isNotEmpty
                            ? e.category.hintDe
                            : e.category.hint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _customTile(int i) {
    final r = _custom[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: TextField(
                controller: r.name,
                onChanged: (_) => setState(() {}),
                decoration: fieldDecoration(tr('Item name', 'Bezeichnung')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: r.amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: fieldDecoration('€'),
              ),
            ),
            IconButton(
              onPressed: () => _removeCustom(i),
              icon: const Icon(Icons.delete_outline, color: AppColors.inkSoft),
              tooltip: tr('Remove item', 'Position entfernen'),
            ),
          ],
        ),
      ),
    );
  }
}

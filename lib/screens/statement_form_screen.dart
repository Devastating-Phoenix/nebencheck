import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/cities.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/common.dart';
import '../util/format.dart';
import '../util/l10n.dart';
import 'about_screen.dart';
import 'positions_screen.dart';

class StatementFormScreen extends StatefulWidget {
  const StatementFormScreen({super.key});

  @override
  State<StatementFormScreen> createState() => _StatementFormScreenState();
}

class _StatementFormScreenState extends State<StatementFormScreen> {
  late final TextEditingController _size;
  late final TextEditingController _prepaid;
  late final TextEditingController _tenant;
  late final TextEditingController _landlord;
  late DateTime _start;
  late DateTime _end;
  late DateTime _received;
  late String _cityId;
  late HeatingBilling _heating;

  @override
  void initState() {
    super.initState();
    final draft = context.read<AppState>().draft;
    _cityId = draft.cityId;
    _heating = draft.heatingBilling;
    _size = TextEditingController(
        text: draft.apartmentSize > 0
            ? draft.apartmentSize.toStringAsFixed(0)
            : '');
    _prepaid = TextEditingController(
        text: draft.prepaid > 0 ? draft.prepaid.toStringAsFixed(0) : '');
    _tenant = TextEditingController(text: draft.tenantName);
    _landlord = TextEditingController(text: draft.landlordName);
    _start = draft.periodStart;
    _end = draft.periodEnd;
    _received = draft.receivedDate;
  }

  @override
  void dispose() {
    _size.dispose();
    _prepaid.dispose();
    _tenant.dispose();
    _landlord.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
      DateTime current, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  void _continue() {
    final size = parseAmount(_size.text);
    if (size < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('Please enter your apartment size in m².',
                'Bitte geben Sie Ihre Wohnfläche in m² an.'))),
      );
      return;
    }
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('The period end must be after its start.',
                'Das Ende des Zeitraums muss nach dessen Beginn liegen.'))),
      );
      return;
    }
    final draft = context.read<AppState>().draft;
    draft
      ..apartmentSize = size
      ..prepaid = parseAmount(_prepaid.text)
      ..tenantName = _tenant.text.trim()
      ..landlordName = _landlord.text.trim()
      ..cityId = _cityId
      ..heatingBilling = _heating
      ..periodStart = _start
      ..periodEnd = _end
      ..receivedDate = _received;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PositionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('Your statement · 1 of 2', 'Ihre Abrechnung · 1 von 2'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          children: [
            SectionLabel(tr('Apartment', 'Wohnung')),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _cityId,
                    isExpanded: true,
                    decoration:
                        fieldDecoration(tr('City / region', 'Stadt / Region')),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    items: [
                      for (final c in kCities)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.isNational
                                ? tr('Germany · national average',
                                    'Deutschland · Bundesdurchschnitt')
                                : (c.name == c.state
                                    ? c.name
                                    : '${c.name} · ${c.state}'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _cityId = v ?? 'de'),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        tr(
                          'Sets the regional reference level — the legal checks are the same everywhere. Why? →',
                          'Bestimmt das regionale Referenzniveau — die rechtlichen Prüfungen sind überall gleich. Warum? →',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _size,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: fieldDecoration(
                        tr('Apartment size', 'Wohnfläche'),
                        suffix: 'm²',
                        hint: tr('e.g. 62', 'z. B. 62')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _prepaid,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: fieldDecoration(
                      tr('Prepayments in the period (Vorauszahlungen)',
                          'Vorauszahlungen im Zeitraum'),
                      suffix: '€',
                      hint: tr('e.g. 1980', 'z. B. 1980'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionLabel(tr('Dates', 'Zeitraum')),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                children: [
                  _DateTile(
                    label: tr('Billing period start',
                        'Beginn des Abrechnungszeitraums'),
                    value: _start,
                    onTap: () => _pickDate(_start, (d) => _start = d),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  _DateTile(
                    label:
                        tr('Billing period end', 'Ende des Abrechnungszeitraums'),
                    value: _end,
                    onTap: () => _pickDate(_end, (d) => _end = d),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  _DateTile(
                    label: tr('Statement received on', 'Abrechnung erhalten am'),
                    value: _received,
                    onTap: () => _pickDate(_received, (d) => _received = d),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                "The received date drives two legal deadlines: the landlord's 12-month delivery limit and your own 12-month objection window.",
                'Das Zugangsdatum bestimmt zwei Fristen: die 12-monatige Abrechnungsfrist des Vermieters und Ihre eigene 12-monatige Widerspruchsfrist.',
              ),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.inkSoft,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SectionLabel(tr('Heating', 'Heizung')),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<HeatingBilling>(
                    initialValue: _heating,
                    isExpanded: true,
                    decoration: fieldDecoration(tr(
                        'Billed by consumption (≥50%)?',
                        'Verbrauchsabhängig abgerechnet (≥50 %)?')),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: HeatingBilling.unknown,
                        child: Text(tr('Not sure', 'Weiß ich nicht')),
                      ),
                      DropdownMenuItem(
                        value: HeatingBilling.consumption,
                        child: Text(tr('Yes — billed by consumption',
                            'Ja — verbrauchsabhängig')),
                      ),
                      DropdownMenuItem(
                        value: HeatingBilling.flat,
                        child: Text(
                            tr('No — flat rate only', 'Nein — nur pauschal')),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _heating = v ?? HeatingBilling.unknown),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'If heating is billed flat only, § 12 HeizKV lets you cut the heating bill by 15%. Look for a consumption split on your statement.',
                      'Wird nur pauschal abgerechnet, dürfen Sie die Heizkosten nach § 12 HeizKV um 15 % kürzen. Suchen Sie auf der Abrechnung nach einem Verbrauchsanteil.',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionLabel(
                tr('For the letter (optional)', 'Für das Schreiben (optional)')),
            SurfaceCard(
              child: Column(
                children: [
                  TextField(
                    controller: _tenant,
                    decoration: fieldDecoration(tr('Your name', 'Ihr Name')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _landlord,
                    decoration: fieldDecoration(tr(
                        'Landlord / property manager',
                        'Vermieter / Hausverwaltung')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
          child: FilledButton(
            onPressed: _continue,
            child: Text(tr('Continue to cost positions',
                'Weiter zu den Kostenpositionen')),
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(fmtDate(value), style: AppText.mono(size: 14.5)),
            const SizedBox(width: 8),
            const Icon(Icons.edit_calendar_outlined,
                size: 19, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

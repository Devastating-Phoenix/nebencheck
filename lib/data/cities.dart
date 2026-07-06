/// Regional cost levels — sourced, two-dimensional.
///
/// German tenancy *law* is federal and identical everywhere. Costs are
/// not — and they split into two very different dimensions that often
/// point in opposite directions:
///
///  * **Municipal charges** (Grundsteuer, water/sewage, waste, street
///    cleaning) are set by each city. Source: Haus & Grund / IW Consult
///    "Nebenkostenranking" of the 100 largest cities (fee data
///    2016–2018; model four-person household). München pays 1.058 €/a,
///    Berlin 1.619 €/a — the expensive-rent cities are often the CHEAP
///    fee cities and vice versa. Factor = city value / ~1.300 € mean.
///
///  * **Building services** (caretaker, cleaning, garden, elevator,
///    chimney sweep…) follow regional wages. Source: DMB
///    Betriebskostenspiegel state-level totals for accounting year 2024
///    (Berlin 2,81 €/m², Sachsen 2,21 €/m² vs 2,67 € national).
///
///  * **Heating, hot water, insurance** are national markets and are
///    not scaled at all.
///
/// Factors marked in notes with "estimate" lack a published state value
/// and are interpolated. All of this is documented in the About screen.
class City {
  final String id;
  final String name;
  final String state;

  /// Building-service cost level vs national (DMB state data 2024).
  final double serviceFactor;

  /// Municipal-charge level vs the 100-city mean (H&G/IW ranking).
  final double feeFactor;

  final String note;
  final String noteDe;

  const City({
    required this.id,
    required this.name,
    required this.state,
    required this.serviceFactor,
    required this.feeFactor,
    this.note = '',
    this.noteDe = '',
  });

  bool get isNational => id == 'de';

  /// Categories that are municipal charges.
  static const _feeCategories = {
    'grundsteuer',
    'wasser',
    'muell',
    'strassenreinigung',
  };

  /// Categories priced on national markets — never scaled.
  static const _nationalCategories = {
    'heizung',
    'warmwasser',
    'versicherung',
    'kabel',
  };

  /// The factor to apply to [categoryId]'s national reference value.
  double factorFor(String categoryId) {
    if (_feeCategories.contains(categoryId)) return feeFactor;
    if (_nationalCategories.contains(categoryId)) return 1.0;
    return serviceFactor;
  }
}

const List<City> kCities = [
  City(
    id: 'de',
    name: 'Germany · national average',
    state: '',
    serviceFactor: 1.00,
    feeFactor: 1.00,
    note: 'Unadjusted national reference values (DMB 2024).',
    noteDe: 'Unangepasste bundesweite Referenzwerte (DMB 2024).',
  ),
  City(
    id: 'berlin',
    name: 'Berlin',
    state: 'Berlin',
    serviceFactor: 1.05,
    feeFactor: 1.25,
    note: 'Fees 1.619 €/a — rank 94 of 100 (H&G/IW). Services: DMB Berlin 2,81 €/m².',
    noteDe: 'Gebühren 1.619 €/J — Rang 94 von 100 (H&G/IW). Dienste: DMB Berlin 2,81 €/m².',
  ),
  City(
    id: 'hamburg',
    name: 'Hamburg',
    state: 'Hamburg',
    serviceFactor: 1.02,
    feeFactor: 1.02,
    note: 'Fees 1.321 €/a — rank 64 of 100. Services: DMB Hamburg 2,73 €/m².',
    noteDe: 'Gebühren 1.321 €/J — Rang 64 von 100. Dienste: DMB Hamburg 2,73 €/m².',
  ),
  City(
    id: 'muenchen',
    name: 'München',
    state: 'Bayern',
    serviceFactor: 0.97,
    feeFactor: 0.81,
    note: 'Fees only 1.058 €/a — rank 19 of 100. Services: DMB Bayern 2,58 €/m² (state level).',
    noteDe: 'Gebühren nur 1.058 €/J — Rang 19 von 100. Dienste: DMB Bayern 2,58 €/m² (Landeswert).',
  ),
  City(
    id: 'koeln',
    name: 'Köln',
    state: 'Nordrhein-Westfalen',
    serviceFactor: 1.01,
    feeFactor: 0.92,
    note: 'Fees 1.195 €/a — rank 49 of 100. Services: DMB NRW 2,69 €/m².',
    noteDe: 'Gebühren 1.195 €/J — Rang 49 von 100. Dienste: DMB NRW 2,69 €/m².',
  ),
  City(
    id: 'frankfurt',
    name: 'Frankfurt am Main',
    state: 'Hessen',
    serviceFactor: 0.98,
    feeFactor: 0.77,
    note: 'Fees only 998 €/a — rank 9 of 100. Services: DMB Hessen 2,61 €/m².',
    noteDe: 'Gebühren nur 998 €/J — Rang 9 von 100. Dienste: DMB Hessen 2,61 €/m².',
  ),
  City(
    id: 'stuttgart',
    name: 'Stuttgart',
    state: 'Baden-Württemberg',
    serviceFactor: 1.04,
    feeFactor: 0.81,
    note: 'Fees 1.052 €/a — rank 18 of 100. Service factor: estimate (no DMB state value).',
    noteDe: 'Gebühren 1.052 €/J — Rang 18 von 100. Dienstefaktor: Schätzung (kein DMB-Landeswert).',
  ),
  City(
    id: 'duesseldorf',
    name: 'Düsseldorf',
    state: 'Nordrhein-Westfalen',
    serviceFactor: 1.01,
    feeFactor: 0.85,
    note: 'Fees 1.100 €/a — rank 28 of 100. Services: DMB NRW 2,69 €/m².',
    noteDe: 'Gebühren 1.100 €/J — Rang 28 von 100. Dienste: DMB NRW 2,69 €/m².',
  ),
  City(
    id: 'nuernberg',
    name: 'Nürnberg',
    state: 'Bayern',
    serviceFactor: 0.97,
    feeFactor: 0.83,
    note: 'Fees 1.078 €/a — rank 17 of 100. Services: DMB Bayern 2,58 €/m².',
    noteDe: 'Gebühren 1.078 €/J — Rang 17 von 100. Dienste: DMB Bayern 2,58 €/m².',
  ),
  City(
    id: 'bremen',
    name: 'Bremen',
    state: 'Bremen',
    serviceFactor: 0.97,
    feeFactor: 1.14,
    note: 'Fees 1.488 €/a — rank 86 of 100. Service factor: estimate.',
    noteDe: 'Gebühren 1.488 €/J — Rang 86 von 100. Dienstefaktor: Schätzung.',
  ),
  City(
    id: 'hannover',
    name: 'Hannover',
    state: 'Niedersachsen',
    serviceFactor: 0.95,
    feeFactor: 0.95,
    note: 'Fees 1.240 €/a — rank 57 of 100. Service factor: estimate.',
    noteDe: 'Gebühren 1.240 €/J — Rang 57 von 100. Dienstefaktor: Schätzung.',
  ),
  City(
    id: 'essen',
    name: 'Essen (Ruhrgebiet)',
    state: 'Nordrhein-Westfalen',
    serviceFactor: 1.01,
    feeFactor: 1.10,
    note: 'Fees 1.424 €/a — rank 72 of 100. Services: DMB NRW 2,69 €/m².',
    noteDe: 'Gebühren 1.424 €/J — Rang 72 von 100. Dienste: DMB NRW 2,69 €/m².',
  ),
  City(
    id: 'leipzig',
    name: 'Leipzig',
    state: 'Sachsen',
    serviceFactor: 0.83,
    feeFactor: 0.99,
    note: 'Fees 1.289 €/a — rank 68 of 100. Services: DMB Sachsen 2,21 €/m².',
    noteDe: 'Gebühren 1.289 €/J — Rang 68 von 100. Dienste: DMB Sachsen 2,21 €/m².',
  ),
  City(
    id: 'dresden',
    name: 'Dresden',
    state: 'Sachsen',
    serviceFactor: 0.83,
    feeFactor: 1.02,
    note: 'Fees 1.324 €/a — rank 69 of 100. Services: DMB Sachsen 2,21 €/m².',
    noteDe: 'Gebühren 1.324 €/J — Rang 69 von 100. Dienste: DMB Sachsen 2,21 €/m².',
  ),
];

City cityById(String id) =>
    kCities.firstWhere((c) => c.id == id, orElse: () => kCities.first);

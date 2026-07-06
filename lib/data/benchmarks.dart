import '../models/models.dart';

/// Reference values in € per m² per month.
///
/// These approximate the Deutscher Mieterbund "Betriebskostenspiegel"
/// (national operating-cost survey). They are deliberately plain constants
/// so they can be updated in one place when a new survey is published, or
/// later replaced by a remote config / API with city-level values.
const List<CostCategory> kCategories = [
  CostCategory(
    id: 'grundsteuer',
    nameDe: 'Grundsteuer',
    nameEn: 'Property tax',
    benchmark: 0.19,
    hint: 'Set by the municipality; varies strongly by city.',
    hintDe: 'Wird von der Gemeinde festgesetzt; stark stadtabhängig.',
  ),
  CostCategory(
    id: 'wasser',
    nameDe: 'Wasser & Abwasser',
    nameEn: 'Water & sewage',
    benchmark: 0.34,
  ),
  CostCategory(
    id: 'heizung',
    nameDe: 'Heizung',
    nameEn: 'Heating',
    benchmark: 1.10,
    hint:
        'Volatile with energy prices. At least 50% must be billed by actual consumption (Heizkostenverordnung).',
    hintDe:
        'Schwankt mit den Energiepreisen. Mindestens 50 % müssen verbrauchsabhängig abgerechnet werden (Heizkostenverordnung).',
  ),
  CostCategory(
    id: 'warmwasser',
    nameDe: 'Warmwasser',
    nameEn: 'Hot water',
    benchmark: 0.27,
  ),
  CostCategory(
    id: 'aufzug',
    nameDe: 'Aufzug',
    nameEn: 'Elevator',
    benchmark: 0.17,
  ),
  CostCategory(
    id: 'strassenreinigung',
    nameDe: 'Straßenreinigung',
    nameEn: 'Street cleaning',
    benchmark: 0.03,
  ),
  CostCategory(
    id: 'muell',
    nameDe: 'Müllbeseitigung',
    nameEn: 'Waste collection',
    benchmark: 0.19,
  ),
  CostCategory(
    id: 'reinigung',
    nameDe: 'Gebäudereinigung & Ungeziefer',
    nameEn: 'Building cleaning & pest control',
    benchmark: 0.19,
  ),
  CostCategory(
    id: 'garten',
    nameDe: 'Gartenpflege',
    nameEn: 'Garden maintenance',
    benchmark: 0.10,
  ),
  CostCategory(
    id: 'strom',
    nameDe: 'Allgemeinstrom / Beleuchtung',
    nameEn: 'Shared electricity / lighting',
    benchmark: 0.06,
  ),
  CostCategory(
    id: 'schornstein',
    nameDe: 'Schornsteinreinigung',
    nameEn: 'Chimney sweep',
    benchmark: 0.03,
  ),
  CostCategory(
    id: 'versicherung',
    nameDe: 'Sach- & Haftpflichtversicherung',
    nameEn: 'Building insurance',
    benchmark: 0.25,
  ),
  CostCategory(
    id: 'hauswart',
    nameDe: 'Hauswart',
    nameEn: 'Caretaker / janitor',
    benchmark: 0.23,
    hint: 'May not contain repair or administration work.',
    hintDe: 'Darf keine Reparatur- oder Verwaltungsarbeiten enthalten.',
  ),
  CostCategory(
    id: 'kabel',
    nameDe: 'Antenne / Kabel-TV',
    nameEn: 'Antenna / cable TV',
    benchmark: 0.12,
    hint:
        'No longer chargeable for periods after 30 June 2024 (end of the "Nebenkostenprivileg").',
    hintDe:
        'Für Zeiträume nach dem 30.06.2024 nicht mehr umlagefähig (Ende des „Nebenkostenprivilegs").',
  ),
  CostCategory(
    id: 'waesche',
    nameDe: 'Wäschepflege',
    nameEn: 'Shared laundry facilities',
    benchmark: 0.03,
  ),
  CostCategory(
    id: 'sonstige',
    nameDe: 'Sonstige Betriebskosten',
    nameEn: 'Other operating costs',
    benchmark: 0.06,
    hint: 'Must be individually itemized — a lump sum "Sonstige" is contestable.',
    hintDe:
        'Muss einzeln aufgeschlüsselt sein — eine Pauschale „Sonstige" ist angreifbar.',
  ),
];

/// Categories most tenants have; pre-enabled in a fresh check.
const Set<String> kDefaultIncluded = {
  'grundsteuer',
  'wasser',
  'heizung',
  'warmwasser',
  'muell',
  'versicherung',
  'strom',
};

/// Cost types a landlord may NOT pass on to tenants (§ 1 Abs. 2 BetrKV):
/// administration, repairs, maintenance reserves, banking and similar.
/// Matching is a lowercase "contains" scan over free-text item names.
const List<String> kNonApportionableKeywords = [
  'verwaltung',
  'instandhaltung',
  'instandsetzung',
  'reparatur',
  'rücklage',
  'ruecklage',
  'bank',
  'kontoführung',
  'kontofuehrung',
  'porto',
  'leerstand',
  'makler',
  'anwalt',
  'rechtsberatung',
];

/// Cutoff of the German TKG reform: cable TV may not be billed as an
/// operating cost for billing periods ending after this date.
final DateTime kCableCutoff = DateTime(2024, 6, 30);

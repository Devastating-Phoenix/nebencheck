#!/usr/bin/env python3
"""Watcher: detect a newer DMB Betriebskostenspiegel and update references.json.

Run on a schedule by GitHub Actions. It fetches the source page, uses the
Claude API (structured outputs) to extract this year's national reference
values, and — only if the published year is newer than what's committed and
the numbers pass a sanity check — rewrites the `national` block of
references.json. The workflow then opens a pull request for human review.

It never writes to production directly and never fails the workflow just
because nothing new was published; it exits 0 quietly in that case. It exits
non-zero only when it finds a genuinely new year whose numbers look wrong —
that failure is the signal to look manually.
"""

import json
import sys
from pathlib import Path

import requests
import anthropic
from pydantic import BaseModel

# Source page carrying the DMB Betriebskostenspiegel table.
SOURCE_URL = "https://www.mein-nebenkostenrechner.de/betriebskostenspiegel"

REFERENCES = Path(__file__).resolve().parent.parent / "references.json"

# App category id -> German label, with mapping notes for the model.
CATEGORY_HINTS = """
grundsteuer      = Grundsteuer
wasser           = Wasserversorgung + Entwässerung/Abwasser COMBINED (add them together)
heizung          = Heizung
warmwasser       = Warmwasser
aufzug           = Aufzug
strassenreinigung= Straßenreinigung
muell            = Müllbeseitigung
reinigung        = Gebäudereinigung (Hausreinigung/Ungeziefer)
garten           = Gartenpflege
strom            = Allgemeinstrom / Beleuchtung
schornstein      = Schornsteinreinigung / Schornsteinfeger
versicherung     = Sach- und Haftpflichtversicherung
hauswart         = Hauswart / Hausmeister
waesche          = Wäschepflege / Waschküche
sonstige         = Sonstige Betriebskosten
"""


class NationalValues(BaseModel):
    grundsteuer: float | None = None
    wasser: float | None = None
    heizung: float | None = None
    warmwasser: float | None = None
    aufzug: float | None = None
    strassenreinigung: float | None = None
    muell: float | None = None
    reinigung: float | None = None
    garten: float | None = None
    strom: float | None = None
    schornstein: float | None = None
    versicherung: float | None = None
    hauswart: float | None = None
    waesche: float | None = None
    sonstige: float | None = None


class Extraction(BaseModel):
    data_year: str  # accounting year, e.g. "2024"; "UNKNOWN" if not confident
    national: NationalValues


def bail(msg: str) -> None:
    """Quiet no-op exit — nothing to do this run."""
    print(msg)
    sys.exit(0)


def main() -> None:
    current = json.loads(REFERENCES.read_text(encoding="utf-8"))
    committed_year = str(current.get("dataYear", "0"))

    try:
        page = requests.get(SOURCE_URL, timeout=30).text
    except Exception as e:  # noqa: BLE001
        bail(f"Could not fetch source ({e}); skipping.")

    client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY
    result = client.messages.parse(
        model="claude-opus-4-8",
        max_tokens=2048,
        messages=[{
            "role": "user",
            "content": (
                "Extract the DMB Betriebskostenspiegel (national operating-cost "
                "table) from this page. Return the accounting year and each "
                "category's value in EUR per m² per month. Map German categories "
                "to these keys, following the notes exactly:\n"
                f"{CATEGORY_HINTS}\n"
                "Only include a value you can actually read from the table; leave "
                "the rest null. Omit 'Kabel/Antenne' (no longer chargeable). If "
                "the table is missing or you are not confident, set data_year to "
                "'UNKNOWN'.\n\n" + page
            ),
        }],
        output_format=Extraction,
    )
    ex = result.parsed_output
    if ex is None:
        bail("Model returned no parseable result; skipping.")

    year = ex.data_year.strip()
    if not (year.isdigit() and len(year) == 4):
        bail(f"No confident year (got {year!r}); skipping.")
    if year <= committed_year:
        bail(f"Published year {year} is not newer than committed {committed_year}; skipping.")

    values = {k: v for k, v in ex.national.model_dump().items() if v is not None}
    if len(values) < 8:
        bail(f"Only {len(values)} categories extracted for {year}; too sparse, skipping.")

    # --- GUARDRAIL: a genuinely new year with implausible numbers is an alert.
    for k, v in values.items():
        if not (0 < v < 2.5):
            print(f"::error::{k}={v} for {year} is out of the plausible 0–2.5 band.")
            sys.exit(1)
    total = sum(values.values())
    if len(values) >= 12 and not (2.0 < total < 3.6):
        print(f"::error::Total {total:.2f} €/m² for {year} is outside the sane 2.0–3.6 band.")
        sys.exit(1)

    current["national"].update(values)
    current["dataYear"] = year
    from datetime import date
    current["updated"] = date.today().isoformat()
    REFERENCES.write_text(
        json.dumps(current, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Updated references.json to data year {year} ({len(values)} categories, total {total:.2f}).")


if __name__ == "__main__":
    main()

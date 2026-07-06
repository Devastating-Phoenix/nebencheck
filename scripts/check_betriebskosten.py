#!/usr/bin/env python3
"""Watcher: detect a newer DMB Betriebskostenspiegel and update references.json.

Run on a schedule by GitHub Actions. It fetches the source page, asks the
Claude API to extract this year's national reference values as JSON, and —
only if the published year is newer than what's committed and the numbers pass
a sanity check — rewrites the `national` block of references.json. The workflow
then opens a pull request for human review.

It never writes to production directly and never fails the workflow just
because nothing new was published; it exits 0 quietly in that case. It exits
non-zero only when it finds a genuinely new year whose numbers look wrong —
that failure is the signal to look manually.
"""

import json
import re
import sys
from datetime import date
from pathlib import Path

import requests
import anthropic

# Source page carrying the DMB Betriebskostenspiegel table.
SOURCE_URL = "https://www.mein-nebenkostenrechner.de/betriebskostenspiegel"

REFERENCES = Path(__file__).resolve().parent.parent / "references.json"

# App category ids the model may use, with mapping notes.
CATEGORY_HINTS = """
grundsteuer       = Grundsteuer
wasser            = Wasserversorgung + Entwässerung/Abwasser COMBINED (add them together)
heizung           = Heizung
warmwasser        = Warmwasser
aufzug            = Aufzug
strassenreinigung = Straßenreinigung
muell             = Müllbeseitigung
reinigung         = Gebäudereinigung (Hausreinigung/Ungeziefer)
garten            = Gartenpflege
strom             = Allgemeinstrom / Beleuchtung
schornstein       = Schornsteinreinigung / Schornsteinfeger
versicherung      = Sach- und Haftpflichtversicherung
hauswart          = Hauswart / Hausmeister
waesche           = Wäschepflege / Waschküche
sonstige          = Sonstige Betriebskosten
"""

VALID_KEYS = {
    "grundsteuer", "wasser", "heizung", "warmwasser", "aufzug",
    "strassenreinigung", "muell", "reinigung", "garten", "strom",
    "schornstein", "versicherung", "hauswart", "waesche", "sonstige",
}


def bail(msg: str) -> None:
    """Quiet no-op exit — nothing to do this run."""
    print(msg)
    sys.exit(0)


def extract(page: str) -> dict:
    """Ask Claude to read the table and return {data_year, national:{id:val}}."""
    client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY
    prompt = (
        "Extract the DMB Betriebskostenspiegel (national operating-cost table) "
        "from the page below. Map German categories to these keys, following "
        "the notes exactly:\n"
        f"{CATEGORY_HINTS}\n"
        "Respond with ONLY a JSON object — no prose, no markdown fences — of "
        'the form: {\"data_year\": \"2024\", \"national\": '
        '{\"grundsteuer\": 0.21, \"wasser\": 0.44, ...}} where each value is '
        "EUR per m² per month. Include only categories you can actually read "
        "from the table; omit the rest and omit 'Kabel/Antenne'. If the table "
        'is missing or you are unsure, use {\"data_year\": \"UNKNOWN\", '
        '\"national\": {}}.\n\n' + page
    )
    resp = client.messages.create(
        model="claude-opus-4-8",
        max_tokens=2048,
        messages=[{"role": "user", "content": prompt}],
    )
    text = "".join(b.text for b in resp.content if b.type == "text")
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        bail("Model did not return JSON; skipping.")
    return json.loads(match.group(0))


def main() -> None:
    current = json.loads(REFERENCES.read_text(encoding="utf-8"))
    committed_year = str(current.get("dataYear", "0"))

    try:
        page = requests.get(SOURCE_URL, timeout=30).text
    except Exception as e:  # noqa: BLE001
        bail(f"Could not fetch source ({e}); skipping.")

    try:
        data = extract(page)
    except anthropic.APIError as e:  # noqa: BLE001
        bail(f"Claude API error ({e}); skipping.")

    year = str(data.get("data_year", "")).strip()
    if not (year.isdigit() and len(year) == 4):
        bail(f"No confident year (got {year!r}); skipping.")
    if year <= committed_year:
        bail(f"Published year {year} is not newer than committed {committed_year}; skipping.")

    raw = data.get("national", {}) or {}
    values = {
        k: float(v)
        for k, v in raw.items()
        if k in VALID_KEYS and isinstance(v, (int, float))
    }
    if len(values) < 8:
        bail(f"Only {len(values)} categories extracted for {year}; too sparse, skipping.")

    # --- GUARDRAIL: a genuinely new year with implausible numbers is an alert.
    for k, v in values.items():
        if not (0 < v < 2.5):
            print(f"::error::{k}={v} for {year} is out of the plausible 0-2.5 band.")
            sys.exit(1)
    total = sum(values.values())
    if len(values) >= 12 and not (2.0 < total < 3.6):
        print(f"::error::Total {total:.2f} EUR/m2 for {year} is outside the sane 2.0-3.6 band.")
        sys.exit(1)

    current["national"].update(values)
    current["dataYear"] = year
    current["updated"] = date.today().isoformat()
    REFERENCES.write_text(
        json.dumps(current, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Updated references.json to data year {year} ({len(values)} categories, total {total:.2f}).")


if __name__ == "__main__":
    main()

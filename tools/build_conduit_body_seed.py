#!/usr/bin/env python3
"""Build Data/seed/conduit_body_dims.csv + Data/seed/conduit_body_sources.csv and apply
them to the shipped seed Data/MED.db (MEDConduitBody table).

Rigid/IMC threaded conduit bodies (Condulet), shapes C, LB, LL, LR, T, TB.
Every dimension below is transcribed from the Eaton Crouse-Hinds catalog page cited
in SOURCES (section 1F, (c) 2022 Eaton, printed pages 7 and 10-12). The transcription
was taken from the PDF text layer (fractions rebuilt from glyph sizes) and checked
against three copies of the page (2018 Elliott spec sheet, 2022 mirror, 2022-11
Hunzicker copy - identical values). Values are printed exactly as published, including
the suspect ones listed in NOTES. Nothing is estimated: hub OD / hub length are not
published and stay blank.

Dimension letters (catalog drawings, inches):
  a  overall length along the run (hub face to hub face; LB/LL/LR: closed end to hub face)
  b  overall depth, perpendicular to the cover (LB, TB: includes the back hub)
  c  overall width in plan (LL, LR, T: includes the side hub)
  d  cover opening width
  e  cover opening length

    python tools/build_conduit_body_seed.py            (from repo root)
    python tools/build_conduit_body_seed.py --no-db    (CSVs only)

Seed-DB update is idempotent and only fills blanks (same rule as MedODSeed.cs at runtime).
"""
import csv, os, sqlite3, sys
from fractions import Fraction

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED = os.path.join(ROOT, "Data", "seed")
DB = os.path.join(ROOT, "Data", "MED.db")

URL_EATON = "https://www.eaton.com/content/dam/eaton/products/conduit-cable-and-wire-management/crouse-hinds/catalog-pages/crouse-hinds-form8-mark9-catalog-page.pdf"
URL_COPY = "https://safsale.com/image/catalog/pdf-seo/79/eaton-crouse-hinds-lb58-1-1-2-inch-iron-alloy-threaded-rigid-conduit-body-51419-brochure.pdf"
URL_ELLIOTT = "https://www.elliottelectric.com/Media/170-CRS-2-1-SpecificationSheet.pdf"
URL_HUNZ = "https://default.assets-hunzicker-prod.roccommercecloud.com/assets%2F71645d74cc722e01bc5b56dd9bad2a4a/GASK852N_Catalog.pdf"
URL_LB58 = "https://www.elliottelectric.com/Media/LB58-CRS"

SOURCES = [
    # SourceId, Title, Publisher, Date, URL, CopyReadURL, Pages, Notes
    ("CH1F-2022", "Crouse-Hinds series Form 8 and Mark 9 catalog page (Condulet conduit bodies - cast iron or aluminum, section 1F)",
     "Eaton", "2022", URL_EATON, URL_COPY,
     "printed p.7 (shape/catalog-number table, PDF p.2); p.10 (C, PDF p.4); p.11 (LB, LL & LR, PDF p.5); p.12 (T, TB, PDF p.6)",
     "Eaton URL is the canonical publication (blocks automated download); values transcribed from the identical copy at CopyReadURL. "
     "Cross-checked value-for-value against " + URL_ELLIOTT + " (2018) and " + URL_HUNZ + " (2022-11)."),
    ("ELLIOTT-LB58", "Elliott Electric product page LB58 (Crouse-Hinds Form 8 LB 1-1/2)", "Elliott Electric Supply", "accessed 2026-09-30",
     URL_LB58, "", "product page", "Spot check only: 9.13 x 2.75 x 4.03 in = a, c, b of Form 8 LB 1-1/2 in CH1F-2022."),
]

PAGE = {4: "p.10", 5: "p.11", 6: "p.12", 7: "p.13"}   # PDF page -> printed page
FORMS = {"F7": ("Crouse-Hinds", "Condulet Form 7", "Feraloy iron alloy"),
         "F8": ("Crouse-Hinds", "Condulet Form 8", "Feraloy iron alloy"),
         "M9": ("Crouse-Hinds", "Condulet Mark 9", "copper-free aluminum")}

# Transcribed dimension tables: "<form> <shape[/shape]> p<PDF page>", then size/a..e rows.
TABLES = """
F7 C p4
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3
  a     5 3/8 | 6 | 7 | 7 7/16 | 8 3/16 | 9 3/16 | 12 | 11 3/4
  b     1 3/8 | 1 5/8 | 1 7/8 | 2 5/16 | 2 9/16 | 3 1/8 | 3 5/8 | 4 3/8
  c     1 3/8 | 1 9/16 | 1 3/4 | 2 3/16 | 2 7/16 | 3 | 4 1/4 | 4 1/4
  d     15/16 | 1 1/8 | 1 3/8 | 1 3/4 | 1 15/16 | 2 7/16 | 3 9/16 | 3 9/16
  e     3 3/16 | 3 13/16 | 4 1/2 | 5 | 5 7/16 | 6 3/8 | 8 3/8 | 8 3/8
F8 C p4
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3
  a     5 11/16 | 6 9/32 | 7 5/16 | 8 1/2 | 10 3/8 | 12 1/4 | 15 5/8 | 15 5/8
  b     1 7/16 | 1 11/16 | 1 15/16 | 2 3/8 | 2 25/32 | 3 9/16 | 4 7/16 | 4 13/16
  c     1 3/8 | 1 3/16 | 1 3/4 | 2 3/16 | 2 3/4 | 3 3/4 | 5 | 5
  d     1 | 1 3/16 | 1 3/8 | 1 3/4 | 2 1/8 | 3 | 4 1/4 | 4 1/4
  e     3 5/16 | 3 15/16 | 4 9/16 | 5 5/16 | 6 1/2 | 8 9/16 | 10 7/8 | 10 7/8
M9 C p4
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  a     4 31/32 | 5 11/32 | 6 19/32 | 7 5/8 | 8 11/32 | 10 5/8 | 15 5/8 | 15 5/8 | 18 3/4 | 18 3/4
  b     1 13/32 | 1 5/8 | 1 7/8 | 2 1/2 | 2 13/16 | 3 7/16 | 4 7/16 | 4 13/16 | 5 11/16 | 5 15/16
  c     1 3/8 | 1 9/16 | 1 3/4 | 2 3/16 | 2 1/2 | 3 7/32 | 5 | 5 | 6 1/4 | 6 1/4
  d     1 1/8 | 1 1/4 | 1 3/8 | 1 27/32 | 2 5/32 | 2 25/32 | 4 1/4 | 4 1/4 | 5 7/16 | 5 7/16
  e     3 9/32 | 3 27/32 | 4 9/16 | 5 3/16 | 5 7/8 | 8 3/32 | 10 7/8 | 10 7/8 | 13 7/16 | 13 7/16
F7 LB p5
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  a     4 9/16 | 5 3/16 | 6 | 6 1/2 | 7 1/8 | 8 1/8 | 10 1/2 | 10 1/2 | 12 11/16 | 12 11/16
  b     2 1/4 | 2 1/2 | 2 7/8 | 3 5/16 | 3 11/16 | 4 1/4 | 5 1/8 | 5 7/8 | 6 9/16 | 7 1/16
  c     1 3/8 | 1 9/16 | 1 3/4 | 2 3/16 | 2 7/16 | 3 | 4 1/4 | 4 1/4 | 5 1/4 | 5 1/4
  d     15/16 | 1 1/8 | 1 3/8 | 1 3/4 | 1 15/16 | 2 7/16 | 3 9/16 | 3 9/16 | 4 1/2 | 4 1/2
  e     3 3/16 | 3 13/16 | 4 1/2 | 5 | 5 7/16 | 6 3/8 | 8 3/8 | 8 3/8 | 10 1/4 | 10 1/4
F8 LB p5
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  a     4 15/16 | 5 9/16 | 6 15/32 | 7 17/32 | 9 1/8 | 11 | 13 15/16 | 13 15/16 | 16 7/8 | 16 7/8
  b     2 7/32 | 2 7/16 | 2 13/16 | 3 11/32 | 4 1/32 | 4 13/16 | 6 1/8 | 6 1/2 | 7 9/16 | 7 13/16
  c     1 3/8 | 1 9/16 | 1 3/4 | 2 3/16 | 2 3/4 | 3 3/4 | 5 | 5 | 6 1/4 | 6 1/4
  d     1 | 1 3/16 | 1 3/8 | 1 3/4 | 2 1/8 | 3 | 4 1/4 | 4 1/4 | 5 7/16 | 5 7/16
  e     3 5/16 | 3 15/16 | 4 9/16 | 5 5/16 | 6 1/2 | 8 9/16 | 10 7/8 | 10 7/8 | 13 7/16 | 13 7/16
M9 LB p5
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  a     4 19/32 | 5 1/4 | 6 3/32 | 7 3/32 | 7 25/32 | 10 3/32 | 13 15/16 | 13 15/16 | 16 7/8 | 16 7/8
  b     2 1/8 | 2 15/32 | 2 13/16 | 3 5/8 | 3 7/8 | 4 19/32 | 6 1/8 | 6 1/2 | 7 9/16 | 7 13/16
  c     1 3/8 | 1 19/32 | 1 3/4 | 2 3/16 | 2 1/2 | 3 7/32 | 5 | 5 | 6 1/4 | 6 1/4
  d     1 1/16 | 1 9/32 | 1 7/16 | 1 7/8 | 2 3/16 | 2 29/32 | 4 1/4 | 4 1/4 | 5 7/16 | 5 7/16
  e     3 9/32 | 3 27/32 | 4 9/16 | 5 3/16 | 5 7/8 | 8 3/32 | 10 7/8 | 10 7/8 | 13 7/16 | 13 7/16
F7 LL/LR p5
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  a     4 9/16 | 5 3/16 | 6 | 6 1/2 | 7 1/8 | 8 1/8 | 10 1/2 | 10 1/2 | 12 11/16 | 12 11/16
  b     1 3/8 | 1 5/8 | 1 7/8 | 2 5/16 | 2 9/16 | 3 1/8 | 3 5/8 | 4 3/8 | 4 7/8 | 5 3/8
  c     2 1/4 | 2 7/16 | 2 3/4 | 3 3/16 | 3 9/16 | 4 1/8 | 5 3/4 | 5 3/4 | 6 15/16 | 6 15/16
  d     15/16 | 1 1/8 | 1 3/8 | 1 3/4 | 1 15/16 | 2 7/16 | 3 9/16 | 3 9/16 | 4 1/2 | 4 1/2
  e     3 3/16 | 3 13/16 | 4 1/2 | 5 | 5 7/16 | 6 3/8 | 8 3/8 | 8 3/8 | 10 1/4 | 10 1/4
F8 LL/LR p5
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3
  a     4 15/16 | 5 9/16 | 6 15/32 | 7 17/32 | 9 1/8 | 11 | 13 15/16 | 13 15/16
  b     1 7/16 | 1 11/16 | 1 15/16 | 2 3/8 | 2 25/32 | 3 9/16 | 4 7/16 | 4 13/16
  c     2 5/32 | 2 5/16 | 2 5/8 | 3 5/32 | 4 | 5 | 6 11/16 | 6 11/16
  d     1 | 1 3/16 | 1 3/8 | 1 3/4 | 2 1/8 | 3 | 4 1/4 | 4 1/4
  e     3 5/16 | 3 15/16 | 4 9/16 | 5 5/16 | 6 1/2 | 8 9/16 | 10 7/8 | 10 7/8
M9 LL/LR p5
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  a     4 19/32 | 5 1/4 | 6 3/32 | 7 3/32 | 7 51/64 | 10 3/32 | 13 15/16 | 13 15/16 | 16 7/8 | 16 7/8
  b     1 13/32 | 1 5/8 | 1 7/8 | 2 1/2 | 2 13/16 | 3 7/16 | 4 7/16 | 4 13/16 | 5 11/16 | 5 15/16
  c     2 1/8 | 2 5/16 | 2 11/16 | 3 1/4 | 3 1/2 | 4 13/64 | 6 11/16 | 6 11/16 | 8 1/8 | 8 1/8
  d     1 1/16 | 1 1/4 | 1 3/8 | 1 7/8 | 2 3/16 | 2 29/32 | 4 1/4 | 4 1/4 | 5 7/16 | 5 7/16
  e     3 9/32 | 3 27/32 | 4 9/16 | 5 3/16 | 5 7/8 | 8 3/32 | 10 7/8 | 10 7/8 | 13 7/16 | 13 7/16
F7 TB p6
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2
  a     5 5/8 | 6 1/4 | 7 1/4 | 7 7/16 | 8 3/16 | 9 3/16
  b     2 5/8 | 2 7/8 | 3 1/4 | 3 5/16 | 5 | 6 1/8
  c     1 9/16 | 1 3/4 | 2 | 2 3/16 | 2 7/16 | 3
  d     15/16 | 1 1/8 | 1 3/8 | 1 3/4 | 1 15/16 | 2 7/16
  e     3 3/16 | 3 13/16 | 4 1/2 | 5 | 5 7/16 | 6 3/8
F7 T p6
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  a     5 5/8 | 6 1/4 | 7 1/4 | 7 7/16 | 8 3/16 | 9 3/16 | 12 | 12 1/16 | 14 5/16 | 14 5/16
  b     1 3/4 | 2 | 2 1/4 | 2 5/16 | 2 9/16 | 3 1/8 | 3 5/8 | 4 3/8 | 4 7/8 | 5 3/8
  c     2 7/16 | 2 5/8 | 3 | 3 3/16 | 3 9/16 | 4 1/8 | 5 3/4 | 5 3/4 | 6 15/16 | 6 15/16
  d     15/16 | 1 1/8 | 1 3/8 | 1 3/4 | 1 15/16 | 2 7/16 | 3 9/16 | 3 9/16 | 4 1/2 | 4 1/2
  e     3 3/16 | 3 13/16 | 4 1/2 | 5 | 5 7/16 | 6 3/8 | 8 3/8 | 8 3/8 | 10 1/4 | 10 1/4
F8 TB p6
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2
  a     5 11/16 | 6 9/32 | 7 5/16 | 8 1/2 | 10 3/8 | 12 1/4
  b     2 17/32 | 2 3/4 | 3 1/8 | 3 11/32 | 4 1/32 | 4 13/16
  c     1 3/8 | 1 9/16 | 1 3/4 | 2 3/16 | 2 3/4 | 3 3/4
  d     1 | 1 3/16 | 1 3/8 | 1 3/4 | 2 1/8 | 3
  e     3 5/16 | 3 15/16 | 4 9/16 | 5 5/16 | 6 1/2 | 8 9/16
F8 T p6
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3
  a     5 11/16 | 6 9/32 | 7 5/16 | 8 1/2 | 10 3/8 | 12 1/4 | 15 5/8 | 15 5/8
  b     1 3/4 | 2 | 2 1/4 | 2 5/8 | 2 25/32 | 3 9/16 | 4 7/16 | 4 13/16
  c     2 5/32 | 2 5/16 | 2 5/8 | 3 5/32 | 4 | 5 | 6 11/16 | 6 11/16
  d     1 | 1 3/16 | 1 3/8 | 1 3/4 | 2 1/8 | 3 | 4 1/4 | 4 1/4
  e     3 5/16 | 3 15/16 | 4 9/16 | 5 5/16 | 6 1/2 | 8 9/16 | 10 7/8 | 10 7/8
M9 TB p6
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2
  a     5 11/16 | 6 9/16 | 7 5/16 | 8 1/2 | 8 11/32 | 10 5/8
  b     2 33/64 | 2 7/8 | 3 1/8 | 3 11/32 | 3 7/8 | 4 19/32
  c     1 3/8 | 1 5/8 | 1 3/4 | 2 3/16 | 2 1/2 | 3 7/32
  d     1 | 1 3/16 | 1 3/8 | 1 3/4 | 2 3/16 | 2 13/16
  e     3 5/16 | 3 15/16 | 4 9/16 | 5 5/16 | 5 7/8 | 8 3/32
M9 T p6
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  a     5 | 5 11/16 | 6 19/32 | 7 5/8 | 8 11/32 | 10 5/8 | 15 5/8 | 15 5/8 | 18 3/4 | 18 3/4
  b     1 13/32 | 1 5/8 | 1 7/8 | 2 1/2 | 2 13/16 | 3 7/16 | 4 7/16 | 4 13/16 | 5 11/16 | 5 15/16
  c     2 1/8 | 2 5/16 | 2 11/16 | 3 1/4 | 3 1/2 | 4 13/32 | 6 11/16 | 6 11/16 | 8 1/8 | 8 1/8
  d     1 1/16 | 1 1/4 | 1 3/8 | 1 7/8 | 2 3/16 | 2 29/32 | 4 1/4 | 4 1/4 | 5 7/16 | 5 7/16
  e     3 9/32 | 3 27/32 | 4 9/16 | 5 3/16 | 5 7/8 | 8 3/32 | 10 7/8 | 10 7/8 | 13 7/16 | 13 7/16
F7 X p7
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2
  a     5 5/8 | 6 1/4 | 7 1/4 | 7 7/16 | 8 3/16 | 9 3/16
  b     3 5/16 | 3 1/2 | 4 | 4 1/8 | 4 5/8 | 5 3/16
  c     1 3/4 | 2 | 2 1/4 | 2 5/16 | 2 9/16 | 3 1/8
  d     15/16 | 1 1/8 | 1 3/8 | 1 3/4 | 1 15/16 | 2 7/16
  e     3 3/16 | 3 13/16 | 4 1/2 | 5 | 5 7/16 | 6 3/8
F8 X p7
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2
  a     5 11/16 | 6 9/32 | 7 5/16 | 8 1/2 | 10 3/8 | 12 1/4
  b     2 29/32 | 3 1/16 | 3 1/2 | 4 1/8 | 5 1/4 | 6 1/4
  c     1 3/4 | 2 | 2 1/4 | 2 5/8 | 2 15/32 | 3 9/16
  d     1 | 1 3/16 | 1 3/8 | 1 3/4 | 2 1/8 | 3
  e     3 5/16 | 3 15/16 | 4 9/16 | 5 5/16 | 6 1/2 | 8 9/16
M9 X p7
  size  1/2 | 3/4 | 1
  a     5 11/16 | 6 9/16 | 7 5/16
  b     2 57/64 | 3 1/4 | 3 1/2
  c     1 3/4 | 2 | 2 1/4
  d     1 | 1 3/16 | 1 3/8
  e     3 5/16 | 3 15/16 | 4 9/16
"""

# Catalog numbers from the shape table (printed p.7). Blank = not listed there.
SIZES10 = ["1/2", "3/4", "1", "1-1/4", "1-1/2", "2", "2-1/2", "3", "3-1/2", "4"]
CATNO = {
    ("F7", "C"):  "C17 C27 C37 C47 C57 C67 C77 C87",
    ("F8", "C"):  "C18 C28 C38 C448 C58 C68 C78 C88",
    ("M9", "C"):  "C19 C29 C39 C49 C59 C69 C789 C889 C989 C1089",
    ("F7", "LB"): "LB17 LB27 LB37 LB47 LB57 LB67 LB777 LB87 LB97 LB107",
    ("F8", "LB"): "LB18 LB28 LB38 LB448 LB58 LB68 LB78 LB888 LB98 LB108",
    ("M9", "LB"): "LB19 LB29 LB39 LB49 LB59 LB69 LB789 LB889 - LB1089",
    ("F7", "LL"): "LL17 LL27 LL37 LL47 LL57 LL67 LL777 LL87 - LL107",
    ("F8", "LL"): "LL18 LL28 LL38 LL448 LL58 LL68 LL78A LL888",
    ("M9", "LL"): "LL19 LL29 LL39 LL49 LL59 LL69 LL789 LL889 LL989 LL1089",
    ("F7", "LR"): "LR17 LR27 LR37 LR47 LR57 LR67 LR777 LR87 - LR107",
    ("F8", "LR"): "LR18 LR28 LR38 LR448 LR58 LR68 LR78A LR888",
    ("M9", "LR"): "LR19 LR29 LR39 LR49 LR59 LR69 LR789 LR889 LR989 LR1089",
    ("F7", "T"):  "T17 T27 T37 T47 T57 T67 T77 T87 T97 T107",
    ("F8", "T"):  "T18 T28 T38 T448 T58 T68 T78 T88",
    ("M9", "T"):  "T19 T29 T39 T49 T59 T69 T789 T889 T989 T1089",
    ("F7", "TB"): "TB17 TB27 TB37 TB47 TB57 TB67",
    ("F8", "TB"): "TB18 TB28 TB38 TB448 TB58 TB68",
    ("M9", "TB"): "TB19 TB29 TB39 TB49 TB59 TB69",
    ("F7", "X"):  "X17 X27 X37 X47 X57 X67",
    ("F8", "X"):  "X18 X28 X38 X448 X58 X68",
    ("M9", "X"):  "X19 X29 X39",
}

# Published values that look inconsistent with neighbours (kept as published).
NOTES = {
    ("F8", "C", "3/4"): "c = 1 3/16 as published (smaller than 1/2 size 1 3/8; Form 8 LB 3/4 has c = 1 9/16) - probable catalog typo",
    ("F7", "C", "3"): "a = 11 3/4 as published (shorter than 2-1/2 size 12)",
    ("F7", "TB", "1-1/2"): "b = 5 as published (large step from 1-1/4 size 3 5/16)",
    ("F7", "TB", "2"): "b = 6 1/8 as published (large step from 1-1/4 size 3 5/16)",
    ("F7", "LL", "3-1/2"): "dimensions published; no catalog number in the p.7 shape table",
    ("F7", "LR", "3-1/2"): "dimensions published; no catalog number in the p.7 shape table",
    ("M9", "LB", "3-1/2"): "dimensions published; no catalog number in the p.7 shape table",
    ("M9", "LL", "1-1/2"): "a = 7 51/64 as published (LB/C same size 7 25/32 / 8 11/32)",
    ("M9", "LR", "1-1/2"): "a = 7 51/64 as published (LB/C same size 7 25/32 / 8 11/32)",
    ("F8", "X", "1-1/2"): "c = 2 15/32 as published (smaller than 1-1/4 size 2 5/8) - probable catalog typo",
}

def frac(s):
    s = s.strip()
    if not s:
        return None
    tot = Fraction(0)
    for part in s.split():
        tot += Fraction(part)
    return tot

def tsdec(t):
    if "-" in t:
        w, f = t.split("-"); return float(int(w) + Fraction(f))
    return float(Fraction(t))

def fmt(v):
    return "" if v is None else ("%.6f" % float(v)).rstrip("0").rstrip(".")

def parse_tables():
    rows, cur = [], None
    for line in TABLES.strip().splitlines():
        if not line.startswith(" "):
            form, shapes, page = line.split()
            cur = {"form": form, "shapes": shapes.split("/"), "page": int(page[1:]), "dims": {}}
            rows.append(cur)
        else:
            k, v = line.strip().split(None, 1)
            cur["dims"][k] = [x.strip() for x in v.split("|")]
    out = []
    for t in rows:
        sizes = t["dims"]["size"]
        for sh in t["shapes"]:
            cats = CATNO.get((t["form"], sh), "").split()
            for i, ts in enumerate(sizes):
                txt = {k: t["dims"][k][i] for k in "abcde"}
                cat = cats[SIZES10.index(ts)] if SIZES10.index(ts) < len(cats) else ""
                if cat == "-":
                    cat = ""
                mfr, series, mat = FORMS[t["form"]]
                pg = PAGE[t["page"]]
                out.append({
                    "Mfr": mfr, "Form": t["form"], "Shape": sh, "TradeSize": ts, "TradeSizeDec": fmt(tsdec(ts)),
                    "CatalogNo": cat,
                    "A_in": fmt(frac(txt["a"])), "B_in": fmt(frac(txt["b"])), "C_in": fmt(frac(txt["c"])),
                    "D_in": fmt(frac(txt["d"])), "E_in": fmt(frac(txt["e"])),
                    "HubOD_in": "", "HubLen_in": "",
                    "SourceId": "CH1F-2022", "SourcePage": pg + " (PDF p.%d)" % t["page"],
                    "Source": "%s %s, %s %s dimension table (copy read: %s)" % (URL_EATON, pg, series, sh if sh not in ("LL", "LR") else "LL & LR", URL_COPY),
                    "Published": "a=%s; b=%s; c=%s; d=%s; e=%s" % (txt["a"], txt["b"], txt["c"], txt["d"], txt["e"])
                                 + ("  (X: a run length, b width across both side hubs, c depth)" if sh == "X" else ""),
                    "Notes": "; ".join(x for x in [series + " (" + mat + ")", NOTES.get((t["form"], sh, ts), ""),
                                                   "" if cat else "no catalog number listed"] if x),
                })
    order = {"F7": 0, "F8": 1, "M9": 2}
    shp = {"C": 0, "LB": 1, "LL": 2, "LR": 3, "T": 4, "TB": 5, "X": 6}
    out.sort(key=lambda r: (order[r["Form"]], shp[r["Shape"]], float(r["TradeSizeDec"])))
    return out

COLS = ["Mfr", "Form", "Shape", "TradeSize", "TradeSizeDec", "CatalogNo", "A_in", "B_in", "C_in", "D_in", "E_in",
        "HubOD_in", "HubLen_in", "SourceId", "SourcePage", "Source", "Published", "Notes"]
NUMCOLS = ["A_in", "B_in", "C_in", "D_in", "E_in", "HubOD_in", "HubLen_in"]

# ---------------------------------------------------------------- phase 2 families
# Other Crouse-Hinds / Myers / Wheatland publications. Table header:
#   <form> <shape> <SourceId> <page>        (page: "_" = space)
# then "size", optional "cat", and the published letters of that family; LETTERS maps
# them onto the CSV columns A_in..E_in / HubOD_in / HubLen_in.
URL_CH06 = "http://www.womackelectric.com/wp-content/uploads/2011/05/Crouse-Hinds-Catalog.pdf"
URL_MOG = "https://images.salsify.com/image/upload/s--i7J4UZBL--/ab833183cc51ee34a08d483e5cf914204e63d03b.pdf"
URL_GUA = "https://www.eaton.com/content/dam/eaton/products/conduit-cable-and-wire-management/crouse-hinds/catalog-pages/crouse-hinds-gua-conduit-outlet-boxes-catalog-page.pdf"
URL_GUA_COPY = "https://cms.intrinsicallysafestore.com/wp-content/uploads/2026/03/crouse-hinds-gua-conduit-outlet-boxes-catalog-page.pdf"
URL_UNY = "https://default.assets-hunzicker-prod.roccommercecloud.com/assets%2F4de6db3f69a0fd8da55d97a16d23c1cc/UNY105_SS_Catalog.pdf"
URL_EYS = "https://buy.wesco.com/static/catalog/products/images/PDF/EYS-conduit-sealing-fittings.pdf"
URL_EYD = "https://assets.usesi.com/product-media/specification-sheets/USESI_541688_specification_sheets.pdf"
URL_HUB = "https://pim.galco.com/Manufacturer/Crouse-Hinds%20Commercial%20Products/TechDocument/Catalog%20Page/meyershubs_cp.pdf"
URL_WH = "https://www.wheatland.com/wp-content/uploads/2017/12/ECN-Brochure.pdf"
URL_PLG = "https://www.elliottelectric.com/Media/PLG1-CRS-2-1-SpecificationSheet.pdf"

SOURCES += [
    ("CH1F-2006", "Crouse-Hinds Condulet conduit outlet bodies, section 1F (LBD, Mogul BC / BLB / BUB / BT, LBY)",
     "Cooper Crouse-Hinds", "2006", URL_CH06, URL_MOG,
     "printed p.13 (LBD, PDF p.11); p.14 (Mogul BC, BLB, PDF p.12); p.15 (Mogul BUB, BT, PDF p.13); p.16 (LBY, PDF p.14)",
     "Mogul values cross-checked against the current Eaton Mogul catalog page at CopyReadURL (identical)."),
    ("CH3F-GUA-2024", "Crouse-Hinds series GUA conduit outlet boxes catalog page (section 3F)", "Eaton", "2024",
     URL_GUA, URL_GUA_COPY, "printed p.55",
     "a body diameter, b overall height, c centre to hub face, d bottom to hub centreline, e hub length (by size); "
     "cover opening diameter from the 2nd digit of the catalog number (4 = 2, 6 = 3, 7 = 3 5/8, 9 = 5)."),
    ("CH5F-UNY-2022", "Crouse-Hinds series UNF / UNL / UNY unions catalog page", "Eaton", "2022", URL_UNY, "",
     "printed p.81-82", "UNY iron: A overall length, B maximum diameter."),
    ("CH6F-EYS-2020", "Crouse-Hinds series EYS / EZS sealing fittings catalog page", "Eaton", "2020", URL_EYS, "",
     "printed p.113-114", "EYS: a overall length, b body diameter, tr turning radius (conduit axis to the pour-boss face; 3-1/2 - 6 with cover removed) -> D_in."),
    ("CLINT-EYD-PROFILE", "EYD side profile sketch (Clint Moore, estimated 2-1/2 in size)", "Moore Design (MED)", "2026-09-30", "", "",
     "-", "Proportion reference only (no dimensions): the drain comes off the lower large opening at 45 deg toward -X (MED3DFittings r10). The r8 geometry scaled from it is superseded."),
    ("EATON-ECD11", "Crouse-Hinds series ECD standard drain ECD11, 1/2 in (product page)", "Eaton", "accessed 2026-09-30", "https://www.eaton.com/us/en-us/skuPage.ECD11.html",
     "https://www.eaton.com/content/dam/eaton/products/conduit-cable-and-wire-management/crouse-hinds/catalog-pages/crouse-hinds-ecd-breather-drain-catalog-page.pdf",
     "product specifications", "ECD11 1/2 in NPT standard drain: 0.88 in length/depth, 1.56 in height, 1.58 in width (published). MED3DFittings r10 EYD drain: hex 0.88 across flats x 0.28, body dia 0.62, 1.06 exposed, on a 1/2 NPT nipple from the special plug, 45 deg down - the split into hex / body is APPROX (the catalog page has no drawing dimensions)."),
    ("CLINT-GUA-DWG", "Clint Moore's GUA reference 3D DWGs (Dropbox\\Development\\3DFittings, GUAL / GUAT / GUAX 4A 4B 6C 7D 9E 9F)", "Moore Design (MED)", "2026-09-30", "", "",
     "-", "3D proportions tuned to Clint's reference DWGs (MED3DFittings r9, measured per solid): hub face at a/2 + HubLen, hub OD per trade size, bottom = hub OD / 2, height per body incl. cover disc and lugs / bar. The catalog rows below stay as published."),
    ("CH6F-EYD", "Crouse-Hinds series EYD / EZD drain seals catalog page (specification sheet copy)", "Eaton", "n.d.", URL_EYD, "",
     "EYD dimension table", "a overall length, b body diameter, tr turning radius (conduit axis to the pour-boss face; 1-1/4 - 4 with cover removed) -> D_in."),
    ("CH-CP269-2006", "Crouse-Hinds Myers hubs (ST) and conduit hubs (MHUB), CP-269 / CP-270", "Cooper Crouse-Hinds", "2006",
     URL_HUB, "", "PDF p.3 (conduit hub MHUB), p.4 (Myers ST)",
     "Conduit hub: a body length, b body diameter, c bushed-nipple flange diameter, d flange thickness, x max. wall. "
     "Myers ST: A overall length, B body diameter, C body height above the enclosure wall, D max. wall, K max. threaded neck."),
    ("WH-ECN-2017", "Wheatland Tube EC&N rigid steel conduit brochure (couplings)", "Wheatland Tube", "2017", URL_WH, "",
     "rigid coupling table", "Coupling OD and UL minimum length."),
    ("APPROX", "Derived (approx) - no dimensions published", "MED", "2026-09-30", URL_PLG, "",
     "-", "PLG (5F) catalog page gives no dimensions. Plug / reducer rows are built from the Wheatland coupling (WH CPL) and "
     "ANSI C80.1 rigid conduit OD; see Notes per row. Spot checks (Eaton SKU pages): PLG1 length 0.84; RE21 1.05 x 1.05 x 0.92; RE31 1.3 x 1.13 x 0.92."),
]
FORMS.update({
    "CH": ("Crouse-Hinds", "Condulet", "Feraloy iron alloy"),
    "MOG": ("Crouse-Hinds", "Mogul Condulet", "Feraloy iron alloy"),
    "XP": ("Crouse-Hinds", "GUA explosionproof outlet box", "Feraloy iron alloy"),
    "MYR": ("Crouse-Hinds", "Myers ST hub", "zinc die cast"),
    "WH": ("Wheatland Tube", "rigid steel coupling", "steel"),
})
# published letter -> CSV column, per shape (default a..e -> A..E)
LETTERS = {
    "LBY": [("a", "A"), ("b", "B")],
    "GUAL": [("a", "A"), ("b", "B"), ("c", "C"), ("d", "D"), ("open", "E"), ("e", "HubLen")],
    "UNY": [("len", "A"), ("dia", "B")],
    "EYS": [("a", "A"), ("b", "B"), ("tr", "D")],
    "EYD": [("a", "A"), ("b", "B"), ("tr", "D")],
    "HUB": [("a", "A"), ("b", "B"), ("c", "C"), ("d", "D"), ("x", "E")],
    "MYRHUB": [("A", "A"), ("B", "B"), ("C", "C"), ("D", "D"), ("K", "E")],
    "CPL": [("len", "A"), ("od", "B")],
}
LETTERS["GUAT"] = LETTERS["GUAX"] = LETTERS["GUAL"]

MOG_C = "2 3/16 | 2 3/16 | 3 | 3 | 4 1/4 | 4 1/4 | 5 1/4 | 5 1/4"
MOG_D = "1 7/8 | 1 7/8 | 2 5/8 | 2 5/8 | 3 13/16 | 3 13/16 | 4 3/4 | 4 3/4"
MOG_E = "6 | 6 | 10 | 10 | 15 | 15 | 20 | 20"
MOG_SZ = "1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4"
GUA_E = "7/8 | 7/8 | 1 | 1 | 1 1/16 | 1 1/16"
TABLES2 = """
CH LBD CH1F-2006 p.13_(PDF_p.11)
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4 | 5 | 6
  cat   LBD1100 | LBD2200 | LBD3300 | LBD4400 | LBD5500 | LBD6600 | LBD7700 | LBD8800 | LBD9900 | LBD10900 | LBD012 | LBD014
  a     5 | 6 1/4 | 6 1/4 | 8 5/8 | 12 7/16 | 12 7/16 | 19 11/16 | 19 11/16 | 20 7/8 | 20 7/8 | 32 7/16 | 41 1/2
  b     2 5/16 | 2 5/8 | 2 15/16 | 4 1/4 | 5 7/16 | 5 7/16 | 9 9/16 | 9 9/16 | 10 7/8 | 10 7/8 | 12 1/2 | 15
  c     1 5/16 | 1 9/16 | 1 13/16 | 3 1/2 | 4 5/8 | 4 5/8 | 5 5/8 | 5 5/8 | 7 3/4 | 7 3/4 | 8 5/8 | 9 3/4
  d     1 | 1 1/4 | 1 1/2 | 1 13/16 | 2 5/8 | 2 5/8 | 3 | 3 | 4 3/4 | 4 3/4 | 5 7/8 | 7
  e     3 11/32 | 4 17/32 | 4 11/32 | 7 3/16 | 10 7/8 | 10 7/8 | 15 3/4 | 15 3/4 | 19 7/8 | 19 7/8 | 30 | 39
MOG BLB CH1F-2006 p.14_(PDF_p.12)
  size  %(MOG_SZ)s
  cat   BLB3 | BLB4 | BLB5 | BLB6 | BLB7 | BLB8 | BLB9 | BLB10
  a     8 19/32 | 8 19/32 | 12 11/16 | 12 11/16 | 16 29/32 | 16 29/32 | 22 1/8 | 22 1/8
  b     2 27/32 | 3 9/32 | 3 5/8 | 4 3/16 | 5 3/32 | 5 27/32 | 6 1/2 | 7
  c     %(MOG_C)s
  d     %(MOG_D)s
  e     %(MOG_E)s
MOG BC CH1F-2006 p.14_(PDF_p.12)
  size  %(MOG_SZ)s
  cat   BC3 | BC4 | BC5 | BC6 | BC7 | BC8 | BC9 | BC10
  a     9 9/16 | 9 9/16 | 13 3/4 | 13 3/4 | 18 3/8 | 18 3/8 | 23 3/4 | 23 3/4
  b     1 7/8 | 2 5/16 | 2 9/16 | 3 1/8 | 3 5/8 | 4 3/8 | 4 7/8 | 5 3/8
  c     %(MOG_C)s
  d     %(MOG_D)s
  e     %(MOG_E)s
MOG BUB CH1F-2006 p.15_(PDF_p.13)
  size  %(MOG_SZ)s
  cat   BUB3 | BUB4 | BUB5 | BUB6 | BUB7 | BUB8 | BUB9 | BUB10
  a     9 3/16 | 9 5/16 | 13 1/2 | 13 1/2 | 17 3/4 | 17 7/8 | 23 3/8 | 23 1/4
  b     2 11/16 | 3 3/16 | 3 1/2 | 4 1/8 | 4 13/16 | 5 5/8 | 6 3/8 | 6 13/16
  c     %(MOG_C)s
  d     %(MOG_D)s
  e     %(MOG_E)s
MOG BT CH1F-2006 p.15_(PDF_p.13)
  size  %(MOG_SZ)s
  cat   BT3 | BT4 | BT5 | BT6 | BT7 | BT8 | BT9 | BT10
  a     9 9/16 | 9 9/16 | 13 3/4 | 13 3/4 | 18 3/8 | 18 3/8 | 23 3/4 | 23 3/4
  b     1 7/8 | 2 5/16 | 2 9/16 | 3 1/8 | 3 5/8 | 4 3/8 | 4 7/8 | 5 3/8
  c     3 5/32 | 3 5/32 | 4 1/16 | 4 1/16 | 5 19/32 | 5 23/32 | 6 7/8 | 6 7/8
  d     %(MOG_D)s
  e     %(MOG_E)s
CH LBY CH1F-2006 p.16_(PDF_p.14)
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2
  cat   LBY15 | LBY25 | LBY35 | LBY45 | LBY55
  a     2 13/16 | 3 3/16 | 3 1/4 | 3 25/32 | 4 1/4
  b     2 | 2 1/4 | 2 1/2 | 2 15/16 | 3 3/8
XP GUAL CH3F-GUA-2024 p.55
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2
  cat   GUAL14D | GUAL24D | GUAL36C | GUAL47D | GUAL59C | GUAL69C
  a     2 1/2 | 2 1/2 | 3 1/2 | 4 1/4 | 5 3/4 | 5 3/4
  b     2 1/4 | 2 1/2 | 2 5/16 | 2 11/16 | 4 1/32 | 4 1/32
  c     2 3/16 | 2 7/16 | 2 3/8 | 2 5/8 | 4 3/16 | 4 3/16
  d     5/8 | 3/4 | 7/8 | 1 3/32 | 1 7/32 | 1 1/2
  open  2 | 2 | 3 | 3 5/8 | 5 | 5
  e     %(GUA_E)s
XP GUAT CH3F-GUA-2024 p.55
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2
  cat   GUAT14D | GUAT24D | GUAT36C | GUAT47D | GUAT59C | GUAT69C
  a     2 1/2 | 2 1/2 | 3 1/2 | 4 1/4 | 5 3/4 | 5 3/4
  b     2 1/4 | 2 | 2 5/16 | 2 11/16 | 4 1/32 | 4 1/32
  c     2 3/16 | 2 | 2 3/8 | 2 5/8 | 4 3/16 | 4 3/16
  d     5/8 | 3/4 | 7/8 | 1 3/32 | 1 7/32 | 1 1/2
  open  2 | 2 | 3 | 3 5/8 | 5 | 5
  e     %(GUA_E)s
XP GUAX CH3F-GUA-2024 p.55
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2
  cat   GUAX14 | GUAX24 | GUAX36C | GUAX47D | GUAX59C | GUAX69C
  a     2 1/2 | 2 1/2 | 3 1/2 | 4 1/4 | 5 3/4 | 5 3/4
  b     1 13/16 | 2 | 2 5/16 | 2 11/16 | 4 1/32 | 4 1/32
  c     1 3/4 | 2 | 2 3/8 | 2 5/8 | 4 3/16 | 4 3/16
  d     5/8 | 3/4 | 7/8 | 1 3/32 | 1 7/32 | 1 1/2
  open  2 | 2 | 3 | 3 5/8 | 5 | 5
  e     %(GUA_E)s
CH UNY CH5F-UNY-2022 p.82
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  cat   UNY105 | UNY205 | UNY305 | UNY405 | UNY505 | UNY605 | UNY705 | UNY805 | UNY905 | UNY1005
  len   2 5/8 | 2 11/16 | 3 | 3 23/32 | 4 7/32 | 4 7/32 | 5 13/32 | 5 13/16 | 6 9/16 | 6 5/8
  dia   1 9/16 | 1 7/8 | 2 3/16 | 2 15/16 | 3 1/16 | 3 7/8 | 4 5/32 | 5 1/16 | 5 11/16 | 6 3/16
CH EYS CH6F-EYS-2020 p.114
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4 | 5 | 6
  cat   EYS1 | EYS2 | EYS3 | EYS4 | EYS5 | EYS6 | EYS7 | EYS8 | EYS9 | EYS10 | EYS012 | EYS014
  a     3 9/32 | 3 12/16 | 4 5/16 | 5 1/16 | 5 1/2 | 6 1/4 | 7 1/2 | 8 1/2 | 9 3/16 | 9 3/4 | 11 1/16 | 12 1/8
  b     1 1/4 | 1 1/2 | 1 3/4 | 2 3/16 | 2 7/16 | 3 | 3 1/2 | 4 1/4 | 4 3/4 | 5 1/4 | 6 1/2 | 7 5/8
  tr    1 5/8 | 1 29/32 | 2 3/8 | 1 23/32 | 2 1/16 | 2 5/16 | 2 11/16 | 3 5/16 | 3 7/16 | 3 11/16 | 4 19/32 | 5 11/32
CH EYD CH6F-EYD table
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  cat   EYD1 | EYD2 | EYD3 | EYD4 | EYD5 | EYD6 | EYD7 | EYD8 | EYD9 | EYD10
  a     3 9/32 | 3 11/16 | 4 5/16 | 5 1/16 | 5 1/2 | 6 1/4 | 7 1/2 | 8 1/2 | 9 3/16 | 9 3/4
  b     1 1/4 | 1 1/2 | 2 3/16 | 2 3/16 | 2 7/16 | 3 | 3 1/2 | 4 1/4 | 4 3/4 | 5 1/4
  tr    1 5/8 | 1 29/32 | 2 3/8 | 1 27/32 | 2 1/16 | 2 5/16 | 2 11/16 | 3 5/16 | 3 7/16 | 3 1/2
CH HUB CH-CP269-2006 PDF_p.3
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4
  cat   MHUB1 | MHUB2 | MHUB3 | MHUB4 | MHUB5 | MHUB6 | MHUB7 | MHUB8 | MHUB9 | MHUB10
  a     1 | 1 1/8 | 1 3/8 | 1 1/2 | 1 5/8 | 1 11/16 | 2 3/16 | 2 7/16 | 2 7/16 | 2 9/16
  b     1 1/4 | 1 9/16 | 1 7/8 | 2 5/16 | 2 1/2 | 3 | 3 5/8 | 4 1/4 | 4 3/4 | 5 1/4
  c     1 | 1 3/8 | 1 5/8 | 2 | 2 3/8 | 2 13/16 | 3 7/16 | 4 1/16 | 4 11/16 | 5 1/16
  d     1/8 | 5/32 | 3/16 | 1/4 | 1/4 | 1/4 | 1/4 | 1/4 | 5/16 | 5/16
  x     9/64 | 1/4 | 9/32 | 7/16 | 7/16 | 7/16 | 7/16 | 7/16 | 3/4 | 1 1/8
MYR HUB CH-CP269-2006 PDF_p.4
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4 | 5 | 6
  cat   ST-1 | ST-2 | ST-3 | ST-4 | ST-5 | ST-6 | ST-7 | ST-8 | ST-9 | ST-10 | ST-11 | ST-12
  A     1 11/32 | 1 15/32 | 1 21/32 | 1 11/16 | 1 11/16 | 1 3/4 | 2 7/32 | 2 5/16 | 2 3/8 | 2 7/16 | 2 15/16 | 3
  B     1 7/16 | 1 23/32 | 2 | 2 3/8 | 2 3/4 | 3 1/4 | 3 3/4 | 4 3/8 | 5 | 5 1/2 | 6 7/8 | 7 11/16
  C     13/16 | 29/32 | 1 1/32 | 1 1/32 | 1 1/32 | 1 3/32 | 1 9/32 | 1 3/8 | 1 7/16 | 1 1/2 | 2 | 2
  D     3/16 | 3/16 | 1/4 | 1/4 | 1/4 | 1/4 | 1/4 | 1/4 | 1/4 | 1/4 | 1/4 | 5/16
  K     7/8 | 1 1/8 | 1 3/8 | 1 3/4 | 2 | 2 1/2 | 3 | 3 5/8 | 4 1/8 | 4 5/8 | 5 11/16 | 6 3/4
WH CPL WH-ECN-2017 coupling_table
  size  1/2 | 3/4 | 1 | 1-1/4 | 1-1/2 | 2 | 2-1/2 | 3 | 3-1/2 | 4 | 5 | 6
  od    1.010 | 1.250 | 1.525 | 1.869 | 2.155 | 2.650 | 3.250 | 3.870 | 4.500 | 4.875 | 6.000 | 7.200
  len   1 5/8 | 1 41/64 | 1 31/32 | 2 1/32 | 2 1/16 | 2 1/8 | 3 3/16 | 3 5/16 | 3 13/32 | 3 33/64 | 3 61/64 | 4 1/4
""" % dict(MOG_C=MOG_C, MOG_D=MOG_D, MOG_E=MOG_E, MOG_SZ=MOG_SZ, GUA_E=GUA_E)

SRC_URL = {"CH1F-2006": (URL_CH06, URL_MOG), "CH3F-GUA-2024": (URL_GUA, URL_GUA_COPY), "CH5F-UNY-2022": (URL_UNY, ""),
           "CH6F-EYS-2020": (URL_EYS, ""), "CH6F-EYD": (URL_EYD, ""), "CH-CP269-2006": (URL_HUB, ""), "WH-ECN-2017": (URL_WH, "")}
NOTES2 = {
    ("CH", "LBD", "1/2"): "c = outside width without bosses (catalog note, 1/2 - 3/4)",
    ("CH", "LBD", "3/4"): "c = outside width without bosses (catalog note, 1/2 - 3/4)",
    ("CH", "LBD", "1"): "e = 4 11/32 as published (smaller than 3/4 size 4 17/32)",
    ("CH", "EYS", "3/4"): "a printed as 3 12/16 (= 3 3/4)",
    ("CH", "EYS", "5"): "EYS vertical/horizontal-position table (5 and 6 in)",
    ("CH", "EYS", "6"): "EYS vertical/horizontal-position table (5 and 6 in)",
    ("CH", "EYD", "1"): "b = 2 3/16 as published (same as 1-1/4 size; EYS 1 in is 1 3/4)",
    ("XP", "GUAX", "1/2"): "catalog GUAX14 (the only 1/2 in GUAX listed)",
}
# ANSI C80.1 rigid steel conduit OD (inches) - the plug / reducer head sizes below
C80_OD = {"1/2": 0.840, "3/4": 1.050, "1": 1.315, "1-1/4": 1.660, "1-1/2": 1.900, "2": 2.375, "2-1/2": 2.875,
          "3": 3.500, "3-1/2": 4.000, "4": 4.500, "5": 5.563, "6": 6.625}

def r16(v):
    return Fraction(round(v * 16), 16)

def parse_tables2():
    tabs, cur = [], None
    for line in TABLES2.strip().splitlines():
        if not line.startswith(" "):
            form, shape, src, page = line.split()
            cur = {"form": form, "shape": shape, "src": src, "page": page.replace("_", " "), "dims": {}}
            tabs.append(cur)
        else:
            k, v = line.strip().split(None, 1)
            cur["dims"][k] = [x.strip() for x in v.split("|")]
    out, cpl = [], {}
    for t in tabs:
        sh, form = t["shape"], t["form"]
        lmap = LETTERS.get("MYRHUB" if (form, sh) == ("MYR", "HUB") else sh, [(x, x.upper()) for x in "abcde"])
        mfr, series, mat = FORMS[form]
        url, copy = SRC_URL[t["src"]]
        for i, ts in enumerate(t["dims"]["size"]):
            txt = {k: t["dims"][k][i] for k, _ in lmap}
            r = {c: "" for c in COLS}
            r.update({"Mfr": mfr, "Form": form, "Shape": sh, "TradeSize": ts, "TradeSizeDec": fmt(tsdec(ts)),
                      "CatalogNo": t["dims"].get("cat", [""] * 99)[i], "SourceId": t["src"], "SourcePage": t["page"],
                      "Source": "%s %s, %s %s dimension table%s" % (url, t["page"], series, sh, (" (copy read: %s)" % copy) if copy else ""),
                      "Published": "; ".join("%s=%s" % (k, txt[k]) for k, _ in lmap)})
            for k, col in lmap:
                r[col + "_in"] = fmt(frac(txt[k]))
            r["Notes"] = "; ".join(x for x in [series + " (" + mat + ")", NOTES2.get((form, sh, ts), ""),
                                               "3D: EYS body + lower large opening with an ECD11 drain 45 deg down (EATON-ECD11; body shape approx)" if sh == "EYD" else "",
                                               "3D proportions tuned to Clint's reference DWGs (CLINT-GUA-DWG)" if sh in ("GUAL", "GUAT", "GUAX") else ""] if x)
            out.append(r)
            if sh == "CPL":
                cpl[ts] = (frac(txt["len"]), frac(txt["od"]))
    # approx rows (no published dimensions): plugged coupling (recessed / square head) and
    # reducer, from the Wheatland coupling + C80.1 conduit OD
    for sh, cat in (("PLGR", "PLG%d"), ("PLGS", "PLG%dSQ"), ("RE", "")):
        for i, ts in enumerate(t for t in cpl if t != "1/2" or sh != "RE"):
            ln, od = cpl[ts]
            cod = C80_OD[ts]
            r = {c: "" for c in COLS}
            r.update({"Mfr": "Crouse-Hinds", "Form": "CH", "Shape": sh, "TradeSize": ts, "TradeSizeDec": fmt(tsdec(ts)),
                      "CatalogNo": "", "SourceId": "APPROX", "SourcePage": "-", "A_in": fmt(ln), "B_in": fmt(od)})
            if sh == "PLGR":
                r["C_in"] = "0.125"
                r["Published"] = "approx: A = coupling length, B = coupling OD (WH-ECN-2017); C = plug face recess 1/8"
                r["Notes"] = "APPROX plugged coupling, recessed-head plug (PLG): coupling from WH-ECN-2017, recess assumed"
            elif sh == "PLGS":
                r["C_in"] = fmt(r16(0.75 * cod)); r["D_in"] = fmt(r16(max(0.25, 0.35 * cod)))
                r["Published"] = "approx: A = coupling length, B = coupling OD (WH-ECN-2017); C = square head 0.75 x conduit OD; D = head height 0.35 x conduit OD"
                r["Notes"] = "APPROX plugged coupling, square-head plug (PLG): head proportions assumed from C80.1 OD %.3f" % cod
            else:
                r["C_in"] = fmt(r16(max(0.125, 0.2 * cod))); r["D_in"] = fmt(cod)
                r["Published"] = "approx: A = coupling length, B = coupling OD of the large size (WH-ECN-2017); C = reducer head thickness max(1/8, 0.2 x OD); D = head dia = C80.1 conduit OD"
                r["Notes"] = ("APPROX reducer RE (large size %s in): recessed in the large-size hub / coupling, head sticks out C; "
                              "spot check RE21 head dia 1.05 = 3/4 in conduit OD" % ts)
            r["Source"] = "APPROX (see conduit_body_sources.csv); coupling " + URL_WH + "; plug page without dimensions " + URL_PLG
            out.append(r)
    return out

def write_csvs(rows):
    os.makedirs(SEED, exist_ok=True)
    with open(os.path.join(SEED, "conduit_body_dims.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, COLS, lineterminator="\r\n"); w.writeheader(); w.writerows(rows)
    with open(os.path.join(SEED, "conduit_body_sources.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\r\n")
        w.writerow(["SourceId", "Title", "Publisher", "Date", "URL", "CopyReadURL", "Pages", "Notes"])
        w.writerows(SOURCES)

DDL = ("CREATE TABLE IF NOT EXISTS MEDConduitBody ("
       "Mfr TEXT, Form TEXT NOT NULL, Shape TEXT NOT NULL, TradeSize TEXT NOT NULL, TradeSizeDec REAL, "
       "CatalogNo TEXT, A_in REAL, B_in REAL, C_in REAL, D_in REAL, E_in REAL, HubOD_in REAL, HubLen_in REAL, "
       "Source TEXT, PRIMARY KEY (Form, Shape, TradeSize))")

def apply_db(rows):
    if not os.path.exists(DB):
        print("no", DB, "- skipped"); return
    con = sqlite3.connect(DB)
    con.execute(DDL)
    n0 = con.execute("SELECT COUNT(*) FROM MEDConduitBody").fetchone()[0]
    num = lambda v: float(v) if v not in ("", None) else None
    for r in rows:
        con.execute("INSERT OR IGNORE INTO MEDConduitBody (Mfr, Form, Shape, TradeSize, TradeSizeDec, CatalogNo, "
                    "A_in, B_in, C_in, D_in, E_in, HubOD_in, HubLen_in, Source) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                    (r["Mfr"], r["Form"], r["Shape"], r["TradeSize"], num(r["TradeSizeDec"]), r["CatalogNo"] or None,
                     *[num(r[c]) for c in NUMCOLS], r["Source"][:400]))
        for c in NUMCOLS:
            if num(r[c]) is not None:
                con.execute("UPDATE MEDConduitBody SET %s=? WHERE Form=? AND Shape=? AND TradeSize=? AND %s IS NULL" % (c, c),
                            (num(r[c]), r["Form"], r["Shape"], r["TradeSize"]))
    con.commit()
    n1 = con.execute("SELECT COUNT(*) FROM MEDConduitBody").fetchone()[0]
    con.close()
    print("MED.db MEDConduitBody rows: %d -> %d" % (n0, n1))

if __name__ == "__main__":
    rows = parse_tables() + parse_tables2()
    write_csvs(rows)
    print("conduit_body_dims.csv rows:", len(rows))
    if "--no-db" not in sys.argv:
        apply_db(rows)

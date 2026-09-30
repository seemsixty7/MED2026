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

PAGE = {4: "p.10", 5: "p.11", 6: "p.12"}   # PDF page -> printed page
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
                    "Published": "a=%s; b=%s; c=%s; d=%s; e=%s" % (txt["a"], txt["b"], txt["c"], txt["d"], txt["e"]),
                    "Notes": "; ".join(x for x in [series + " (" + mat + ")", NOTES.get((t["form"], sh, ts), ""),
                                                   "" if cat else "no catalog number listed"] if x),
                })
    order = {"F7": 0, "F8": 1, "M9": 2}
    shp = {"C": 0, "LB": 1, "LL": 2, "LR": 3, "T": 4, "TB": 5}
    out.sort(key=lambda r: (order[r["Form"]], shp[r["Shape"]], float(r["TradeSizeDec"])))
    return out

COLS = ["Mfr", "Form", "Shape", "TradeSize", "TradeSizeDec", "CatalogNo", "A_in", "B_in", "C_in", "D_in", "E_in",
        "HubOD_in", "HubLen_in", "SourceId", "SourcePage", "Source", "Published", "Notes"]
NUMCOLS = ["A_in", "B_in", "C_in", "D_in", "E_in", "HubOD_in", "HubLen_in"]

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
    rows = parse_tables()
    write_csvs(rows)
    print("conduit_body_dims.csv rows:", len(rows))
    if "--no-db" not in sys.argv:
        apply_db(rows)

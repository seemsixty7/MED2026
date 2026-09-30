#!/usr/bin/env python3
"""Build Data/seed/fitting_body_keys.csv and apply it to the shipped seed Data/MED.db.

Conduit-body key for MEDMAKE3D (MED3DFittings.lsp): MEDType.ITEMKEY2 on FITTING rows,
"<material>|<form>|<shape>", e.g. RGD|F7|LB. Only the rows the 3D bodies have data for
are keyed here: codes 11-16 (T, TB), 30-38 (LB, LL, LR), 50-52 (C) - Form 7, Form 8,
Mark 9. The LISP also parses the description when ITEMKEY2 is blank, so these keys are
a convenience / override, not a requirement.

    python tools/build_fitting_body_keys.py            (from repo root)
    python tools/build_fitting_body_keys.py --no-db    (CSV only)

Same rule as MedODSeed.cs at runtime: ITEMKEY2 is only written where it is blank and
ITEMDESC still matches the seed row (renumbered / edited codes are left alone).
"""
import csv, os, sqlite3, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED = os.path.join(ROOT, "Data", "seed", "fitting_body_keys.csv")
DB = os.path.join(ROOT, "Data", "MED.db")

FORMS = ["F7", "F8", "M9"]
ROWS = []  # (code, desc, key)
for base, shape in ((11, "T"), (14, "TB"), (30, "LB"), (33, "LL"), (36, "LR"), (50, "C")):
    word = {"F7": "Form 7", "F8": "Form 8", "M9": "Mark 9"}
    for i, form in enumerate(FORMS):
        ROWS.append((base + i, '%s "%s" condulet fitting' % (word[form], shape), "RGD|%s|%s" % (form, shape)))


def write_csv():
    with open(SEED, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\r\n")
        w.writerow(["ITEMCODE", "ITEMDESC", "BodyKey"])
        for r in ROWS:
            w.writerow(r)
    print("wrote %s (%d rows)" % (os.path.relpath(SEED, ROOT), len(ROWS)))


def apply_db():
    con = sqlite3.connect(DB)
    n = 0
    for code, desc, key in ROWS:
        cur = con.execute(
            "UPDATE MEDType SET ITEMKEY2 = ? WHERE ITEMTYPE = 'FITTING' AND ITEMCODE = ? "
            "AND (ITEMKEY2 IS NULL OR TRIM(ITEMKEY2) = '') AND UPPER(TRIM(ITEMDESC)) = ?",
            (key, code, desc.strip().upper()))
        n += cur.rowcount
    con.commit()
    miss = [c for c, d, k in ROWS if con.execute(
        "SELECT ITEMKEY2 FROM MEDType WHERE ITEMTYPE='FITTING' AND ITEMCODE=?", (c,)).fetchone() in (None, (None,), ("",))]
    con.close()
    print("MED.db: %d ITEMKEY2 value(s) filled%s" % (n, (", not keyed (desc differs): %s" % miss) if miss else ""))


if __name__ == "__main__":
    write_csv()
    if "--no-db" not in sys.argv:
        apply_db()

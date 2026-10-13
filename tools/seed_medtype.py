"""Idempotent DBSEED for a SQLite MED.db: insert missing MEDType rows from Data/seed/ductbank_medtype.csv
and fill a blank ITEMDESC (same logic as c:DBSEED in MEDDuctbank.lsp). Usage: seed_medtype.py [MED.db] [csv]"""
import csv, os, sqlite3, sys
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
db = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "Data", "MED.db")
src = sys.argv[2] if len(sys.argv) > 2 else os.path.join(REPO, "Data", "seed", "ductbank_medtype.csv")
c = sqlite3.connect(db); add = fill = 0
for r in csv.DictReader(open(src, newline="", encoding="utf-8-sig")):
    t, code, d = r["ITEMTYPE"].strip(), int(r["ITEMCODE"]), r["ITEMDESC"].strip()
    cur = c.execute("INSERT INTO MEDType (ITEMTYPE, ITEMCODE, ITEMDESC) SELECT ?,?,? WHERE NOT EXISTS "
                    "(SELECT 1 FROM MEDType WHERE ITEMTYPE=? AND ITEMCODE=?)", (t, code, d, t, code)); add += cur.rowcount
    cur = c.execute("UPDATE MEDType SET ITEMDESC=? WHERE ITEMTYPE=? AND ITEMCODE=? AND TRIM(COALESCE(ITEMDESC,''))=''",
                    (d, t, code)); fill += cur.rowcount
c.commit(); print("added %d, filled %d" % (add, fill))

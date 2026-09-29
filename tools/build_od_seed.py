#!/usr/bin/env python3
"""Build Data/seed/conduit_od.csv + Data/seed/cable_od_sources.csv and apply them to
the shipped seed Data/MED.db (MEDConduitOD table + MEDType.USER3 for CABLE rows).

Every OD below is transcribed from the cited manufacturer / standard data sheet.
Unsourced sizes/cables are left blank (never estimated). Re-run after editing tables:

    python tools/build_od_seed.py            (from repo root)

Seed-DB update is idempotent and only fills blanks (same rule as MedODSeed.cs at runtime).
"""
import csv, os, re, sqlite3, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED = os.path.join(ROOT, "Data", "seed")
DB = os.path.join(ROOT, "Data", "MED.db")

# ---------------------------------------------------------------- conduit
SRC_RMC = "https://www.wheatland.com/wp-content/uploads/2018/11/Rigid-Metal-Conduit-Submittal-Sheet.pdf (Wheatland RMC, ANSI C80.1 nominal OD)"
SRC_PVCRMC = "https://assets.usesi.com/product-media/brochures/USESI_479720_brochure.pdf (Robroy Plasti-Bond PRHCONDUIT buyers guide, 'Outside Diameter With Coating', 40 mil PVC)"
SRC_PVC40 = "https://pvcelectrical.cantexinc.com/CANTEX_Sell_Sheets/CANTEX-Schedule-40-and-80-Conduit-Sell-Sheet.pdf (Cantex Sch 40, UL 651 / NEMA TC-2 OD)"
SRC_EMT = "https://images.blazerelectricsupply.com/specsheets/EMT3.pdf (Allied Tube EMT spec sheet, ANSI C80.3 OD)"
SRC_ENT = "https://assets.usesi.com/product-media/catalogs/USESI_12171_catalog.pdf (Carlon ENT Application Handbook, Flex-Plus Blue ENT O.D. table)"
SRC_IMC = "https://www.cpesupply.com/ASSETS/DOCUMENTS/ITEMS/EN/Allied_Tube_Conduit_2IMC_Specification_Sheet.pdf (Allied Tube IMC, ANSI C80.6 OD)"
SRC_LFMC = "http://flexiblewiringconduits.anacondasealtite.com/Asset/AEI%20CAT%202013_UA.pdf (Anaconda Sealtite Type UA LFMC; OD range min-max, MAX stored)"

TS = ["3/8", "1/2", "3/4", "1", "1-1/4", "1-1/2", "2", "2-1/2", "3", "3-1/2", "4", "5", "6"]
def tsdec(t):
    if "-" in t:
        w, f = t.split("-"); a, b = f.split("/"); return int(w) + int(a) / int(b)
    if "/" in t:
        a, b = t.split("/"); return int(a) / int(b)
    return float(t)

CONDUIT = [
    # code, desc (MEDType CONDUIT ITEMDESC), {trade size: OD}, source
    (1, "Rigid Steel Conduit", dict(zip(TS[1:], [0.840, 1.050, 1.315, 1.660, 1.900, 2.375, 2.875, 3.500, 4.000, 4.500, 5.563, 6.625])), SRC_RMC),
    (2, "Plastic Coated Rigid Steel Conduit", dict(zip(TS[1:], [0.920, 1.130, 1.395, 1.740, 1.980, 2.455, 2.955, 3.580, 4.080, 4.580, 5.643, 6.705])), SRC_PVCRMC),
    (3, "Rigid Non-Metalic Conduit", dict(zip(TS[1:], [0.840, 1.050, 1.315, 1.660, 1.900, 2.375, 2.875, 3.500, 4.000, 4.500, 5.563, 6.625])), SRC_PVC40),
    (4, "Electrical Metalic Tubing", dict(zip(TS[1:11], [0.706, 0.922, 1.163, 1.510, 1.740, 2.197, 2.875, 3.500, 4.000, 4.500])), SRC_EMT),
    (5, "Electrical Non-Metalic Tubing", dict(zip(TS[1:7], [0.840, 1.050, 1.315, 1.660, 1.900, 2.375])), SRC_ENT),
    (6, "Intermediate Metal Conduit", dict(zip(TS[1:11], [0.815, 1.029, 1.290, 1.638, 1.883, 2.360, 2.857, 3.476, 3.971, 4.466])), SRC_IMC),
    (7, "Plastic Coated Flexable Metalic Conduit", dict(zip(TS[0:11], [0.710, 0.840, 1.050, 1.315, 1.660, 1.900, 2.375, 2.875, 3.500, 4.000, 4.500])), SRC_LFMC),
]

# ---------------------------------------------------------------- cable
SRC_THHN = "https://default.assets-stateelectric-prod.roccommercecloud.com/assets%2Fd2fb6576aa3bcdf239f5a6b6eb080e1f/southwire_55617107_specification_sheet.pdf (Southwire SIMpull THHN/THWN-2, stranded nominal O.D.)"
SRC_THW = "https://encorewire-prod.imgix.net/media/products/product-sheets/copper/commercial/EncoreWire-CU-THW2.pdf (Encore Wire THW-2 copper OD)"
SRC_XHHW = "https://encorewire-prod.imgix.net/media/products/product-sheets/copper/commercial/EncoreWire-CU-XHHW-2.pdf (Encore Wire XHHW-2 copper OD)"
SRC_BARE = "https://encorewire-prod.imgix.net/media/products/product-sheets/copper/commercial/EncoreWire-CU-Bare-2.pdf (Encore Wire soft-drawn bare copper, stranded OD)"
SRC_BARE10 = "https://encorewire-prod.imgix.net/media/products/product-sheets/copper/commercial/EncoreWire-CU-Bare-2.pdf (Encore Wire soft-drawn bare copper; #10 listed SOLID only)"
SRC_TC = "https://cabletechsupport.southwire.com/cablespec/download_spec/?country=US&spec=45051 (Southwire SPEC 45051 Type TC-ER control cable THHN/THWN (TFFN for 16 AWG), approx OD)"
SRC_NM = "https://cabletechsupport.southwire.com/en/cablespec/download_spec/?country=us&spec=10028 (Southwire Romex SIMpull NM-B w/ground; flat cables: MAJOR dimension stored)"
SRC_SER = "https://cabletechsupport.southwire.com/en/cablespec/download_cable/?cable=55748&country=US (Southwire SER AL stock 131078 4/0-4/0-4/0-2/0, approx OD)"
SRC_POS = "https://cabletechsupport.southwire.com/en/cablespec/download_spec/?country=US&spec=43602 (Southwire SPEC 43602 600V Type TC instrumentation pairs, overall shield, approx OD)"
SRC_TOS = "https://cabletechsupport.southwire.com/en/cablespec/download_spec/?country=US&spec=43606 (Southwire SPEC 43606 600V Type TC-ER instrumentation triads, overall shield, approx OD)"
SRC_PLTC = "https://cabletechsupport.southwire.com/en/cablespec/download_spec/?country=US&spec=43301 (Southwire SPEC 43301 300V Type PLTC/ITC pairs, overall shield, approx OD)"

SIZES = ["14", "12", "10", "8", "6", "4", "3", "2", "1", "1/0", "2/0", "3/0", "4/0", "250", "300", "350", "400", "500", "600", "750", "1000"]
THHN = dict(zip(SIZES, [0.109, 0.128, 0.161, 0.213, 0.249, 0.318, 0.346, 0.378, 0.435, 0.474, 0.518, 0.568, 0.624, 0.694, 0.747, 0.797, 0.842, 0.926, 1.024, 1.126, 1.275]))
THW = dict(zip(SIZES, [0.131, 0.150, 0.173, 0.236, 0.304, 0.352, 0.380, 0.412, 0.481, 0.520, 0.564, 0.614, 0.670, 0.732, 0.784, 0.831, 0.875, 0.956, 1.113, 1.218, 1.372]))
XHHW = dict(zip(SIZES, [0.131, 0.150, 0.173, 0.236, 0.274, 0.322, 0.350, 0.382, 0.431, 0.470, 0.514, 0.564, 0.620, 0.672, 0.724, 0.771, 0.815, 0.896, 1.053, 1.158, 1.312]))
BARE = dict(zip(SIZES[3:], [0.1460, 0.1840, 0.2320, 0.2600, 0.2920, 0.3280, 0.3600, 0.4040, 0.4540, 0.5100, 0.5420, 0.5940, 0.6410, 0.6850, 0.7660, 0.8930, 0.9980, 1.1520]))
TC = {  # (awg, count) -> OD, Southwire 45051 (first/stock row where duplicated)
    "18": {2: .268, 3: .280, 4: .304, 5: .336, 6: .358, 8: .385, 10: .438, 12: .454, 16: .508, 19: .560, 24: .654},
    "16": {2: .292, 3: .308, 4: .333, 5: .362, 6: .393, 7: .393, 8: .410, 9: .454, 10: .476, 12: .510, 15: .595, 19: .625, 20: .632, 25: .700, 30: .767, 37: .867},
    "14": {2: .305, 3: .322, 4: .351, 5: .380, 6: .416, 8: .456, 9: .490, 10: .556, 12: .573, 15: .632, 19: .664, 20: .697, 25: .802, 30: .875, 37: .949},
    "12": {2: .348, 3: .369, 4: .401, 5: .438, 6: .481, 7: .477, 8: .546, 9: .580, 10: .634, 12: .657, 15: .734, 16: .738, 19: .772, 20: .802, 25: .943, 30: .982, 37: 1.064},
    "10": {2: .420, 3: .446, 4: .505, 5: .565, 6: .611, 7: .615, 8: .662, 9: .715, 10: .774, 12: .806, 19: .993, 20: 1.028, 25: 1.140, 30: 1.207, 37: 1.303},
}
NM = {("14", 2): 0.372, ("12", 2): 0.422, ("10", 2): 0.505, ("8", 2): 0.628, ("6", 2): 0.700,
      ("14", 3): 0.478, ("12", 3): 0.524, ("10", 3): 0.630, ("8", 3): 0.585, ("6", 3): 0.672}
POS = {("16", 1): .292, ("16", 2): .423, ("16", 8): .651, ("16", 12): .829, ("18", 1): .264, ("18", 2): .379, ("18", 4): .433}
TOS = {("16", 1): .312, ("18", 1): .286}

def size_of(desc):
    m = re.search(r"(\d+)MCM", desc)
    if m: return m.group(1)
    m = re.search(r"\b(\d/0)\b", desc)
    if m: return m.group(1)
    m = re.search(r"#(\d+)", desc)
    if m: return m.group(1)
    return None

def cable_od(code, grp, desc):
    d = desc.upper()
    if grp in ("Building Wire", "Ground Cable"):
        s = size_of(d)
        if "BARE" in d:
            if s == "10": return 0.1019, SRC_BARE10
            return BARE.get(s), SRC_BARE if s in BARE else None
        if "XHHW" in d: tbl, src = XHHW, SRC_XHHW
        elif "THWN" in d: tbl, src = THHN, SRC_THHN
        elif "THW" in d: tbl, src = THW, SRC_THW
        else: return None, None
        return (tbl[s], src) if s in tbl else (None, None)
    if grp == "Tray Cable":
        m = re.match(r"TRAY CABLE W/(\d+) #(\d+)", d)
        n, s = int(m.group(1)), m.group(2)
        od = TC.get(s, {}).get(n)
        return (od, SRC_TC) if od else (None, None)
    if grp == "Residential Cable":
        m = re.match(r"(\d+)/(\d)/?\s+ROMEX", d)
        if m:
            od = NM.get((m.group(1), int(m.group(2))))
            return (od, SRC_NM) if od else (None, None)
        if d.startswith("4/0 SER CABLE ALUMINUM"): return 1.518, SRC_SER
        return None, None
    if grp == "Instrument Cable":
        m = re.match(r"(\d+)/(PR|TRIAD) #(\d+) OVERALL SHIELDED TYPE (TC|PLTC)", d)
        if m:
            n, kind, s, t = int(m.group(1)), m.group(2), m.group(3), m.group(4)
            if t == "PLTC":
                return (0.409, SRC_PLTC) if (kind, s, n) == ("PR", "16", 2) else (None, None)
            tbl, src = (POS, SRC_POS) if kind == "PR" else (TOS, SRC_TOS)
            od = tbl.get((s, n))
            return (od, src) if od else (None, None)
        return None, None
    return None, None

def fmt(v):
    return ("%.4f" % v).rstrip("0").rstrip(".") if v is not None else ""

def main():
    os.makedirs(SEED, exist_ok=True)
    con = sqlite3.connect(DB)
    conduit_rows = []
    for code, desc, tbl, src in CONDUIT:
        for t in TS:
            if t in tbl:
                conduit_rows.append((code, desc, t, round(tsdec(t), 4), tbl[t], src))
    with open(os.path.join(SEED, "conduit_od.csv"), "w", newline="") as f:
        w = csv.writer(f, lineterminator="\r\n")
        w.writerow(["ConduitCode", "ConduitDesc", "TradeSize", "TradeSizeDec", "OD_in", "Source"])
        for r in conduit_rows:
            w.writerow([r[0], r[1], r[2], fmt(r[3]), fmt(r[4]), r[5]])
    cab = []
    for code, grp, desc in con.execute("SELECT ITEMCODE, ITEM_GRP, ITEMDESC FROM MEDType WHERE ITEMTYPE='CABLE' ORDER BY ITEMCODE"):
        od, src = cable_od(code, grp, desc)
        cab.append((code, desc, grp, od, src or ""))
    with open(os.path.join(SEED, "cable_od_sources.csv"), "w", newline="") as f:
        w = csv.writer(f, lineterminator="\r\n")
        w.writerow(["ITEMCODE", "ITEMDESC", "ITEM_GRP", "OD_in", "Source"])
        for r in cab:
            w.writerow([r[0], r[1], r[2], fmt(r[3]), r[4] if r[3] is not None else "not sourced"])
    # apply to seed DB (fill blanks only)
    con.execute("""CREATE TABLE IF NOT EXISTS MEDConduitOD (
  ConduitCode INTEGER NOT NULL,
  ConduitDesc TEXT,
  TradeSize TEXT NOT NULL,
  TradeSizeDec REAL,
  OD_in REAL,
  Source TEXT,
  PRIMARY KEY (ConduitCode, TradeSize)
)""")
    for r in conduit_rows:
        con.execute("INSERT OR IGNORE INTO MEDConduitOD (ConduitCode, ConduitDesc, TradeSize, TradeSizeDec, OD_in, Source) VALUES (?,?,?,?,?,?)", r)
    n = 0
    for code, desc, grp, od, src in cab:
        if od is None: continue
        n += con.execute("UPDATE MEDType SET USER3=? WHERE ITEMTYPE='CABLE' AND ITEMCODE=? AND (USER3 IS NULL OR TRIM(USER3)='')", (fmt(od), code)).rowcount
    con.commit()
    con.execute("VACUUM")
    con.close()
    from collections import Counter
    tot, got = Counter(), Counter()
    for code, desc, grp, od, src in cab:
        tot[grp] += 1
        if od is not None: got[grp] += 1
    for g in tot: print("%-18s %3d / %3d" % (g, got[g], tot[g]))
    print("conduit rows", len(conduit_rows), "USER3 updated", n)

if __name__ == "__main__":
    main()

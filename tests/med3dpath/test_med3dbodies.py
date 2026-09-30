"""Desk test for the MEDMAKE3D conduit-body stage: MED3DFittings.lsp (plan fittings:
body key from MEDType.ITEMKEY2 / description / seed CSV, placement, snap, TB for tee
up / down, placeholders) together with the MED3DPath.lsp planner (runs cut back to
the hub faces at a body, no fillet / sphere there, flags for legs with no hub).
Uses the real Data/MED.db FITTING rows as the MEDType catalog.
Usage: python3 tests/med3dpath/test_med3dbodies.py [-v]"""
import math, os, sqlite3, sys
sys.path.insert(0, os.path.dirname(__file__))
from fitmock import *
import fitmock

PATH_LSP = os.path.join(ROOT, 'Support', 'MED3DPath.lsp')
DB = os.path.join(ROOT, 'Data', 'MED.db')

def sub(a, b): return [x - y for x, y in zip(a, b)]
def dist(a, b): return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))
def closev(a, b, tol=1e-6): return dist(a, b) <= tol

class Ent:
    n = 0
    def __init__(self, ed, xdata=None):
        Ent.n += 1; self.ed = ed; self.xdata = xdata or {}; self.h = f'E{Ent.n}'
        self.ed.insert(1, Pair(5, self.h))
    def __repr__(self): return f'<{self.h}>'

class SS:
    def __init__(self, items): self.items = items

def catalog_rows(blank_keys=False, edits=None):
    con = sqlite3.connect(DB)
    rows = [list(r) for r in con.execute("SELECT ITEMCODE, ITEMDESC, ITEMKEY2 FROM MEDType WHERE ITEMTYPE='FITTING'")]
    con.close()
    for r in rows:
        if blank_keys: r[2] = None
        if edits and r[0] in edits: r[2] = edits[r[0]]
    return [['ITEMCODE', 'ITEMDESC', 'ITEMKEY2']] + rows

def world(sql='db'):
    """Interp with MED3DPath + MED3DFittings, a tiny entity store and a MEDType catalog."""
    L = Interp(); mk = Mock(L)
    L.load(PATH_LSP); L.load(LSP)
    ents = []
    def ssget(mode, flt=None):
        app = typ = None
        for it in flt or []:
            if isinstance(it, list) and it and it[0] == -3: app = it[1][0]
            if isinstance(it, Pair) and it.car == 0 and it.cdr in ('INSERT',): typ = 'INSERT'
        got = [e for e in ents if app in e.xdata and
               ((typ == 'INSERT') == (e.ed[0].cdr == 'INSERT'))]
        return SS(got) if got else None
    L.g.update({
        '_FITTING': 'MED_FITTING', '_CONDUIT': 'MED_CONDUIT',
        'SSGET': ssget, 'SSLENGTH': lambda ss: len(ss.items), 'SSNAME': lambda ss, i: ss.items[i] if i < len(ss.items) else None,
        'ENTGET': lambda e, *a: e.ed, 'XDATAGET': lambda e, app: e.xdata.get(app),
        'MED3D-ENSURE-LAYER': lambda info: (mk.layers.add(info[0]), info[0])[1],
    })
    markers = []
    L.g['MED3D-FLAG-AT'] = lambda v, s, txt: markers.append((list(v), txt))
    if sql == 'db': mk.sql = lambda s: catalog_rows()
    elif sql == 'blank': mk.sql = lambda s: catalog_rows(blank_keys=True)
    elif isinstance(sql, dict): mk.sql = lambda s: catalog_rows(edits=sql)
    else: mk.sql = None                                     # no MED-DotNet -> seed CSV
    return L, mk, ents, markers

def conduit(ents, pts, elev=12.0, closed=False):
    ed = [Pair(0, 'LWPOLYLINE'), Pair(70, 1 if closed else 0), Pair(38, elev)]
    for p in pts: ed += [[10, float(p[0]), float(p[1])], Pair(42, 0.0)]
    ed.append([210, 0.0, 0.0, 1.0])
    e = Ent(ed, {'MED_CONDUIT': ['MED_CONDUIT', 'C1', 1.0, 1]}); ents.append(e); return e

def fitting(ents, blk, pt, rot_deg, code, size=1.0, scale=(1.0, 1.0, 1.0), extr=None):
    ed = [Pair(0, 'INSERT'), Pair(2, blk), [10] + [float(c) for c in pt], Pair(50, math.radians(rot_deg)),
          Pair(41, float(scale[0])), Pair(42, float(scale[1])), Pair(43, float(scale[2]))]
    if extr: ed.append([210] + [float(c) for c in extr])
    e = Ent(ed, {'MED_FITTING': ['MED_FITTING', 'NONE', size, code, 0.0, 0.0, 0.0]}); ents.append(e); return e

def body(bodies, e):
    for b in bodies:
        if get(b, 'HANDLE') == e.h: return b
    return None

def plan_run(L, ents, e, od=1.163, kind='CONDUIT'):
    pd = L.apply(Sym('MED3D-READ-PATH'), [e])
    return L.apply(Sym('MED3D-PLAN'), [pd[0], pd[1], pd[2], pd[3], od, kind, None])

def hub(geom_hubs, name): return next(h for h in to_py(geom_hubs) if h[0] == name)

# ----------------------------------------------------------- key parsing
L, mk, ents, markers = world()
for d, k in [('Form 7 "LB" condulet fitting', 'RGD|F7|LB'), ('Form 8 "TB" condulet fitting', 'RGD|F8|TB'),
             ('Mark 9 "C" condulet fitting', 'RGD|M9|C'), ('Mogul "BLB" condulet fitting', 'RGD|MOG|BLB'),
             ('"LBD" condulet fitting', 'RGD|CH|LBD'), ('Explosion Proof GUAL condulet fitting', 'RGD|XP|GUAL'),
             ('Rigid Steel Coupling', None), ('"EYS" sealling fitting', None), ('', None)]:
    check('desc-key', call(L, 'medcb-desc-key', d) == k, f'{d!r} -> {call(L, "medcb-desc-key", d)}')
for s, v in [('RGD|F7|LB', ['RGD', 'F7', 'LB']), (' rgd|f8|tb ', ['RGD', 'F8', 'TB']), ('RGD||X', ['RGD', '', 'X']),
             ('RGD|F7', None), ('', None), (None, None), ('RGD|F7|', None)]:
    check('key-parse', to_py(call(L, 'medcb-key-parse', s)) == v, f'{s!r} -> {to_py(call(L, "medcb-key-parse", s))}')

# ------------------------------------------------------------ resolution
def resolve(sql, code):
    L, mk, ents, markers = world(sql); return to_py(call(L, 'medcb-resolve-code', code))
check('res-itemkey2', resolve('db', 30) == ['RGD|F7|LB', 'ITEMKEY2', 'Form 7 "LB" condulet fitting'], str(resolve('db', 30)))
check('res-desc', resolve('blank', 31) == ['RGD|F8|LB', 'DESC', 'Form 8 "LB" condulet fitting'], str(resolve('blank', 31)))
check('res-desc-x', resolve('blank', 80)[:2] == ['RGD|F7|X', 'DESC'], str(resolve('blank', 80)))
check('res-key-x', resolve('db', 80)[:2] == ['RGD|F7|X', 'ITEMKEY2'], str(resolve('db', 80)))
# r6: LBD / LBY without a form -> CH, "Explosion Proof" -> XP (description parse)
check('res-desc-lbd', resolve('blank', 39)[:2] == ['RGD|CH|LBD', 'DESC'], str(resolve('blank', 39)))
check('res-desc-gua', resolve('blank', 142)[:2] == ['RGD|XP|GUAT', 'DESC'], str(resolve('blank', 142)))
# inline fittings (no "condulet" in the description): ITEMKEY2 blank in the DB -> the
# seed keys CSV by code when the description is the same
for code, key in ((72, 'RGD|CH|UNY'), (61, 'RGD|CH|EYS'), (64, 'RGD|CH|EYD'), (100, 'RGD|CH|PLGR'), (101, 'RGD|CH|PLGS'),
                  (103, 'RGD|CH|RE'), (120, 'RGD|CH|HUB'), (121, 'RGD|MYR|HUB')):
    check(f'res-csv-fallback {code}', resolve('blank', code)[:2] == [key, 'CSV'], str(resolve('blank', code)))
    check(f'res-key {code}', resolve('db', code)[:2] == [key, 'ITEMKEY2'], str(resolve('db', code)))
# a renamed code (other description) is not taken from the CSV
L0, mk0, _, _ = world('blank'); mk0.sql = lambda s: [['ITEMCODE', 'ITEMDESC', 'ITEMKEY2'], [72, 'my union', None]]
check('res-csv-desc-differs', call(L0, 'medcb-resolve-code', 72) is None)
check('res-override', resolve({30: 'RGD|F8|LB'}, 30)[:2] == ['RGD|F8|LB', 'ITEMKEY2'], str(resolve({30: 'RGD|F8|LB'}, 30)))
check('res-coupling', resolve('db', 8) is None)
check('res-unknown', resolve('db', 9999) is None)
check('res-csv', resolve(None, 36)[:2] == ['RGD|F7|LR', 'CSV'], str(resolve(None, 36)))
check('res-csv-miss', resolve(None, 8) is None, str(resolve(None, 8)))   # CSV keys only the modelled codes (no coupling)
check('res-csv-x', resolve(None, 80)[:2] == ['RGD|F7|X', 'CSV'], str(resolve(None, 80)))
L, mk, ents, markers = world('db'); call(L, 'medcb-resolve-code', 30); call(L, 'medcb-resolve-code', 11)
check('one-select', len(mk.queries) == 1 and 'ITEMKEY2' in mk.queries[0], str(mk.queries))

# --------------------------------------- LL at a square corner (1lbl, code 33)
L, mk, ents, markers = world()
run = conduit(ents, [(0, 0), (60, 0), (60, 40), (100, 40)], elev=12.0)
ll = fitting(ents, '1lbl', (60, 0, 0), 90, 33)                   # 2D +X north (long leg), local +Y = west leg
res = call(L, 'medcb-collect')
bodies, nm = res[0], res[1]
b = body(bodies, ll)
check('ll-found', b is not None and nm == 0, str(to_py(res)))
check('ll-shape', get(b, 'SHAPE') == 'LL' and get(b, 'FORM') == 'F7' and get(b, 'SRC') == 'ITEMKEY2')
check('ll-z', closev(get(b, 'PT'), [60, 0, 12]), f'conduit elevation wins: {get(b, "PT")}')
# r5: LL body along the symbol's long leg (north), side hub (+Y) west, cover up
check('ll-rot', abs(get(b, 'ROT') - math.pi / 2) < 1e-9 and get(b, 'TURN') == 0 and get(b, 'LEGS') == 2 and not get(b, 'FLIP'),
      f'rot {get(b, "ROT")} turn {get(b, "TURN")} legs {get(b, "LEGS")}')
g = call(L, 'medcb-geom-for', 'F7', 'LL', 1.0); W = get(g, 'W')
runf, brf = hub(get(g, 'HUBS'), 'RUN')[1], hub(get(g, 'HUBS'), 'BRANCH')[1]
L.g['*MED3D-FITS*'] = [call(L, 'medcb-fit-rec', x) for x in bodies]
pl = plan_run(L, ents, run)
cs = [dict((c.car, c.cdr) if isinstance(c, Pair) else (car(c), cdr(c)) for c in cc) for cc in get(pl, 'CORNERS')]
check('ll-corner', cs[0]['STATUS'] == 'FITTING' and cs[0]['FITTING'] == ll.h and cs[1]['STATUS'] == 'FITTED',
      str([(c['STATUS'], c.get('FITTING')) for c in cs]))
pcs = to_py(get(pl, 'PIECES'))
check('ll-no-sphere', all(p[0] != 'S' for p in pcs) and get(pl, 'GAPS') and not get(pl, 'FITFLAGS'), str(pcs))
check('ll-cut-west', closev(pcs[0][2], [60 - abs(brf[1]), 0, 12]), f'{pcs[0]} vs branch face {brf}')
check('ll-cut-north', closev(pcs[1][1], [60, runf[0], 12]), f'{pcs[1]} vs run face {runf}')
check('ll-next-bend', pcs[2][0] == 'A' and pcs[1][2][1] < pcs[2][1][1] + 1e-9, str(pcs[1:3]))
pc = plan_run(L, ents, run, od=0.5, kind='CABLE')
check('cable-unaffected', all(dict((car(c), cdr(c)) for c in cc)['STATUS'] != 'FITTING' for cc in get(pc, 'CORNERS')))
L.g['*MED3D-FITS*'] = None
pn = plan_run(L, ents, run)
check('no-fits-unchanged', not get(pn, 'GAPS') and get(pn, 'ENDTRIM') is None
      and [dict((car(c), cdr(c)) for c in cc)['STATUS'] for cc in get(pn, 'CORNERS')] == ['FITTED', 'FITTED'])
pl_res = to_py(call(L, 'medcb-place-all', bodies))
ins = mk.inserts[-1].props
check('ll-insert', ins['Name'] == 'MED_CB_RGD_F7_LL_1-00' and closev(ins['Pt'], [60, 0, 12]) and abs(ins['Rot'] - math.pi / 2) < 1e-9
      and ins['Layer'] == 'MED_3DCONDUIT' and 'Rot3D' not in ins, str(ins))
check('ll-place-res', get(call(L, 'medcb-place-all', []), 'PLACED') == 0)

# --------------------------- LB as a flat plan turn (1lbl, code 30): back hub tilted
#   into the plan (+/-90 deg about the body X axis), both legs cut, no flag, no note
def dot3(a, b): return sum(x * y for x, y in zip(a, b))
for drawn in (90, 0, 180, 270):
    L, mk, ents, markers = world()
    run = conduit(ents, [(0, 0), (60, 0), (60, 40)], elev=0.0)
    lb = fitting(ents, '1lbl', (60, 0, 0), drawn, 30)
    bodies = call(L, 'medcb-collect')[0]; b = body(bodies, lb)
    fl = get(b, 'FLIP')
    check(f'lb-turn-tilt {drawn}', isinstance(fl, float) and near(abs(fl), math.pi / 2), str(fl))
    check(f'lb-turn-no-note {drawn}', get(b, 'NOTE') is None, str(get(b, 'NOTE')))
    hb = dict((h[0], (h[1], h[2])) for h in to_py(get(b, 'HUBS')))
    dirs = sorted([hb['RUN'][1], hb['BACK'][1]])
    check(f'lb-turn-hubs {drawn}', all(closev(x, y) for x, y in zip(dirs, sorted([[-1.0, 0.0, 0.0], [0.0, 1.0, 0.0]]))), str(hb))
    cover = to_py(call(L, 'medcb-xdir', [0.0, 0.0, 1.0], get(b, 'ROT'), fl))
    check(f'lb-turn-cover-sideways {drawn}', abs(cover[2]) < 1e-9 and near(dist(cover, [0, 0, 0]), 1.0), str(cover))
    L.g['*MED3D-FITS*'] = [call(L, 'medcb-fit-rec', x) for x in bodies]
    pl = plan_run(L, ents, run)
    pcs = to_py(get(pl, 'PIECES'))
    face = {tuple(round(c) for c in d): dot3(f, d) for f, d in hb.values()}
    check(f'lb-turn-no-flag {drawn}', not get(pl, 'FITFLAGS'), str(to_py(get(pl, 'FITFLAGS'))))
    check(f'lb-turn-west-cut {drawn}', closev(pcs[0][2], [60 - face[(-1, 0, 0)], 0, 0]), f'{pcs} {face}')
    check(f'lb-turn-north-cut {drawn}', closev(pcs[1][1], [60, face[(0, 1, 0)], 0]), f'{pcs} {face}')
    mk.log.clear(); call(L, 'medcb-place-all', bodies)
    ins = mk.inserts[-1].props; r3 = ins.get('Rot3D') or []
    check(f'lb-turn-insert {drawn}', len(r3) == 1 and near(r3[0][2], fl)
          and closev(sub(r3[0][1], r3[0][0]), [math.cos(ins['Rot']), math.sin(ins['Rot']), 0.0])
          and closev(r3[0][0], [60, 0, 0]), str(ins))
    check(f'lb-turn-no-note-printed {drawn}', not any('flat plan turn' in l for l in mk.log), str(mk.log))
# LB flat turn lies along the symbol's long leg (drawn +X = the conduit picked) for
# both 1lbl and 1lbr; the cover faces sideways, away from the other leg
for blk in ('1lbl', '1lbr'):
    for drawn, other in ((180, (0.0, 1.0, 0.0)), (90, (-1.0, 0.0, 0.0))):
        L, mk, ents, markers = world()
        run = conduit(ents, [(0, 0), (60, 0), (60, 40)], elev=0.0)
        lb = fitting(ents, blk, (60, 0, 0), drawn, 30)
        b = body(call(L, 'medcb-collect')[0], lb)
        hb = dict((h[0], h[2]) for h in to_py(get(b, 'HUBS')))
        a0 = math.radians(drawn)
        check(f'lb-long-leg {blk} {drawn}', closev(hb['RUN'], [math.cos(a0), math.sin(a0), 0.0])
              and closev(hb['BACK'], list(other)), str(hb))
        cover = to_py(call(L, 'medcb-xdir', [0.0, 0.0, 1.0], get(b, 'ROT'), get(b, 'FLIP')))
        check(f'lb-long-leg-cover {blk} {drawn}', closev(cover, [-c for c in other]), str(cover))

# mirrored 2D fitting: no body, conduit left as drawn, one marker, Skipped line
for tag, kw, mir in [('xscale', dict(scale=(-1.0, 1.0, 1.0)), True), ('yscale', dict(scale=(1.0, -1.0, 1.0)), True),
                     ('extrusion', dict(extr=(0.0, 0.0, -1.0)), True),
                     ('both-neg', dict(scale=(-1.0, -1.0, 1.0)), False), ('menu-48', dict(scale=(48.0, 48.0, 48.0)), False),
                     ('xscale-48', dict(scale=(-48.0, 48.0, 48.0)), True), ('z-only', dict(scale=(1.0, 1.0, -1.0)), False)]:
    L, mk, ents, markers = world()
    run = conduit(ents, [(0, 0), (60, 0), (60, 40)], elev=0.0)
    f = fitting(ents, '1lbl', (60, 0, 0), 180, 30, **kw)
    bodies = call(L, 'medcb-collect')[0]; b = body(bodies, f)
    check(f'mirror-detect {tag}', bool(get(b, 'MIRROR')) == mir, str(to_py(b)))
    if not mir: continue
    check(f'mirror-no-fitrec {tag}', call(L, 'medcb-fit-rec', b) is None)
    L.g['*MED3D-FITS*'] = [x for x in [call(L, 'medcb-fit-rec', x) for x in bodies] if x]
    pl = plan_run(L, ents, run)
    cs = [dict((car(c), cdr(c)) for c in cc)['STATUS'] for cc in get(pl, 'CORNERS')]
    check(f'mirror-conduit-as-drawn {tag}', cs == ['FITTED'] and not get(pl, 'FITFLAGS') and not get(pl, 'GAPS'), str(cs))
    n0 = len(mk.inserts); mk.log.clear(); markers.clear()
    pr = call(L, 'medcb-place-all', bodies)
    check(f'mirror-no-insert {tag}', len(mk.inserts) == n0, str(len(mk.inserts)))
    check(f'mirror-counts {tag}', get(pr, 'MIRRORED') == 1 and get(pr, 'FLAGGED') == 1 and get(pr, 'PLACED') == 0
          and get(pr, 'PH') == 0, str(to_py(pr)))
    sk = to_py(get(pr, 'SKIPPED'))
    check(f'mirror-skipped {tag}', len(sk) == 1 and sk[0][0] == f.h and 'mirrored' in sk[0][2], str(sk))
    check(f'mirror-marker {tag}', len(markers) == 1 and markers[0][1].startswith('MIRRORED FITTING - re-insert, do not mirror')
          and closev(markers[0][0], [60, 0, 0]), str(markers))
# a mirrored non-body fitting (coupling) is simply not modelled
L, mk, ents, markers = world()
cp = fitting(ents, '1cplg', (0, 0, 0), 0, 8, scale=(-1.0, 1.0, 1.0))
res = call(L, 'medcb-collect')
check('mirror-nm', not res[0] and res[1] == 1, str(to_py(res)))

# the same LB turn with only one leg drawn (r5): the symbol says where the other leg
# is, so the LB still lies on its side - back hub toward the symbol's short leg, no note
L, mk, ents, markers = world()
conduit(ents, [(0, 0), (60, 0)], elev=0.0)
lb = fitting(ents, '1lbl', (60, 0, 0), 90, 30)
b = body(call(L, 'medcb-collect')[0], lb)
hb = dict((h[0], h[2]) for h in to_py(get(b, 'HUBS')))
check('lb-turn-1leg', near(get(b, 'FLIP'), math.pi / 2) and get(b, 'NOTE') is None and closev(hb['BACK'], [-1.0, 0.0, 0.0])
      and closev(hb['RUN'], [0.0, 1.0, 0.0]), f'{get(b, "FLIP")} {get(b, "NOTE")} {hb}')
# snap off: drawn rotation, the symbol's tilt
L, mk, ents, markers = world()
conduit(ents, [(0, 0), (60, 0), (60, 40)], elev=0.0)
lb = fitting(ents, '1lbl', (60, 0, 0), 90, 30)
L.g['*MEDCB-SNAP*'] = None
b = body(call(L, 'medcb-collect')[0], lb)
check('lb-turn-nosnap', near(get(b, 'FLIP'), math.pi / 2) and near(get(b, 'ROT'), math.pi / 2), f'{get(b, "FLIP")} {get(b, "ROT")}')

# ----------------------------------------- tee: pass-through run + branch end
L, mk, ents, markers = world()
main = conduit(ents, [(0, 0), (100, 0)], elev=0.0)
br = conduit(ents, [(50, 0), (50, -30)], elev=0.0)
tee = fitting(ents, '1tee', (50, 0, 0), -90, 11)                 # 2D +X = branch
bodies = call(L, 'medcb-collect')[0]; b = body(bodies, tee)
check('tee-rot', abs(get(b, 'ROT') - math.pi) < 1e-9 and get(b, 'LEGS') == 3 and get(b, 'TURN') == 0,
      f'rot {get(b, "ROT")} legs {get(b, "LEGS")} turn {get(b, "TURN")}')
L.g['*MED3D-FITS*'] = [call(L, 'medcb-fit-rec', x) for x in bodies]
pm = plan_run(L, ents, main); pb = plan_run(L, ents, br)
check('tee-pass-through', to_py(get(pm, 'PIECES')) == [['L', [0.0, 0.0, 0.0], [100.0, 0.0, 0.0]]] and not get(pm, 'GAPS'),
      str(to_py(get(pm, 'PIECES'))))
g = call(L, 'medcb-geom-for', 'F7', 'T', 1.0); brf = hub(get(g, 'HUBS'), 'BRANCH')[1]
check('tee-branch-cut', closev(to_py(get(pb, 'PIECES'))[0][1], [50, -brf[1], 0]) and near(to_py(get(pb, 'ENDTRIM'))[0], brf[1]),
      f'{to_py(get(pb, "PIECES"))} {brf}')
# the same tee with a wrong 2D rotation is snapped back onto the legs
L, mk, ents, markers = world()
conduit(ents, [(0, 0), (100, 0)], elev=0.0); conduit(ents, [(50, 0), (50, -30)], elev=0.0)
tee = fitting(ents, '1tee', (50, 0, 0), 0, 11)
b = body(call(L, 'medcb-collect')[0], tee)
check('tee-snap', abs(math.cos(get(b, 'ROT')) + 1) < 1e-9 and get(b, 'TURN') != 0, f'rot {get(b, "ROT")} turn {get(b, "TURN")}')
L.g['*MEDCB-SNAP*'] = None
b = body(call(L, 'medcb-collect')[0], tee)
check('tee-nosnap', abs(get(b, 'ROT') - 1.5 * math.pi) < 1e-9 and get(b, 'TURN') == 0, str(get(b, 'ROT')))

# ------------------------------------- tee up / down -> TB, LB up note, misc
L, mk, ents, markers = world()
conduit(ents, [(0, 0), (100, 0)], elev=0.0)
td = fitting(ents, '1teed', (20, 0, 0), 0, 11)
tu = fitting(ents, '1TEEU', (40, 0, 0), 0, 11)
tuo = fitting(ents, '1teeuo', (45, 0, 0), 0, 11)
lbu = fitting(ents, '1lbu', (100, 0, 0), 180, 30)
lbd = fitting(ents, '1lbd', (0, 0, 0), 0, 30)
x = fitting(ents, '1exs', (60, 0, 0), 0, 80)
cp = fitting(ents, 'coup', (70, 0, 0), 0, 8)
lbdd = fitting(ents, '1lbdl', (80, 0, 0), 0, 39)
nosz = fitting(ents, '1cee', (90, 0, 0), 0, 50, size=0.0)
big = fitting(ents, '1teed', (30, 0, 0), 0, 11, size=4.0)       # F7 TB only to 2"
res = call(L, 'medcb-collect'); bodies, nm = res[0], res[1]
B = {e.h: body(bodies, e) for e in (td, tu, tuo, lbu, lbd, x, lbdd, nosz, big)}
check('not-modelled', nm == 1 and body(bodies, cp) is None, f'nm {nm}')
check('teed-tb', get(B[td.h], 'SHAPE') == 'TB' and not get(B[td.h], 'FLIP') and get(B[td.h], 'REASON') is None)
check('teeu-tb-flip', get(B[tu.h], 'SHAPE') == 'TB' and get(B[tu.h], 'FLIP') and get(B[tuo.h], 'FLIP'))
hb = dict((h[0], h[2]) for h in to_py(get(B[tu.h], 'HUBS')))
check('teeu-back-up', closev(hb['BACK'], [0, 0, 1]), str(hb))
hb = dict((h[0], h[2]) for h in to_py(get(B[td.h], 'HUBS')))
check('teed-back-down', closev(hb['BACK'], [0, 0, -1]), str(hb))
check('lbu-flip', get(B[lbu.h], 'FLIP') is True and get(B[lbu.h], 'NOTE') is None and get(B[lbd.h], 'NOTE') is None
      and get(B[lbd.h], 'FLIP') is None, f'{get(B[lbu.h], "FLIP")} {get(B[lbu.h], "NOTE")}')
hb = dict((h[0], h[2]) for h in to_py(get(B[lbu.h], 'HUBS')))
check('lbu-back-up', closev(hb['BACK'], [0, 0, 1]) and closev(hb['RUN'], [-1, 0, 0]), str(hb))
hb = dict((h[0], h[2]) for h in to_py(get(B[lbd.h], 'HUBS')))
check('lbd-run-on-conduit', closev(hb['RUN'], [1, 0, 0]) and closev(hb['BACK'], [0, 0, -1]), str(hb))
check('x-real', get(B[x.h], 'REASON') is None and get(B[x.h], 'SHAPE') == 'X', str(get(B[x.h], 'REASON')))
check('lbd-real', get(B[lbdd.h], 'REASON') is None and get(B[lbdd.h], 'FORM') == 'CH', str(get(B[lbdd.h], 'REASON')))
check('size-reason', get(B[nosz.h], 'REASON') == 'no trade size on the fitting')
check('big-reason', 'no F7 TB 4" row' in get(B[big.h], 'REASON'), str(get(B[big.h], 'REASON')))
check('fit-rec-no-size', call(L, 'medcb-fit-rec', B[nosz.h]) is None)
mk.log.clear()
out = call(L, 'medcb-place-all', bodies)
names = [i.props['Name'] for i in mk.inserts]
check('place-names', 'MED_CB_RGD_F7_TB_1-00' in names and 'MED_CB_RGD_F7_X_1-00' in names
      and 'MED_CB_RGD_CH_LBD_1-00' in names and 'MED_CB_RGD_F7_TB_4-00_PH' in names, str(names))
flipped = [i for i in mk.inserts if 'Rot3D' in i.props and near(i.props['Rot3D'][0][2], math.pi)]
tilted = [i for i in mk.inserts if 'Rot3D' in i.props and not near(i.props['Rot3D'][0][2], math.pi)]
# r5: the LBD on 1lbdl lies on its side like an LB on 1lbl (+90 deg about X)
check('place-lbd-side', len(tilted) == 1 and tilted[0].props['Name'] == 'MED_CB_RGD_CH_LBD_1-00'
      and near(tilted[0].props['Rot3D'][0][2], math.pi / 2), str([i.props for i in tilted]))
check('place-flip', len(flipped) == 3 and all(closev(sub(i.props['Rot3D'][0][1], i.props['Rot3D'][0][0]), [math.cos(i.props['Rot']), math.sin(i.props['Rot']), 0])
                                               and near(i.props['Rot3D'][0][2], math.pi) for i in flipped), str([i.props for i in flipped]))
ph = [i for i in mk.inserts if i.props['Name'].endswith('_PH')]
check('place-ph-layer', ph and all(i.props['Layer'] == 'MED_3DFLAG' for i in ph))
sk = to_py(get(out, 'SKIPPED'))
check('place-counts', get(out, 'PLACED') == 7 and get(out, 'PH') == 1 and get(out, 'FLAGGED') == 2 and len(sk) == 2,
      f'placed {get(out, "PLACED")} ph {get(out, "PH")} flagged {get(out, "FLAGGED")} skipped {sk}')
check('place-skipped-text', any(s[0] == big.h and s[1] == 'FITTING' and 'TB 4' in s[2] and 'placeholder' in s[2] for s in sk)
      and any(s[0] == nosz.h and 'placeholder' not in s[2] for s in sk), str(sk))
check('place-markers', len(markers) == 2, str(markers))
check('place-refs', len(to_py(get(out, 'REFS'))) == 8, str(len(to_py(get(out, 'REFS')))))
check('place-flag-msg', sum('MED3D FLAG: fitting' in l for l in mk.log) == 2 and not any('MED3D note' in l for l in mk.log), str(mk.log))

# ---------------------------------------------------- seed CSV (no MED-DotNet)
L, mk, ents, markers = world(None)
conduit(ents, [(0, 0), (60, 0), (60, 40)])
e = fitting(ents, '1lbr', (60, 0, 0), 0, 36)
b = body(call(L, 'medcb-collect')[0], e)
check('csv-body', b and get(b, 'SHAPE') == 'LR' and get(b, 'SRC') == 'CSV', str(to_py(b)))

# ------------------------------- r5: vertical conduit from the fitting's xdata; Q5 search
# LB up (1lbu) at DIMSCALE 48: the menu left the conduit 0.0527 x 48 = 2.53" short
L, mk, ents, markers = world()
L.g['GET_BL_DATA'] = lambda name: [0.052734375] * 4 + [0]
run = conduit(ents, [(-40, 0), (-0.052734375 * 48, 0)], elev=10.0)
lb = fitting(ents, '1lbu', (0, 0, 0), 180, 30, scale=(48.0, 48.0, 48.0))
lb.xdata['MED_CONDUIT'] = ['MED_CONDUIT', 'NONE', 1.0, 1, 36.0, 'F']
lb.xdata['VERT_DATA'] = ['VERT_DATA', 0.0, 0.0, 1, 0.0]
bodies = call(L, 'medcb-collect')[0]; b = body(bodies, lb)
hb = dict((h[0], (h[1], h[2])) for h in to_py(get(b, 'HUBS')))
check('q5-found', get(b, 'LEGS') == 1 and closev(get(b, 'PT'), [0, 0, 10]) and near(get(b, 'TOL'), 0.25 + 48 * 0.052734375),
      f'{get(b, "LEGS")} {get(b, "PT")} {get(b, "TOL")}')
check('q5-lb-up', closev(hb['BACK'][1], [0, 0, 1]) and closev(hb['RUN'][1], [-1, 0, 0]), str(hb))
L.g['*MED3D-FITS*'] = [call(L, 'medcb-fit-rec', x) for x in bodies]
pl = plan_run(L, ents, run)
pcs = to_py(get(pl, 'PIECES')); et = to_py(get(pl, 'ENDTRIM'))
check('q5-trim-to-face', closev(pcs[-1][2], [hb['RUN'][0][0], 0, 10]) and not get(pl, 'FITFLAGS'), f'{et} {pcs}')
n0 = len(mk.ms_solids); pr = call(L, 'medcb-place-all', bodies)
vs = mk.ms_solids[n0:]
check('vert-leg', len(vs) == 1 and get(pr, 'VERT') == 1 and vs[0].props.get('Layer') == 'MED_3DCONDUIT', str(to_py(pr)))
if vs:
    c = vs[0].parts[0]
    check('vert-leg-span', near(c[1][2], 10 + hb['BACK'][0][2]) and near(c[2][2], 46.0) and near(c[1][0], 0) and near(c[1][1], 0),
          f'{c} back face {hb["BACK"][0]}')
# break wider than the hub: the run end is extended back to the face (negative trim)
r = to_py(call(L, 'med3d-fit-trim', ['H', [0.0, 0.0, 0.0], [['RUN', [2.0, 0.0, 0.0], [1.0, 0.0, 0.0]]]], [1.0, 0.0, 0.0], [3.0, 0.0, 0.0]))
check('q5-extend', near(r[0], -1.0) and r[1] is True, str(r))
# down, no hub pointing down (a C code on the LB-down symbol): built from the insertion point + flagged
L, mk, ents, markers = world()
run = conduit(ents, [(0, 0), (40, 0)], elev=0.0)
c = fitting(ents, '1lbd', (0, 0, 0), 0, 50)
c.xdata['MED_CONDUIT'] = ['MED_CONDUIT', 'NONE', 1.0, 1, 24.0, 'F']
c.xdata['VERT_DATA'] = ['VERT_DATA', 0.0, 0.0, -1, 0.0]
bodies = call(L, 'medcb-collect')[0]
pr = call(L, 'medcb-place-all', bodies)
check('vert-no-hub', len(mk.ms_solids) == 1 and near(mk.ms_solids[0].parts[0][1][2], -24.0) and near(mk.ms_solids[0].parts[0][2][2], 0.0)
      and get(pr, 'FLAGGED') == 1 and any('vertical conduit' in m[1] for m in markers), f'{to_py(pr)} {markers}')
# TA (code 17) is modelled as a T
L, mk, ents, markers = world()
conduit(ents, [(0, -40), (0, 40)]); conduit(ents, [(0, 0), (40, 0)])
t = fitting(ents, '1tee', (0, 0, 0), 0, 17)
b = body(call(L, 'medcb-collect')[0], t)
check('ta-as-t', get(b, 'SHAPE') == 'T' and not get(b, 'REASON') and 'TA modelled as a T' in (get(b, 'NOTE') or ''), str(to_py(b)))

if fails:
    print(f'FAILED {len(fails)}'); [print('  ' + f) for f in fails]; sys.exit(1)
print('OK test_med3dbodies')

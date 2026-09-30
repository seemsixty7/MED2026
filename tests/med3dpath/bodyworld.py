"""Shared fixture for the conduit-body desk tests that need a drawing: lispmini with
MED3DPath + MED3DFittings, a tiny entity store (LWPOLYLINE conduits, INSERT
fittings with MED_FITTING xdata), the real Data/MED.db FITTING rows as MEDType."""
import math, os, sqlite3, sys
sys.path.insert(0, os.path.dirname(__file__))
from fitmock import *

PATH_LSP = os.path.join(ROOT, 'Support', 'MED3DPath.lsp')
DB = os.path.join(ROOT, 'Data', 'MED.db')

class Ent:
    n = 0
    def __init__(self, ed, xdata=None):
        Ent.n += 1; self.ed = ed; self.xdata = xdata or {}; self.h = f'E{Ent.n}'
        self.ed.insert(1, Pair(5, self.h))
    def __repr__(self): return f'<{self.h}>'

class SS:
    def __init__(self, items): self.items = items

def catalog_rows():
    con = sqlite3.connect(DB)
    rows = [list(r) for r in con.execute("SELECT ITEMCODE, ITEMDESC, ITEMKEY2 FROM MEDType WHERE ITEMTYPE='FITTING'")]
    con.close()
    return [['ITEMCODE', 'ITEMDESC', 'ITEMKEY2']] + rows

def world():
    L = Interp(); mk = Mock(L)
    L.load(PATH_LSP); L.load(LSP)
    ents = []
    def ssget(mode, flt=None):
        app = typ = None
        for it in flt or []:
            if isinstance(it, list) and it and it[0] == -3: app = it[1][0]
            if isinstance(it, Pair) and it.car == 0 and it.cdr in ('INSERT',): typ = 'INSERT'
        got = [e for e in ents if app in e.xdata and ((typ == 'INSERT') == (e.ed[0].cdr == 'INSERT'))]
        return SS(got) if got else None
    L.g.update({
        '_FITTING': 'MED_FITTING', '_CONDUIT': 'MED_CONDUIT',
        'SSGET': ssget, 'SSLENGTH': lambda ss: len(ss.items), 'SSNAME': lambda ss, i: ss.items[i] if i < len(ss.items) else None,
        'ENTGET': lambda e, *a: e.ed, 'XDATAGET': lambda e, app: e.xdata.get(app),
        'MED3D-ENSURE-LAYER': lambda info: (mk.layers.add(info[0]), info[0])[1],
    })
    markers = []
    L.g['MED3D-FLAG-AT'] = lambda v, s, txt: markers.append((list(v), txt))
    mk.sql = lambda s: catalog_rows()
    return L, mk, ents, markers

def conduit(ents, pts, elev=0.0):
    ed = [Pair(0, 'LWPOLYLINE'), Pair(70, 0), Pair(38, elev)]
    for p in pts: ed += [[10, float(p[0]), float(p[1])], Pair(42, 0.0)]
    ed.append([210, 0.0, 0.0, 1.0])
    e = Ent(ed, {'MED_CONDUIT': ['MED_CONDUIT', 'NONE', 1.0, 1]}); ents.append(e); return e

def fitting(ents, blk, pt, rot_deg, code, size=1.0):
    ed = [Pair(0, 'INSERT'), Pair(2, blk), [10] + [float(c) for c in pt], Pair(50, math.radians(rot_deg))]
    e = Ent(ed, {'MED_FITTING': ['MED_FITTING', 'NONE', size, code, 0.0, 0.0, 0.0]}); ents.append(e); return e

def body(bodies, e):
    for b in bodies or []:
        if get(b, 'HANDLE') == e.h: return b
    return None

def plan_run(L, e, od=1.315, kind='CONDUIT'):
    pd = L.apply(Sym('MED3D-READ-PATH'), [e])
    return L.apply(Sym('MED3D-PLAN'), [pd[0], pd[1], pd[2], pd[3], od, kind, None])

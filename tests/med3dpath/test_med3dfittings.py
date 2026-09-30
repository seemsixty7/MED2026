"""Desk test for Support/MED3DFittings.lsp (rigid conduit body blocks) with the
lispmini interpreter and a small block/solid mock (no AutoCAD):
  - block naming, trade-size parsing
  - Data/seed/conduit_body_dims.csv read by the LISP CSV reader (all rows)
  - geometry of every data row: hub faces / directions / origin, overall A, B, C
  - block build: solids (box / cylinders after Rotate3D + Move) match the geometry,
    generate-on-demand, an existing definition is never redefined, placeholder
  - DB rows (MEDConduitBody via MED-DotNet) win over CSV rows
  - MEDCBTEST inserts all 6 shapes in a row without overlaps
Usage: python3 tests/med3dpath/test_med3dfittings.py [-v]"""
import csv, math, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from lispmini import Interp, Sym, Pair, car, cdr, to_py

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
LSP = os.path.join(ROOT, 'Support', 'MED3DFittings.lsp')
CSV = os.path.join(ROOT, 'Data', 'seed', 'conduit_body_dims.csv')
VERBOSE = '-v' in sys.argv
fails, notes = [], []
def check(name, cond, msg=''):
    if not cond: fails.append(f'{name}: {msg}')
def near(a, b, tol=1e-6): return abs(a - b) <= tol * max(1.0, abs(a), abs(b))
def get(alist, key):
    for it in alist or []:
        if car(it) == key: return cdr(it)
    return None

class CatchErr:
    def __init__(self, m): self.msg = m

def autolisp_atof(s):
    m = re.match(r'\s*[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?', s or '')
    return float(m.group(0)) if m else 0.0

def rot_y90(p): return [p[2], p[1], -p[0]]
def rot_x90(p): return [p[0], -p[2], p[1]]

class Obj:
    n = 0
    def __init__(self, kind, owner=None, parts=None):
        Obj.n += 1; self.id = Obj.n; self.kind = kind; self.owner = owner
        self.parts = parts or []; self.props = {}; self.deleted = False
    def __repr__(self): return f'<{self.kind}#{self.id}>'

class Mock:
    def __init__(self, L):
        self.L = L; self.blocks = {}; self.inserts = []; self.texts = []; self.layers = set(); self.log = []
        self.sql = None; self.settings = None; self.queries = []
        g = L.g
        g.update({
            'STRCASE': lambda s, lo=None: s.lower() if lo else s.upper(),
            'SUBSTR': lambda s, i, n=None: s[i - 1:] if n is None else s[i - 1:i - 1 + n],
            'STRLEN': lambda s: len(s), 'CHR': chr, 'ATOF': autolisp_atof, 'ATOI': lambda s: int(autolisp_atof(s)),
            'VL-STRING-SEARCH': lambda p, s, st=0: (s.find(p, st) if s.find(p, st) >= 0 else None),
            'VL-STRING-TRANSLATE': lambda a, b, s: s.translate(str.maketrans(a, b)),
            'VL-STRING-TRIM': lambda cs, s: s.strip(cs),
            'VL-FILENAME-DIRECTORY': lambda p: os.path.dirname(p.replace('\\', '/')),
            'FINDFILE': self.findfile, 'OPEN': lambda p, m, *a: open(p.replace('\\', '/'), encoding='utf-8'),
            'READ-LINE': lambda f: (lambda l: l.rstrip('\r\n') if l else None)(f.readline()),
            'CLOSE': lambda f: f.close(),
            'MEMBER': lambda x, l: (lambda i: (l[i:] if i is not None else None))(next((i for i, y in enumerate(l or []) if y == x), None)),
            'VL-REMOVE': lambda x, l: [y for y in (l or []) if y != x] or None,
            'WCMATCH': lambda s, pat: True if any(re.fullmatch(p.replace('*', '.*'), s) for p in pat.split(',')) else None,
            'TBLSEARCH': self.tblsearch, 'ENTMAKE': self.entmake,
            'VL-CATCH-ALL-APPLY': self.catch_apply, 'VL-CATCH-ALL-ERROR-P': lambda x: True if isinstance(x, CatchErr) else None,
            'VL-CATCH-ALL-ERROR-MESSAGE': lambda x: x.msg,
            'VLAX-GET-ACAD-OBJECT': lambda: 'ACAD', 'VLA-GET-ACTIVEDOCUMENT': lambda a: 'DOC',
            'VLA-GET-BLOCKS': lambda d: 'BLOCKS', 'VLA-GET-MODELSPACE': lambda d: 'MS',
            'VLAX-INVOKE': self.invoke, 'VLAX-PUT': self.put, 'VLA-DELETE': self.delete,
            'VLA-GET-LAYER': lambda o: o.props.get('Layer', '0'),
            'VLA-STARTUNDOMARK': lambda d: None, 'VLA-ENDUNDOMARK': lambda d: None,
            'PRINC': self.princ, 'TRANS': lambda p, a, b: list(p), 'GETVAR': lambda n: [1.0, 0.0, 0.0] if n.upper() == 'UCSXDIR' else 0,
            'ANGLE': lambda a, b: math.atan2(b[1] - a[1], b[0] - a[0]),
            'MED-DOTNET-READY': lambda: True if self.sql is not None else None,
            'MEDPROCESSSQLSTATEMENT': lambda s: (self.queries.append(s), self.sql(s))[1],
        })
    def princ(self, *a):
        if a and isinstance(a[0], str): self.log.append(a[0])
        return a[0] if a else None
    def findfile(self, p):
        p2 = p.replace('\\', '/')
        if p2.upper() == 'MED3DFITTINGS.LSP': return LSP
        if p2.upper() == 'MEDDATABASESETTINGS.DAT': return self.settings
        if os.path.isabs(p2) and os.path.exists(p2): return os.path.normpath(p2)
        return None
    def tblsearch(self, t, n):
        if t.upper() == 'BLOCK': return [Pair(2, n)] if n.upper() in self.blocks else None
        if t.upper() == 'LAYER': return [Pair(2, n)] if n in self.layers else None
        return None
    def entmake(self, ed):
        d = {car(x): cdr(x) for x in ed if isinstance(x, Pair)}
        if d.get(0) == 'LAYER': self.layers.add(d[2])
        if d.get(0) == 'TEXT': self.texts.append(d)
        return ed
    def catch_apply(self, f, args):
        try: return self.L.apply(f, list(args or []))
        except Exception as ex: return CatchErr(str(ex))
    def put(self, o, prop, v): o.props[str(prop).upper().capitalize()] = v; return None
    def delete(self, o):
        o.deleted = True
        if o.kind == 'BLOCK': self.blocks.pop(o.props['Name'].upper(), None)
        return None
    def invoke(self, obj, meth, *a):
        m = str(meth).upper()
        if obj == 'BLOCKS' and m == 'ADD':
            b = Obj('BLOCK'); b.props['Name'] = a[1]; b.base = list(a[0]); b.ents = []
            self.blocks[a[1].upper()] = b; return b
        if obj == 'MS' and m == 'INSERTBLOCK':
            if a[1].upper() not in self.blocks: raise Exception('no block ' + a[1])
            r = Obj('INSERT'); r.props.update(Name=a[1], Pt=list(a[0]), Rot=a[5]); self.inserts.append(r); return r
        if isinstance(obj, Obj) and obj.kind == 'BLOCK':
            if m == 'ADDBOX':
                c, l, w, h = a
                s = Obj('3DSOLID', obj, [('BOX', [c[0] - l / 2, c[1] - w / 2, c[2] - h / 2], [c[0] + l / 2, c[1] + w / 2, c[2] + h / 2])])
            elif m == 'ADDCYLINDER':
                c, r, h = a
                s = Obj('3DSOLID', obj, [('CYL', [c[0], c[1], c[2] - h / 2], [c[0], c[1], c[2] + h / 2], r)])
            else: raise Exception('mock block: ' + m)
            obj.ents.append(s); return s
        if isinstance(obj, Obj) and obj.kind == '3DSOLID':
            if m == 'ROTATE3D':
                p1, p2, ang = a
                check('rotate-about-origin', list(p1) == [0.0, 0.0, 0.0] and near(ang, math.pi / 2), f'{p1} {ang}')
                f = rot_y90 if list(p2) == [0.0, 1.0, 0.0] else rot_x90 if list(p2) == [1.0, 0.0, 0.0] else None
                if f is None: raise Exception('mock: rotate axis')
                obj.parts = [(p[0], f(p[1]), f(p[2]), p[3]) if p[0] == 'CYL' else p for p in obj.parts]; return None
            if m == 'MOVE':
                d = [y - x for x, y in zip(a[0], a[1])]
                mv = lambda p: [x + y for x, y in zip(p, d)]
                obj.parts = [(p[0], mv(p[1]), mv(p[2])) + tuple(p[3:]) for p in obj.parts]; return None
            if m == 'BOOLEAN':
                check('boolean-union', a[0] == 0, str(a[0]))
                other = a[1]; obj.parts += other.parts; other.deleted = True; return None
        raise Exception(f'mock: {obj} {meth}')

def live(b): return [e for e in b.ents if not e.deleted]
def bbox(parts):
    lo, hi = [1e99] * 3, [-1e99] * 3
    for p in parts:
        if p[0] == 'BOX': pts = [p[1], p[2]]
        else:
            a, b, r = p[1], p[2], p[3]; ax = [abs(y - x) > 1e-9 for x, y in zip(a, b)]
            pts = []
            for q in (a, b):
                for i in range(3):
                    if not ax[i]:
                        for s in (-r, r):
                            t = list(q); t[i] += s; pts.append(t)
        for q in pts:
            for i in range(3): lo[i] = min(lo[i], q[i]); hi[i] = max(hi[i], q[i])
    return lo, hi

def session():
    L = Interp(); mk = Mock(L); L.load(LSP); return L, mk
def call(L, name, *args): return L.apply(Sym(name.upper()), list(args))

# ------------------------------------------------------------------ naming
L, mk = session()
for sz, tag in [(0.5, '0-50'), (0.75, '0-75'), (1.0, '1-00'), (1.25, '1-25'), (1.5, '1-50'), (2.0, '2-00'), (2.5, '2-50'), (3.5, '3-50'), (4.0, '4-00'), (4, '4-00')]:
    check('size-tag', call(L, 'medcb-size-tag', sz) == tag, f'{sz} -> {call(L, "medcb-size-tag", sz)}')
check('block-name', call(L, 'medcb-block-name', 'f7', 'lb', 1.0) == 'MED_CB_RGD_F7_LB_1-00')
check('block-name2', call(L, 'medcb-block-name', 'F8', 'TB', 1.25) == 'MED_CB_RGD_F8_TB_1-25')
check('ph-name', call(L, 'medcb-ph-name', 'F7', 'C', 0.5) == 'MED_CB_RGD_F7_C_0-50_PH')
for s, v in [('1/2', 0.5), ('3/4', 0.75), ('1', 1.0), ('1-1/4', 1.25), ('1 1/2', 1.5), ('2-1/2', 2.5), ('1.25', 1.25), ('4"', 4.0), ('x', None), ('0', None)]:
    check('parse-size', call(L, 'medcb-parse-size', s) == v, f'{s!r} -> {call(L, "medcb-parse-size", s)}')
for v, s in [(0.5, '1/2'), (0.75, '3/4'), (1.0, '1'), (1.25, '1-1/4'), (3.5, '3-1/2')]:
    check('size-text', call(L, 'medcb-size-text', v) == s, f'{v} -> {call(L, "medcb-size-text", v)}')
check('csv-split', to_py(call(L, 'medcb-csv-split', 'a,"b,""c""",d', None)) == ['a', 'b,"c"', 'd'])
check('csv-split-n', to_py(call(L, 'medcb-csv-split', 'a,b,c,d', 2)) == ['a', 'b'])

# ------------------------------------------------------------ CSV via LISP
rows_py = list(csv.DictReader(open(CSV, encoding='utf-8')))
data = to_py(call(L, 'medcb-load-data', True))
check('csv-rows', len(data) == len(rows_py) and len(data) > 100, f'{len(data)} vs {len(rows_py)}')
check('csv-from', all(get(r, 'FROM') == 'CSV' for r in call(L, 'medcb-load-data', None)))
r = call(L, 'medcb-find', 'F8', 'LB', 1.5)
check('find-F8-LB-1.5', r and near(get(r, 'A'), 9.125) and near(get(r, 'B'), 4.03125) and near(get(r, 'C'), 2.75), str(to_py(r)))
check('find-missing', call(L, 'medcb-find', 'F7', 'TB', 4.0) is None)

# ------------------------------------------------------- geometry per row
DIRS = {'C': {'RUN': [1, 0, 0], 'RUN2': [-1, 0, 0]},
        'T': {'RUN': [1, 0, 0], 'RUN2': [-1, 0, 0], 'BRANCH': [0, 1, 0]},
        'TB': {'RUN': [1, 0, 0], 'RUN2': [-1, 0, 0], 'BACK': [0, 0, -1]},
        'LB': {'RUN': [1, 0, 0], 'BACK': [0, 0, -1]},
        'LL': {'RUN': [1, 0, 0], 'BRANCH': [0, -1, 0]},
        'LR': {'RUN': [1, 0, 0], 'BRANCH': [0, 1, 0]}}
clamped = []
for rp in rows_py:
    f, sh, sz = rp['Form'], rp['Shape'], float(rp['TradeSizeDec'])
    A, B, C, D, E = (float(rp[k]) for k in ('A_in', 'B_in', 'C_in', 'D_in', 'E_in'))
    tag = f'{f} {sh} {rp["TradeSize"]}'
    for cod in (None, 0.84 * sz / 0.5 if sz <= 0.5 else None):
        g = call(L, 'medcb-geom', sh, A, B, C, D, E, None, None, cod)
        W, H, hub = get(g, 'W'), get(g, 'H'), get(g, 'HUBOD')
        hubs = {h[0]: (h[1], h[2]) for h in to_py(get(g, 'HUBS'))}
        body = to_py(get(g, 'BODY')); cov = to_py(get(g, 'COVER')); cyls = to_py(get(g, 'CYLS'))
        note = get(g, 'NOTE')
        check('no-short ' + tag, get(g, 'SHORT') is None, str(note))
        if note: clamped.append(f'{tag}: {note}')
        check('hub-names ' + tag, set(hubs) == set(DIRS[sh]), str(hubs))
        for n, d in DIRS[sh].items():
            check(f'hub-dir {tag} {n}', hubs[n][1] == [float(x) for x in d], str(hubs[n][1]))
        ell = sh in ('LB', 'LL', 'LR')
        run = hubs['RUN'][0]
        if ell:
            check('run-face ' + tag, near(run[0], A - W / 2) and run[1] == 0 and run[2] == 0, str(run))
            check('closed-end ' + tag, near(body[0] - body[1] / 2, -W / 2), str(body))
            check('x-extent ' + tag, near(run[0] - (body[0] - body[1] / 2), A))
        else:
            check('run-faces ' + tag, near(run[0], A / 2) and near(hubs['RUN2'][0][0], -A / 2))
            check('body-centred ' + tag, body[0] == 0)
        for n in ('BRANCH', 'BACK'):
            if n in hubs:
                p = hubs[n][0]
                check(f'origin-on-{n} ' + tag, p[0] == 0 and (p[1] == 0 or p[2] == 0), str(p))
        if 'BACK' in hubs:
            check('B-extent ' + tag, near(H / 2 - hubs['BACK'][0][2], B), f'{H/2 - hubs["BACK"][0][2]} vs {B}')
        if 'BRANCH' in hubs:
            check('C-extent ' + tag, near(abs(hubs['BRANCH'][0][1]) + W / 2, C), f'{abs(hubs["BRANCH"][0][1]) + W/2} vs {C}')
        if sh == 'C': check('C-section ' + tag, near(W, C) and near(H, B))
        check('cover-top ' + tag, near(cov[4], H / 2) and cov[3] < cov[4] and near(body[4], cov[3]) and near(body[3], -H / 2))
        check('cover-inside ' + tag, cov[1] <= body[1] + 1e-9 and cov[2] <= W + 1e-9 and near(cov[0], body[0]))
        check('hub-od ' + tag, 0 < hub <= min(W, H) + 1e-9, f'{hub} {W} {H}')
        if cod: check('hub-covers-conduit ' + tag, hub >= min(W, H, 1.15 * cod) - 1e-9)
        check('run-len ' + tag, get(g, 'RUNLEN') >= 0.25 * hub - 1e-9, str(get(g, 'RUNLEN')))
        check('body-len ' + tag, body[1] >= W - 1e-9)
        for (p0, p1, rr), (n, face, d) in zip(cyls, to_py(get(g, "HUBS"))):
            check('cyl-face ' + tag, p1 == face and near(rr, hub / 2))
            ax = [b - a for a, b in zip(p0, p1)]
            ln = math.sqrt(sum(x * x for x in ax))
            check('cyl-dir ' + tag, all(near(x / ln, y) for x, y in zip(ax, d)), f'{ax} {d}')

# ------------------------------------------------------------ block build
L, mk = session()
res = to_py(call(L, 'medcb-ensure-block', 'F7', 'LB', 1.0))
check('ensure-created', res == ['MED_CB_RGD_F7_LB_1-00', 'CREATED'], str(res))
b = mk.blocks.get('MED_CB_RGD_F7_LB_1-00')
check('block-exists', b is not None and b.base == [0.0, 0.0, 0.0])
if b:
    sols = live(b)
    body = [s for s in sols if s.props.get('Color') == 0]; cover = [s for s in sols if s.props.get('Color') == 8]
    check('two-solids', len(sols) == 2 and len(body) == 1 and len(cover) == 1 and all(s.props.get('Layer') == '0' for s in sols), str([(s, s.props) for s in sols]))
    g = call(L, 'medcb-geom-for', 'F7', 'LB', 1.0)
    W, H = get(g, 'W'), get(g, 'H'); hubs = {h[0]: h[1] for h in to_py(get(g, 'HUBS'))}
    lo, hi = bbox(body[0].parts)
    check('body-bbox', near(lo[0], -W / 2) and near(hi[0], 6.0 - W / 2) and near(lo[1], -W / 2) and near(hi[1], W / 2)
          and near(lo[2], -(2.875 - H / 2)), f'{lo} {hi} W={W} H={H}')
    clo, chi = bbox(cover[0].parts)
    check('cover-bbox', near(chi[2], H / 2) and chi[2] >= hi[2], f'{clo} {chi}')
    cyl = [p for p in body[0].parts if p[0] == 'CYL' and abs(p[1][0] - p[2][0]) > 1e-9]
    check('run-cyl-rotated', len(cyl) == 1 and near(max(cyl[0][1][0], cyl[0][2][0]), 6.0 - W / 2), str(cyl))
    back = [p for p in body[0].parts if p[0] == 'CYL' and abs(p[1][2] - p[2][2]) > 1e-9 and p[1][0] == 0 and abs(p[3] - W / 2) > 1e-9]
    check('back-cyl', len(back) == 1 and near(min(back[0][1][2], back[0][2][2]), hubs['BACK'][2]), str(back))
n0 = sum(len(x.ents) for x in mk.blocks.values())
res2 = to_py(call(L, 'medcb-ensure-block', 'F7', 'LB', 1.0))
check('no-overwrite', res2 == ['MED_CB_RGD_F7_LB_1-00', 'EXISTS'] and sum(len(x.ents) for x in mk.blocks.values()) == n0, str(res2))
# a definition made by someone else is used as is
mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_F7_T_1-00')
res3 = to_py(call(L, 'medcb-ensure-block', 'F7', 'T', 1.0))
check('existing-left-alone', res3[1] == 'EXISTS' and mk.blocks['MED_CB_RGD_F7_T_1-00'].ents == [], str(res3))
# LR / LL / T branch cylinder along Y on the right side
for sh, sign in (('LR', 1), ('LL', -1), ('T', 1)):
    res = to_py(call(L, 'medcb-ensure-block', 'F8', sh, 2.0))
    bb = mk.blocks[res[0]]; body = [s for s in live(bb) if s.props.get('Color') == 0][0]
    ycyl = [p for p in body.parts if p[0] == 'CYL' and abs(p[1][1] - p[2][1]) > 1e-9]
    g = call(L, 'medcb-geom-for', 'F8', sh, 2.0); br = [h for h in to_py(get(g, 'HUBS')) if h[0] == 'BRANCH'][0]
    check('branch-cyl ' + sh, len(ycyl) == 1 and near((max if sign > 0 else min)(ycyl[0][1][1], ycyl[0][2][1]), br[1][1]) and br[1][1] * sign > 0, str(ycyl))
    lo, hi = bbox(body.parts)
    check('branch-C ' + sh, near(hi[1] - lo[1], 5.0), f'{hi[1] - lo[1]}')
# C straight: centred, both hubs
res = to_py(call(L, 'medcb-ensure-block', 'F7', 'C', 0.5)); body = [s for s in live(mk.blocks[res[0]]) if s.props.get('Color') == 0][0]
lo, hi = bbox(body.parts)
check('C-bbox', near(lo[0], -5.375 / 2) and near(hi[0], 5.375 / 2) and near(hi[1] - lo[1], 1.375), f'{lo} {hi}')
# placeholder: no data for Form 7 TB 4"
res = to_py(call(L, 'medcb-ensure-block', 'F7', 'TB', 4.0))
check('placeholder', res == ['MED_CB_RGD_F7_TB_4-00_PH', 'PLACEHOLDER'], str(res))
ph = mk.blocks.get('MED_CB_RGD_F7_TB_4-00_PH')
check('placeholder-box', ph and len(live(ph)) == 1 and live(ph)[0].props.get('Layer') == 'MED_3DFLAG' and live(ph)[0].parts[0][0] == 'BOX')
check('placeholder-layer', 'MED_3DFLAG' in mk.layers)
check('real-name-free', 'MED_CB_RGD_F7_TB_4-00' not in mk.blocks)
check('placeholder-again', to_py(call(L, 'medcb-ensure-block', 'F7', 'TB', 4.0))[1] == 'PH-EXISTS')
check('bad-shape', call(L, 'medcb-ensure-block', 'F7', 'XX', 1.0) is None)
check('bad-size', call(L, 'medcb-ensure-block', 'F7', 'LB', 0.0) is None)
# insert
ins = to_py(call(L, 'medcb-insert', 'F8', 'LB', 1.5, [10.0, 5.0, 0.0], 0.0))
check('insert', ins and ins[1] == 'MED_CB_RGD_F8_LB_1-50' and mk.inserts[-1].props['Pt'] == [10.0, 5.0, 0.0]
      and mk.inserts[-1].props['Layer'] == 'MED_3DCONDUIT', str(ins))
call(L, 'medcb-insert', 'F8', 'TB', 3.0, [0.0, 0.0, 0.0], 0.0)
check('insert-ph-layer', mk.inserts[-1].props['Layer'] == 'MED_3DFLAG')
hubs = to_py(call(L, 'medcb-hubs', 'F7', 'LL', 1.0))
check('hubs-api', [h[0] for h in hubs] == ['RUN', 'BRANCH'] and hubs[1][2] == [0.0, -1.0, 0.0], str(hubs))

# ------------------------------------------------------- DB rows win over CSV
import tempfile
tmpd = tempfile.mkdtemp()
def settings(text):
    p = os.path.join(tmpd, 'MEDDataBaseSettings.dat'); open(p, 'w').write(text); return p
# table missing (old MED-DotNet): only the catalog is asked, never MEDConduitBody
for text, cat in (('; c\nConnectString=Server=X\\Y;Database=MED;Integrated Security=SSPI;\n', 'INFORMATION_SCHEMA'),
                  ('ConnectString=Data Source=C:\\MED\\Data\\MED.db\n', 'sqlite_master'),
                  ('Provider=SQLite\nConnectString=whatever\n', 'sqlite_master')):
    L, mk = session(); mk.settings = settings(text)
    mk.sql = lambda s: None
    n = len(call(L, 'medcb-load-data', True))
    check('no-table ' + cat, n == len(rows_py) and len(mk.queries) == 1 and cat in mk.queries[0], str(mk.queries))
L, mk = session(); mk.sql = lambda s: None
call(L, 'medcb-load-data', True)
check('no-settings-no-sql', mk.queries == [], str(mk.queries))
L, mk = session(); mk.settings = settings('ConnectString=Server=X;Database=MED;\n')
mk.sql = lambda s: [['TABLE_NAME'], ['MEDConduitBody']] if 'INFORMATION_SCHEMA' in s else [['Form', 'Shape', 'TradeSizeDec', 'A_in', 'B_in', 'C_in', 'D_in', 'E_in', 'HubOD_in', 'HubLen_in', 'CatalogNo'],
                    ['F7', 'LB', '1', '9.5', '2.875', '1.75', '1.375', '4.5', None, '', 'LB37'],
                    ['F7', 'TB', 4.0, 12.0, 8.0, 5.0, 4.5, 10.0, 5.0, 1.0, '']]
data = call(L, 'medcb-load-data', True)
check('db-count', len(data) == len(rows_py) + 1, str(len(data)))
r = call(L, 'medcb-find', 'F7', 'LB', 1.0)
check('db-wins', r and get(r, 'FROM') == 'DB' and near(get(r, 'A'), 9.5), str(to_py(r)))
r = call(L, 'medcb-find', 'F7', 'LB', 2.0)
check('csv-fills', r and get(r, 'FROM') == 'CSV')
g = call(L, 'medcb-geom-for', 'F7', 'TB', 4.0)
check('db-hub-override', near(get(g, 'HUBOD'), 5.0) and near(get(g, 'RUNLEN'), 1.0) and near(get(g, 'LBODY'), 10.0), str(to_py(g)))

# ------------------------------------------------------------- MEDCBTEST
L, mk = session()
answers = {'GETKWORD': ['F8'], 'GETSTRING': ['1-1/2'], 'GETPOINT': [[100.0, 50.0, 0.0]]}
L.g['GETKWORD'] = lambda *a: answers['GETKWORD'].pop(0) if answers['GETKWORD'] else None
L.g['GETSTRING'] = lambda *a: answers['GETSTRING'].pop(0) if answers['GETSTRING'] else ''
L.g['GETPOINT'] = lambda *a: answers['GETPOINT'].pop(0) if answers['GETPOINT'] else None
L.g['INITGET'] = lambda *a: None
call(L, 'c:MEDCBTEST')
names = [i.props['Name'] for i in mk.inserts]
check('test-6', names == [f'MED_CB_RGD_F8_{s}_1-50' for s in ('LB', 'LR', 'LL', 'T', 'TB', 'C')], str(names))
check('test-labels', len(mk.texts) == 6, str(len(mk.texts)))
spans = []
for i in mk.inserts:
    sh = i.props['Name'].split('_')[4]
    lo, hi = to_py(call(L, 'medcb-geom-xrange', call(L, 'medcb-geom-for', 'F8', sh, 1.5)))
    spans.append((i.props['Pt'][0] + lo, i.props['Pt'][0] + hi))
check('test-no-overlap', all(spans[k][1] < spans[k + 1][0] for k in range(len(spans) - 1)) and near(spans[0][0], 100.0), str(spans))
check('test-y', all(i.props['Pt'][1] == 50.0 for i in mk.inserts))

if VERBOSE or fails:
    for c in clamped: print('  note:', c)
print(f'{len(rows_py)} data rows; {len(clamped)} geometry notes (clamps)')
if fails:
    print(f'FAILED {len(fails)}'); [print('  ' + f) for f in fails[:60]]; sys.exit(1)
print('OK test_med3dfittings')

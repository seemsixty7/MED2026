"""Shared mock for the MED3DFittings desk tests: lispmini + a small block / solid /
insert model (no AutoCAD). Used by test_med3dfittings.py and test_med3dbodies.py."""
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
        self.sql = None; self.settings = None; self.queries = []; self.ms_solids = []
        g = L.g
        g.update({
            'STRCASE': lambda s, lo=None: s.lower() if lo else s.upper(),
            'SUBSTR': lambda s, i, n=None: s[i - 1:] if n is None else s[i - 1:i - 1 + n],
            'STRLEN': lambda s: len(s), 'CHR': chr, 'ASCII': lambda s: ord(s[0]) if s else 0, 'ATOF': autolisp_atof, 'ATOI': lambda s: int(autolisp_atof(s)),
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
            'VLA-ITEM': self.item, 'VLAX-GET': lambda o, p: o.props.get(str(p).upper().capitalize(), ''),
            'VLA-GET-LAYER': lambda o: o.props.get('Layer', '0'),
            'VLA-STARTUNDOMARK': lambda d: None, 'VLA-ENDUNDOMARK': lambda d: None,
            'PRINC': self.princ, 'TRANS': lambda p, a, b, *d: list(p),
            'VLAX-VLA-OBJECT->ENAME': lambda o: o, 'GETVAR': lambda n: [1.0, 0.0, 0.0] if n.upper() == 'UCSXDIR' else 0,
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
    def put(self, o, prop, v):
        k = str(prop).upper().capitalize()
        if isinstance(o, Obj) and o.kind == 'BLOCK' and k == 'Name':
            self.blocks.pop(o.props['Name'].upper(), None); self.blocks[v.upper()] = o
        o.props[k] = v; return None
    def item(self, coll, name):
        if coll == 'BLOCKS' and name.upper() in self.blocks: return self.blocks[name.upper()]
        raise Exception('no item ' + name)
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
        if obj == 'MS' and m == 'ADDCYLINDER':
            c, r, h = a
            s = Obj('3DSOLID', 'MS', [('CYL', [c[0], c[1], c[2] - h / 2], [c[0], c[1], c[2] + h / 2], r)])
            self.ms_solids.append(s); return s
        if isinstance(obj, Obj) and obj.kind == 'INSERT' and m == 'ROTATE3D':
            obj.props.setdefault('Rot3D', []).append((list(a[0]), list(a[1]), a[2])); return None
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


"""Minimal AutoCAD mock for lispmini: entity table, trans (arbitrary axis
algorithm), entmake/entget/entnext/entlast, and the ActiveX / command calls
MED3DPath.lsp makes (AddRegion, AddLine, AddExtrudedSolidAlongPath,
AddExtrudedSolid, AddRevolvedSolid, AddSphere, Boolean, Move, GetBoundingBox,
Centroid, _.SWEEP, _.EXTRUDE _Direction). Solids keep their exact parts so the
test can compare them with the plan."""
import math, fnmatch
from lispmini import Sym, Pair, car, cdr, aslist

def v_add(a, b): return [x + y for x, y in zip(a, b)]
def v_sub(a, b): return [x - y for x, y in zip(a, b)]
def v_mul(a, s): return [x * s for x in a]
def v_dot(a, b): return sum(x * y for x, y in zip(a, b))
def v_cross(a, b): return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]
def v_unit(a):
    l = math.sqrt(v_dot(a, a)); return v_mul(a, 1.0 / l)
def rot(v, k, th):
    return v_add(v_add(v_mul(v, math.cos(th)), v_mul(v_cross(k, v), math.sin(th))), v_mul(k, v_dot(k, v) * (1 - math.cos(th))))

def ocs_axes(n):
    n = v_unit(n)
    if abs(n[0]) < 1/64 and abs(n[1]) < 1/64: ax = v_unit(v_cross([0, 1, 0], n))
    else: ax = v_unit(v_cross([0, 0, 1], n))
    return ax, v_cross(n, ax), n
def wcs2ocs(p, n):
    ax, ay, az = ocs_axes(n); return [v_dot(p, ax), v_dot(p, ay), v_dot(p, az)]
def ocs2wcs(p, n):
    ax, ay, az = ocs_axes(n); p = list(p) + [0.0] * (3 - len(p))
    return v_add(v_add(v_mul(ax, p[0]), v_mul(ay, p[1])), v_mul(az, p[2]))

def dxf(ed, code):
    for it in aslist(ed):
        if car(it) == code: return cdr(it)
    return None

class CatchErr:
    def __init__(self, msg): self.msg = msg
class SafeArray:
    def __init__(self, l): self.l = l

class Ent:
    n = 0
    def __init__(self, typ, ed=None, geom=None):
        Ent.n += 1; self.id = Ent.n; self.typ = typ; self.ed = ed; self.geom = geom or {}
        self.deleted = False; self.xdata = {}
    def __repr__(self): return f'<{self.typ}#{self.id}>'

class Mock:
    def __init__(self, interp, extrude_semantics='normal', od=1.163):
        self.L = interp; self.ents = []; self.log = []; self.stamps = []; self.errors = []
        # failure model: 'ball' = AddRevolvedSolid about a non-vertical axis revolves
        # the profile about its own diameter (gives a ball at the bend start)
        self.revolve_model = 'exact'
        self.extrude_semantics = extrude_semantics; self.od = od
        self.vars = {'OSMODE': 39, 'CMDECHO': 1, 'CLAYER': '0', 'CMDACTIVE': 0}
        g = interp.g
        g['_CONDUIT'] = 'MED_CONDUIT'; g['_CABLE'] = 'MED_CABLE'
        B = {
            'ENTMAKE': self.entmake, 'ENTLAST': self.entlast, 'ENTGET': self.entget, 'ENTNEXT': self.entnext,
            'ENTDEL': self.entdel, 'TRANS': self.trans, 'VLAX-ENAME->VLA-OBJECT': lambda e: e,
            'VLAX-VLA-OBJECT->ENAME': lambda e: e, 'VLA-DELETE': self.vdel, 'VLA-PUT-LAYER': lambda o, l: None,
            'VLAX-GET-ACAD-OBJECT': lambda: 'ACAD', 'VLA-GET-ACTIVEDOCUMENT': lambda a: 'DOC',
            'VLA-GET-MODELSPACE': lambda d: 'MS', 'VLAX-INVOKE': self.invoke, 'VLAX-GET': self.vget,
            'VLA-GETBOUNDINGBOX': self.bbox_out, 'VLAX-SAFEARRAY->LIST': lambda sa: list(sa.l),
            'VL-CATCH-ALL-APPLY': self.catch_apply, 'VL-CATCH-ALL-ERROR-P': lambda x: True if isinstance(x, CatchErr) else None,
            'VL-CATCH-ALL-ERROR-MESSAGE': lambda x: x.msg, 'COMMAND': self.command, 'VL-CMDF': self.command,
            'GETVAR': lambda n: self.vars.get(n.upper()), 'SETVAR': self.setvar, 'TBLSEARCH': lambda t, n: True,
            'XDATAGET': lambda e, app: e.xdata.get(app), 'MED_CONDUIT_OD': lambda c, s: self.od,
            'MEDSTAMP3DFROMBOM': lambda s, e, k, l: self.stamps.append((s, e, k)),
            'MEDREBUILDMEDPROPSJSONBESIDE': lambda p: None, 'MED-DOTNET-READY': lambda: None,
            'GETCOLORNUMBER': lambda c: 3, 'PRINC': self.princ, 'STRCASE': lambda s, lo=None: s.lower() if lo else s.upper(),
            'WCMATCH': lambda s, pat: True if any(fnmatch.fnmatch(s, p) for p in pat.split(',')) else None,
            'ATOF': float, 'ATOI': int,
            'RTOS': lambda x, m=2, p=4: f'{x:.{p}f}',
        }
        g.update(B)

    # ---------------- entities
    def princ(self, *a):
        if a and isinstance(a[0], str): self.log.append(a[0])
        return a[0] if a else None
    def setvar(self, n, v): self.vars[n.upper()] = v; return v
    def entmake(self, ed):
        typ = dxf(ed, 0)
        e = Ent(typ, ed); self.ents.append(e); return ed
    def entlast(self):
        for e in reversed(self.ents):
            if not e.deleted and e.typ not in ('VERTEX', 'SEQEND', 'LAYER'): return e
        return None
    def entget(self, e):
        if e is None or e.deleted: return None
        if e.ed is None: return [Pair(-1, e), Pair(0, e.typ), Pair(5, f'H{e.id}')]
        return [Pair(-1, e), Pair(5, f'H{e.id}')] + [it for it in e.ed]
    def entnext(self, e):
        i = self.ents.index(e)
        return self.ents[i + 1] if i + 1 < len(self.ents) else None
    def entdel(self, e): e.deleted = not e.deleted; return e
    def vdel(self, e): e.deleted = True; return None
    def normal_of(self, sys):
        if sys in (0, 1): return None
        if isinstance(sys, Ent):
            n = dxf(sys.ed, 210); return list(n) if n else [0.0, 0.0, 1.0]
        return list(sys)
    def trans(self, p, frm, to, disp=None):
        p = [float(c) for c in p] + [0.0] * (3 - len(p))
        n = self.normal_of(frm); w = p if n is None else ocs2wcs(p, n)
        n = self.normal_of(to); return w if n is None else wcs2ocs(w, n)

    # ---------------- geometry of mock solids
    def new_solid(self, parts):
        s = Ent('3DSOLID', None, {'parts': parts}); self.ents.append(s); return s
    def circle_geom(self, c):
        n = dxf(c.ed, 210) or [0, 0, 1]
        return ocs2wcs(dxf(c.ed, 10), n), dxf(c.ed, 40), v_unit(list(n))
    def invoke(self, obj, meth, *a):
        m = meth.upper()
        if m == 'ADDREGION':
            c = a[0][0]; ctr, r, n = self.circle_geom(c)
            reg = Ent('REGION', None, {'center': ctr, 'r': r, 'n': n}); self.ents.append(reg); return [reg]
        if m == 'ADDLINE':
            ln = Ent('LINE', None, {'a': list(a[0]), 'b': list(a[1])}); self.ents.append(ln); return ln
        if m == 'ADDEXTRUDEDSOLIDALONGPATH':
            reg, ln = a; g = reg.geom
            if ln.typ == 'ARC':
                n = v_unit(list(dxf(ln.ed, 210) or [0, 0, 1])); oc = list(dxf(ln.ed, 10)) + [0.0] * 3
                R = dxf(ln.ed, 40); sa = dxf(ln.ed, 50); ea = dxf(ln.ed, 51)
                sw = (ea - sa) % (2 * math.pi)
                st = ocs2wcs([oc[0] + R * math.cos(sa), oc[1] + R * math.sin(sa), oc[2]], n); cw = ocs2wcs(oc[:3], n)
                tn = v_unit(v_cross(n, v_sub(st, cw)))
                if abs(abs(v_dot(g['n'], tn)) - 1) > 1e-9: self.errors.append('AlongPath(ARC) profile not perpendicular to arc start')
                if math.dist(g['center'], st) > 1e-6 * max(1, max(map(abs, st))): self.errors.append('AlongPath(ARC) profile not at arc start')
                return self.new_solid([('TOR', st, cw, n, sw, g['r'])])
            dd = v_unit(v_sub(ln.geom['b'], ln.geom['a']))
            if abs(abs(v_dot(g['n'], dd)) - 1) > 1e-9: self.errors.append('AlongPath profile not perpendicular to path')
            if math.dist(g['center'], ln.geom['a']) > 1e-6 * max(1, max(map(abs, g['center']))): self.errors.append('AlongPath profile not at path start')
            return self.new_solid([('CYL', g['center'], v_add(g['center'], v_sub(ln.geom['b'], ln.geom['a'])), g['r'])])
        if m == 'ADDEXTRUDEDSOLID':
            reg, h, taper = a; g = reg.geom
            d = g['n'] if self.extrude_semantics == 'normal' else [0.0, 0.0, 1.0]
            return self.new_solid([('CYL', g['center'], v_add(g['center'], v_mul(d, h)), g['r'])])
        if m == 'ADDREVOLVEDSOLID':
            reg, c, ax, th = a; g = reg.geom; axu = v_unit(list(ax))
            if abs(v_dot(g['n'], axu)) > 1e-9 or abs(v_dot(v_sub(g['center'], list(c)), axu)) > 1e-6: self.errors.append('revolve axis not in profile plane')
            if self.revolve_model == 'ball' and abs(axu[2]) < 0.999:
                return self.new_solid([('SPH', g['center'], g['r'])])
            return self.new_solid([('TOR', g['center'], list(c), v_unit(list(ax)), th, g['r'])])
        if m == 'ADDSPHERE':
            return self.new_solid([('SPH', list(a[0]), a[1])])
        if m == 'BOOLEAN':
            other = a[1]; obj.geom['parts'] += other.geom['parts']; other.deleted = True; return None
        if m == 'MOVE':
            d = v_sub(a[1], a[0]); obj.geom['parts'] = [self.move_part(p, d) for p in obj.geom['parts']]; return None
        raise Exception(f'mock: unknown method {meth}')
    def move_part(self, p, d):
        if p[0] == 'CYL': return ('CYL', v_add(p[1], d), v_add(p[2], d), p[3])
        if p[0] == 'TOR': return ('TOR', v_add(p[1], d), v_add(p[2], d), p[3], p[4], p[5])
        return ('SPH', v_add(p[1], d), p[2])
    def samples(self, p):
        pts = []
        if p[0] == 'SPH':
            for i in range(3):
                for s in (-1, 1):
                    q = list(p[1]); q[i] += s * p[2]; pts.append(q)
            return pts
        if p[0] == 'CYL':
            a, b, r = p[1], p[2], p[3]; d = v_unit(v_sub(b, a)); axes = [a, b]
            u = v_unit(v_cross(d, [1, 0, 0] if abs(d[0]) < 0.9 else [0, 1, 0])); w = v_cross(d, u)
            for q in axes:
                for k in range(64):
                    t = 2 * math.pi * k / 64
                    pts.append(v_add(q, v_add(v_mul(u, r * math.cos(t)), v_mul(w, r * math.sin(t)))))
            return pts
        a, c, ax, th, r = p[1], p[2], p[3], p[4], p[5]
        for i in range(65):
            q = v_add(c, rot(v_sub(a, c), ax, th * i / 64))
            tn = v_unit(v_cross(ax, v_sub(q, c))); u = v_unit(v_sub(q, c)); w = v_cross(tn, u)
            for k in range(32):
                t = 2 * math.pi * k / 32
                pts.append(v_add(q, v_add(v_mul(u, r * math.cos(t)), v_mul(w, r * math.sin(t)))))
        return pts
    def bbox(self, obj):
        pts = [q for p in obj.geom['parts'] for q in self.samples(p)]
        return [min(q[i] for q in pts) for i in range(3)], [max(q[i] for q in pts) for i in range(3)]
    def bbox_out(self, obj, mn, mx):
        lo, hi = self.bbox(obj); self.L.set(mn, SafeArray(lo)); self.L.set(mx, SafeArray(hi)); return None
    def vget(self, obj, prop):
        if prop.upper() == 'CENTROID':
            pts = [q for p in obj.geom['parts'] for q in self.samples(p)]
            return [sum(q[i] for q in pts) / len(pts) for i in range(3)]
        raise Exception('mock: unknown property')
    def catch_apply(self, f, args):
        try: return self.L.apply(f, list(aslist(args)))
        except Exception as ex: return CatchErr(str(ex))
    def command(self, *a):
        a = list(a)
        if not a: return None
        c = str(a[0]).upper()
        if c == '_.SWEEP':
            ents = [x for x in a if isinstance(x, Ent)]
            circ, path = ents[0], ents[1]
            s = self.new_solid([]); s.geom['sweep'] = (list(circ.ed), list(path.ed)); return None
        if c == '_.EXTRUDE':
            circ = a[1]; ctr, r, n = self.circle_geom(circ); p1, p2 = a[4], a[5]
            if abs(abs(v_dot(n, v_unit(v_sub(p2, p1)))) - 1) > 1e-9: self.errors.append('EXTRUDE profile not perpendicular')
            self.new_solid([('CYL', ctr, v_add(ctr, v_sub(p2, p1)), r)]); return None
        return None

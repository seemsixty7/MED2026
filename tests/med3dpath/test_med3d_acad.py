"""Entity-level desk test for Support/MED3DPath.lsp with a mock AutoCAD
(tests/med3dpath/acadmock.py): real LWPOLYLINE / 2D POLYLINE / 3D POLYLINE DXF
with OCS normals and elevations -> med3d-run -> the solids / SWEEP path the code
builds are compared with the plan computed independently from WCS points.
Usage: python3 tests/med3dpath/test_med3d_acad.py [-v]"""
import math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from lispmini import Interp, Sym, Pair, car, cdr, to_py
import acadmock as M
from acadmock import v_add, v_sub, v_mul, v_dot, v_cross, v_unit, rot, ocs2wcs, wcs2ocs, dxf

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
LSP = os.path.join(ROOT, 'Support', 'MED3DPath.lsp')
VERBOSE = '-v' in sys.argv
fails = []
def check(name, cond, msg=''):
    if not cond: fails.append(f'{name}: {msg}')
def dist(a, b): return math.sqrt(v_dot(v_sub(a, b), v_sub(a, b)))
def close(a, b, tol=1e-6): return dist(a, b) < tol * max(1.0, max(abs(c) for c in list(a) + list(b)))
def get(alist, key):
    for it in alist or []:
        if car(it) == key: return cdr(it)
    return None

def session(lsp=LSP, semantics='normal', method='PIECES'):
    L = Interp(); mk = M.Mock(L, semantics); L.load(lsp)
    L.g['*MED3D-METHOD*'] = method; L.g['*MED3D-DEBUG*'] = True
    return L, mk

# ---------------------------------------------------------- entity builders
def lw(mk, ocs_pts, buls, n, elev, closed=False):
    ed = [Pair(0, 'LWPOLYLINE'), Pair(100, 'AcDbEntity'), Pair(8, 'E-COND'), Pair(100, 'AcDbPolyline'),
          Pair(90, len(ocs_pts)), Pair(70, 1 if closed else 0), Pair(38, float(elev))]
    for p, b in zip(ocs_pts, buls): ed += [[10, float(p[0]), float(p[1])], Pair(42, float(b))]
    ed.append([210] + [float(c) for c in n]); mk.entmake(ed); e = mk.ents[-1]
    e.xdata['MED_CONDUIT'] = ['MED_CONDUIT', 'C1', '1', 3]; return e

def heavy(mk, ocs_pts, buls, n, elev, flag=0, closed=False):
    mk.entmake([Pair(0, 'POLYLINE'), Pair(8, 'E-COND'), Pair(66, 1), [10, 0.0, 0.0, float(elev)],
                Pair(70, flag | (1 if closed else 0)), [210] + [float(c) for c in n]])
    e = mk.ents[-1]
    for p, b in zip(ocs_pts, buls):
        z = float(p[2]) if len(p) > 2 else float(elev)
        mk.entmake([Pair(0, 'VERTEX'), Pair(8, 'E-COND'), [10, float(p[0]), float(p[1]), z],
                    Pair(42, float(b)), Pair(70, 32 if flag & 8 else 0)])
    mk.entmake([Pair(0, 'SEQEND'), Pair(8, 'E-COND')])
    e.xdata['MED_CONDUIT'] = ['MED_CONDUIT', 'C2', '1', 3]; return e

# ------------------------------------------------------------ expectations
def expected_plan(L, wpts, buls, n, closed):
    return L.apply(Sym('MED3D-PLAN'), [wpts, buls, v_unit(n) if n else None, True if closed else None,
                                       1.163, 'CONDUIT', None])

def same_pieces(name, got, exp):
    check(name, len(got) == len(exp), f'{len(got)} pieces vs {len(exp)} expected')
    for i, (g, x) in enumerate(zip(got, exp)):
        check(name, g[0] == x[0], f'piece {i} type {g[0]} vs {x[0]}')
        if g[0] == 'S': check(name, close(g[1], x[1]), f'sphere {i} at {g[1]} vs {x[1]}')
        else: check(name, close(g[1], x[1]) and close(g[2], x[2]), f'piece {i} {g[1]}->{g[2]} vs {x[1]}->{x[2]}')

def check_solids(name, mk, sol_ent, pieces, r):
    parts = sol_ent.geom['parts']
    check(name, len(parts) == len(pieces), f'{len(parts)} solid parts vs {len(pieces)} pieces')
    for i, (s, p) in enumerate(zip(parts, pieces)):
        if p[0] == 'L':
            ok = s[0] == 'CYL' and close(s[1], p[1], 1e-5) and close(s[2], p[2], 1e-5) and abs(s[3] - r) < 1e-9
            check(name, ok, f'straight {i}: solid {s[0]} {s[1]}->{s[2]} vs plan {p[1]}->{p[2]}')
        elif p[0] == 'A':
            ok = s[0] == 'TOR' and close(s[1], p[1], 1e-5) and close(s[2], p[3], 1e-5)
            if ok:
                end = v_add(s[2], rot(v_sub(s[1], s[2]), s[3], s[4]))
                ok = close(end, p[2], 1e-5)
            check(name, ok, f'bend {i}: solid {s} vs plan {p[1]}->{p[2]} c {p[3]}')
        else:
            check(name, s[0] == 'SPH' and close(s[1], p[1]), f'sphere {i}')
    check(name, not mk.errors, '; '.join(mk.errors))

def decode_lw(ed):
    n = list(dxf(ed, 210)); elev = dxf(ed, 38); pts = []; buls = []
    for it in ed:
        if car(it) == 10: pts.append([it[1], it[2], elev]); buls.append(0.0)
        elif car(it) == 42: buls[-1] = cdr(it)
    return n, pts, buls, dxf(ed, 70) & 1

def check_sweep(name, sol_ent, pieces, r):
    circ, path = sol_ent.geom['sweep']
    n, opts, buls, closed = decode_lw(path)
    w = [ocs2wcs(p, n) for p in opts]
    real = pieces
    check(name, len(w) == len(real) + (0 if closed else 1), f'{len(w)} path vertices for {len(real)} pieces')
    for i, p in enumerate(real):
        q = opts[(i + 1) % len(opts)]
        check(name, close(w[i], p[1], 1e-6), f'path vertex {i} {w[i]} vs piece start {p[1]}')
        check(name, close(ocs2wcs(q, n), p[2], 1e-6), f'path vertex {i+1} vs piece end {p[2]}')
        b = buls[i]
        if p[0] == 'L': check(name, abs(b) < 1e-12, f'bulge {i} {b} on a straight')
        else:
            th = 4 * math.atan(b); p0 = opts[i]; d = v_sub(q, p0); ch = math.hypot(d[0], d[1])
            perp = [-d[1] / ch, d[0] / ch, 0.0]
            c = v_add(v_mul(v_add(p0, q), 0.5), v_mul(perp, (ch / 2) / math.tan(th / 2)))
            check(name, abs(abs(th) - p[5]) < 1e-9, f'bulge {i} angle {th} vs {p[5]}')
            check(name, close(ocs2wcs(c, n), p[3], 1e-6), f'bulge {i} centre {ocs2wcs(c, n)} vs {p[3]}')
    cn = dxf(circ, 210); cc = ocs2wcs(dxf(circ, 10), cn)
    p0 = pieces[0]
    tn = v_unit(v_sub(p0[2], p0[1])) if p0[0] == 'L' else v_unit(v_cross(p0[4], v_sub(p0[1], p0[3])))
    check(name, close(cc, p0[1]), f'profile centre {cc} vs run start {p0[1]}')
    check(name, abs(abs(v_dot(v_unit(list(cn)), tn)) - 1) < 1e-9, 'profile not perpendicular to start tangent')
    check(name, abs(dxf(circ, 40) - r) < 1e-12, 'profile radius')

# --------------------------------------------------------------------- cases
def run_case(name, build, method='PIECES', expect_method=None, lsp=LSP, semantics='normal', quiet=False):
    """build(mk) -> (ent, wcs_pts, buls, normal_or_None, closed)"""
    L, mk = session(lsp, semantics, method)
    ent, wpts, wb, n, closed = build(mk)
    res = L.apply(Sym('MED3D-RUN'), [ent, 'CONDUIT'])
    nfail = len(fails)
    check(name, res, 'med3d-run returned nil')
    if not res: return mk
    sol, plan = res[0], res[1]
    pieces = to_py(get(plan, 'PIECES'))
    exp = to_py(get(expected_plan(L, wpts, wb, n, closed), 'PIECES'))
    same_pieces(name, pieces, exp)
    r = 1.163 / 2
    swept = 'sweep' in sol.geom
    if expect_method: check(name, (expect_method == 'SWEEP') == swept, f'expected {expect_method}, got {"SWEEP" if swept else "PIECES"}')
    if swept: check_sweep(name, sol, pieces, r)
    else: check_solids(name, mk, sol, pieces, r)
    status = 'ok' if len(fails) == nfail else 'FAIL'
    if not quiet: print(f'{status:4} {name}  [{("SWEEP" if swept else "PIECES")}, {len(pieces)} pieces]')
    if VERBOSE: print('     ' + ''.join(mk.log).replace('\n', '\n     '))
    return mk

def pts_ocs_to_wcs(opts, n, elev): return [ocs2wcs([p[0], p[1], elev], n) for p in opts]

OCS = [[0, 0], [120, 0], [120, 96], [300, 96]]
BUL = [0, 0, 0, 0]
ARCS = [[0, 0], [100, 0], [140, 40], [140, 150]]
ARCB = [0, 0.41421356, 0, 0]   # 90 deg bulge on 2nd segment

def mk_lw(opts, buls, n, elev, closed=False):
    return lambda mk: (lw(mk, opts, buls, n, elev, closed), pts_ocs_to_wcs(opts, n, elev), [float(b) for b in buls], n, closed)
def mk_heavy(opts, buls, n, elev, closed=False):
    return lambda mk: (heavy(mk, opts, buls, n, elev, 0, closed), pts_ocs_to_wcs(opts, n, elev), [float(b) for b in buls], n, closed)
def mk_3d(wpts, closed=False):
    return lambda mk: (heavy(mk, wpts, [0] * len(wpts), [0, 0, 1], 0, 8, closed), [[float(c) for c in p] for p in wpts], [0.0] * len(wpts), None, closed)

BIG = [[1.25e6 + x, 8.3e5 + y] for x, y in OCS]
OBL = v_unit([0.3, -0.6, 0.74])
CASES = [
    ('LW normal +Z elev 120', mk_lw(OCS, BUL, [0, 0, 1], 120)),
    ('LW normal -Z elev 10 (mirrored)', mk_lw(OCS, BUL, [0, 0, -1], 10)),
    ('LW oblique normal with bulge', mk_lw(ARCS, ARCB, OBL, 25)),
    ('LW large coordinates', mk_lw(BIG, BUL, [0, 0, 1], 0)),
    ('LW closed loop', mk_lw([[0, 0], [200, 0], [200, 150], [0, 150]], [0] * 4, [0, 0, 1], 5, True)),
    ('2D heavy +Z elev 60 with bulge', mk_heavy(ARCS, ARCB, [0, 0, 1], 60)),
    ('2D heavy -Z elev 60 with bulge', mk_heavy(ARCS, ARCB, [0, 0, -1], 60)),
    ('2D heavy normal +X (vertical plane)', mk_heavy(OCS, BUL, [1, 0, 0], 30)),
    ('3D sloped', mk_3d([[0, 0, 100], [120, 0, 100], [120, 96, 60], [300, 96, 60], [300, 200, 140]])),
    ('3D planar vertical', mk_3d([[0, 50, 0], [120, 50, 0], [120, 50, 96], [300, 50, 96]])),
]
# Clint's 4a1d703 test shape: lead-in, then a tilted triangle loop with long legs
LA, LB, LC = [1200, 0, 120], [3600, 400, 240], [2000, 2600, 60]
LOOP = [[0, -48, 120], LA, LB, LC, LA]
JOG = 0.05   # near-duplicate vertex (vertical jog) at every corner
LOOP_JOG = [LOOP[0]] + [q for p in LOOP[1:] for q in (p, [p[0], p[1], p[2] + JOG])]
CASES += [
    ('3D lead-in + tilted triangle loop (back to A)', mk_3d(LOOP)),
    ('3D tilted triangle loop, closed flag', mk_3d(LOOP[1:4], True)),
    ('3D loop with 0.05 jogs at corners', mk_3d(LOOP_JOG)),
]
def jog_clean(mk):   # expectation for the jog case: the jog vertices are gone
    e, w, b, n, c = mk_3d(LOOP_JOG)(mk); return e, [[float(x) for x in p] for p in LOOP], [0.0] * len(LOOP), n, c

if __name__ == '__main__':
    print('--- PIECES (ActiveX), AddExtrudedSolid-free straights')
    for nm, b in CASES: run_case(nm + ' / pieces', b, 'PIECES')
    print('--- PIECES with AlongPath broken -> _.EXTRUDE _Direction fallback')
    for nm, b in CASES[:3] + CASES[8:9]:
        L0 = None
        def broken(mk, b=b):
            orig = mk.invoke
            def inv(obj, meth, *a):
                if meth.upper() == 'ADDEXTRUDEDSOLIDALONGPATH': raise Exception('mock: AlongPath refused')
                return orig(obj, meth, *a)
            mk.invoke = inv; mk.L.g['VLAX-INVOKE'] = inv
            return b(mk)
        run_case(nm + ' / EXTRUDE fallback', broken, 'PIECES')
    print('--- 3D loop (Clint 4a1d703): corners must all be FITTED bends, no spheres')
    for nm, bld in [(CASES[10][0], CASES[10][1]), (CASES[11][0], CASES[11][1]), ('3D loop with jogs (jog vertices dropped)', jog_clean)]:
        for model in ('exact', 'ball'):
            def with_model(mk, bld=bld, model=model):
                mk.revolve_model = model; return bld(mk)
            mk = run_case(f'{nm} / revolve {model}', with_model, 'PIECES')
            if mk.log and any('FLAG' in l or 'sphere' in l for l in mk.log): check(nm, False, 'flag/sphere reported')
    print('--- SWEEP')
    for nm, b in CASES:
        exp = 'PIECES' if nm.startswith(('3D sloped', '3D lead-in', '3D loop with')) else 'SWEEP'   # non-planar
        run_case(nm + ' / sweep', b, 'SWEEP', exp)
    # c0c08c2 demonstration (informational, not a failure of the new code)
    old = os.path.join(os.path.dirname(__file__), 'old_c0c08c2.lsp')
    if os.path.exists(old):
        print('--- c0c08c2 med3d-solid-line under "extrude along WCS Z" semantics (demo)')
        keep = list(fails)
        run_case('c0c08c2 2D heavy +Z', mk_heavy(OCS, BUL, [0, 0, 1], 60), 'PIECES', lsp=old, semantics='wcsz')
        demo = fails[len(keep):]; del fails[len(keep):]
        for f in demo: print('     ' + f)
    old4 = os.path.join(os.path.dirname(__file__), 'old_4a1d703.lsp')
    if os.path.exists(old4):
        print('--- 4a1d703 on the 3D loop (demo of the two ways to get balls at every corner)')
        keep = list(fails)
        for nm, bld, model, extra in [('4a1d703 loop, revolve ball model', CASES[10][1], 'ball', None),
                                      ('4a1d703 loop with 0.05 jogs', jog_clean, 'exact', None)]:
            def with_model(mk, bld=bld, model=model):
                mk.revolve_model = model; return bld(mk)
            mk = run_case(nm, with_model, 'PIECES', lsp=old4, quiet=True)
            got = fails[len(keep):]; del fails[len(keep):]
            print(f'     {nm}: {len(got)} mismatch(es); ' + (got[0][:150] if got else ''))
            print('       ' + ' | '.join(l.strip() for l in mk.log if 'FLAG' in l or 'box wrong' in l)[:300])
    print(f'\n{len(fails)} failure(s)')
    for f in fails: print('  ' + f)
    sys.exit(1 if fails else 0)

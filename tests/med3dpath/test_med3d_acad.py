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

# ------------------------------------------------------- MEDMAKE3D harness
class SS:
    def __init__(self, items=None): self.items = list(items or [])
TRAY_LSP = os.path.join(ROOT, 'Support', 'MED3DTrayFunctions.lsp')
FIT_LSP = os.path.join(ROOT, 'Support', 'MED3DFittings.lsp')

def make3d_session(fmt, tray_file=False):
    """Mock drawing with 1 good + 1 no-OD conduit run, 1 cable run; the tray worker
    is a stub that makes 2 tray + 1 fitting solids and reports one skipped fitting."""
    L, mk = session()
    if tray_file: L.load(TRAY_LSP)
    L.load(FIT_LSP)           # conduit bodies stage (no MED_FITTING inserts here -> no bodies)
    L.g['*MED3D-DEBUG*'] = None
    calls, cmds, sidecars, tray_sols = [], [], [], []
    def ssget(*a):
        if not a or a[0] != '_X' and a[0] != 'x' and a[0] != 'X': return None
        flt = a[-1]; app = None; typ = None
        for it in flt or []:
            if isinstance(it, list) and it and it[0] == -3: app = it[1][0]
            if isinstance(it, Pair) and it.car == 0 and it.cdr == '3DSOLID': typ = '3DSOLID'
            if isinstance(it, Pair) and it.car == 8 and typ is None and app is None: return None   # flag layer
        if app:
            got = [e for e in mk.ents if not e.deleted and app in e.xdata]
        elif typ:
            got = [e for e in mk.ents if not e.deleted and e.typ == '3DSOLID']
        else: return None
        return SS(got) if got else None
    def tray_build():
        calls.append(('TRAY',))
        for _ in range(3): tray_sols.append(mk.new_solid([]))
        mk.command('UCS', '')
        return [tray_sols[:2], tray_sols[2:], [['FIT9', 'FITTING', 'no solid created (not an elbow / tee / cross / reducer outline)']]]
    real_run = L.g['MED3D-PATH-BUILD-ALL']
    def build_all(kind):
        calls.append((kind,)); return L.apply(real_run, [kind])
    def command(*a):
        cmds.append(list(a)); return mk.command(*a)
    L.g.update({
        'SSGET': ssget, 'SSNAME': lambda ss, i: ss.items[i] if i < len(ss.items) else None,
        'SSLENGTH': lambda ss: len(ss.items), 'SSADD': lambda e=None, ss=None: (ss.items.append(e) or ss) if ss else SS(),
        'INITGET': lambda *a: None, 'GETKWORD': lambda p: fmt, 'GETFILED': lambda *a: 'C:/proj/combined.dwg',
        'FINDFILE': lambda f: f, 'SMLAYER': lambda li: None, 'COMMAND': command, 'VL-CMDF': command,
        'MEDREBUILDMEDPROPSJSONBESIDE': lambda p: sidecars.append(p), 'MED3D-TRAY-BUILD': tray_build,
        'MED3D-PATH-BUILD-ALL': build_all, 'ARXLOAD': lambda *a: None, 'PROMPT': mk.princ,
        '_MED3DTRAY': ['MED_3DTRAY', 'BLUE', 'CONTINUOUS'], '*ERROR*': 'ORIG-ERR',
        'MED3D-CABLEOD-CACHE*': None,
    })
    # med3d-begin clears the OD caches, so give cable code 3 an OD through the lookup
    L.g['MED3D-CABLE-OD'] = lambda code: 0.5 if code == 3 else None
    ods = {'1': 1.163}
    L.g['MED_CONDUIT_OD'] = lambda c, sz: ods.get(f'{sz:g}') if isinstance(sz, float) else ods.get(str(sz))
    L.g['MED3D-PRELOAD-OD'] = lambda kind: None
    e = lw(mk, OCS, BUL, [0, 0, 1], 0)                                   # conduit, OD found
    e = lw(mk, OCS, BUL, [0, 0, 1], 0); e.xdata['MED_CONDUIT'] = ['MED_CONDUIT', 'C9', '7', 3]   # no OD
    e = lw(mk, OCS, BUL, [0, 0, 1], 0); del e.xdata['MED_CONDUIT']
    e.xdata['MED_CABLE'] = ['MED_CABLE', 'K1', '1', 3]                   # cable
    return L, mk, calls, cmds, sidecars, tray_sols

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
    print('--- cable run: bend radius 7 x OD')
    L, mk = session()
    e = lw(mk, OCS, BUL, [0, 0, 1], 0); e.xdata['MED_CABLE'] = ['MED_CABLE', 'K1', '1', 3]
    L.g['*MED3D-CABLEOD-CACHE*'] = [Pair(3, 0.5)]
    res = L.apply(Sym('MED3D-RUN'), [e, 'CABLE'])
    rc = get(res[1], 'R') if res else None
    check('cable R', rc is not None and abs(rc - 3.5) < 1e-12, f'cable R {rc}, expected 7 x 0.5')
    print(f'{"ok  " if rc and abs(rc - 3.5) < 1e-12 else "FAIL"} cable run R = {rc} (OD 0.5)')
    print('--- command ownership (old MED3DCON loaded later) and quiet OD lookups')
    L, mk = session()
    check('banner', any('MED3DPath 2026' in l and 'MAKE3DCONDUIT' in l for l in mk.log), 'no load banner')
    old_fn = lambda: 'OLD 2012'
    L.g['C:MAKE3DCONDUIT'] = old_fn; L.g['C:M3D'] = old_fn          # (load "MED3DCON") 2012 version
    L.apply(Sym('MED3D-LISP-WILL-START'), [None, ['(C:MAKE3DCONDUIT)']])
    check('claim', L.g['C:MAKE3DCONDUIT'] is L.g['MED3D-CMD-MAKE3DCONDUIT'] and L.g['C:M3D'] is L.g['MED3D-CMD-M3D'],
          'old commands not taken back')
    check('claim msg', any('had been redefined' in l for l in mk.log), 'no redefinition message')
    n0 = len(mk.log); L.apply(Sym('MED3D-LISP-WILL-START'), [None, ['(C:MAKE3DCONDUIT)']])
    check('claim quiet', not any('redefined' in l for l in mk.log[n0:]), 'message repeated when nothing changed')
    # OD lookups: one quiet SELECT per command, no per-run queries
    sql = []
    def fake_sql(q):
        sql.append((q, L.g.get('*MED-SQL-QUIET*')))
        if 'MEDConduitOD' in q and 'ConduitCode,' in q:
            return [['ConduitCode', 'TradeSizeDec', 'OD_in'], [3, 1.0, 1.163], [3, 0.75, 0.922]]
        return None
    def fake_conduit_od(code, size):
        key = [int(code), f'{size:.4f}']
        for it in L.g.get('_MEDCONDUITOD_CACHE') or []:
            if car(it) == key: return cdr(it) if cdr(it) else 1.315
        fake_sql('SELECT OD_in FROM MEDConduitOD WHERE ...'); return 1.315
    L.g['MED-DOTNET-READY'] = lambda: True; L.g['MEDPROCESSSQLSTATEMENT'] = fake_sql
    L.g['MED_CONDUIT_OD'] = fake_conduit_od
    L.apply(Sym('MED3D-BEGIN'), ['M3D'])
    ods = []
    for size in ('1', '0.75', '1', '2'):
        e = lw(mk, OCS, BUL, [0, 0, 1], 0); e.xdata['MED_CONDUIT'] = ['MED_CONDUIT', 'C', size, 3]
        ods.append(L.apply(Sym('MED3D-RUN-OD'), [e, 'CONDUIT']))
    L.apply(Sym('MED3D-END'), [])
    check('od values', ods == [1.163, 0.922, 1.163, 1.315], f'ODs {ods}')
    check('one select', len(sql) == 1, f'{len(sql)} SELECTs: {[q for q, _ in sql]}')
    check('quiet', all(qt is True for _, qt in sql), 'SELECT not run with *MED-SQL-QUIET* T')
    check('quiet restored', not L.g.get('*MED-SQL-QUIET*'), '*MED-SQL-QUIET* left set')
    print(f'ok   ownership + OD preload ({len(sql)} SELECT for 4 runs, ODs {ods})' if len(fails) == 0 else 'FAIL ownership / OD preload')
    print('--- MEDMAKE3D orchestration (tray stub -> conduit -> cable, one combined output)')
    for fmt in ('Dwg', 'Layer'):
        n0 = len(fails); mk3 = make3d_session(fmt)
        L, mk, calls, cmds, sidecars, tray_sols = mk3
        L.apply(L.g['C:MEDMAKE3D'], [])
        order = [c[0] for c in calls]
        check(f'make3d {fmt} order', order[:1] == ['TRAY'] and order.index('CONDUIT') < order.index('CABLE'),
              f'stage order {order}')
        wb = [c for c in cmds if str(c[0]).upper() == '_.-WBLOCK']
        sel = [c for c in cmds if c and c[0] == '0,0,0']
        live = [e for e in mk.ents if e.typ == '3DSOLID' and not e.deleted]
        if fmt == 'Dwg':
            check('make3d one wblock', len(wb) == 1 and len(sel) == 1, f'{len(wb)} WBLOCK, {len(sel)} selections')
            got = set(sel[0][1].items) if sel else set()
            check('make3d combined', got == set(live) and all(t in got for t in tray_sols) and len(got) >= 5,
                  f'WBLOCK selection {sorted(e.id for e in got)} vs solids {sorted(e.id for e in live)}')
            check('make3d one sidecar', sidecars == ['C:/proj/combined.dwg'], f'sidecars {sidecars}')
        else:
            check('make3d layer no wblock', not wb, 'WBLOCK in Layer mode')
            check('make3d layer sidecar', sidecars == [None], f'sidecars {sidecars}')
        summary = ' '.join(mk.log[mk.log.index(next(l for l in mk.log if 'MEDMAKE3D summary' in l)):]) \
            if any('MEDMAKE3D summary' in l for l in mk.log) else ''
        for want in ('Tray          : 2', 'Tray fittings : 1', 'Conduit       : 1 solid(s) from 1 of 2',
                     'Cable         : 1 solid(s) from 1 of 1', 'Skipped       : 2', 'FIT9 fitting', 'no OD for this conduit'):
            check(f'make3d {fmt} summary', want in summary, f'missing "{want}" in summary: {summary[:400]}')
        check(f'make3d {fmt} sysvars', mk.vars['OSMODE'] == 39 and mk.vars['CMDECHO'] == 1, f'{mk.vars}')
        check(f'make3d {fmt} error restored', L.g.get('*ERROR*') == 'ORIG-ERR', '*error* not restored')
        print(f'{"ok  " if len(fails) == n0 else "FAIL"} MEDMAKE3D {fmt}: stages {order}, '
              f'{len(wb)} WBLOCK, sidecars {sidecars}')
    # conduit bodies: collect -> *MED3D-FITS* during the conduit stage only -> place -> cable
    n0 = len(fails); L, mk, calls, cmds, sidecars, tray_sols = make3d_session('Layer')
    body = [Pair('HANDLE', 'HB1'), Pair('PT', [1000.0, 1000.0, 0.0]), Pair('SIZE', 1.0),
            Pair('HUBS', [['RUN', [1003.0, 1000.0, 0.0], [1.0, 0.0, 0.0]]])]
    nosize = [Pair('HANDLE', 'HB2'), Pair('PT', [0.0, 0.0, 0.0]), Pair('SIZE', 0.0), Pair('HUBS', None)]
    seen = {}
    real_build = L.g['MED3D-PATH-BUILD-ALL']
    def build_all2(kind):
        seen[kind] = to_py(L.g.get('*MED3D-FITS*')); return real_build(kind)
    ref = mk.new_solid([])
    def place_all(bodies):
        calls.append(('PLACE', len(bodies)))
        return [Pair('REFS', [ref]), Pair('PLACED', 1), Pair('PH', 1), Pair('FLAGGED', 1),
                Pair('SKIPPED', [['HB2', 'FITTING', 'no trade size on the fitting']])]
    L.g.update({'MEDCB-COLLECT': lambda: (calls.append(('COLLECT',)) or [[body, nosize], 3]),
                'MEDCB-PLACE-ALL': place_all, 'MED3D-PATH-BUILD-ALL': build_all2})
    L.apply(L.g['C:MEDMAKE3D'], [])
    order = [c[0] for c in calls]
    check('bodies order', order == ['TRAY', 'COLLECT', 'CONDUIT', 'PLACE', 'CABLE'], f'{order}')
    check('bodies fits', seen.get('CONDUIT') and len(seen['CONDUIT']) == 1 and seen['CONDUIT'][0][0] == 'HB1'
          and not seen.get('CABLE'), f'{seen}')
    check('bodies reset', not L.g.get('*MED3D-FITS*'), '*MED3D-FITS* left set')
    summary = ' '.join(mk.log[mk.log.index(next(l for l in mk.log if 'MEDMAKE3D summary' in l)):])
    for want in ('Conduit bodies: 1 block(s), 1 placeholder(s), 3 fitting(s) not modelled',
                 'Flagged       : 1', 'Skipped       : 3', 'HB2 fitting: no trade size'):
        check('bodies summary', want in summary, f'missing "{want}" in {summary[:500]}')
    print(f'{"ok  " if len(fails) == n0 else "FAIL"} MEDMAKE3D conduit bodies: stages {order}')
    # MAKE3DTRAY goes through the same worker
    n0 = len(fails); L, mk, calls, cmds, sidecars, tray_sols = make3d_session('Dwg', tray_file=True)
    L.apply(L.g['C:MAKE3DTRAY'], [])
    check('make3dtray worker', [c[0] for c in calls] == ['TRAY'], f'calls {calls}')
    check('make3dtray sidecar', sidecars == ['C:/proj/combined.dwg'], f'sidecars {sidecars}')
    print(f'{"ok  " if len(fails) == n0 else "FAIL"} MAKE3DTRAY uses med3d-tray-build ({calls})')
    # the real tray worker: new-solid tracking and skipped fittings
    n0 = len(fails); L, mk, calls, cmds, sidecars, tray_sols = make3d_session('Dwg', tray_file=True)
    trays = [mk.new_solid([]) for _ in range(2)]
    for t in trays: t.typ = 'LWPOLYLINE'; t.xdata['MED_TRAY'] = ['MED_TRAY']
    fits = [mk.new_solid([]) for _ in range(2)]
    for f in fits: f.typ = 'LWPOLYLINE'; f.xdata['MED_FITTING'] = ['MED_FITTING']
    cbody = mk.new_solid([]); cbody.typ = 'INSERT'; cbody.xdata['MED_FITTING'] = ['MED_FITTING']   # conduit body block
    made = []
    def conv(e): s_ = mk.new_solid([]); made.append(s_); return s_
    L.load(TRAY_LSP)          # real med3d-tray-build back (make3d_session stubbed it)
    L.g.update({'MEDSET3DTRAYLAYER': lambda e: None, 'MEDCONVERTTRAYTO3D': conv,
                'MEDCONVERTTRAYFITTINGSTO3D': lambda e: conv(e) if e is fits[0] else None})
    res = L.apply(Sym('MED3D-TRAY-BUILD'), [])
    ok = (res[0] == made[:2] and res[1] == made[2:3] and len(res[2]) == 1 and len(made) == 3
          and res[2][0][0] == f'H{fits[1].id}' and res[2][0][1] == 'FITTING')
    check('tray worker', ok, f'{res}')
    print(f'{"ok  " if len(fails) == n0 else "FAIL"} med3d-tray-build: 2 tray + 1 fitting solid, 1 fitting skipped, conduit-body INSERT left alone')
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

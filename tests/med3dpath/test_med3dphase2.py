"""Desk test for the phase 2 builders of Support/MED3DFittings.lsp (r6): X, LBD, BLB,
LBY, Mogul BT / BC / BUB, GUA L / T / X, and the inline fittings UNY union, EYS / EYD
seals, plugged couplings PLGR / PLGS, conduit / Myers hubs, RE reducer.
  - every data row of those shapes builds: hub names / directions, overall sizes equal
    the published letters, block entities on layer 0 ByLayer (Clint's block rule)
  - oblique cylinders (BUB hubs, LBY cover) after the generalised Rotate3D
  - plan use: RE reduce-to size (#ITEM_ALT, else one size down), GUA side views, 1guat
    offset, union break longer than the union (conduit extended to the faces), the
    MED3DPath hub-axis guard for big break radii, MEDCBALL gallery.
Usage: python3 tests/med3dpath/test_med3dphase2.py [-v]"""
import csv, math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from bodyworld import *

PH2 = ('LBD', 'BLB', 'LBY', 'BT', 'BC', 'BUB', 'GUAL', 'GUAT', 'GUAX', 'UNY', 'EYS', 'EYD', 'PLGR', 'PLGS', 'HUB', 'RE')
X, Y, Z = [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]
def closev(a, b, tol=1e-6): return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b))) <= tol
def neg(v): return [-c if c else 0.0 for c in v]
DIRS = {'LBD': {'RUN': X, 'BACK': neg(Z)}, 'BLB': {'RUN': X, 'BACK': neg(Z)}, 'LBY': {'RUN': X, 'BACK': neg(Z)},
        'BT': {'RUN': X, 'RUN2': neg(X), 'BRANCH': Y}, 'BC': {'RUN': X, 'RUN2': neg(X)}, 'BUB': {'RUN': X, 'RUN2': neg(X)},
        'GUAL': {'RUN': X, 'BRANCH': Y}, 'GUAT': {'RUN': X, 'RUN2': neg(X), 'BRANCH': Y},
        'GUAX': {'RUN': X, 'RUN2': neg(X), 'BRANCH': Y, 'BRANCH2': neg(Y)},
        'UNY': {'RUN': X, 'RUN2': neg(X)}, 'EYS': {'RUN': X, 'RUN2': neg(X)}, 'EYD': {'RUN': X, 'RUN2': neg(X)},
        'PLGR': {'RUN': X}, 'PLGS': {'RUN': X}, 'HUB': {'RUN': X}, 'RE': {'RUN': X, 'RUN2': neg(X)}}

def bylayer_bad(blk):
    return [e.props for e in live(blk) if not (e.props.get('Layer') == '0' and e.props.get('Color') == 256
            and str(e.props.get('Linetype', '')).upper() == 'BYLAYER' and e.props.get('Lineweight') == -1)]
# Clint's GUA reference DWGs (C:\\Users\\moore\\Dropbox\\Development\\3DFittings, measured
# per solid with accoreconsole; the same for GUAL / GUAT / GUAX): trade size ->
# (hub face from the centre, bottom z, top z incl. lugs / bar, hub OD, body dia);
# z from the hub axis
GUA_REF = {'1/2': (2.125, -0.625, 1.6875, 1.25, 2.5), '3/4': (2.125, -0.75, 1.5625, 1.5, 2.5),
           '1': (2.75, -0.875, 1.9375, 1.75, 3.5), '1-1/4': (3.125, -1.094, 2.094, 2.1875, 4.25),
           '1-1/2': (3.9375, -1.281, 3.682, 2.5625, 5.75), '2': (3.9375, -1.5, 3.463, 3.0, 5.75)}
def part_rmax(p, n=2000):
    """farthest distance from the X axis of a part (CYL: both end rims sampled; PTS: points)"""
    if p[0] == 'PTS': return max(math.hypot(q[1], q[2]) for q in p[1])
    if p[0] == 'BOX': return max(math.hypot(y, z) for y in (p[1][1], p[2][1]) for z in (p[1][2], p[2][2]))
    a, b, r = p[1], p[2], p[3]
    w = [y - x for x, y in zip(a, b)]; L = math.sqrt(sum(c * c for c in w)); w = [c / L for c in w]
    t = [0.0, 1.0, 0.0] if abs(w[1]) < 0.9 else [1.0, 0.0, 0.0]
    e1 = [w[1] * t[2] - w[2] * t[1], w[2] * t[0] - w[0] * t[2], w[0] * t[1] - w[1] * t[0]]
    m = math.sqrt(sum(c * c for c in e1)); e1 = [c / m for c in e1]
    e2 = [w[1] * e1[2] - w[2] * e1[1], w[2] * e1[0] - w[0] * e1[2], w[0] * e1[1] - w[1] * e1[0]]
    best = 0.0
    for c in (a, b):
        for i in range(n):
            f = 2 * math.pi * i / n
            q = [c[k] + r * (math.cos(f) * e1[k] + math.sin(f) * e2[k]) for k in range(3)]
            best = max(best, math.hypot(q[1], q[2]))
    return best
def span(blk):
    parts = [p for e in live(blk) for p in e.parts]
    return bbox(parts)

# ------------------------------------------------------------- every data row
rows = [r for r in csv.DictReader(open(CSV, encoding='utf-8')) if r['Shape'] in PH2]
check('rows', len(rows) > 150, str(len(rows)))
L, mk = session()
n = 0
for r in rows:
    f, sh, sz = r['Form'], r['Shape'], float(r['TradeSizeDec'])
    num = {k: float(r[k + '_in']) if r[k + '_in'] else None for k in 'ABCDE'}
    A, B, C, D, E = (num[k] for k in 'ABCDE')
    tag = f'{f} {sh} {r["TradeSize"]}'
    size = [sz, max(0.5, sz - 0.25)] if sh == 'RE' else sz
    g = call(L, 'medcb-real-geom', f, sh, size)
    check('geom ' + tag, g is not None)
    if g is None: continue
    hubs = {h[0]: (h[1], h[2]) for h in to_py(get(g, 'HUBS'))}
    check('hub-names ' + tag, set(hubs) == set(DIRS[sh]), str(hubs))
    for k, d in DIRS[sh].items():
        if k in hubs: check(f'hub-dir {tag} {k}', all(near(a, b) for a, b in zip(hubs[k][1], d)), str(hubs[k]))
    res = to_py(call(L, 'medcb-ensure-block', f, sh, size))
    check('built ' + tag, res and res[1] == 'CREATED', str(res))
    if not res or res[1] != 'CREATED': continue
    n += 1
    blk = mk.blocks[res[0].upper()]
    check('bylayer ' + tag, not bylayer_bad(blk), str(bylayer_bad(blk)[:2]))
    lo, hi = span(blk)
    tol = 1e-6
    if sh in ('UNY', 'EYS', 'EYD'):
        # r11 EYD: the drain (nipple, ECD hex, ECD body) may reach past the hub faces /
        # the turning radius; A, B and D are checked on the rest
        parts = [p for e in live(blk) for p in e.parts]
        def lowhigh(p): return (p[1], p[2]) if p[1][2] < p[2][2] else (p[2], p[1])
        obl = [p for p in parts if p[0] == 'CYL' and abs(p[1][0] - p[2][0]) > 1e-6 and abs(p[1][2] - p[2][2]) > 1e-6]
        drain = [p for p in obl if lowhigh(p)[1][0] < lowhigh(p)[0][0]] + [p for p in parts if p[0] == 'PTS' and len(p[1]) == 12]
        bparts = [p for p in parts if p not in drain]
        blo, bhi = bbox(bparts)
        check('A ' + tag, near(bhi[0] - blo[0], A), f'{blo} {bhi}')
        check('B ' + tag, near(hi[1] - lo[1], B), f'{lo} {hi}')
        check('faces ' + tag, near(hubs['RUN'][0][0], A / 2) and near(hubs['RUN2'][0][0], -A / 2))
        if sh in ('EYS', 'EYD'):
            # r10 (Clint's AutoCAD test of r9, EYS approved): the body is CENTRED on the conduit
            # axis; pour hub (+Z) and a leaning boss toward +X, each with a recessed plug;
            # nothing past the published turning radius D (rim corners included) and the
            # farthest point reaches it. r11 EYD (Clint's markup of r10): the EYS exactly, no
            # other opening; the pour hub plug is a special drain plug with a nipple + ECD
            # angled 45 deg toward -X (down when mounted vertically); only the drain may pass D.
            sol = live(blk)
            cuts = [p for e in sol for p in getattr(e, 'cuts', [])]
            rmax = max(part_rmax(p) for p in bparts)
            check('seal-solids ' + tag, len(sol) == 2, str(sol))
            check('seal-within-D ' + tag, D and rmax <= D + 1e-6, f'{rmax} vs {D}')
            check('seal-reaches-D ' + tag, D and rmax >= D - 0.031 * B, f'{rmax} vs {D}')
            xcyl = [p for p in parts if p[0] == 'CYL' and abs(p[1][1] - p[2][1]) < 1e-9 and abs(p[1][2] - p[2][2]) < 1e-9 and abs(p[1][0] - p[2][0]) > 1e-9]
            check('seal-concentric ' + tag, all(near(c, 0) for p in xcyl for c in (p[1][1], p[1][2], p[2][1], p[2][2]))
                  and any(near(p[3], B / 2) for p in xcyl), str(xcyl))
            vert = [p for p in parts if p[0] == 'CYL' and near(p[1][0], p[2][0]) and near(p[1][1], p[2][1]) and abs(p[1][2] - p[2][2]) > 1e-9 and near(p[3], 0.42 * B)]
            check('seal-pour-up ' + tag, len(vert) == 1 and min(vert[0][1][2], vert[0][2][2]) >= -1e-9 and max(vert[0][1][2], vert[0][2][2]) > B / 2, str(vert))
            boss = [p for p in obl if p not in drain]
            check('seal-leaning-boss-up ' + tag, any(near(p[3], 0.25 * B) for p in boss) and all(min(p[1][2], p[2][2]) >= -1e-9
                  and lowhigh(p)[1][0] > lowhigh(p)[0][0] for p in boss), str(obl))
            check('seal-bottom ' + tag, near(lo[2], -B / 2), f'{lo}')        # no underside opening
            if sh == 'EYS':
                check('seal-cuts ' + tag, len([p for p in cuts if p[0] == 'CYL']) == 3 and len([p for p in cuts if p[0] == 'PTS' and len(p[1]) == 8]) == 2, str(cuts))
                check('seal-no-drain ' + tag, not drain, str(drain))
            else:
                check('eyd-cuts ' + tag, len([p for p in cuts if p[0] == 'CYL']) == 3 and len([p for p in cuts if p[0] == 'PTS' and len(p[1]) == 8]) == 1, str(cuts))
                dc = [p for p in drain if p[0] == 'CYL']
                hx = [p for p in drain if p[0] == 'PTS']
                check('eyd-drain-parts ' + tag, len(dc) == 2 and len(hx) == 1 and all(p in sol[1].parts for p in drain), str(drain))
                # axis 45 deg toward -X: going up / out of the pour hub it moves -X as much as +Z
                check('eyd-drain-45 ' + tag, all(near(lowhigh(p)[1][0] - lowhigh(p)[0][0], -(lowhigh(p)[1][2] - lowhigh(p)[0][2])) and abs(p[1][1]) < 1e-9 and abs(p[2][1]) < 1e-9 for p in dc), str(dc))
                # seated in the pour hub: the nipple starts on the pour hub axis, inside the plug
                ph = vert[0]; ptop = max(ph[1][2], ph[2][2])
                nip = min(dc, key=lambda p: lowhigh(p)[0][2])
                st = lowhigh(nip)[0]
                check('eyd-drain-seated ' + tag, near(st[0], ph[1][0]) and ptop - 0.14 * B - 1e-9 < st[2] < ptop, f'{st} vs pour hub {ph}')
    elif sh.startswith('GUA'):
        # r9: tuned to Clint's reference DWGs (3DFittings GUA?4A 4B 6C 7D 9E 9F, measured
        # solid by solid): hub face, bottom, top (lugs / bar), hub OD, body dia
        ref = GUA_REF.get(r['TradeSize'])
        check('gua-ref ' + tag, ref is not None)
        if ref:
            face, zb, zt, hod, dia = ref
            t2 = 0.02
            check('gua-face ' + tag, all(near(math.sqrt(sum(c * c for c in hubs[k][0])), face, t2) for k in hubs), str(hubs))
            check('gua-z ' + tag, near(lo[2], zb, t2) and near(hi[2], zt, t2), f'{lo} {hi} vs {zb} {zt}')
            cyl = [p for e in live(blk) for p in e.parts if p[0] == 'CYL']
            check('gua-dia ' + tag, any(near(2 * p[3], dia, t2) and near(p[1][0], 0) and near(p[1][1], 0) for p in cyl), str(cyl))
            hc = [p for p in cyl if abs(p[1][2] - p[2][2]) < 1e-9]
            check('gua-hub ' + tag, len(hc) == len(hubs) and all(near(2 * p[3], hod, t2) for p in hc), str(hc))
            check('gua-span ' + tag, near(hi[0], face, t2) and near(hi[1], face, t2), f'{hi}')
    elif sh == 'BUB':
        check('A ' + tag, near(hi[0] - lo[0], A, 1e-4), f'{hi[0] - lo[0]} vs {A}')
        check('B ' + tag, near(hi[2] - lo[2], B, 1e-4), f'{hi[2] - lo[2]} vs {B}')
        check('faces-z0 ' + tag, hubs['RUN'][0][2] == 0 and near(hubs['RUN'][0][0], -hubs['RUN2'][0][0]))
    elif sh == 'LBY':
        check('A ' + tag, near(hi[0] - lo[0], A, 1e-4) and near(hubs['RUN'][0][0], hi[0]), f'{lo} {hi} vs {A}')
        check('A-back ' + tag, near(hi[2] - lo[2], A, 1e-4) and near(hubs['BACK'][0][2], lo[2]), f'{lo} {hi} vs {A}')
        check('sym ' + tag, near(hubs['RUN'][0][0], -hubs['BACK'][0][2]))
    elif sh == 'HUB':
        if f == 'MYR':
            check('A ' + tag, near(hi[0] - lo[0], A, 1e-3) and near(hubs['RUN'][0][0], C), f'{lo} {hi}')
        else:
            check('A ' + tag, near(hi[0], A) and near(hubs['RUN'][0][0], A) and near(hi[1] - lo[1], B), f'{lo} {hi}')
    elif sh in ('PLGR', 'PLGS'):
        check('cpl ' + tag, near(hi[0], A / 2) and hubs['RUN'][0] == [0.0, 0.0, 0.0] and lo[0] < -A / 2, f'{lo} {hi}')
        if sh == 'PLGS': check('head ' + tag, near(lo[0], -(A / 2 + D)), f'{lo}')
    elif sh == 'RE':
        check('re-name ' + tag, res[0].endswith('X' + call(L, 'medcb-size-tag', size[1])), res[0])
        check('re-faces ' + tag, near(hubs['RUN2'][0][0], -A) and hubs['RUN'][0][0] > C - 1e-9, str(hubs))
        check('re-recessed ' + tag, near(hi[1] - lo[1], B) and D < B, f'{lo} {hi}')
    else:   # LBD BLB BT BC: classic geometry on the published letters
        ell = sh in ('LBD', 'BLB')
        if ell:
            check('A ' + tag, near(hi[0] - lo[0], A), f'{lo} {hi}')
            check('B ' + tag, near(hi[2] - lo[2], B), f'{lo} {hi}')
        else:
            check('A ' + tag, near(hi[0] - lo[0], A), f'{lo} {hi}')
            check('C ' + tag, near(hi[1] - lo[1], C), f'{lo} {hi}')     # BT: incl. side hub; BC: width
check('built-count', n == len(rows), f'{n} of {len(rows)}')
# the X row of the classic forms builds too (published b = width across the side hubs)
res = to_py(call(L, 'medcb-ensure-block', 'F8', 'X', 1.0)); blk = mk.blocks[res[0]]
lo, hi = span(blk)
check('x-width', near(hi[1] - lo[1], 3.5) and near(hi[0] - lo[0], 7.3125) and not bylayer_bad(blk), f'{lo} {hi}')
# oblique cylinders: BUB hubs 45 deg (Rodrigues Rotate3D in the mock)
g = call(L, 'medcb-real-geom', 'MOG', 'BUB', 1.0)
cy = [p for p in to_py(get(g, 'PRIMS')) if p[0] == 'CYL']
res = to_py(call(L, 'medcb-ensure-block', 'MOG', 'BUB', 1.0)); blk = mk.blocks[res[0]]
obl = [p for e in live(blk) for p in e.parts if p[0] == 'CYL' and abs(p[1][0] - p[2][0]) > 1e-6 and abs(p[1][2] - p[2][2]) > 1e-6]
check('bub-oblique', len(obl) == 2 and all(near(abs(p[1][0] - p[2][0]), abs(p[1][2] - p[2][2])) for p in obl), str(obl))
ends = sorted([tuple(round(c, 6) for c in q) for p in obl for q in (p[1], p[2])])
faces = sorted([tuple(round(c, 6) for c in h[1]) for h in to_py(get(g, 'HUBS'))])
check('bub-hub-to-face', all(fc in ends for fc in faces), f'{ends} {faces}')
check('size-tag-list', call(L, 'medcb-size-tag', [1.0, 0.75]) == '1-00X0-75' and call(L, 'medcb-size-text', [1.25, 0.5]) == '1-1/4 x 1/2')
check('size-down', call(L, 'medcb-size-down', 1.0) == 0.75 and call(L, 'medcb-size-down', 0.5) is None)

# --------------------------------------------------------------- plan use
def world48(brk):
    L, mk, ents, markers = world()
    L.g['GET_BL_DATA'] = lambda name: brk.get(name.upper(), [0.0] * 4) + [0]
    return L, mk, ents, markers
# reducer: #ITEM_ALT reduce-to size; missing -> one size down + note
L, mk, ents, markers = world()
conduit(ents, [(-40, 0), (0, 0)]); conduit(ents, [(0, 0), (40, 0)])
re1 = fitting(ents, '1re', (0, 0, 0), 0, 103); re1.xdata['MED_FITTING'][4] = 0.5
re2 = fitting(ents, '1re', (0, 100, 0), 0, 103)
bodies = call(L, 'medcb-collect')[0]
b1, b2 = body(bodies, re1), body(bodies, re2)
check('re-alt', get(b1, 'SIZE2') == 0.5 and get(b1, 'NOTE') is None and get(b1, 'REASON') is None, str(to_py(b1)))
check('re-no-alt', get(b2, 'SIZE2') == 0.75 and 'one size down' in (get(b2, 'NOTE') or ''), str(get(b2, 'NOTE')))
call(L, 'medcb-place-all', bodies)
names = [i.props['Name'] for i in mk.inserts]
check('re-blocks', 'MED_CB_RGD_CH_RE_1-00X0-50' in names and 'MED_CB_RGD_CH_RE_1-00X0-75' in names, str(names))
check('re-bylayer', all(not bylayer_bad(mk.blocks[n.upper()]) for n in names))
# GUA side views: branch down, cover +Y; 1guat: branch = symbol +X
L, mk, ents, markers = world()
conduit(ents, [(-40, 0), (40, 0)])
gs = fitting(ents, '1guatsid', (0, 0, 0), 0, 142)
gl = fitting(ents, '1gualsid', (0, 50, 0), 0, 141)
conduit(ents, [(100, -40), (100, 40)]); conduit(ents, [(100, 0), (140, 0)])
gt = fitting(ents, '1guat', (100, 0, 0), 0, 142)
bodies = call(L, 'medcb-collect')[0]
for e in (gs, gl):
    b = body(bodies, e); hb = dict((h[0], h[2]) for h in to_py(get(b, 'HUBS')))
    cv = to_py(call(L, 'medcb-xdir', [0.0, 0.0, 1.0], get(b, 'ROT'), get(b, 'FLIP')))
    check('gua-side ' + e.h, closev(hb['BRANCH'], [0, 0, -1]) and closev(cv, [0, 1, 0]), f'{hb} {cv}')
b = body(bodies, gt); hb = dict((h[0], h[2]) for h in to_py(get(b, 'HUBS')))
check('guat-offset', closev(hb['BRANCH'], [1, 0, 0]) and get(b, 'TURN') == 0 and get(b, 'LEGS') == 3, f'{hb} {get(b, "TURN")}')
# union at DIMSCALE 48: the menu breaks 2.25" each side, the union is shorter -> the
# conduit is extended back to the union faces (negative trim)
brk = 0.046875 * 48
L, mk, ents, markers = world48({'1UNION': [0.046875, 0.0, 0.046875, 0.0]})
r1 = conduit(ents, [(-40, 0), (-brk, 0)]); r2 = conduit(ents, [(brk, 0), (40, 0)])
u = fitting(ents, '1union', (0, 0, 0), 0, 72, scale=(48.0, 48.0, 48.0))
bodies = call(L, 'medcb-collect')[0]; b = body(bodies, u)
L.g['*MED3D-FITS*'] = [call(L, 'medcb-fit-rec', x) for x in bodies]
face = 3.0 / 2      # UNY 1" length 3
p1 = plan_run(L, r1); p2 = plan_run(L, r2)
e1 = to_py(get(p1, 'ENDTRIM')); e2 = to_py(get(p2, 'ENDTRIM'))
check('union-extend', near(e1[1], face - brk) and near(e2[0], face - brk) and e1[1] < 0, f'{e1} {e2}')
check('union-pieces', near(to_py(get(p1, 'PIECES'))[-1][2][0], -face) and near(to_py(get(p2, 'PIECES'))[0][1][0], face),
      f'{to_py(get(p1, "PIECES"))} {to_py(get(p2, "PIECES"))}')
# hub-axis guard: a 43.8" break (+X only at 48; the pre-1c73970 1re typo 0.9125, kept
# as a stress case) must not grab a run that ends near it off the axis or on the other side
L, mk, ents, markers = world48({'1RE': [0.9125, 0.0, 0.0, 0.0]})
on = conduit(ents, [(0.9125 * 48, 0), (100, 0)])          # the broken +X run
back = conduit(ents, [(-60, 0), (-20, 0)])                  # ends 20" away on -X (not at the fitting)
side = conduit(ents, [(20, 30), (20, 10)])                  # ends 22" away, off the axis
lead = conduit(ents, [(-40, 0.001), (0, 0)])                # the large-size run into the reducer
rf = fitting(ents, '1re', (0, 0, 0), 0, 103, scale=(48.0, 48.0, 48.0)); rf.xdata['MED_FITTING'][4] = 0.75
bodies = call(L, 'medcb-collect')[0]
L.g['*MED3D-FITS*'] = [call(L, 'medcb-fit-rec', x) for x in bodies]
check('guard-on-axis', near(to_py(get(plan_run(L, on), 'ENDTRIM'))[0], to_py(get(body(bodies, rf), 'HUBS'))[0][1][0] - 0.9125 * 48),
      str(to_py(get(plan_run(L, on), 'ENDTRIM'))))
check('guard-other-side', not any(abs(x) > 1e-9 for x in (to_py(get(plan_run(L, back), 'ENDTRIM')) or [])), str(to_py(get(plan_run(L, back), 'ENDTRIM'))))
check('guard-off-axis', not any(abs(x) > 1e-9 for x in (to_py(get(plan_run(L, side), 'ENDTRIM')) or [])), str(to_py(get(plan_run(L, side), 'ENDTRIM'))))
check('guard-lead', near(to_py(get(plan_run(L, lead), 'ENDTRIM'))[1], -to_py(get(body(bodies, rf), 'HUBS'))[1][1][0], 1e-3),
      str(to_py(get(plan_run(L, lead), 'ENDTRIM'))))

# --------------------------------------------------------------- MEDCBALL
L, mk = session()
answers = {'GETSTRING': ['1'], 'GETPOINT': [[0.0, 0.0, 0.0]]}
L.g['GETSTRING'] = lambda *a: answers['GETSTRING'].pop(0) if answers['GETSTRING'] else ''
L.g['GETPOINT'] = lambda *a: answers['GETPOINT'].pop(0) if answers['GETPOINT'] else None
L.g['INITGET'] = lambda *a: None; L.g['GETKWORD'] = lambda *a: None
call(L, 'c:MEDCBALL')
names = [i.props['Name'] for i in mk.inserts]
shapes = set(nm.split('_')[4] for nm in names)
check('all-shapes', shapes >= set(PH2) | {'X', 'LB', 'LL', 'LR', 'T', 'TB', 'C'}, str(sorted(set(PH2) - shapes)))
check('all-myers', 'MED_CB_RGD_MYR_HUB_1-00' in names and 'MED_CB_RGD_CH_RE_1-00X0-75' in names, str(names))
check('all-real', not [nm for nm in names if nm.endswith('_PH')], str([nm for nm in names if nm.endswith('_PH')]))
check('all-bylayer', all(not bylayer_bad(mk.blocks[nm.upper()]) for nm in names))
check('all-insert-layer', all(i.props['Layer'] == 'MED_3DCONDUIT' and i.props.get('Color') == 256 for i in mk.inserts))

print(f'{len(rows)} phase 2 data rows, {n} blocks built EYS r10 / EYD r11, GUA r9')
if fails:
    print(f'FAILED {len(fails)}'); [print('  ' + f) for f in fails[:60]]; sys.exit(1)
print('OK test_med3dphase2')

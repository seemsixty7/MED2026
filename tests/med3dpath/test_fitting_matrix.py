"""Orientation matrix check: every row of tests/med3dpath/fitting_matrix.csv (2D fitting
block x fitting code x leg geometry, see docs/3d-fitting-matrix.md) is built in the
mock drawing the way the MED menus leave it (conduit breaks from Support/medblck.dat
x DIMSCALE), run through the real MED3DFittings / MED3DPath resolution, and compared
with the expected orientation. The cur_* / match_* columns record the current result;
the test fails if the code no longer gives what the CSV records.
Usage: python3 tests/med3dpath/test_fitting_matrix.py [--write] [-v]"""
import csv, io, math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from bodyworld import *

MATRIX = os.path.join(os.path.dirname(__file__), 'fitting_matrix.csv')
MEDBLCK = os.path.join(ROOT, 'Support', 'medblck.dat')
LEG = 40.0
SCALES = (1.0, 48.0)          # DIMSCALE: 1 (breaks < 0.25") and 48 (1/4" = 1'-0")
DIRS = {'+X': (1, 0), '+Y': (0, 1), '-X': (-1, 0), '-Y': (0, -1)}
BRK = {'+X': 0, '+Y': 1, '-X': 2, '-Y': 3}   # medblck d1..d4 = block +X, +Y, -X, -Y

def medblck():
    out = {}
    for ln in open(MEDBLCK, encoding='latin-1'):
        if len(ln) < 20: continue
        name = ln[0:8].strip().upper()
        try: d = [float(ln[9 + 18 * i:9 + 18 * (i + 1)].strip() or 0) for i in range(4)]
        except ValueError: continue
        out[name] = d
    return out

def rotv(v, a): return (v[0] * math.cos(a) - v[1] * math.sin(a), v[0] * math.sin(a) + v[1] * math.cos(a))

def build_legs(legs, brk, sc, rot):
    """-> list of polylines (lists of local points) for the leg spec"""
    ends, runs = [], []
    for tok in legs.split():
        if tok in DIRS: ends.append(tok)
        elif tok.startswith('PASS'):
            ax = tok[4]
            a, b = '+' + ax, '-' + ax
            if brk[BRK[a]] * sc == 0 and brk[BRK[b]] * sc == 0:
                runs.append([mulp(DIRS[b], LEG), mulp(DIRS[a], LEG)])
            else: ends += [a, b]
    gaps = {t: brk[BRK[t]] * sc for t in ends}
    if len(ends) == 2 and all(g == 0 for g in gaps.values()) and DIRS[ends[0]][0] * DIRS[ends[1]][0] + DIRS[ends[0]][1] * DIRS[ends[1]][1] == 0:
        runs.append([mulp(DIRS[ends[0]], LEG), (0.0, 0.0), mulp(DIRS[ends[1]], LEG)])     # one drawn corner
    else:
        for t in ends: runs.append([mulp(DIRS[t], gaps[t]), mulp(DIRS[t], gaps[t] + LEG)])   # r6: 1re breaks 43.8" at 48
    return [[rotv(p, rot) for p in r] for r in runs]
def mulp(d, s): return (d[0] * s, d[1] * s)

def axis_tok(v):
    for i, ax in enumerate('XYZ'):
        if abs(v[i]) > 0.99: return ('+' if v[i] > 0 else '-') + ax
    return '?'

def result(row, sc, rot_deg, brk, brks):
    L, mk, ents, markers = world()
    # the menu's get_bl_data (medblck.dat d1..d4 + rotation rule) for the leg search radius
    L.g['GET_BL_DATA'] = lambda name: (brks.get(name.upper(), [0.0] * 4) + [0])
    rot = math.radians(rot_deg)
    runs = [conduit(ents, r) for r in build_legs(row['legs'], brk, sc, rot)]
    mir = (row.get('mirror') or '').strip().upper()
    # the menu inserts at +DIMSCALE on every axis; M39 / M40 fake a user MIRROR
    scale = (-sc if mir == 'X' else sc, -sc if mir == 'Y' else sc, sc)
    f = fitting(ents, row['block'], (0.0, 0.0, 0.0), rot_deg, int(row['code']), scale=scale)
    if int(row['instype']) == 8: f.xdata['MED_FITTING'][4] = 0.75   # reducer: refitt_ins "Size to" (#ITEM_ALT)
    vt = [t for t in row['legs'].split() if t in ('UP', 'DN')]
    if vt:   # as dcon_ins: MED_CONDUIT (tag size code dist msr) + VERT_DATA (r1 r2 dir r4) on the insert
        f.xdata['MED_CONDUIT'] = ['MED_CONDUIT', 'NONE', 1.0, 1, 36.0, 'F']
        f.xdata['VERT_DATA'] = ['VERT_DATA', 0.0, 0.0, 1 if vt[0] == 'UP' else -1, 0.0]
    res = call(L, 'medcb-collect'); bodies = res[0]
    b = body(bodies, f)
    if b is None: return 'NM', 0, 0, 0
    if get(b, 'MIRROR'):
        toks = 'MIRROR'
    else:
        toks = []
        runsdirs, brdirs = [], []
        for h in to_py(get(b, 'HUBS')):
            d = list(rotv(h[2][:2], -rot)) + [h[2][2]]
            if h[0] in ('RUN', 'RUN2') and get(b, 'SHAPE') in SYM_RUNS: runsdirs.append(axis_tok(d))
            elif h[0] in ('BRANCH', 'BRANCH2') and get(b, 'SHAPE') in SYM_BRANCHES: brdirs.append(axis_tok(d))
            else: toks.append(h[0] + axis_tok(d))
        for tag, dd in (('RUNS:', runsdirs), ('BRANCHES:', brdirs)):
            if dd: toks.append(tag + (dd[0][1] if len(set(t[1] for t in dd)) == 1 and len(set(t[0] for t in dd)) == 2 else '?'))
        cv = to_py(call(L, 'medcb-xdir', [0.0, 0.0, 1.0], get(b, 'ROT'), get(b, 'FLIP')))
        toks.append('COVER' + axis_tok(list(rotv(cv[:2], -rot)) + [cv[2]]))
        toks = ' '.join(sorted(toks))
        if get(b, 'REASON'): toks = 'PH ' + toks        # placeholder: orientation still shown
    L.g['*MED3D-FITS*'] = [x for x in (call(L, 'medcb-fit-rec', y) for y in bodies) if x]
    cuts = flags = 0
    for r in runs:
        pl = plan_run(L, r)
        et = to_py(get(pl, 'ENDTRIM')) or []
        cuts += sum(1 for x in et if abs(x) > 1e-9)
        cuts += 2 * sum(1 for c in (get(pl, 'CORNERS') or []) if dict((car(i), cdr(i)) for i in c).get('STATUS') == 'FITTING')
        flags += len(to_py(get(pl, 'FITFLAGS')) or [])
    n0 = len(mk.ms_solids)
    call(L, 'medcb-place-all', bodies)
    flags += len(markers)          # placeholder / mirrored / vertical-leg markers
    vert = len(mk.ms_solids) - n0
    return toks, cuts, flags, vert

# symmetrical hub pairs shown as one axis token (RUNS:X = RUN and RUN2 along X);
# the reducer keeps RUN (small end) / RUN2 (large end) apart
SYM_RUNS = ('C', 'T', 'TB', 'X', 'BT', 'BC', 'GUAT', 'GUAX', 'UNY', 'EYS', 'EYD', 'BUB')
SYM_BRANCHES = ('X', 'GUAX')

def fmt(r): return f'{r[0]} | cuts {r[1]} | flags {r[2]} | vert {r[3]}'

def matches(row, r):
    e = row['expected']
    if e.endswith('*') and e != '*':
        if not r[0].startswith(e[:-1]): return False
    elif e != '*' and r[0] != e: return False
    if row['exp_cuts'] != '*' and r[1] != int(row['exp_cuts']): return False
    if r[3] != int(row.get('exp_vert') or 0): return False
    if row['exp_flags'].endswith('+'): return r[2] >= int(row['exp_flags'][:-1])
    return r[2] == int(row['exp_flags'])

def main():
    write = '--write' in sys.argv
    brks = medblck()
    rows = list(csv.DictReader(open(MATRIX, newline='', encoding='utf-8')))
    fields = list(rows[0].keys())
    for c in ('exp_vert', 'mirror', 'cur_sc1', 'cur_sc48', 'match_sc1', 'match_sc48'):
        if c not in fields: fields.append(c)
    for row in rows:
        brk = brks.get(row['block'].upper(), [0.0] * 4)
        for sc in SCALES:
            r0 = result(row, sc, 0, brk, brks)
            r90 = result(row, sc, 90, brk, brks)
            check(f"{row['id']} rotation invariance sc {sc:g}", r0 == r90, f'{fmt(r0)} vs {fmt(r90)}')
            tag = 'sc1' if sc == 1.0 else 'sc48'
            got, ok = fmt(r0), 'Y' if matches(row, r0) else 'N'
            if write: row['cur_' + tag], row['match_' + tag] = got, ok
            else:
                check(f"{row['id']} cur_{tag}", row.get('cur_' + tag) == got, f"CSV '{row.get('cur_' + tag)}' but code gives '{got}'")
                check(f"{row['id']} match_{tag}", row.get('match_' + tag) == ok, f"CSV {row.get('match_' + tag)} vs {ok}")
        if VERBOSE: print(row['id'], row['block'], row['code'], row['cur_sc1'] if write else '', row['match_sc1'] if write else '')
    if write:
        buf = io.StringIO(); w = csv.DictWriter(buf, fieldnames=fields, lineterminator='\r\n'); w.writeheader(); w.writerows(rows)
        open(MATRIX, 'w', newline='', encoding='utf-8').write(buf.getvalue())
    n = len(rows); m1 = sum(r['match_sc1'] == 'Y' for r in rows); m48 = sum(r['match_sc48'] == 'Y' for r in rows)
    print(f'{n} rows; match at DIMSCALE 1: {m1}; at DIMSCALE 48: {m48}')
    for r in rows:
        if r['match_sc1'] != 'Y' or r['match_sc48'] != 'Y':
            print(f"  mismatch {r['id']} {r['block']} code {r['code']}: expected '{r['expected']} | cuts {r['exp_cuts']} | flags {r['exp_flags']} | vert {r.get('exp_vert') or 0}'"
                  f"; sc1 '{r['cur_sc1']}'; sc48 '{r['cur_sc48']}'")
    if fails:
        print(f'FAILED {len(fails)}'); [print('  ' + f) for f in fails]; sys.exit(1)
    print('OK test_fitting_matrix')

main()

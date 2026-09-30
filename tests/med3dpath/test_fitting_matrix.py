"""Orientation matrix check: every row of tests/med3dpath/fitting_matrix.csv (2D fitting
block x fitting code x leg geometry, see docs/3d-fitting-matrix.md) is built in the
mock drawing the way the MED menus leave it (conduit breaks from Support/medblck.dat
x DIMSCALE), run through the real MED3DFittings / MED3DPath resolution, and compared
with the expected orientation. The r9_* / match_* columns record the current result;
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
        for t in ends: runs.append([mulp(DIRS[t], gaps[t]), mulp(DIRS[t], LEG)])
    return [[rotv(p, rot) for p in r] for r in runs]
def mulp(d, s): return (d[0] * s, d[1] * s)

def axis_tok(v):
    for i, ax in enumerate('XYZ'):
        if abs(v[i]) > 0.99: return ('+' if v[i] > 0 else '-') + ax
    return '?'

def result(row, sc, rot_deg, brk):
    L, mk, ents, markers = world()
    rot = math.radians(rot_deg)
    runs = [conduit(ents, r) for r in build_legs(row['legs'], brk, sc, rot)]
    f = fitting(ents, row['block'], (0.0, 0.0, 0.0), rot_deg, int(row['code']))
    res = call(L, 'medcb-collect'); bodies = res[0]
    b = body(bodies, f)
    if b is None: return 'NM', 0, 0
    if get(b, 'REASON'):
        toks = 'PH'
    else:
        toks = []
        runsdirs = []
        for h in to_py(get(b, 'HUBS')):
            d = list(rotv(h[2][:2], -rot)) + [h[2][2]]
            if h[0] in ('RUN', 'RUN2') and get(b, 'SHAPE') in ('C', 'T', 'TB'): runsdirs.append(axis_tok(d))
            else: toks.append(h[0] + axis_tok(d))
        if runsdirs: toks.append('RUNS:' + (runsdirs[0][1] if len(set(t[1] for t in runsdirs)) == 1 and len(set(t[0] for t in runsdirs)) == 2 else '?'))
        cv = to_py(call(L, 'medcb-xdir', [0.0, 0.0, 1.0], get(b, 'ROT'), get(b, 'FLIP')))
        toks.append('COVER' + axis_tok(list(rotv(cv[:2], -rot)) + [cv[2]]))
        toks = ' '.join(sorted(toks))
    L.g['*MED3D-FITS*'] = [x for x in (call(L, 'medcb-fit-rec', y) for y in bodies) if x]
    cuts = flags = 0
    for r in runs:
        pl = plan_run(L, r)
        et = to_py(get(pl, 'ENDTRIM')) or []
        cuts += sum(1 for x in et if x > 1e-9)
        cuts += 2 * sum(1 for c in (get(pl, 'CORNERS') or []) if dict((car(i), cdr(i)) for i in c).get('STATUS') == 'FITTING')
        flags += len(to_py(get(pl, 'FITFLAGS')) or [])
    if toks == 'PH': flags += 1
    return toks, cuts, flags

def fmt(r): return f'{r[0]} | cuts {r[1]} | flags {r[2]}'

def matches(row, r):
    if row['expected'] != '*' and r[0] != row['expected']: return False
    if row['exp_cuts'] != '*' and r[1] != int(row['exp_cuts']): return False
    if row['exp_flags'].endswith('+'): return r[2] >= int(row['exp_flags'][:-1])
    return r[2] == int(row['exp_flags'])

def main():
    write = '--write' in sys.argv
    brks = medblck()
    rows = list(csv.DictReader(open(MATRIX, newline='', encoding='utf-8')))
    fields = list(rows[0].keys())
    for c in ('r9_sc1', 'r9_sc48', 'match_sc1', 'match_sc48'):
        if c not in fields: fields.append(c)
    for row in rows:
        brk = brks.get(row['block'].upper(), [0.0] * 4)
        for sc in SCALES:
            r0 = result(row, sc, 0, brk)
            r90 = result(row, sc, 90, brk)
            check(f"{row['id']} rotation invariance sc {sc:g}", r0 == r90, f'{fmt(r0)} vs {fmt(r90)}')
            tag = 'sc1' if sc == 1.0 else 'sc48'
            got, ok = fmt(r0), 'Y' if matches(row, r0) else 'N'
            if write: row['r9_' + tag], row['match_' + tag] = got, ok
            else:
                check(f"{row['id']} r9_{tag}", row.get('r9_' + tag) == got, f"CSV '{row.get('r9_' + tag)}' but code gives '{got}'")
                check(f"{row['id']} match_{tag}", row.get('match_' + tag) == ok, f"CSV {row.get('match_' + tag)} vs {ok}")
        if VERBOSE: print(row['id'], row['block'], row['code'], row['r9_sc1'] if write else '', row['match_sc1'] if write else '')
    if write:
        buf = io.StringIO(); w = csv.DictWriter(buf, fieldnames=fields, lineterminator='\r\n'); w.writeheader(); w.writerows(rows)
        open(MATRIX, 'w', newline='', encoding='utf-8').write(buf.getvalue())
    n = len(rows); m1 = sum(r['match_sc1'] == 'Y' for r in rows); m48 = sum(r['match_sc48'] == 'Y' for r in rows)
    print(f'{n} rows; match r9 at DIMSCALE 1: {m1}; at DIMSCALE 48: {m48}')
    for r in rows:
        if r['match_sc1'] != 'Y' or r['match_sc48'] != 'Y':
            print(f"  mismatch {r['id']} {r['block']} code {r['code']}: expected '{r['expected']} | cuts {r['exp_cuts']} | flags {r['exp_flags']}'"
                  f"; sc1 '{r['r9_sc1']}'; sc48 '{r['r9_sc48']}'")
    if fails:
        print(f'FAILED {len(fails)}'); [print('  ' + f) for f in fails]; sys.exit(1)
    print('OK test_fitting_matrix')

main()

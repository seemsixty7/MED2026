"""Desk test for the pure geometry in Support/MED3DPath.lsp.
Runs the real LISP through lispmini.py. Usage: python3 tests/med3dpath/test_med3dpath.py"""
import math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from lispmini import Interp, Sym, Pair, car, cdr, to_py

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
L = Interp()
L.load(os.path.join(ROOT, 'Support', 'MED3DPath.lsp'))

EPS = 1e-6
fails = []

def get(alist, key):
    for it in alist or []:
        if car(it) == key: return to_py(cdr(it))
    return None

def plan(pts, buls=None, nrm=None, closed=False, od=1.163, override=None, kind='CONDUIT'):
    pts = [[float(c) for c in (p if len(p) == 3 else (p[0], p[1], 0.0))] for p in pts]
    buls = [float(b) for b in (buls or [0.0] * len(pts))]
    return L.apply(Sym('MED3D-PLAN'), [pts, buls, nrm, True if closed else None, od, kind, override])

def sub(a, b): return [x - y for x, y in zip(a, b)]
def add(a, b): return [x + y for x, y in zip(a, b)]
def mul(a, s): return [x * s for x in a]
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]
def norm(a): return math.sqrt(dot(a, a))
def unit(a): return mul(a, 1.0 / norm(a))
def close(a, b, tol=1e-6): return norm(sub(a, b)) < tol
def rot(v, k, th):  # Rodrigues
    return add(add(mul(v, math.cos(th)), mul(cross(k, v), math.sin(th))), mul(k, dot(k, v) * (1 - math.cos(th))))

def check(name, cond, msg=''):
    if not cond: fails.append(f'{name}: {msg}')

def cdict(c):
    out = {}
    for it in c:
        if isinstance(it, tuple): out[it[0]] = it[1]
        elif len(it) == 1: out[it[0]] = None
        else: out[it[0]] = it[1:]
    return out

def piece_start(p): return p[1]
def piece_end(p): return p[2]
def piece_tin(p): return unit(sub(p[2], p[1])) if p[0] == 'L' else unit(cross(p[4], sub(p[1], p[3])))
def piece_tout(p): return unit(sub(p[2], p[1])) if p[0] == 'L' else unit(cross(p[4], sub(p[2], p[3])))
def piece_len(p): return norm(sub(p[2], p[1])) if p[0] == 'L' else norm(sub(p[1], p[3])) * p[5]

def invariants(name, pl):
    pieces = get(pl, 'PIECES'); corners = get(pl, 'CORNERS') or []
    segs = get(pl, 'SEGS'); R = get(pl, 'R'); closed = get(pl, 'CLOSED')
    check(name, pieces, 'no pieces')
    real = [p for p in pieces if p[0] != 'S']
    # continuity (spheres sit exactly on the joint)
    seq = pieces + ([pieces[0]] if closed else [])
    for a, b in zip(seq, seq[1:]):
        if a[0] == 'S' or b[0] == 'S':
            s, o = (a, b) if a[0] == 'S' else (b, a)
            if o[0] != 'S':
                check(name, close(s[1], o[1]) or close(s[1], o[2]), f'sphere not on joint {s[1]}')
            continue
        check(name, close(piece_end(a), piece_start(b)), f'gap between {a[0]} and {b[0]}: {piece_end(a)} -> {piece_start(b)}')
    for p in pieces:
        if p[0] == 'L':
            check(name, piece_len(p) > 0, 'zero straight')
        elif p[0] == 'A':
            A, B, C, N, th = p[1], p[2], p[3], p[4], p[5]
            check(name, abs(norm(sub(A, C)) - norm(sub(B, C))) < 1e-6, 'arc radii differ')
            check(name, abs(dot(N, sub(A, C))) < 1e-6, 'axis not normal to radius')
            check(name, close(add(C, rot(sub(A, C), N, th)), B, 1e-5), f'arc end mismatch {B}')
    # fillets
    for c in corners:
        cd = cdict(c)
        if cd['STATUS'] == 'FITTED':
            V, C, th = cd['VERTEX'], cd['CENTER'], cd['ANGLE']
            check(name, abs(norm(sub(V, C)) - R / math.cos(th / 2)) < 1e-6, 'center distance')
            check(name, abs(cd['TANGENT'] - R * math.tan(th / 2)) < 1e-9, 'tangent length')
            check(name, close(unit(sub(cd['PTIN'], V)), mul(cd['TIN'], -1)), 'ptin not on incoming')
            check(name, abs(norm(sub(cd['PTIN'], C)) - R) < 1e-6, 'ptin not at R')
            check(name, abs(norm(sub(cd['PTOUT'], C)) - R) < 1e-6, 'ptout not at R')
            check(name, abs(dot(sub(cd['PTIN'], C), cd['TIN'])) < 1e-6, 'fillet not tangent in')
            check(name, abs(dot(sub(cd['PTOUT'], C), cd['TOUT'])) < 1e-6, 'fillet not tangent out')
    # tangent continuity except at spheres
    for a, b in zip(pieces, pieces[1:] + ([pieces[0]] if closed else [])):
        if a[0] != 'S' and b[0] != 'S':
            check(name, close(piece_tout(a), piece_tin(b), 1e-6), f'tangent break {a[0]}->{b[0]}')
    # tangents on each straight fit
    for k, s in enumerate(segs):
        if s[0] == 'L':
            used = 0.0
            for c in corners:
                cd = cdict(c)
                if cd['STATUS'] == 'FITTED' and (cd['SEGIN'] == k or cd['SEGOUT'] == k):
                    used += cd['TANGENT']
            check(name, used <= norm(sub(s[2], s[1])) + 1e-9, f'seg {k} over-allocated {used}')
    return pieces, corners


def statuses(corners): return [(cdict(c)['INDEX'], cdict(c)['STATUS']) for c in corners]

def total_len(pieces): return sum(piece_len(p) for p in pieces if p[0] != 'S')

results = []
def case(name, pl, expect=None, length=None):
    pieces, corners = invariants(name, pl)
    st = statuses(corners)
    if expect is not None: check(name, st == expect, f'statuses {st} != {expect}')
    if length is not None: check(name, abs(total_len(pieces) - length) < 1e-5, f'length {total_len(pieces)} != {length}')
    kinds = ''.join(p[0] for p in pieces)
    results.append((name, st, kinds, round(total_len(pieces), 4)))

od = 1.163; R = 5 * od; T90 = R  # tan(45) = 1
arc90 = R * math.pi / 2
# 1 LW open L-shape at elevation 120
case('LW open, 3x90', plan([(0,0,120),(120,0,120),(120,96,120),(240,96,120)], nrm=[0.,0.,1.]),
     [(1,'FITTED'),(2,'FITTED')], 120+96+120 - 4*T90 + 2*arc90)
# 2 2D bulges kept, fillet between straights, kink at non-tangent arc
b = math.tan(math.pi/8)
case('2D bulge + kink', plan([(0,0),(50,0),(60,10),(60,50),(100,50),(120,70),(160,70)],
                             [0,b,0,0,-b,0,0], nrm=[0.,0.,1.]),
     [(3,'FITTED'),(4,'KINK')])
# 2b same path with normal (0,0,-1) and mirrored points (OCS flipped) - invariants only
case('2D bulge, normal -Z', plan([(0,0),(50,0),(60,-10),(60,-50)], [0,b,0,0], nrm=[0.,0.,-1.]), [])
# 2c bulge in YZ plane (normal +X)
p2c = plan([(0,0,0),(0,10,10)], [b,0], nrm=[1.,0.,0.])
case('bulge normal +X', p2c, [])
A = get(p2c, 'PIECES')[0]
check('bulge normal +X', close(A[3], [0,0,10]), f'center {A[3]}')
# 3 sloped 3D
p3 = plan([(0,300,0),(100,300,0),(160,360,40),(160,460,120)])
case('3D sloped', p3, [(1,'FITTED'),(2,'FITTED')])
check('3D sloped', L.apply(Sym('MED3D-PLANAR-NORMAL'), [p3]) is None, 'should be non-planar')
check('LW planar', L.apply(Sym('MED3D-PLANAR-NORMAL'), [plan([(0,0,120),(120,0,120),(120,96,120)], nrm=[0.,0.,1.])]) is not None, 'should be planar')
# 4 short segment: both bends need 5.815, only 3 available -> both flagged
p4 = plan([(0,600),(100,600),(100,603),(200,603)])
case('short seg (3") flags both', p4, [(1,'FLAGGED'),(2,'FLAGGED')])
for c in get(p4, 'CORNERS'):
    d = cdict(c); check('short seg', abs(d['AVAIL'] - 3.0) < 1e-9 and abs(d['NEED'] - R) < 1e-9, f"need/avail {d['NEED']} {d['AVAIL']}")
# 5 each fits alone, not both -> one flagged; avail = 8 - 5.815
p5 = plan([(0,700),(100,700),(100,708),(200,708)])
case('8" seg, pair conflict', p5, [(1,'FLAGGED'),(2,'FITTED')])
check('8" seg', abs(cdict(get(p5,'CORNERS')[0])['AVAIL'] - (8 - R)) < 1e-9, 'avail')
# 5b unequal bends: the smaller bend (45 deg) is the one dropped
case('pair conflict, keep bigger bend', plan([(0,800),(100,800),(100,806),(200,906)]),
     [(1,'FITTED'),(2,'FLAGGED')])
# 5c sum exactly fits: T1 + T2 == L -> both fitted, zero-length straight omitted
case('exact fit', plan([(0,900),(100,900),(100,900+2*R),(200,900+2*R)]), [(1,'FITTED'),(2,'FITTED')])
# 6 three bends, middle conflicts both sides -> only middle dropped
case('chain drop middle', plan([(0,0),(100,0),(100,8),(92,8),(92,100)]),
     [(1,'FITTED'),(2,'FLAGGED'),(3,'FITTED')])
# 7 closed square 48 with 2" rigid OD
od7 = 2.375; R7 = 5*od7
case('closed square 48', plan([(0,0),(48,0),(48,48),(0,48)], nrm=[0.,0.,1.], closed=True, od=od7),
     [(1,'FITTED'),(2,'FITTED'),(3,'FITTED'),(0,'FITTED')], 4*48 - 8*R7 + 4*R7*math.pi/2)
# 7b closed by repeated end point (no closed flag)
case('closed by end point', plan([(0,0),(48,0),(48,48),(0,48),(0,0)], nrm=[0.,0.,1.], od=od7),
     [(1,'FITTED'),(2,'FITTED'),(3,'FITTED'),(0,'FITTED')])
# 8 tight closed square: cycle of conflicts -> alternate
case('tight closed square 20', plan([(0,0),(20,0),(20,20),(0,20)], nrm=[0.,0.,1.], closed=True, od=od7),
     [(1,'FLAGGED'),(2,'FITTED'),(3,'FLAGGED'),(0,'FITTED')])
# 9 reversal
case('reversal', plan([(0,0),(10,0),(5,0)]), [(1,'FLAGGED')])
# 10 collinear vertices merged so the bend can use both pieces
case('collinear merge', plan([(0,0),(3,0),(6,0),(6,50)]), [(2,'FITTED')])
# 11 duplicate points
case('duplicates', plan([(0,0),(0,0),(50,0),(50,0),(50,50)]), [(2,'FITTED')])
# 12 single straight
case('single straight', plan([(0,0,0),(10,10,10)]), [], math.sqrt(300))
# 13 override: fixed radius and factor
p13 = plan([(0,0),(100,0),(100,100)], override=24.0)
check('override', abs(get(p13,'R') - 24.0) < 1e-12, 'fixed R')
p13b = plan([(0,0),(100,0),(100,100)], override=Pair('FACTOR', 8.0))
check('override', abs(get(p13b,'R') - 8*od) < 1e-12, 'factor R')
# 14 default bend radius: conduit 5 x OD, cable 7 x OD (override still wins)
check('radius', abs(get(plan([(0,0),(100,0),(100,100)]),'R') - 5*od) < 1e-12, 'conduit R != 5 x OD')
check('radius', abs(get(plan([(0,0),(100,0),(100,100)], kind='CABLE'),'R') - 7*od) < 1e-12, 'cable R != 7 x OD')
check('radius', abs(get(plan([(0,0),(100,0),(100,100)], kind='CABLE', override=Pair('FACTOR', 5.0)),'R') - 5*od) < 1e-12, 'cable override')
# a 90 deg corner on a 7" leg: fits at 5 x OD (T 5.815) but not at 7 x OD (T 8.141)
case('cable 7xOD flags short leg', plan([(0,0),(7,0),(7,50)], kind='CABLE'), [(1,'FLAGGED')])
case('conduit 5xOD fits short leg', plan([(0,0),(7,0),(7,50)]), [(1,'FITTED')])

# 15 conduit bodies (*MED3D-FITS*, MEDMAKE3D): body joint = sharp, no sphere, legs cut
#    back to the hub faces; no hub along a leg -> uncut + FITFLAGS; cable ignores bodies
def corners(pl): return [cdict(c) for c in (get(pl, 'CORNERS') or [])]
LLH = [['RUN', [-4.0, 0.0, 0.0], [-1.0, 0.0, 0.0]], ['BRANCH', [0.0, 2.5, 0.0], [0.0, 1.0, 0.0]]]
L.g['*MED3D-FITS*'] = [['F1', [50.0, 0.0, 0.0], LLH]]
pf = plan([(0,0),(50,0),(50,30),(80,30)])
cf = corners(pf); pcs = get(pf, 'PIECES')
check('body corner', cf[0]['STATUS'] == 'FITTING' and cf[0]['FITTING'] == 'F1' and cf[1]['STATUS'] == 'FITTED', str(cf))
check('body cut', close(pcs[0][2], [46, 0, 0]) and close(pcs[1][1], [50, 2.5, 0]) and all(p[0] != 'S' for p in pcs), str(pcs))
check('body gaps', get(pf, 'GAPS') is True and not get(pf, 'FITFLAGS'), 'GAPS / FITFLAGS')
check('body bend fits after cut', pcs[2][0] == 'A' and abs(dot(sub(pcs[2][1], pcs[1][2]), [1, 1, 1])) < 1e-9, str(pcs[1:3]))
# a short leg: the bend next to the body gets the length left after the cut
pf = plan([(0,0),(50,0),(50,8),(80,8)])
check('body short leg', corners(pf)[1]['STATUS'] == 'FLAGGED', str(corners(pf)))
# no hub along the west leg
L.g['*MED3D-FITS*'] = [['F2', [50.0, 0.0, 0.0], LLH[1:]]]
pf = plan([(0,0),(50,0),(50,30)])
ff = get(pf, 'FITFLAGS')
check('body flag', len(ff) == 1 and ff[0][1] == 'F2' and ff[0][2] == 1 and close(get(pf, 'PIECES')[0][2], [50, 0, 0]), str(ff))
# run ends at a body (both ends), Z tolerance, cable unaffected, 3D leg on a back hub
L.g['*MED3D-FITS*'] = [['A', [0.0, 0.0, 0.0], [['RUN', [3.0, 0.0, 0.0], [1.0, 0.0, 0.0]]]],
                       ['B', [40.0, 0.0, 0.0], [['BACK', [0.0, 0.0, 2.0], [0.0, 0.0, 1.0]], ['RUN', [-3.0, 0.0, 0.0], [-1.0, 0.0, 0.0]]]]]
pf = plan([(0,0,0),(40,0,0),(40,0,30)])
pcs = get(pf, 'PIECES')
check('body ends', close(pcs[0][1], [3, 0, 0]) and close(pcs[0][2], [37, 0, 0]) and close(pcs[1][1], [40, 0, 2]), str(pcs))
check('body endtrim', close(get(pf, 'ENDTRIM'), [3.0, 0.0]), str(get(pf, 'ENDTRIM')))
pz = plan([(0,0,50),(40,0,50)])
check('body z tol', get(pz, 'ENDTRIM') == [0.0, 0.0] and not get(pz, 'FITHITS'), str(get(pz, 'ENDTRIM')))
pc = plan([(0,0),(50,0),(50,30)], kind='CABLE')
check('body cable', get(pc, 'ENDTRIM') is None and not get(pc, 'GAPS'), 'cable run used bodies')
L.g['*MED3D-FITS*'] = None
case('bodies off again', plan([(0,0),(50,0),(50,30)]), [(1,'FITTED')])

for r in results:
    print(f'{r[0]:34s} {str(r[1]):70s} pieces={r[2]:14s} len={r[3]}')
print()
if fails:
    print('FAILURES:'); [print('  ', f) for f in fails]; sys.exit(1)
print(f'ALL {len(results)} CASES + override checks PASSED')

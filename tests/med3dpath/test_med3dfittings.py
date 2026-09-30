"""Desk test for Support/MED3DFittings.lsp (rigid conduit body blocks) with the
lispmini interpreter and a small block/solid mock (no AutoCAD):
  - block naming, trade-size parsing
  - Data/seed/conduit_body_dims.csv read by the LISP CSV reader (all rows)
  - geometry of every data row: hub faces / directions / origin, overall A, B, C
  - block build: solids (box / cylinders after Rotate3D + Move) match the geometry,
    generate-on-demand, an existing definition is never redefined, placeholder
  - DB rows (MEDConduitBody via MED-DotNet) win over CSV rows
  - MEDCBTEST inserts all 6 shapes in a row without overlaps
The mock lives in fitmock.py (shared with test_med3dbodies.py).
Usage: python3 tests/med3dpath/test_med3dfittings.py [-v]"""
import csv, math, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from lispmini import Interp, Sym, Pair, car, cdr, to_py

from fitmock import *
import fitmock

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
        'LL': {'RUN': [1, 0, 0], 'BRANCH': [0, 1, 0]},      # r5: LL side hub +Y, LR -Y (Clint)
        'LR': {'RUN': [1, 0, 0], 'BRANCH': [0, -1, 0]},
        'X': {'RUN': [1, 0, 0], 'RUN2': [-1, 0, 0], 'BRANCH': [0, 1, 0], 'BRANCH2': [0, -1, 0]}}
clamped = []
for rp in rows_py:
    f, sh, sz = rp['Form'], rp['Shape'], float(rp['TradeSizeDec'])
    if sh not in DIRS or f not in ('F7', 'F8', 'M9'): continue      # phase 2 shapes: test_med3dphase2.py
    A, B, C, D, E = (float(rp[k]) for k in ('A_in', 'B_in', 'C_in', 'D_in', 'E_in'))
    if sh == 'X': B, C = C, B          # X: published b = width across the side hubs, c = depth
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
            if sh == 'X':
                check('C-extent ' + tag, near(hubs['BRANCH'][0][1] - hubs['BRANCH2'][0][1], C), f'{hubs["BRANCH"]} {hubs["BRANCH2"]} vs {C}')
            else:
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
# r6 (Clint): no colour in the block - the body is the solid with the hubs (most parts)
def split_solids(sols):
    sols = sorted(sols, key=lambda s: -len(s.parts))
    return sols[:1], sols[1:]
def bylayer_ok(blocks):
    bad = []
    for b in blocks.values():
        for e in live(b):
            pr = e.props
            if not (pr.get('Layer') == '0' and pr.get('Color') == 256 and str(pr.get('Linetype', '')).upper() == 'BYLAYER'
                    and pr.get('Lineweight') == -1):
                bad.append((b.props['Name'], pr))
    return bad
L, mk = session()
res = to_py(call(L, 'medcb-ensure-block', 'F7', 'LB', 1.0))
check('ensure-created', res == ['MED_CB_RGD_F7_LB_1-00', 'CREATED'], str(res))
b = mk.blocks.get('MED_CB_RGD_F7_LB_1-00')
check('block-exists', b is not None and b.base == [0.0, 0.0, 0.0])
if b:
    sols = live(b)
    body, cover = split_solids(sols)
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
# a current definition (r6 tag) is used as is, even when edited by hand
mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_F7_T_1-00').props['Comments'] = 'MEDCB geom r6'
res3 = to_py(call(L, 'medcb-ensure-block', 'F7', 'T', 1.0))
check('existing-left-alone', res3[1] == 'EXISTS' and mk.blocks['MED_CB_RGD_F7_T_1-00'].ents == [], str(res3))
# LR / LL / T branch cylinder along Y on the right side
for sh, sign in (('LR', -1), ('LL', 1), ('T', 1)):
    res = to_py(call(L, 'medcb-ensure-block', 'F8', sh, 2.0))
    bb = mk.blocks[res[0]]; body = split_solids(live(bb))[0][0]
    ycyl = [p for p in body.parts if p[0] == 'CYL' and abs(p[1][1] - p[2][1]) > 1e-9]
    g = call(L, 'medcb-geom-for', 'F8', sh, 2.0); br = [h for h in to_py(get(g, 'HUBS')) if h[0] == 'BRANCH'][0]
    check('branch-cyl ' + sh, len(ycyl) == 1 and near((max if sign > 0 else min)(ycyl[0][1][1], ycyl[0][2][1]), br[1][1]) and br[1][1] * sign > 0, str(ycyl))
    lo, hi = bbox(body.parts)
    check('branch-C ' + sh, near(hi[1] - lo[1], 5.0), f'{hi[1] - lo[1]}')
# C straight: centred, both hubs
res = to_py(call(L, 'medcb-ensure-block', 'F7', 'C', 0.5)); body = split_solids(live(mk.blocks[res[0]]))[0][0]
lo, hi = bbox(body.parts)
check('C-bbox', near(lo[0], -5.375 / 2) and near(hi[0], 5.375 / 2) and near(hi[1] - lo[1], 1.375), f'{lo} {hi}')
# placeholder: no data for Form 7 TB 4"
res = to_py(call(L, 'medcb-ensure-block', 'F7', 'TB', 4.0))
check('placeholder', res == ['MED_CB_RGD_F7_TB_4-00_PH', 'PLACEHOLDER'], str(res))
ph = mk.blocks.get('MED_CB_RGD_F7_TB_4-00_PH')
check('placeholder-box', ph and len(live(ph)) == 1 and live(ph)[0].props.get('Layer') == '0' and live(ph)[0].parts[0][0] == 'BOX')
check('real-name-free', 'MED_CB_RGD_F7_TB_4-00' not in mk.blocks)
check('placeholder-again', to_py(call(L, 'medcb-ensure-block', 'F7', 'TB', 4.0))[1] == 'PH-EXISTS')
check('bad-shape', call(L, 'medcb-ensure-block', 'F7', 'XX', 1.0) is None)
check('bad-size', call(L, 'medcb-ensure-block', 'F7', 'LB', 0.0) is None)
# insert
ins = to_py(call(L, 'medcb-insert', 'F8', 'LB', 1.5, [10.0, 5.0, 0.0], 0.0))
check('insert', ins and ins[1] == 'MED_CB_RGD_F8_LB_1-50' and mk.inserts[-1].props['Pt'] == [10.0, 5.0, 0.0]
      and mk.inserts[-1].props['Layer'] == 'MED_3DCONDUIT', str(ins))
call(L, 'medcb-insert', 'F8', 'TB', 3.0, [0.0, 0.0, 0.0], 0.0)
check('insert-ph-layer', mk.inserts[-1].props['Layer'] == 'MED_3DFLAG' and 'MED_3DFLAG' in mk.layers)
hubs = to_py(call(L, 'medcb-hubs', 'F7', 'LL', 1.0))
check('hubs-api', [h[0] for h in hubs] == ['RUN', 'BRANCH'] and hubs[1][2] == [0.0, 1.0, 0.0], str(hubs))
# a block made before r6 (no / older geometry tag: LL / LR convention before r5, gray
# cover / red placeholder before r6) is renamed out of the way and rebuilt - any shape
old = mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_F7_LR_1-00')
res = to_py(call(L, 'medcb-ensure-block', 'F7', 'LR', 1.0))
check('stale-ll-lr', res == ['MED_CB_RGD_F7_LR_1-00', 'CREATED'] and old.props['Name'] == 'MED_CB_RGD_F7_LR_1-00_PRE_R6'
      and 'MED_CB_RGD_F7_LR_1-00_PRE_R6' in mk.blocks and mk.blocks['MED_CB_RGD_F7_LR_1-00'] is not old
      and mk.blocks['MED_CB_RGD_F7_LR_1-00'].props.get('Comments') == 'MEDCB geom r6', f'{res} {old.props}')
check('fresh-ll-lr-kept', to_py(call(L, 'medcb-ensure-block', 'F7', 'LR', 1.0))[1] == 'EXISTS')
old = mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_F7_C_1-00'); old.props['Comments'] = 'MEDCB geom r5'
res = to_py(call(L, 'medcb-ensure-block', 'F7', 'C', 1.0))
check('stale-r5-c', res[1] == 'CREATED' and old.props['Name'] == 'MED_CB_RGD_F7_C_1-00_PRE_R6', f'{res} {old.props}')
old = mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_F7_TB_5-00_PH'); old.props['Comments'] = 'MEDCB geom r5'
res = to_py(call(L, 'medcb-ensure-block', 'F7', 'TB', 5.0))
check('stale-r5-ph', res == ['MED_CB_RGD_F7_TB_5-00_PH', 'PLACEHOLDER'] and old.props['Name'] == 'MED_CB_RGD_F7_TB_5-00_PH_PRE_R6', f'{res} {old.props}')
# r7 - r12: per-shape revisions - EYS blocks older than r10 are renamed _PRE_R10, EYD older
# than r12 _PRE_R12, GUAL / GUAT / GUAX older than r9 _PRE_R9, and rebuilt; other r6 blocks
# are left alone
check('tag-for', call(L, 'medcb-tag-for', 'MED_CB_RGD_CH_EYS_1-00') == 'MEDCB geom r10'
      and call(L, 'medcb-tag-for', 'MED_CB_RGD_CH_EYD_2-00_PH') == 'MEDCB geom r12'
      and call(L, 'medcb-tag-for', 'MED_CB_RGD_XP_GUAT_1-00') == 'MEDCB geom r9'
      and call(L, 'medcb-tag-for', 'MED_CB_RGD_F7_LB_1-00') == 'MEDCB geom r6'
      and call(L, 'medcb-name-shape', 'MED_CB_RGD_CH_RE_1-00X0-75') == 'RE' and call(L, 'medcb-name-shape', 'OTHER') == '')
old = mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_CH_EYS_1-00'); old.props['Comments'] = 'MEDCB geom r9'
res = to_py(call(L, 'medcb-ensure-block', 'CH', 'EYS', 1.0))
check('stale-r9-eys', res == ['MED_CB_RGD_CH_EYS_1-00', 'CREATED'] and old.props['Name'] == 'MED_CB_RGD_CH_EYS_1-00_PRE_R10'
      and mk.blocks['MED_CB_RGD_CH_EYS_1-00'].props.get('Comments') == 'MEDCB geom r10', f'{res} {old.props}')
old = mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_CH_UNY_1-00'); old.props['Comments'] = 'MEDCB geom r6'
check('r6-uny-kept', to_py(call(L, 'medcb-ensure-block', 'CH', 'UNY', 1.0))[1] == 'EXISTS' and old.props['Name'] == 'MED_CB_RGD_CH_UNY_1-00')
old.props['Comments'] = ''
old = mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_CH_EYD_1-00'); old.props['Comments'] = 'MEDCB geom r5'
res = to_py(call(L, 'medcb-ensure-block', 'CH', 'EYD', 1.0))
check('stale-r5-eyd', res[1] == 'CREATED' and old.props['Name'] == 'MED_CB_RGD_CH_EYD_1-00_PRE_R12', f'{res} {old.props}')
old = mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_CH_EYD_2-00'); old.props['Comments'] = 'MEDCB geom r11'
res = to_py(call(L, 'medcb-ensure-block', 'CH', 'EYD', 2.0))
check('stale-r11-eyd', res[1] == 'CREATED' and old.props['Name'] == 'MED_CB_RGD_CH_EYD_2-00_PRE_R12'
      and mk.blocks['MED_CB_RGD_CH_EYD_2-00'].props.get('Comments') == 'MEDCB geom r12', f'{res} {old.props}')
old = mk.invoke('BLOCKS', 'Add', [0.0, 0.0, 0.0], 'MED_CB_RGD_XP_GUAL_1-00'); old.props['Comments'] = 'MEDCB geom r6'
res = to_py(call(L, 'medcb-ensure-block', 'XP', 'GUAL', 1.0))
check('stale-r6-gual', res == ['MED_CB_RGD_XP_GUAL_1-00', 'CREATED'] and old.props['Name'] == 'MED_CB_RGD_XP_GUAL_1-00_PRE_R9'
      and mk.blocks['MED_CB_RGD_XP_GUAL_1-00'].props.get('Comments') == 'MEDCB geom r9', f'{res} {old.props}')
# Clint's block rule: every entity of every generated block on layer 0, ByLayer
gen = {k: v for k, v in mk.blocks.items() if v.props.get('Comments') in ('MEDCB geom r6', 'MEDCB geom r7', 'MEDCB geom r8', 'MEDCB geom r9', 'MEDCB geom r10', 'MEDCB geom r11', 'MEDCB geom r12')}
check('bylayer-blocks', len(gen) >= 7 and not bylayer_ok(gen), str(bylayer_ok(gen)[:3]))
check('bylayer-inserts', all(i.props.get('Color') == 256 and i.props.get('Lineweight') == -1 for i in mk.inserts), str([i.props for i in mk.inserts][:2]))

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
check('test-7', names == [f'MED_CB_RGD_F8_{s}_1-50' for s in ('LB', 'LR', 'LL', 'T', 'TB', 'C', 'X')], str(names))
check('test-labels', len(mk.texts) == 7, str(len(mk.texts)))
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

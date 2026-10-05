import zipfile,re,sys,json,xml.etree.ElementTree as ET,collections
p=sys.argv[1]; z=zipfile.ZipFile(p)
defs=json.load(open('/workspace/medrib/work/defs.json')); CMDS=set(defs['cmds']); FUNCS=set(defs['funcs'])
DLL=set(open('/workspace/medrib/work/dllnames.txt').read().split())
BUILTIN={'SETQ','IF','NOT','STRCAT','LIST','C:LOADTXT','*','FILLET','R'}
IMGMENUS=set(re.findall(r'<Alias>([^<]+)</Alias>',zipfile.ZipFile('/workspace/medrib/med.cuix').read('ImageMenuRoot.cui').decode('utf-8','ignore'))) if False else None
err=[]; uids=collections.Counter(); docs={}
for n in z.namelist():
    if n.endswith(('.cui','.xml','.rels')):
        b=z.read(n)
        try: docs[n]=ET.fromstring(b)
        except Exception as e: err.append(f'XML {n}: {e}')
        for el in docs.get(n,ET.Element('x')).iter():
            if 'UID' in el.attrib: uids[el.attrib['UID']]+=1
dup=[u for u,c in uids.items() if c>1]
if dup: err.append(f'dup UIDs {dup[:20]} ({len(dup)})')
mg=docs['MenuGroup.cui']; macros={}
for mm in mg.iter('MenuMacro'):
    m=mm.find('Macro'); macros[mm.get('UID')]=(m.findtext('Command') or '', m.find('SmallImage').get('Name') if m.find('SmallImage') is not None else '', m.find('LargeImage').get('Name') if m.find('LargeImage') is not None else '')
emb={n for n in z.namelist() if n.endswith('.bmp')}
rels=z.read('_rels/.rels').decode('utf-8-sig'); mpi=z.read('Menu_Package_Info.xml').decode()
for n in emb:
    if f'"/{n}"' not in rels: err.append('bmp not in rels '+n)
    if f'"/{n}"' not in mpi: err.append('bmp not in MPI '+n)
for t in re.findall(r'Target="/([^"]+)"',rels):
    if t not in z.namelist(): err.append('rels target missing '+t)
rr=docs['RibbonRoot.cui']; used=set(); badimg=set()
for el in rr.iter():
    for a in ('SmallImage','LargeImage'):
        if a in el.attrib and el.attrib[a] and el.attrib[a] not in DLL and el.attrib[a] not in emb: badimg.add(el.attrib[a])
    if 'MenuMacroID' in el.attrib:
        u=el.attrib['MenuMacroID']
        if u not in macros: err.append('missing macro '+u)
        else: used.add(u)
panels={p.get('UID') for p in rr.iter('RibbonPanelSource')}
for r in rr.iter('RibbonPanelSourceReference'):
    if r.get('PanelId') not in panels: err.append('missing panel '+r.get('PanelId'))
imenus={a.upper() for a in open('/workspace/medrib/work/imagemenus.txt').read().split()}
badcmd=set()
for u in used:
    cmd,sm,lg=macros[u]
    for im in (sm,lg):
        if not im or (im not in DLL and im not in emb): badimg.add(f'{u}:{im!r}')
    c=re.sub(r'^(\^C)+','',cmd.strip())
    for menu in re.findall(r'\$I=MED\.(\w+)',c,re.I):
        if menu.upper() not in imenus: badcmd.add(f'{u}: image menu {menu}')
    if '$' in c: continue
    for f in re.findall(r'\(\s*([^\s()]+)',c):
        F=f.upper()
        if F not in FUNCS and F not in BUILTIN and F not in CMDS: badcmd.add(f'{u}: func {f}')
    cc=re.sub(r'"[^"]*"','""',c)
    while True:
        n2=re.sub(r'\([^()]*\)','',cc)
        if n2==cc: break
        cc=n2
    rest=cc.split()
    for w in rest:
        W=w.upper()
        if W in('R','FILLET'): continue
        if W not in CMDS: badcmd.add(f'{u}: cmd {w} in {cmd!r}')
print('macros used',len(used),'uids',len(uids))
for e in err: print('ERR',e)
for b in sorted(badimg): print('IMG',b)
for b in sorted(badcmd): print('CMD',b)
print('OK' if not(err or badimg or badcmd) else 'PROBLEMS')

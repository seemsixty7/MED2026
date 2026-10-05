import os,re,shutil,json,zipfile,sys,html,datetime
from PIL import Image
from lookup import find,norm,RIB,MED
import spec
SRC='/workspace/medrib/ex/rib'; OUT='/workspace/medrib/out/rib'
ICONS='/workspace/medrib/src/Icons'
DLL=set(open('/workspace/medrib/work/dllnames.txt').read().split())
shutil.rmtree(OUT,ignore_errors=True); shutil.copytree(SRC,OUT)
for f in ('TRAY-newtest.bmp','TESTICONONEINCHa.bmp'): os.remove(f'{OUT}/{f}')
MR='<ModifiedRev MajorVersion="23" MinorVersion="1" UserVersion="1" />'
esc=lambda s: html.escape(s,quote=True)
cnt=[0]
def uid(p='MEDRB'):
    cnt[0]+=1; return f'{p}_{cnt[0]:04d}'
# ---------- images
EMB=set(f for f in os.listdir(OUT) if f.endswith('.bmp'))
def ensure_bmp(name):          # name like 'TRAY_SIDE90.bmp'
    base=name[:-4]
    if name in EMB: return
    src=f'{ICONS}/Med_{base}.bmp'
    im=Image.open(src)
    bg=im.getpixel((0,0))
    sm=Image.new(im.mode,(16,16),bg)
    if im.mode=='P': sm.putpalette(im.getpalette())
    sm.paste(im,(0,0))
    sm.save(f'{OUT}/{base}.bmp')
    sm.resize((32,32),Image.NEAREST).save(f'{OUT}/{base}_32.bmp')
    EMB.update({f'{base}.bmp',f'{base}_32.bmp'}); NEWBMP.extend([f'{base}.bmp',f'{base}_32.bmp'])
NEWBMP=[]
def imgpair(img):
    if img.endswith('.bmp'):
        ensure_bmp(img); return img, img[:-4]+'_32.bmp'
    return img,img
# ---------- macros
NEWMAC={}   # uid -> dict
USED=set(); MACKEY={}
def macro_for(b):
    key=(norm(b.cmd),b.img)
    if key in MACKEY: return MACKEY[key]
    hits=find(b.cmd)
    want=imgpair(b.img) if b.img else None
    chosen=None
    for src,u,m in sorted(hits,key=lambda h:h[0]!='rib'):
        cur=(m['small'],m['large'])
        if want is None and cur[0]:
            chosen=(src,u,m); break
        if want and cur==want:
            chosen=(src,u,m); break
        if want and cur[0]==want[0] and (want[0] in DLL):  # large differs but dll name; accept
            pass
    if chosen and chosen[0]=='rib':
        u=chosen[1]
    else:
        base=chosen or (hits[0] if hits else None)
        same= base is not None and want is not None and (base[2]['small'],base[2]['large'])==want or (base is not None and want is None)
        u=('MEDR_'+base[1]) if same else uid('MEDR_N')
        if u in NEWMAC or u in RIB: u=uid('MEDR_N')
        sm,lg=want if want else (base[2]['small'],base[2]['large']) if base else ('','')
        if not sm: raise SystemExit(f'no image for {b.label} {b.cmd}')
        cmd=base[2]['cmd'] if base else b.cmd
        NEWMAC[u]=dict(name=b.label,cmd=cmd,small=sm,large=lg)
    MACKEY[key]=u; USED.add(u); return u
def btn(b,style,text=True,ind=0):
    u=macro_for(b); p=' '*ind
    return (f'{p}<RibbonCommandButton UID="{uid()}" Id="AcRibbonCommandButton" Text="{esc(b.label) if text else ""}" ButtonStyle="{style}" MenuMacroID="{u}" KeyTip="">\n'
            f'{p}  <TooltipTitle xlate="true" UID="{uid("XLS_MEDRB")}">{esc(b.tip)}</TooltipTitle>\n{p}  {MR}\n{p}</RibbonCommandButton>\n')
def split(label,items,size,ind):
    if isinstance(items,str): items={'@TERM1@':spec.TERM1,'@TERM2@':spec.TERM2}[items]
    p=' '*ind; st='LargeWithText' if size=='L' else 'SmallWithText'
    s=(f'{p}<RibbonSplitButton UID="{uid()}" Id="AcRibbonSplitButton" Text="{esc(label)}" Behavior="SplitFollow" ListStyle="IconText" ButtonStyle="{st}" Grouping="false">\n{p}  {MR}\n')
    for b in items: s+=btn(b,'SmallWithText',True,ind+2)
    return s+f'{p}</RibbonSplitButton>\n'
def rowpanel(inner_rows,ind):
    p=' '*ind
    s=f'{p}<RibbonRowPanel UID="{uid()}" ResizeStyle="None" ResizePriority="100" TopJustify="True">\n{p}  {MR}\n'
    for r in inner_rows: s+=f'{p}  <RibbonRow UID="{uid()}">\n{p}    {MR}\n{r}{p}  </RibbonRow>\n'
    return s+f'{p}</RibbonRowPanel>\n'
LAYOUT=[]
def rimg(b):
    u=MACKEY[(norm(b.cmd),b.img)]; m=NEWMAC.get(u) or RIB.get(u); return m['small'] or m['large']
def entries(rows,ind,lay):
    s=''
    for r in rows:
        k=r[0]
        if k=='L': s+=btn(r[1],'LargeWithText',True,ind); lay.append(('L',[(r[1].label,rimg(r[1]))],None))
        elif k=='S': s+=rowpanel([btn(r[1],'SmallWithText',True,ind+4)],ind); lay.append(('stack',[(r[1].label,rimg(r[1]))],None))
        elif k in('stack','stackicons'):
            s+=rowpanel([btn(b,'SmallWithText' if k=='stack' else 'SmallWithoutText',k=='stack',ind+4) for b in r[1]],ind)
            lay.append(('stack',[(b.label,rimg(b)) for b in r[1]],None))
        elif k=='split':
            items=r[2] if not isinstance(r[2],str) else {'@TERM1@':spec.TERM1,'@TERM2@':spec.TERM2}[r[2]]
            if r[3]=='L': s+=split(r[1],items,'L',ind)
            else: s+=rowpanel([split(r[1],items,'S',ind+4)],ind)
            lay.append(('split'+r[3],r[1],[(b.label,rimg(b)) for b in items]))
    return s
panels_xml=''; tabs_xml=''; stats=[]
for tabname,tabuid,panels in spec.TABS:
    refs=''; tl=[]
    for pi,(pname,rows,slide) in enumerate(panels):
        puid=f'{tabuid.replace("MED_TAB","MED_PNL")}_{pi+1:02d}'
        lay_main=[]; lay_slide=[]
        x=f'    <RibbonPanelSource UID="{puid}" Text="{esc(pname)}" HiddenInEditor="false">\n      {MR}\n      <Name xlate="true" UID="XLS_{puid}">{esc(pname)}</Name>\n'
        x+=f'      <RibbonRow UID="{uid()}">\n        {MR}\n'+entries(rows,8,lay_main)+'      </RibbonRow>\n'
        if slide:
            x+=f'      <RibbonPanelBreak UID="{uid()}" Id="AcRibbonPanelBreak">\n        {MR}\n      </RibbonPanelBreak>\n'
            x+=f'      <RibbonRow UID="{uid()}">\n        {MR}\n'+entries(slide,8,lay_slide)+'      </RibbonRow>\n'
        x+='    </RibbonPanelSource>\n'
        panels_xml+=x
        refs+=f'      <RibbonPanelSourceReference UID="{puid}_REF" PanelId="{puid}" ResizeStyle="Default">\n        {MR}\n      </RibbonPanelSourceReference>\n'
        tl.append((pname,lay_main,lay_slide))
    tabs_xml+=f'    <RibbonTabSource Text="{tabname}" UID="{tabuid}">\n      {MR}\n      <Name xlate="true" UID="XLS_{tabuid}">{tabname}</Name>\n{refs}    </RibbonTabSource>\n'
    LAYOUT.append((tabname,tl))
hdr=open(f'{SRC}/RibbonRoot.cui',encoding='utf-8').read()
hdr=hdr[:hdr.index('<RibbonRoot>')]
rr=(hdr+'<RibbonRoot>\n  <RibbonPanelSourceCollection xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n'
    +panels_xml+'  </RibbonPanelSourceCollection>\n  <RibbonTabSourceCollection>\n'+tabs_xml+'  </RibbonTabSourceCollection>\n</RibbonRoot>')
open(f'{OUT}/RibbonRoot.cui','w',encoding='utf-8').write(rr)
# MenuGroup: append new macros
mg=open(f'{SRC}/MenuGroup.cui',encoding='utf-8').read()
add=''
for u,m in NEWMAC.items():
    add+=(f'    <MenuMacro UID="{u}">\n      <Macro type="Any">\n        <Revision MajorVersion="23" MinorVersion="1" UserVersion="1" />\n        {MR}\n'
          f'        <Name xlate="true" UID="XLS_{u}">{esc(m["name"])}</Name>\n        <Command>{esc(m["cmd"]).replace("&quot;",chr(34))}</Command>\n'
          f'        <SmallImage Name="{esc(m["small"])}" />\n        <LargeImage Name="{esc(m["large"])}" />\n      </Macro>\n    </MenuMacro>\n')
i=mg.rindex('  </MacroGroup>'); mg=mg[:i]+add+mg[i:]
open(f'{OUT}/MenuGroup.cui','w',encoding='utf-8').write(mg)
# package metadata
now=datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S.0000000-05:00')
mpi=open(f'{SRC}/Menu_Package_Info.xml',encoding='utf-8').read()
mpi=re.sub(r'\s*<PartData PartData_Name="/(TRAY-newtest|TESTICONONEINCHa)\.bmp"[^>]*/>','',mpi)
mpi=re.sub(r'(PartData_Name="/(RibbonRoot|MenuGroup)\.cui" PartData_Modified=")[^"]+',lambda m:m.group(1)+now,mpi)
for f in sorted(EMB):
    if f'"/{f}"' not in mpi: mpi=mpi.replace('  <PartData PartData_Name="/Menu_Package_Info.xml"',f'  <PartData PartData_Name="/{f}" PartData_Modified="{now}" />\n  <PartData PartData_Name="/Menu_Package_Info.xml"')
open(f'{OUT}/Menu_Package_Info.xml','w',encoding='utf-8').write(mpi)
rels=open(f'{SRC}/_rels/.rels',encoding='utf-8-sig').read()
rels=re.sub(r'<Relationship Type="Image" Target="/(TRAY-newtest|TESTICONONEINCHa)\.bmp" Id="[^"]+" />','',rels)
import hashlib
for f in sorted(EMB):
    if f'"/{f}"' not in rels:
        rid='R'+hashlib.md5(f.encode()).hexdigest()[:16]
        rels=rels.replace('</Relationships>',f'<Relationship Type="Image" Target="/{f}" Id="{rid}" /></Relationships>')
open(f'{OUT}/_rels/.rels','w',encoding='utf-8').write(rels)
json.dump(LAYOUT,open('/workspace/medrib/gen/layout.json','w'),indent=1)
json.dump(dict(newmac=NEWMAC,newbmp=NEWBMP,used=sorted(USED)),open('/workspace/medrib/gen/genout.json','w'),indent=1)
# pack: keep original zip member order, then new bmps
import zipfile
orig=zipfile.ZipFile('/workspace/medrib/MEDRibbon.cuix') if os.path.exists('/workspace/medrib/MEDRibbon.cuix') else None
names=['[Content_Types].xml','_rels/.rels']
for root,_,fs in os.walk(OUT):
    for f in fs:
        n=os.path.relpath(f'{root}/{f}',OUT).replace(os.sep,'/')
        if n not in names: names.append(n)
os.makedirs('/workspace/medrib/stage',exist_ok=True)
with zipfile.ZipFile('/workspace/medrib/stage/MEDRibbon.cuix','w',zipfile.ZIP_DEFLATED) as z:
    for n in names: z.write(f'{OUT}/{n}',n)
print('panels',sum(len(t[1]) for t in LAYOUT),'newmacros',len(NEWMAC),'newbmp',NEWBMP,'zipnames',len(names))

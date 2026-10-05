import json,os,textwrap
from PIL import Image,ImageDraw,ImageFont
L=json.load(open('layout.json'))
ICON='/workspace/medrib/icons'; EMB='/workspace/medrib/out/rib'
F='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'; FB='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
f9=ImageFont.truetype(F,11); f8=ImageFont.truetype(F,10); fb=ImageFont.truetype(FB,12); ft=ImageFont.truetype(FB,17); fh=ImageFont.truetype(FB,22)
_c={}
def icon(name,sz):
    k=(name,sz)
    if k in _c: return _c[k]
    im=None
    try:
        if name and name.endswith('.bmp'):
            p=f'{EMB}/{name[:-4]}_32.bmp' if sz>16 and os.path.exists(f'{EMB}/{name[:-4]}_32.bmp') else f'{EMB}/{name}'
            im=Image.open(p).convert('RGBA')
        elif name and os.path.exists(f'{ICON}/{name}.png'):
            im=Image.open(f'{ICON}/{name}.png').convert('RGBA')
    except Exception: im=None
    if im is None:
        im=Image.new('RGBA',(sz,sz),(255,0,255,255))
    im=im.resize((sz,sz),Image.LANCZOS if im.width>sz else Image.NEAREST)
    _c[k]=im; return im
def tw(t,f): return f.getbbox(t)[2]
def wrap2(t,f,w):
    words=t.split(); lines=['']
    for x in words:
        c=(lines[-1]+' '+x).strip()
        if tw(c,f)<=w or not lines[-1]: lines[-1]=c
        else: lines.append(x)
    return lines[:2]
BTNH=92
def col_width(e):
    k=e[0]
    if k in('L','splitL'): 
        lbl=e[1][0][0] if k=='L' else e[1]
        return max(56,min(84,max(tw(l,f9) for l in wrap2(lbl+(' ▾' if k=='splitL' else ''),f9,80))+10))
    items=e[1] if k=='stack' else [(e[1]+' ▾',e[2][0][1])]
    return 24+max(tw(i[0],f9) for i in items)+8
def draw_col(d,img,e,x,y):
    k=e[0]; w=col_width(e)
    if k in('L','splitL'):
        lbl,ic=(e[1][0] if k=='L' else (e[1],e[2][0][1]))
        img.alpha_composite(icon(ic,32),(x+(w-32)//2,y+6))
        for i,l in enumerate(wrap2(lbl+(' ▾' if k=='splitL' else ''),f9,w-6)):
            d.text((x+(w-tw(l,f9))//2,y+44+i*13),l,font=f9,fill=(20,20,20))
        if k=='splitL':
            d.rectangle([x+1,y+2,x+w-2,y+BTNH-6],outline=(150,170,200))
    else:
        items=e[1] if k=='stack' else [(e[1]+' ▾',e[2][0][1])]
        for i,(lbl,ic) in enumerate(items):
            yy=y+6+i*27
            img.alpha_composite(icon(ic,16),(x+4,yy+2))
            d.text((x+24,yy+3),lbl,font=f9,fill=(20,20,20))
            if k=='splitS': d.rectangle([x+1,yy,x+w-2,yy+21],outline=(150,170,200))
    return w
def legend_lines(m,sl,width):
    out=[]
    for e in m+sl:
        if e[0].startswith('split'):
            out+= [('▾ '+e[1]+': ',', '.join(i[0] for i in e[2]))]
    sll=[]
    for e in sl:
        if e[0] in('L','stack'): sll+=[i[0] for i in e[1]]
        else: sll.append(e[1]+' ▾')
    lines=[]
    if sll: lines+=[(True,l) for l in textwrap.wrap('Slide-out ▿: '+', '.join(sll),width)]
    for h,b in out: lines+=[(False,l) for l in textwrap.wrap(h+b,width)]
    return lines
W=1900; PAD=12
def panel_size(pn,m,sl):
    w=sum(col_width(e) for e in m)+6*(len(m)-1)+12
    w=max(w,tw(pn,fb)+30,170)
    chars=max(30,int((w-10)/6.1))
    leg=legend_lines(m,sl,chars)
    return w,BTNH+22+len(leg)*13+8,leg,chars
tabs=[]
for tab,ps in L:
    rows=[[]]; x=0
    for pn,m,sl in ps:
        w,h,leg,ch=panel_size(pn,m,sl)
        if x+w>W-2*PAD and rows[-1]: rows.append([]); x=0
        rows[-1].append((pn,m,sl,w,h,leg)); x+=w+8
    tabs.append((tab,rows))
H=70+sum(40+sum(max(p[4] for p in r)+10 for r in rows)+16 for _,rows in tabs)+40
img=Image.new('RGBA',(W,H),(255,255,255,255)); d=ImageDraw.Draw(img)
d.text((PAD,12),'MED ribbon layout preview (MEDRibbon.cuix): MED Main always shown + the current mode tab (MEDPLAN / MEDDETAIL / MEDWIRING)',font=fh,fill=(0,0,0))
d.text((PAD,42),'Large = 32px icon with label under it.  Small = 16px icon with label beside it.  Boxed ▾ = split button (contents listed under the panel).  Slide-out ▿ = items under the panel arrow.',font=f9,fill=(70,70,70))
y=70
for tab,rows in tabs:
    d.rectangle([PAD,y,PAD+tw(tab,ft)+28,y+30],fill=(45,85,140)); d.text((PAD+14,y+5),tab,font=ft,fill=(255,255,255))
    d.line([PAD,y+30,W-PAD,y+30],fill=(45,85,140),width=2); y+=38
    for r in rows:
        x=PAD; rh=max(p[4] for p in r)
        for pn,m,sl,w,h,leg in r:
            d.rectangle([x,y,x+w,y+rh],fill=(243,246,250),outline=(170,180,195))
            cx=x+6
            for e in m: cx+=draw_col(d,img,e,cx,y)+6
            ty=y+BTNH
            d.rectangle([x,ty,x+w,ty+18],fill=(214,222,234))
            d.text((x+(w-tw(pn,fb))//2-(6 if sl else 0),ty+2),pn,font=fb,fill=(30,40,60))
            if sl: d.text((x+w-14,ty+2),'▿',font=fb,fill=(30,40,60))
            for i,(isS,l) in enumerate(leg):
                d.text((x+5,ty+22+i*13),l,font=f8,fill=(90,60,0) if isS else (60,60,60))
            x+=w+8
        y+=rh+10
    y+=16
img=img.crop((0,0,W,y+10)).convert('RGB')
img.save('/workspace/medrib/stage/med-ribbon-layout.png'); print(img.size)

import sys,re,json
sys.path.insert(0,'/workspace/medrib/work')
from dump import load
_,_,RIB=load('/workspace/medrib/ex/rib')
_,_,MED=load('/workspace/medrib/ex/med')
def norm(c):
    c=c.upper().replace('\\',' ')
    c=re.sub(r'\s+',' ',c).strip()
    c=re.sub(r'\s*([()])\s*',r'\1',c)
    c=re.sub(r'^(\^C)+','',c)
    c=c.replace(';',' ').strip()
    return c
IDX={}
for src,pool in (('med',MED),('rib',RIB)):   # rib last wins -> prefer rib uid
    for u,m in pool.items():
        IDX.setdefault(norm(m['cmd']),[]).append((src,u,m))
def find(cmd):
    return IDX.get(norm(cmd),[])

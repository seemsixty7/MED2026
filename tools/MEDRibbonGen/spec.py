# MED ribbon layout spec. Items reference macros by command text (looked up in
# MEDRibbon.cuix first, then med.cuix; else a new macro is created).
# B(label, cmd, img=None, tip=None)  -> button
# Panel rows: list of entries:
#   ('L', B)            large button with text
#   ('S', B)            small button with text (alone in row)
#   ('stack', [B,...])  2-3 small buttons stacked (SmallWithText)
#   ('stackicons', [B,...]) stacked small buttons without text
#   ('split', label, [B,...], style)  style 'L' (large) or 'S' (small, in stack)
#   ('splitstack', [split,...]) stack of small split buttons
class B:
    def __init__(s,label,cmd,img=None,tip=None):
        s.label,s.cmd,s.img,s.tip=label,cmd,img,tip or label

def fsz(lbl,a,l,c): return B(lbl,'^C^C(setq _ACSIZE %s _CLETT "%s" _CSIZE %s)'%(a,l,c))
CON_SIZES=[B('1/2"','^C^C(setq _ACSIZE 0.84  _CLETT "A" _CSIZE 0.5 )','CON_0050'),
 B('3/4"','^C^C(setq _ACSIZE 1.050 _CLETT "B" _CSIZE 0.75)','CON_0075'),
 B('1"','^C^C(setq _ACSIZE 1.315 _CLETT "C" _CSIZE 1.0 )','CON_0100'),
 B('1-1/4"','^C^C(setq _ACSIZE 1.660 _CLETT "D" _CSIZE 1.25)','CON_0125'),
 B('1-1/2"','^C^C(setq _ACSIZE 1.9   _CLETT "E" _CSIZE 1.5 )','CON_0150'),
 B('2"','^C^C(setq _ACSIZE 2.375 _CLETT "F" _CSIZE 2.0 )','CON_0200'),
 B('2-1/2"','^C^C(setq _ACSIZE 2.875 _CLETT "G" _CSIZE 2.5 )','CON_0250'),
 B('3"','^C^C(setq _ACSIZE 3.50  _CLETT "H" _CSIZE 3.0 )','CON_0300'),
 B('3-1/2"','^C^C(setq _ACSIZE 4.0   _CLETT "I" _CSIZE 3.5 )','CON_0350'),
 B('4"','^C^C(setq _ACSIZE 4.50  _CLETT "J" _CSIZE 4.0 )','CON_0400'),
 B('5"','^C^C(setq _ACSIZE 5.563 _CLETT "K" _CSIZE 5.0 )','CON_0500'),
 B('6"','^C^C(setq _ACSIZE 6.625 _CLETT "L" _CSIZE 6.0 )','CON_0600')]
for b in CON_SIZES: b.tip='Set conduit size '+b.label

def sym(lbl,blk,img,extra=''):
    return B(lbl,'^C^C(medblkins _MEDSYM "%s" nil nil _SC -1)'%blk if not extra else extra,img)
def detfit(lbl,code,blk,mode,img='FIT_CONDULET'):
    return B(lbl,'^C^C(setq _FITTCODE %s) (medblkins _MEDETFIT (strcat "%s" _CLETT) nil nil 1 %s)'%(code,blk,mode),img)

# ---------------------------------------------------------------- MED Main
MAIN=[
 ('Mode',[
   ('L',B('Plan Drawings','^C^CMEDPLAN','CON_CONDUIT','Plan mode: MED Plan tab + Plan pulldowns (MEDPLAN)')),
   ('L',B('Detail Drawings','^C^CMEDDETAIL','FIT_CONDULET','Detail mode: MED Detail tab + Detail pulldowns (MEDDETAIL)')),
   ('L',B('Wiring Diagrams','^C^CMEDWIRING','SYM_CONTACT','Wiring mode: MED Wiring tab + Wiring pulldowns (MEDWIRING)')),
   ('stack',[B('Title Block Setup','^C^CSETUP','LSP_SETUP')]),
  ],[]),
 ('MED Data Tools',[
   ('L',B('MED Change','^C^CMEDCHG','LSP_MEDCHG','MED Change (MED Properties palette)')),
   ('L',B('MED Settings','^C^CMEDSET','LSP_MEDSET')),
   ('stack',[B('MED Records','^C^CMEDRECORDS'),B('MED 3D Library','^C^CMED3DLIB'),B('MED Change Classic','^C^CMEDCHG-CLASSIC')]),
   ('stack',[B('BOM','^C^CBOM','LSP_BOM','MED Data to BOM'),B('BOM SS','^C^CBOMSS','LSP_BOMSS','BOM from a selection set'),B('Browse BOM','^C^CMEDSHOWBOM','LSP_BROWSE')]),
   ('stack',[B('Detail Update','^C^CDETAGUPD','LSP_DETAGUPD'),B('MED Find','^C^CMEDFIND','LSP_MEDFIND','MED Item Find'),B('MED Copy','^C^CMEDCOPY','LSP_MEDCOPY','MED Data Copy')]),
   ('stack',[B('MED Data Strip','^C^CMEDSTRIP','LSP_MEDSTRIP'),B('Change Size','^C^CCHGSIZE','LSP_CHGSZ','Change conduit or fitting size (1" to 2")')]),
  ],[
   ('stack',[B('MED List','^C^CMEDLIST','LSP_MEDLIST'),B('Isolate Equip','^C^CISOLATE','LSP_MEDFIND'),B('Unisolate Equip','^C^CUNISOLATE','LSP_SL')]),
  ]),
 ('3D',[
   ('L',B('MED 3D Library','^C^CMED3DLIB')),
   ('L',B('Make 3D','^C^CMEDMAKE3D','TRAY_3DTRAYOUT','MEDMAKE3D: tray, fittings, conduit, conduit bodies and cable to 3D. 3D models are approximations; verify all dimensions.')),
   ('stack',[B('3D Tray Out','^C^CMAKE3DTRAY','TRAY_3DTRAYOUT')]),
  ],[]),
 ('Text',[
   ('L',B('Body Text','^C^C(if (not C:T1) (c:loadtxt)) T1','LSP_T1','T1: body text in the default MED style (0.125 plotted)')),
   ('stack',[B('Medium Text','^C^C(if (not C:T2) (c:loadtxt)) T2','LSP_T2','T2: medium text (0.15625 plotted)'),
             B('Large Text','^C^C(if (not C:T3) (c:loadtxt)) T3','LSP_T3','T3: large text (0.1875 plotted)'),
             B('Load Text Styles','^C^CLOADTXT','LSP_LOADTXT')]),
   ('stack',[B('Bold Body','^C^C(if (not C:B1) (c:loadtxt)) B1','LSP_B1','B1: body text on the bold layer'),
             B('Bold Medium','^C^C(if (not C:B2) (c:loadtxt)) B2','LSP_B2','B2: medium text on the bold layer'),
             B('Bold Large','^C^C(if (not C:B3) (c:loadtxt)) B3','LSP_B3','B3: large text on the bold layer')]),
   ('stack',[B('Change Text','^C^CCT','LSP_CT'),B('Replace Text','^C^CRT','LSP_RT'),B('Change Text Styles','^C^CXT','LSP_XT')]),
  ],[
   ('stack',[B('Coordinate Text','^C^CCD','LSP_CT'),B('Find & Replace Text','^C^CCX','LSP_RT'),B('Suffix & Prefix','^C^CCTEDIT','LSP_CT')]),
  ]),
 ('Tagging',[
   ('split','Tags',[B('Conduit Tag','^C^CCTAG','LSP_CTAG'),B('Tray Tag','^C^CTTAG','LSP_TTAG'),B('Detail Tag','^C^CDETAG','LSP_DETAG'),
                    B('HotDog Tag','^C^CHDTAG','LSP_HDTAG'),B('Instrument Bubble','^C^CIT','LSP_IT'),B('Material Bubble','^C^CMB','LSP_MB'),
                    B('Material Bubble 2','^C^CMB1','LSP_MB2'),B('Wire Markers','^C^CWIRES','LSP_WIRES')],'L'),
   ('stack',[B('Add Bubble Leader','^C^CABL','LSP_ABL'),B('Move Bubble/Leader','^C^CMBL','LSP_MBL'),B('Section Marks','^C^CSECT','LSP_SECT')]),
  ],[
   ('stack',[B('Cut Marks','^C^CCUT','LSP_CUT'),B('Add Hoop','^C^CGR','LSP_ADDHOOP')]),
  ]),
 ('Attributes',[
   ('stack',[B('Attribute Change','^C^CACX','LSP_ACX'),B('Attribute Replace','^C^CAC','LSP_AC'),B('Attribute Rotate','^C^CATTROT','LSP_ATTROT')]),
   ('stack',[B('Dialog Edit','^C^CDD','LSP_DD')]),
  ],[]),
 ('Utilities',[
   ('split','Leaders',[B('Arrow Leader','^C^CALEAD','LSP_ALEAD'),B('Hoop Leader','^C^CGRAB','LSP_GRAB'),B('Loop Leader','^C^CLOOPIT','LSP_LOOPIT')],'L'),
   ('stack',[B('Revision Cloud','^C^CCLOUD','LSP_CLOUD'),B('Box Cloud','^C^CBOXCLOUD','LSP_BOXCLOUD'),B('Draw Pline Box','^C^CPBOX','LSP_PBOX')]),
  ('L',B('Parametric Motor','^C^CMOTOR','LSP_MOTOR','2D plan motor from MOTOR.DAT')),
   ('stack',[B('Line Break','^C^CLBREAK','LSP_LBREAK'),B('Priority Break','^C^CLB','LSP_LB'),B('Bracket','^C^CBRACKET','LSP_BRACKET')]),
   ('stack',[B('Change Layer','^C^CCL','LSP_CL'),B('Set Current Layer','^C^CSL','LSP_SL'),B('Freeze Layers','^C^CFL','LSP_FL')]),
  ],[
   ('stack',[B('Polyline Width','^C^CPW','LSP_PW'),B('Extend Multiple','^C^CEM','LSP_EM.bmp'),B('Trim Multiple','^C^CTM','LSP_TM.bmp')]),
   ('stack',[B('Block Name','^C^CBN','LSP_MEDLIST'),B('File Date','^C^CFD','LSP_FILEDATE'),B('Tray Fix','^C^CTRAYFIX','TRAY_TRAYFIX')]),
   ('stack',[B('Fillet Zero Radius','^C^CF0','LSP_FILLET000'),B('Fillet 0.0625','^C^CFILLET R (* _SC 0.06250) FILLET','LSP_FILLET625'),B('Fillet 0.09375','^C^CFILLET R (* _SC 0.09375) FILLET','LSP_FILLET937')]),
   ('stack',[B('Fillet 0.125','^C^CFILLET R (* _SC 0.12500) FILLET','LSP_FILLET125'),B('Fillet Conduit','^C^CFC','LSP_FILLETFC')]),
  ]),
 ('Symbols',[
   ('stack',[B('North Arrow','^C^C(medblkins _MEDSYM "n_arrow" nil nil _SC -1)','SYM_NARR'),B('Break Symbol','^C^C(medblkins _MEDSYM "break" nil nil _SC -1)','SYM_BREAK'),
             B('Arrow','^C^C(medblkins _MEDSYM "arrhead" nil nil (* _LEADSYMSIZE _SC) -1)','SYM_ARROW')]),
   ('stack',[B('Separate Symbol','^C^C(medblkins _MEDSYM "separ" nil nil _SC -1)','SYM_CONTINUE'),B('Revision Triangle','^C^C(medblkins _REVISION "revtag" nil nil _SC -1)','LSP_REVTAG'),
             B('Double Lines','^C^C2LINE','LSP_2LINE')]),
  ],[
   ('stack',[B('Triple Lines','^C^C3LINE','LSP_3LINE'),B('Tags Icons...','$I=MED.MEDTAGSICON $I=*','LSP_CTAG','Classic tagging image menu'),B('Tools Icons...','$I=MED.MEDTOOLSICON $I=*','LSP_PBOX','Classic misc tools image menu')]),
  ]),
]

# ---------------------------------------------------------------- MED Plan
TRAY_W=[B('%d" Tray'%w,'^C^C(setq _TRSIZE %s)'%('%4.1f'%w).replace(' ',' '),'TRAY_%02d00'%w if w>=10 else 'TRAY_0%d00'%w,'Set tray width to %d"'%w) for w in (6,9,12,18,24,30,36,42,48)]
PLAN=[
 ('Conduit',[
   ('split','Conduit Size',CON_SIZES,'L'),
   ('split','Conduit Type',[B('EMT','^C^C(smlayer _MCON) (setq _CODE 4) CONDUIT','CON_EMT','Draw EMT conduit'),
                            B('PVC','^C^C(smlayer _MCON) (setq _CODE 3) CONDUIT','CON_PVC','Draw PVC conduit'),
                            B('Rigid','^C^C(smlayer _MCON) (setq _CODE 1) CONDUIT','CON_RGS','Draw rigid (RGS) conduit'),
                            B('PVC-Coat','^C^C(smlayer _MCON) (setq _CODE 2) CONDUIT','CON_PVCRGS','Draw PVC-coated rigid conduit'),
                            B('IMT','^C^C(smlayer _MCON) (setq _CODE 6) CONDUIT','CON_IMT','Draw intermediate metallic tubing')],'L'),
   ('stack',[B('Up','^C^C(smlayer _MCON) (medblkins nil "1conu" nil nil _SC 5)','CON_UPOPEN','Conduit up'),
             B('Up Solid','^C^C(smlayer _MCON) (medblkins nil "1conus" nil nil _SC 5)','CON_UP','Conduit up (solid)'),
             B('Down','^C^C(smlayer _MCON) (medblkins nil "1cond" nil nil _SC 4)','CON_DOWN','Conduit down')]),
   ('stack',[B('Flex','^C^Cflex','CON_FLEX','Flexible conduit'),B('Define','^C^CDEFINE','LSP_MEDCHG','Attach current conduit settings to an existing run'),
             B('Set Size...','^C^CCONSIZE','CON_0100','Conduit size dialog')]),
  ],[
   ('stack',[B('Conduit Icons...','$i=MED.MEDplancon $i=*','CON_CONDUIT','Classic plan conduit image menu')]),
  ]),
 ('Conduit Fittings',[
   ('split','LB Fittings',[B('LBL','^C^C(setq _FITTCODE  30) (medblkins _MEDFIT "1lbl"     nil nil _SC 2)','CON_LB1'),
                           B('LBR','^C^C(setq _FITTCODE  30) (medblkins _MEDFIT "1lbr"     nil nil _SC 2)','CON_LB2'),
                           B('LB Up Open','^C^C(setq _FITTCODE  30) (medblkins _MEDFIT "1lbuo"     nil nil _SC 6)','CON_LBUPOPEN'),
                           B('LB Up','^C^C(setq _FITTCODE  30) (medblkins _MEDFIT "1lbu"     nil nil _SC 6)','CON_LBUP'),
                           B('LB Down','^C^C(setq _FITTCODE  30) (medblkins _MEDFIT "1lbd"     nil nil _SC 3)','CON_LBDOWN'),
                           B('LBY','^C^C(setq _FITTCODE  41) (medblkins _MEDFIT "1lby"     nil nil _SC 2)','CON_LBY'),
                           B('LBD R','^C^C(setq _FITTCODE  39) (medblkins _MEDFIT "1lbdr"    nil nil _SC 2)','CON_LBD2'),
                           B('LBD L','^C^C(setq _FITTCODE  39) (medblkins _MEDFIT "1lbdl"    nil nil _SC 2)','CON_LBD1'),
                           B('LL','^C^C(setq _FITTCODE  33) (medblkins _MEDFIT "1lbl"     nil nil _SC 2)','CON_LL','LL fitting'),
                           B('LR','^C^C(setq _FITTCODE  36) (medblkins _MEDFIT "1lbr"     nil nil _SC 2)','CON_LR','LR fitting')],'L'),
   ('split','Tee / X',[B('Tee','^C^C(setq _FITTCODE  11) (medblkins _MEDFIT "1tee"     nil nil _SC 2)','CON_TEE'),
                       B('Tee Up Open','^C^C(setq _FITTCODE  11) (medblkins _MEDFIT "1teeuo"    nil nil _SC 6)','CON_TEEUPOPEN'),
                       B('Tee Up','^C^C(setq _FITTCODE  11) (medblkins _MEDFIT "1teeu"    nil nil _SC 6)','CON_TEEUP'),
                       B('Tee Down','^C^C(setq _FITTCODE  11) (medblkins _MEDFIT "1teed"    nil nil _SC 3)','CON_TEEDOWN'),
                       B('X','^C^C(setq _FITTCODE  80) (medblkins _MEDFIT "1exs"     nil nil _SC 2)','CON_CROSS','X (cross) fitting')],'L'),
   ('split','Fittings',[B('Seal','^C^C(setq _FITTCODE  61) (medblkins _MEDFIT "1seal"    nil nil _SC 2)','CON_SEAL'),
                        B('Seal-Drain','^C^C(setq _FITTCODE  64) (medblkins _MEDFIT "1sealdr"  nil nil _SC 2)','CON_SEALDR'),
                        B('Union','^C^C(setq _FITTCODE  72) (medblkins _MEDFIT "1union"   nil nil _SC 2)','CON_UNION'),
                        B('Cee','^C^C(setq _FITTCODE  50) (medblkins _MEDFIT "1cee"     nil nil _SC 2)','CON_CEE'),
                        B('Hub','^C^C(setq _FITTCODE 120) (medblkins _MEDFIT "1hub"     nil nil _SC 2)','CON_HUB'),
                        B('Reducer','^C^C(setq _FITTCODE 103 _TYPE T) (medblkins _MEDFIT "1re"      nil nil _SC 8)','CON_RE'),
                        B('Pulling Fitting (Bub)','^C^C(setq _FITTCODE  94) (medblkins _MEDFIT "1bub"     nil nil _SC 2)','CON_BUB'),
                        B('Plug - Square Head','^C^C(setq _FITTCODE 101) (medblkins _MEDFIT "1cap"     nil nil _SC 2)','CON_SQPLUG'),
                        B('Plug - Recessed','^C^C(setq _FITTCODE 100) (medblkins _MEDFIT "1capa"     nil nil _SC 2)','CON_REPLUG')],'L'),
   ('split','GUA',[B('GUAL','^C^C(setq _FITTCODE 141) (medblkins _MEDFIT "1gual"    nil nil _SC 2)','CON_GUAL'),
                   B('GUAT','^C^C(setq _FITTCODE 142) (medblkins _MEDFIT "1guat"    nil nil _SC 2)','CON_GUAT'),
                   B('GUAX','^C^C(setq _FITTCODE 143) (medblkins _MEDFIT "1guax"    nil nil _SC 2)','CON_GUAX'),
                   B('GUAT Side View','^C^C(setq _FITTCODE 142) (medblkins _MEDFIT "1guatsid" nil nil _SC 2)','CON_GUAT'),
                   B('GUAL Side View','^C^C(setq _FITTCODE 141) (medblkins _MEDFIT "1gualsid" nil nil _SC 2)','CON_GUAL')],'L'),
  ],[
   ('stack',[B('18" LR Elbow','^C^C(attachfitting 89)','CON_CONDUIT','18" RGS long radius elbow'),
             B('24" LR Elbow','^C^C(attachfitting 90)','CON_CONDUIT','24" RGS long radius elbow'),
             B('36" LR Elbow','^C^C(attachfitting 91)','CON_CONDUIT','36" RGS long radius elbow')]),
   ('stack',[B('Fitting Icons...','$i=MED.MEDplanfit $i=*','CON_TEE','Classic plan fittings image menu')]),
  ]),
 ('Cables',[
   ('split','Ground Cable',[B('#4/0 Gnd Cable','^C^C(smlayer _MEDGRND)(setq _CABCODE 308) cable','CAB_NUM40'),
                            B('#2/0 Gnd Cable','^C^C(smlayer _MEDGRND)(setq _CABCODE 310) cable','CAB_NUM20'),
                            B('#2 Gnd Cable','^C^C(smlayer _MEDGRND)(setq _CABCODE 313) cable','CAB_NUM2')],'L'),
   ('stack',[B('Gnd Up','^C^C(smlayer _MEDGRND) (medblkins nil "1conu" nil nil _SC 11)','CAB_UPOPEN','Ground cable up'),
             B('Gnd Up Solid','^C^C(smlayer _MEDGRND) (medblkins nil "1conus" nil nil _SC 11)','CAB_UP','Ground cable up (solid)'),
             B('Gnd Down','^C^C(smlayer _MEDGRND) (medblkins nil "1cond" nil nil _SC 10)','CAB_DOWN','Ground cable down')]),
  ],[]),
 ('Cable Tray',[
   ('split','Tray Type',[B('Heavy Duty','^C^C(setq _TRTYPE 2) TRAY','TRAY_HEAVY','Heavy duty cable tray'),
                         B('Medium Duty','^C^C(setq _TRTYPE 1) TRAY','TRAY_MEDIUM','Medium duty cable tray'),
                         B('Light Duty','^C^C(setq _TRTYPE 0) TRAY','TRAY_LIGHT','Light duty cable tray')],'L'),
   ('split','Tray Width',TRAY_W,'L'),
   ('split','Tray Depth',[B('3" Depth','^C^C(setq _TRDEPTH 3.0)','TRAY_03DPTH'),B('4" Depth','^C^C(setq _TRDEPTH 4.0)','TRAY_04DPTH'),
                          B('6" Depth','^C^C(setq _TRDEPTH 6.0)','TRAY_06DPTH')],'L'),
   ('stack',[B('Tray Fix','^C^CTRAYFIX','TRAY_TRAYFIX','Tray Fix (works on tray and fittings)')]),
  ],[]),
 ('Tray Fittings',[
   ('split','Radius',[B('12" Radius','^C^C(setq _TRFITTADD 0 _TRRAD 12.0)','TRAY_12RAD'),B('24" Radius','^C^C(setq _TRFITTADD 1 _TRRAD 24.0)','TRAY_24RAD'),
                      B('36" Radius','^C^C(setq _TRFITTADD 2 _TRRAD 36.0)','TRAY_36RAD'),B('48" Radius','^C^C(setq _TRFITTADD 120 _TRRAD 48.0)','TRAY_48RAD')],'L'),
   ('split','Elbows',[B('90 Elbow','^C^CTRAY90','TRAY_FITT90'),B('60 Elbow','^C^CTRAY60','TRAY_FITT60'),
                      B('45 Elbow','^C^CTRAY45','TRAY_FITT45'),B('30 Elbow','^C^CTRAY30','TRAY_FITT30')],'L'),
   ('split','Tee / Cross / Reducer',[B('Tee','^C^CTRAYTEE','TRAY_FITTTEE'),B('Cross','^C^CTRAYCROSS','TRAY_FITTCROSS'),
                      B('Straight Reducer','^C^CTRAYRE','TRAY_FITTRESTR'),B('Left Reducer','^C^CTRAYREL','TRAY_FITTRELH'),B('Right Reducer','^C^CTRAYRER','TRAY_FITTRERH')],'L'),
  ],[
   ('split','Side View Elbows',[B('VTRAY 90','^C^CVTRAY90','TRAY_SIDE90.bmp','Side view 90 elbow'),B('VTRAY 60','^C^CVTRAY60','TRAY_SIDE60.bmp','Side view 60 elbow'),
                                B('VTRAY 45','^C^CVTRAY45','TRAY_SIDE45.bmp','Side view 45 elbow'),B('VTRAY 30','^C^CVTRAY30','TRAY_SIDE30.bmp','Side view 30 elbow')],'S'),
   ('stack',[B('Side View Tray','^C^CVTRAY','TRAY_SIDEVIEW.bmp','VTRAY: side view cable tray (kept for older side-view drawings)'),
             B('Side View Offset','^C^CVTRAYOFF','TRAY_VOFFSET.bmp','VTRAYOFF: side view offset (kept for older side-view drawings)'),
             B('Plan Tray Icons...','$i=MED.MEDtraysldp $i=*','TRAY_HEAVY','Classic plan tray image menu')]),
   ('stack',[B('Side Tray Icons...','$i=MED.MEDtraysldv $i=*','TRAY_SIDEVIEW.bmp','Classic side view tray image menu')]),
  ]),
 ('Tray Layout',[
   ('L',B('Horizontal Offset','^C^CTRAYOFF','TRAY_OFFSET')),
   ('L',B('Vertical Offset','^C^CPTRAYOFF','TRAY_PTRAYOFF','PTRAYOFF (prompts for Up/Down)')),
   ('stack',[B('Plan Vert 90','^C^CTRAYV90','TRAY_FITTV90'),B('Tray Down','^C^Ctraydn','TRAY_DOWN'),B('Tray Up','^C^Ctrayup','TRAY_UP')]),
  ],[
   ('split','Cable Channel',[B('4" Channel','^C^C(setq _CHANSIZE 4.0) channel','TRAY_LIGHT','4" cable channel'),
                             B('6" Channel','^C^C(setq _CHANSIZE 6.0) channel','TRAY_LIGHT','6" cable channel')],'S'),
   ('split','Channel Fittings',[B('Chan 90','^C^Cchan90','TRAY_FITT90','90 deg channel fitting'),B('Chan 60','^C^Cchan60','TRAY_FITT60','60 deg channel fitting'),
                                B('Chan 45','^C^Cchan45','TRAY_FITT45','45 deg channel fitting'),B('Chan 30','^C^Cchan30','TRAY_FITT30','30 deg channel fitting'),
                                B('Chan Cross','^C^CCHANCROSS','TRAY_FITTCROSS','Channel cross'),B('Chan Tee','^C^CCHANTEE','TRAY_FITTTEE','Channel tee')],'S'),
   ('stack',[B('Chan Vert 90','^C^CCHANV90','TRAY_FITTV90','Channel plan vertical 90'),B('Chan Down','^C^Cchandn','TRAY_DOWN','Channel down'),B('Chan Up','^C^Cchanup','TRAY_UP','Channel up')]),
   ('stack',[B('Chan Offset','^C^CCHANOFF','TRAY_OFFSET','Channel offset'),B('Channel Icons...','$i=MED.MEDchansld $i=*','TRAY_LIGHT','Classic channel image menu')]),
  ]),
 ('Details & Equipment',[
   ('L',B('Details...','^C^CDETAIL','LSP_DETAG','DETAIL: attach a detail to equipment')),
   ('stack',[B('Lighting','^C^CLTG','EQP_LTG','Lighting details'),B('Grounding','^C^CGND','EQP_GND','Grounding details'),B('Power','^C^CPWR','EQP_PWR','Power details')]),
   ('stack',[B('Instrumentation','^C^CINS','EQP_INS','Instrument details (INS)'),B('Tray','^C^CTRY','EQP_TRY','Tray details')]),
   ('split','Receptacles',[
      B('120V Receptacle','^C^C(opt_eq_ins (list (list "" 10)) 1 "1plug" _MEDELEQP)','EQP_PLUG120'),
      B('120V Dedicated','^C^C(opt_eq_ins (list (list "" 10)) 1 "1plugded" _MEDELEQP)','EQP_PLUGDED'),
      B('120V GFI','^C^C(opt_eq_ins (list (list "" 11)) 1 "1gfci" _MEDELEQP)','EQP_PLUGGFI'),
      B('240V Receptacle','^C^C(opt_eq_ins (list (list "" 12)) 1 "1plug230" _MEDELEQP)','EQP_PLUG240'),
      B('Welding Receptacle','^C^C(opt_eq_ins (list (list "" 13)) 1 "1weld" _MEDELEQP)','EQP_PLUGWELD'),
      B('Switch','^C^C(opt_eq_ins (list (list "" 14)) 1 "1switch" _MEDELEQP)','EQP_SWITCH'),
      B('Photocell','^C^C(opt_eq_ins (list (list "" 15)) 1 "1photo" _MEDELEQP)','EQP_PHOTOCELL'),
      B('Phone Jack','^C^C(opt_eq_ins (list (list "" 16)) 1 "1phnjk" _MEDELEQP)','EQP_PHONE')],'L'),
   ('split','Lighting',[B('Ceiling/Pendant Light','^C^C(opt_eq_ins (list (list "" 1)) 1 "1liteoh" _MEDELEQP)','EQP_OHLITE'),
      B('Wall Mount Light','^C^C(opt_eq_ins (list (list "" 2)) 1 "1litewm" _MEDELEQP)','EQP_WALLLITE'),
      B('Stanchion Mount Light','^C^C(opt_eq_ins (list (list "" 3)) 1 "1stanlit" _MEDELEQP)','EQP_STANLITE'),
      B('Schedule Designator','^C^C(medblkins _MEDELEQP "1litype" nil nil _SC -1)','EQP_LITETYPE'),
      B('WallPack Light','^C^C(opt_eq_ins (list (list "" 4)) 1 "1paclite" _MEDELEQP)','EQP_WALLPACK'),
      B('Emergency Light','^C^C(opt_eq_ins (list (list "" 5)) 1 "1emrglit" _MEDELEQP)','EQP_EMERG'),
      B('Exhaust Fan','^C^C(opt_eq_ins (list (list "" 7)) 1 "1fanoh" _MEDELEQP)','EQP_CIELFAN'),
      B('Flood Light Pole','^C^C(opt_eq_ins (list (list "" 9)) 1 "1fpole" _MEDELEQP)','EQP_POLE'),
      B('Flood Light','^C^C(opt_eq_ins (list (list "" 8)) 1 "1flite" _MEDELEQP)','EQP_FLITE')],'L'),
   ('split','Grounding',[
      B('Ground Well','^C^C(opt_eq_ins (list (list "" 202)) 1 "1grnd" _MEDGRND)','EQP_GNDWELL'),
      B('Ground Test Well','^C^C(opt_eq_ins (list (list "" 203)) 1 "1grndtw" _MEDGRND)','EQP_TESTWELL'),
      B('Ground Splice','^C^C(opt_eq_ins (list (list "#4/0x#4/0" 204) (list "#4/0x#2/0" 205)(list "#4/0x#2" 206)) 1 "1grmain" _MEDGRND)','EQP_GNDSPLICE'),
      B('Ground Tap','^C^C(opt_eq_ins (list (list "Motor Tap" 201) (list "#4/0x#2/0" 207)(list "#4/0x#2" 208)(list "#2/0x#2" 209)) 1 "1grtap" _MEDGRND)','EQP_GNDTAP')],'L'),
  ],[
   ('split','Fluorescent',[
      B('4x2 Fluorescent','^C^C(opt_eq_ins (list (list "" 17)) 0 "14x2flit" _MEDELEQP)','EQP_42FLUOR'),
      B('4x1 Fluorescent','^C^C(opt_eq_ins (list (list "" 18)) 0 "14x1flit" _MEDELEQP)','EQP_41FLUOR'),
      B('8x1 Fluorescent','^C^C(opt_eq_ins (list (list "" 19)) 0 "11x8flit" _MEDELEQP)','EQP_81FLUOR'),
      B('8 ft Slim Line','^C^C(opt_eq_ins (list (list "" 20)) 0 "18flite" _MEDELEQP)','EQP_8SLIM')],'S'),
   ('split','Detectors & Alarms',[
      B('Gas Detector','^C^C(opt_eq_ins (list (list "" 801)) 1 "1gasd" _MEDELEQP)','EQP_GASDET'),
      B('Smoke Detector','^C^C(opt_eq_ins (list (list "" 802)) 1 "1smoked" _MEDELEQP)','EQP_SMOKEDET'),
      B('Temperature Detector','^C^C(opt_eq_ins (list (list "" 803)) 1 "1tempd" _MEDELEQP)','EQP_TEMPDET'),
      B('Flame Detector','^C^C(opt_eq_ins (list (list "" 804)) 1 "1flamed" _MEDELEQP)','EQP_FLAMEDET'),
      B('Horn','^C^C(opt_eq_ins (list (list "" 805)) 1 "1horn" _MEDELEQP)','EQP_HORN')],'S'),
  ]),
]

# ---------------------------------------------------------------- MED Detail
DETAIL=[
 ('Detail Conduit',[
   ('split','Conduit Size',CON_SIZES,'L'),
   ('L',B('Draw Conduit','^C^C(smlayer _MCON) (setq _CODE 1) 2lcon','CON_CONDUIT','Draw two-line detail conduit')),
   ('L',B('Draw Flex','^C^C(smlayer _MCON) (setq _CODE 7) 2lflex','CON_FLEX','Draw two-line flex')),
   ('stack',[B('Add Break','^C^C2break','CON_BREAK'),B('Turn Away','^C^C2away','CON_AWAY'),B('Turn Toward','^C^C2toward','CON_TOWARD')]),
   ('stack',[B('Bends On/Off','(toggle "_CONFILL" "Conduit Bend Radius")','VAR_BENDS.bmp','Toggle conduit bend radius')]),
  ],[]),
 ('Fittings',[
   ('split','Condulets',[detfit('Bub (Pulling)',' 94','bub',2,'CON_BUB'),detfit('Coupling','  8','coup',2),detfit('Cee',' 51','c',1,'CON_CEE'),
                         detfit('Hub CH','120','hub',2,'CON_HUB'),detfit('Hub MYR','121','mhub',2,'CON_HUB'),
                         detfit('LB',' 31','lb',1,'CON_LB1'),detfit('LB Rev',' 31','lb_',1,'CON_LB2'),detfit('LBD',' 39','lbd',1,'CON_LBD1'),
                         detfit('LL',' 34','ll',2,'CON_LL'),detfit('LR',' 37','lr',2,'CON_LR'),detfit('LBY',' 41','lby',2,'CON_LBY'),
                         detfit('LBY Front',' 41','lbyfrnt',2,'CON_LBY'),detfit('Flex Connector','103','ltsc',2,'CON_FLEX'),
                         B('Reducer','^C^C(setq _FITTCODE 103 _TYPE T) (medblkins _MEDETFIT (strcat "re"    _CLETT) nil nil 1 8)','CON_RE'),
                         detfit('Tee',' 12','t',2,'CON_TEE'),detfit('UNF',' 73','uny',2,'CON_UNION'),detfit('UNY',' 72','uny',2,'CON_UNION'),
                         detfit('X',' 81','x',2,'CON_CROSS')],'L'),
   ('split','Seals',[detfit('Seal',' 61','eys',2,'CON_SEAL'),detfit('Seal-Drain',' 64','EYD',2,'CON_SEALDR')],'L'),
   ('L',B('Condulet Icons...','^C^C$i=MED.meddetailfit $i=*','FIT_CONDULET','Classic condulet fittings image menu (all Form 7/8 variants)')),
  ],[]),
 ('GUA Fittings',[
   ('split','GUA',[detfit('GUA','144','gua-',1,'FIT_GUA'),detfit('GUAB','145','guab',2,'FIT_GUA'),detfit('GUAC','146','guac',2,'FIT_GUA'),
                   detfit('GUAD','147','guad',2,'FIT_GUA'),detfit('GUAL','141','gual',2,'CON_GUAL'),detfit('GUAM','148','guam',2,'FIT_GUA'),
                   detfit('GUAN','149','guan',2,'FIT_GUA'),detfit('GUAT','142','guat',2,'CON_GUAT'),detfit('GUAW','150','guaw',2,'FIT_GUA'),
                   detfit('GUAX','143','guax',2,'CON_GUAX')],'L'),
   ('stack',[B('GUA Icons...','^C^C$i=MED.meddetailgua $i=*','FIT_GUA','Classic GUA fittings image menu')]),
  ],[]),
 ('Devices',[
   ('split','Devices',[B('H O A','^C^C(setq _FITTCODE  200) (medblkins _MEDETFIT (strcat (feedset "hoas") _CLETT) nil nil 1.0 2)','CON_DEVICES','Hand-Off-Auto station'),
                       B('Start/Stop','^C^C(setq _FITTCODE  202) (medblkins _MEDETFIT (strcat (feedset "efs") "s-s" _CLETT) nil nil 1.0 2)','CON_DEVICES'),
                       B('Stop','^C^C(setq _FITTCODE  204) (medblkins _MEDETFIT (strcat (feedset "efs") "stp" _CLETT) nil nil 1.0 2)','CON_DEVICES'),
                       B('Outlet','^C^C(setq _FITTCODE  208) (medblkins _MEDETFIT (strcat (feedset "cps") _CLETT) nil nil 1.0 2)','CON_DEVICES'),
                       B('2 Outlet','^C^C(setq _FITTCODE  210) (medblkins _MEDETFIT (strcat "2cps" _CLETT) nil nil 1.0 2)','CON_DEVICES'),
                       B('Outlet Side View','^C^C(setq _FITTCODE  208) (medblkins _MEDETFIT (strcat (feedset "cps") "sid" _CLETT) nil nil 1.0 2)','CON_DEVICES')],'L'),
   ('stack',[B('Feed Through','(toggle "_FEED" "Device switch Feed through")','VAR_BENDS.bmp','Toggle device feed-through'),
             B('Device Icons...','^C^C$i=MED.meddetaildevices $i=*','CON_DEVICES','Classic devices image menu')]),
  ],[]),
 ('Lighting',[
   ('split','Fixtures',[detfit('VMV Stanchion','243','vmvstan',1,'CON_LTG'),
                        detfit('EVCX Ceiling','251','evcx',1,'CON_LTG'),
                        detfit('EVCX Pendant','252','evcxpnd',1,'CON_LTG'),
                        B('Globe','^C^C(setq _FITTCODE 244) (medblkins _MEDETFIT "globe"                   nil nil 1 2)','CON_LTG'),
                        B('Globe 30','^C^C(setq _FITTCODE 245) (medblkins _MEDETFIT "globe30"                 nil nil 1 2)','CON_LTG')],'L'),
   ('stack',[B('UNJ/UNJY','^C^Cunj','CON_UNION','UNJ / UNJY union'),B('Lighting Icons...','^C^C$i=MED.meddetaillight $i=*','CON_LTG','Classic detail lighting image menu')]),
  ],[]),
 ('J-Boxes',[
   ('split','J-Boxes',[B('8x8 J-Box','^C^C(setq _FITTCODE 221 _ZERO T) (medblkins _MEDETFIT "jbox8x8" nil 0 1 2)','CON_JBOX8X8'),
                       B('8x4 J-Box','^C^C(setq _FITTCODE 222 _ZERO T) (medblkins _MEDETFIT "jbox8x4" nil 0 1 2)','CON_JBOX4X8'),
                       B('4x4 J-Box','^C^C(setq _FITTCODE 223 _ZERO T) (medblkins _MEDETFIT "jbox4x4" nil 0 1 2)','CON_JBOX4X4')],'L'),
   ('stack',[B('J-Box Hubs','^C^CHUBS','CON_JBOXHUBS'),B('J-Box Icons...','^C^C$i=MED.meddetailbox $i=*','CON_JBOX8X8','Classic J-box image menu')]),
  ],[]),
 ('Construction',[
   ('split','Material',[B('Angle Side View','^C^C(medblkins _MEDEQP "angle"    nil nil 1 0)','CON_MATERIAL'),
                        B('Channel Top View','^C^C(medblkins _MEDEQP "channel"  nil nil 1 0)','CON_MATERIAL'),
                        B('Square Washer','^C^C(medblkins _MEDEQP "fltsqwsh" nil nil 1 0)','CON_MATERIAL'),
                        B('Spring Nut','^C^C(medblkins _MEDEQP "sprnut"   nil nil 1 0)','CON_MATERIAL'),
                        B('Unistrut Side View','^C^C(medblkins _MEDEQP "uniside" nil nil 1 0)','CON_MATERIAL'),
                        B('Clamp Elevation','^C^C(setq _FITTCODE 123)(medblkins _MEDEQP (strcat "uclmpe" _CLETT) nil nil 1 2)','CON_MATERIAL'),
                        B('Clamp Front View','^C^C(setq _FITTCODE 123)(medblkins _MEDEQP (strcat "uclmpf" _CLETT) nil nil 1 2)','CON_MATERIAL'),
                        B('Clamp Side View','^C^C(setq _FITTCODE 123)(medblkins _MEDEQP (strcat "uclmps" _CLETT) nil nil 1 2)','CON_MATERIAL')],'L'),
   ('stack',[B('Material Icons...','^C^C$i=MED.meddetailconst $i=*','CON_MATERIAL','Classic construction material image menu')]),
  ],[]),
]

# ---------------------------------------------------------------- MED Wiring
def ssym(lbl,blk,img,tip=None): b=sym(lbl,blk,img); b.tip=tip or lbl; return b
WIRING=[
 ('Line Work',[
   ('split','Power',[B('Power Line','^C^C(smlayer _MEDPCABLE) MEDLINE','LSP_PWRLINE','Bus or feeder (continuous)'),
                     B('Power Hidden','^C^C(setq _LTP "HIDDEN")(smlayer _MEDPCABLE) MEDLINE','LSP_PWRLINEHD'),
                     B('Power Dashed','^C^C(setq _LTP "DASHED")(smlayer _MEDPCABLE) MEDLINE','LSP_PWRLINEDSH')],'L'),
   ('split','Control',[B('Control Line','^C^C(smlayer _MEDCCABLE) MEDLINE','LSP_CNTLINE','Control cable / control wiring'),
                       B('Field Wiring','^C^C(setq _LTP "HIDDEN")(smlayer _MEDCCABLE) MEDLINE','LSP_CNTLINEHD','Field wiring (control, hidden)'),
                       B('Control Dashed','^C^C(setq _LTP "DASHED")(smlayer _MEDCCABLE) MEDLINE','LSP_CNTLINEDSH')],'L'),
   ('split','Instrument',[B('Instrument Line','^C^C(smlayer _MEDICABLE) MEDLINE','LSP_INSLINE'),
                          B('Instrument Hidden','^C^C(setq _LTP "HIDDEN")(smlayer _MEDICABLE) MEDLINE','LSP_INSLINEHD'),
                          B('Instrument Dashed','^C^C(setq _LTP "DASHED")(smlayer _MEDICABLE) MEDLINE','LSP_INSLINEDSH')],'L'),
  ],[
   ('stack',[B('Linetype Icons...','$I=MED.MEDWDLTYPE $I=*','LSP_PWRLINE','Classic linetype image menu')]),
  ]),
 ('One Lines',[
   ('split','Typical Starters',[B('Magnetic Starter','^C^C(typstrins "typstrm1")','SYM_CONMAG'),B('Magnetic 2 Speed','^C^C(typstrins "typstrm2")','SYM_CONMAG'),
                                B('Thermal Starter','^C^C(typstrins "typstrt1")','SYM_CONOL'),B('Thermal 2 Speed','^C^C(typstrins "typstrt2")','SYM_CONOL'),
                                B('Welding Receptacle','^C^C(typstrins "typstrwl")','SYM_WELD','Typical welding receptacle'),
                                B('Lighting Panel','^C^C(typstrins "typstrlp")','SYM_LTGPNL','Typical lighting panel'),
                                B('Distribution Panel','^C^C(typstrins "typstrdp")','SYM_DISPNL','Typical distribution panel')],'L'),
   ('split','Components',[ssym('Stab Socket','STAB','SYM_STAB1'),ssym('Stabbed Socket','STABED','SYM_STAB2'),ssym('Circuit Breaker','CBRKR','SYM_CIRBRK'),
                          ssym('Fused Disconnect','FUSESW','SYM_FUSBRK'),ssym('Control Transformer','CPT01','SYM_CNTXFMR'),
                          ssym('M Contactor Coil','COIL01','SYM_CONCOIL'),ssym('Fuse','FUSE02','SYM_FUSE'),ssym('Fuse w/ Connects','FUSE','SYM_CONFUSE2'),
                          ssym('Thermal Overloads','TOLOAD','SYM_CONOL'),ssym('Magnetic Overloads','MOLOAD','SYM_CONMAG'),
                          B('Main Contact','^C^C(medblkins _MEDSYM "CONTACTR" nil nil _SC -1)','SYM_CONTACT')],'L'),
   ('split','Control Devices',[ssym('Hand Off Auto','devhoa','SYM_HOA'),ssym('Start / Stop','devss','SYM_S-S'),ssym('Stop Station','devs','SYM_STOP'),
                               ssym('Slow / Fast / Stop','devsfs','SYM_SFS'),ssym('A or B Selector','devab','SYM_AORB'),ssym('PLC/DCS Interconnect','devplc','SYM_ICON'),
                               ssym('Indicator Light','pilot03','SYM_PILOT'),ssym('Off On','devoo','SYM_OFFON')],'L'),
   ('split','Feeder Loads',[ssym('Motor or Pump','motor01','SYM_MOTOR'),ssym('Transformer','xfmr01','SYM_XFMR'),ssym('Lighting Panel','ltgpnl','SYM_LTGPNL'),
                            ssym('Welding Receptacle','eqpweld','SYM_WELD'),ssym('Lighting Contactor','eqpcntr','SYM_LTGCON')],'L'),
   ('split','Relays & Meters',[ssym('Single Designator','devmtr1','SYM_RLYSING'),ssym('Dual Designator','devmtr2','SYM_RLYDUAL'),
                               ssym('Dual Designator w/Line','devmtr3','SYM_RLYDUALW'),ssym('Device w/Designator','devmtr4','SYM_DEVDES'),
                               ssym('Normal Test Switch','devmtr5','SYM_TSTSW')],'L'),
  ],[
   ('stack',[B('Starter Icons...','$I=MED.MEDWDTYPSTART $I=*','SYM_CONMAG','Classic typical starters image menu'),
             B('Device Icons...','$I=MED.MEDWD1lcntdev $I=*','SYM_HOA','Classic control devices image menu'),
             B('Load Icons...','$I=MED.medwd1lloads $I=*','SYM_MOTOR','Classic feeder loads image menu')]),
   ('stack',[B('Meter Icons...','$I=MED.medwd1lmeters $I=*','SYM_RLYSING','Classic relays & meters image menu'),
             B('Component Icons...','$I=MED.medwd1lcmpnt $I=*','SYM_CIRBRK','Classic one-line components image menu')]),
  ]),
 ('Contacts & Switches',[
   ('split','Open Contacts',[ssym('Contact NO','cono','SYM_SWCONNO'),ssym('Push Button NO','pbno','SYM_SWPUSHNO'),ssym('Switch NO','swno','SYM_SWITCHNO'),
                             ssym('Limit NO','lmbno','SYM_SWLIMNO'),ssym('Limit Held Open','lmtno','SYM_SWLIMHLDNO'),ssym('Level NO','lvno','SYM_SWLEVNO'),
                             ssym('Flow NO','flno','SYM_SWFLOWNO'),ssym('Pressure NO','psno','SYM_SWPRESNO'),ssym('Software NO','sino','SYM_SWSOFTNO'),
                             ssym('Temperature NO','tmno','SYM_SWTEMPNO'),ssym('Timed Energized NO','teno','SYM_SWTIMEENO'),ssym('Timed De-Energized NO','tdno','SYM_SWTIMEDNO')],'L'),
   ('split','Closed Contacts',[ssym('Contact NC','conc','SYM_SWCONNC'),ssym('Push Button NC','pbnc','SYM_SWPUSHNC'),ssym('Switch NC','swnc','SYM_SWITCHNC'),
                               ssym('Limit NC','lmtnc','SYM_SWLIMNC'),ssym('Limit Held Closed','lmbnc','SYM_SWLIMHLDNC'),ssym('Level NC','lvnc','SYM_SWLEVNC'),
                               ssym('Flow NC','flnc','SYM_SWFLOWNC'),ssym('Pressure NC','psnc','SYM_SWPRESNC'),ssym('Software NC','sinc','SYM_SWSOFTNC'),
                               ssym('Temperature NC','tmnc','SYM_SWTEMPNC'),ssym('Timed Energized NC','tenc','SYM_SWTIMEENC'),ssym('Timed De-Energized NC','tdnc','SYM_SWTIMEDNC')],'L'),
   ('split','Selector Switches',[ssym('Hand Off Auto Switch','hoasw','SYM_SWHOA'),ssym('Rotary 3 Position','slra03','SYM_SW3POS'),ssym('Rotary 4 Position','slra04','SYM_SW4POS'),
                                 ssym('3 Position','slha03','SYM_SW3POS2'),ssym('4 Position','slha04','SYM_SW4POS2')],'L'),
  ],[
   ('stack',[B('Switch Icons...','$I=MED.MEDWDswitches $I=*','SYM_SWCONNO','Classic contacts & switches image menu')]),
  ]),
 ('Circuits & Protection',[
   ('split','Typical Circuits',[B('Start / Stop','^C^C(typstrins "typcrss")','SYM_S-S','Typical start/stop circuit'),
                                B('Hand Off Auto','^C^C(typstrins "typcrhoa")','SYM_HOA','Typical HOA circuit'),
                                B('Double Start/Stop','^C^C(typstrins "typcrdss")','SYM_S-S','Typical double start/stop circuit'),
                                B('Triple Start/Stop','^C^C(typstrins "typcrtss")','SYM_S-S','Typical triple start/stop circuit'),
                                B('Start/Stop w/Indicator','^C^C(typstrins "typcrssi")','SYM_PILOT','Typical start/stop with indicator'),
                                B('Fused Control Xfmr','^C^C(typstrins "typcrfcx")','SYM_CNTXFMR','Typical fused control transformer')],'L'),
   ('stack',[ssym('Circuit Breaker 3P','CB03','SYM_CB3PH'),ssym('Circuit Breaker 1P','CBRKR','SYM_CB1PH'),ssym('Fused Disconnect 3P','FD03','SYM_FD3PH')]),
   ('stack',[ssym('Fused Disconnect 1P','FUSESW','SYM_FD1PH')]),
  ],[
   ('stack',[B('Circuit Icons...','$I=MED.MEDWDtypcir $I=*','SYM_S-S','Classic typical circuits image menu'),
             B('Overcurrent Icons...','$I=MED.medwdovercurr $I=*','SYM_CB3PH','Classic overcurrent image menu')]),
  ]),
 ('Transformers',[
   ('split','Transformers',[ssym('Auto Transformer','autoxfmr','SYM_AUTOXFMR'),ssym('Air Core','xfmr3','SYM_AIRCORE','Air core transformer'),
                            ssym('Iron Core','xfmr4','SYM_IRONCORE','Iron core transformer'),ssym('Current','currxfmr','SYM_CURXFMR','Current transformer'),
                            ssym('Dual Voltage','dualxfmr','SYM_DUALXFMR','Dual voltage transformer')],'L'),
   ('split','Identifiers',[ssym('Delta','xfmrdel','SYM_DELTA','Delta transformer identifier'),ssym('Delta w/ Ground','xfmrdelg','SYM_DELTAWGND','Delta with ground identifier'),
                           ssym('Wye','xfmrwye','SYM_WYE','Wye transformer identifier'),ssym('Wye w/ CT Ground','xfmrwyeg','SYM_WYEWGND','Wye with center tap ground identifier')],'L'),
   ('stack',[ssym('Inductor Iron Core','indciron','SYM_AIRCORE2'),ssym('Inductor Air Core','indcair','SYM_IRONCORE2')]),
  ],[
   ('stack',[B('Transformer Icons...','$I=MED.MEDWDxfmrind $I=*','SYM_AUTOXFMR','Classic transformers & inductors image menu')]),
  ]),
 ('Semi-Conductors',[
   ('split','Resistors',[ssym('Fixed Resistor','resfixed','SYM_FXDRESIST'),ssym('Heating Element','heatelem','SYM_HEATELM'),
                         ssym('Adjustable Fixed Taps','resadjst','SYM_ADJRHEOFXD'),ssym('Adjustable Rheostat','rheostat','SYM_ADJRHEO')],'L'),
   ('split','Diodes & Semis',[ssym('Diode','diode01','SYM_DIODE'),ssym('Tunnel Diode','diode02','SYM_TUNLDIOD'),ssym('Zener Diode','diode03','SYM_ZENRDIOD'),
                              ssym('Bi-Direct Diode','diode04','SYM_BIDIRDIOD'),ssym('Triac','triac','SYM_TRIAC'),ssym('SCR','scr','SYM_SCR'),
                              ssym('PUT','put','SYM_PUT'),ssym('Photo Cell','photocel','SYM_PHOTCELL'),ssym('Full Wave Rectifier','fullrect','SYM_FWAVRECT'),
                              ssym('NPN Transistor','npn','SYM_NPNTRAN'),ssym('PNP Transistor','pnp','SYM_PNPTRAN'),ssym('UJT N Base','ujtnbase','SYM_UJTNBASE'),
                              ssym('UJT P Base','ujtpbase','SYM_UJTPBASE'),ssym('Gate Turn Off Thyristor','gatetrst','SYM_GATETHY')],'L'),
   ('split','Capacitors',[ssym('Fixed Capacitor','capactr2','SYM_FIXCAP'),ssym('Fixed Cap w/Conn','capactr1','SYM_FIXCAP2'),
                          ssym('Adjustable Capacitor','capactr4','SYM_ADJCAP'),ssym('Adjustable Cap w/Conn','capactr3','SYM_ADJCAP2')],'L'),
  ],[
   ('stack',[B('Semi-Cond Icons...','$I=MED.medwddiode $I=*','SYM_DIODE','Classic resistors & semi-conductors image menu')]),
  ]),
 ('Components',[
   ('split','Misc Components',[ssym('Annunciator','anunciat','SYM_ANNUNC'),ssym('Battery 1 Cell','batt01','SYM_BATTERY'),ssym('Battery 2 Cell','batt02','SYM_BATTERY'),
                               ssym('Battery 3 Cell','batt03','SYM_BATTERY'),ssym('Battery 4 Cell','batt04','SYM_BATTERY'),ssym('Bell','bell','SYM_BELL'),
                               ssym('Buzzer','buzzer','SYM_HORN'),ssym('Chassis Ground','grnd02','SYM_CHASGND'),ssym('Coil','coil02','SYM_COIL'),
                               ssym('Earth Ground','grnd01','SYM_ERTHGND'),ssym('Fuse','FUSE02','SYM_CONFUSE'),ssym('Horn, Alarm or Siren','horn','SYM_SIREN'),
                               ssym('Indicator Light','pilot03','SYM_PILOT1'),ssym('Meter','devmtr1','SYM_METER'),ssym('Meter Shunt','mtrshunt','SYM_SHUNT'),
                               ssym('Motor','motor01','SYM_MOTOR1'),ssym('Overloads','oloads','SYM_OLS'),ssym('Thermocouple','tcouple','SYM_THERMO'),
                               B('Heater Element','^C^C(medblkins _MEDSYM "heater"  nil nil _SC -1)','SYM_HEATER')],'L'),
   ('stack',[ssym('Solid Connect','connectf','SYM_CONNECT'),ssym('Open Connect','connecto','SYM_CONNECT2')]),
  ],[
   ('stack',[B('Component Icons...','$I=MED.medwdmscmpnt $I=*','SYM_ANNUNC','Classic misc components image menu')]),
  ]),
 ('Terminals',[
   ('L',B('Terminal Strip','^C^CTSTRIP','MNU_TERMINALS','TSTRIP: generate a terminal strip')),
   ('split','Terminals 01-14','@TERM1@','L'),
  ],[
   ('split','Terminals 15-28','@TERM2@','S'),
   ('stack',[B('Terminal Icons...','^C^C$I=MED.MEDTERMINALS $I=*','MNU_TERMINALS','Classic terminals image menu')]),
  ]),
 ('Diagram Tools',[
   ('stack',[B('Double Lines','^C^C2LINE','LSP_2LINE'),B('Triple Lines','^C^C3LINE','LSP_3LINE')]),
   ('stack',[B('Fillet 0.0625','^C^CFILLET R (* _SC 0.06250) FILLET','LSP_FILLET625'),B('Fillet 0.09375','^C^CFILLET R (* _SC 0.09375) FILLET','LSP_FILLET937'),
             B('Fillet 0.125','^C^CFILLET R (* _SC 0.12500) FILLET','LSP_FILLET125')]),
  ],[]),
]
TERM1=[ssym('Terminal %02d'%i,'term%02d'%i,'MNU_TERMINALS','Terminal type %02d'%i) for i in range(1,15)]
TERM2=[ssym('Terminal %02d'%i,'term%02d'%i,'MNU_TERMINALS','Terminal type %02d'%i) for i in range(15,29)]
LIGHTS=None  # filled from med.cuix Lighting Symbols toolbar

TABS=[('MED Main','MED_TAB_MAIN',MAIN),('MED Plan','MED_TAB_PLAN',PLAN),('MED Detail','MED_TAB_DETAIL',DETAIL),('MED Wiring','MED_TAB_WIRING',WIRING)]

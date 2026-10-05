# MEDRibbonGen

Generator for `Support\MEDRibbon.cuix` (MED Main / MED Plan / MED Detail / MED Wiring tabs).

- `spec.py` - the layout: tabs, panels, large/small buttons, split buttons, slide-outs. Edit this.
- `lookup.py` - finds each button's macro by command text in MEDRibbon.cuix, then med.cuix.
- `gen.py` - rebuilds RibbonRoot.cui, appends new macros (UIDs `MEDR_*`), embeds missing BMPs
  (Icons folder, padded to 16x16 and scaled x2 for 32x32), and writes the new cuix.
- `validate.py` - XML well-formed, unique UIDs, all macro/panel refs, images (MED.dll names or
  embedded), commands/functions exist (docs command list), image menus exist.
- `render.py` - draws a PNG preview of the layout.

Paths at the top of each script point at a scratch folder holding the unzipped cuix files
(`ex/rib`, `ex/med`), the Icons folder, the MED.dll image name list and the extracted icons; adjust before
re-running. Images come from MEDRibbon.dll (a copy of MED.dll, the med.cuix resource DLL).
Tab UIDs MED_TAB_MAIN/PLAN/DETAIL/WIRING are what MedRibbonMode.cs looks for (it also matches by title).

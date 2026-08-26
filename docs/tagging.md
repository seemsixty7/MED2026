# Tagging

Material tags and balloons. Tagging of **new** raceway is also a [MEDSETTINGS](medsettings.md) toggle (`_TAGOFF`). Off = no tag prompt; tag stored as `NONE`.

The 2012 tagging flyout is the CUI. Commands below are live.

## Raceway and details

| Command | Use |
| --- | --- |
| `CTAG` | Conduit tag. Select conduit, pick insert point. Block `contag`, layer `ECTAG`. Size and tag from xdata |
| `TTAG` | Tray tag. Pick the **centerline**, then leader. Tag, size, elevation prompt. Block `traytag` |
| `TTAGS` | Tray tag variant |
| `DETAG` | Detail bubble `detbub2` from catalog keys. Enter = fill attributes by hand |
| `DETAG2` | Alternate bubble `dtlhd1` |
| `DETAGUPD` | Refresh typical counts on existing bubbles. See [detail.md](detail.md) |
| `CHGTAG` | Change tags on a selection (`MEDCommands.lsp`) |

## Balloons and leaders

| Command | Use |
| --- | --- |
| `MB` / `MB1` | Material bubble. Multiple IDs string along |
| `MBL` | Move bubble or its leader; the other end follows |
| `ABL` | Add a leader to a selected balloon |
| `HDTAG` | "Hot dog" tag. Sizes the tag to the character count, max 15. `HDTAGOLD` is the previous version |
| `IT` | Instrument tag (type and number). `ITAGA` / `ITAGE` / `ITAGT` variants |
| `WIRES` | Dashes and squiggles on conduit for circuits. A small G on a longer dash is ground. Text height is `0.0625 × scale`, not the style height |
| `ALEAD` / `AL` | Arrow leader (DIM leader plus extras) |
| `GLEAD` / `GL` / `GRAB` / `GR` | Leader that hooks / grabs the first line |
| `SECT` / `SECTD` | Section marks in plan |
| `CUT` | Cut marks plus a section letter |
| `CLOUD` / `BOXCLOUD` | Revision cloud. `CLOUD` is pick-and-drag a closed polyline cloud |
| `BRACKET` | Bracket mark |

`MED` / `MC` open [MEDCHG](medchg.md), not a tag command. (QKEY once defined `MC` as move-crossing; the later defun aliases `MEDCHG`.)

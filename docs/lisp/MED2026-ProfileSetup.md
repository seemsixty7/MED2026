# MED2026-ProfileSetup.lsp

`Support\MED2026-ProfileSetup.lsp` - One-time profile setup (MED2026SETUP): support/trusted paths, CUILOAD. Identical copy in installer\.

**Not loaded by MEDCore.** APPLOAD it to use it. 13 defun(s): 1 command(s), 12 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 11 | [`MED2026-Root`](#med2026-root) | function |
| 17 | [`MED2026-SupportRoot`](#med2026-supportroot) | function |
| 21 | [`MED2026-FilesPref`](#med2026-filespref) | function |
| 25 | [`MED2026-EnsureSettings`](#med2026-ensuresettings) | function |
| 43 | [`MED2026-EnsureTrusted`](#med2026-ensuretrusted) | function |
| 65 | [`MED2026-EnsureSupportPath`](#med2026-ensuresupportpath) | function |
| 74 | [`MED2026-ClearEnterpriseIfOurs`](#med2026-clearenterpriseifours) | function |
| 101 | [`MED2026-UnloadRibbon`](#med2026-unloadribbon) | function |
| 109 | [`MED2026-MedGroupLoaded`](#med2026-medgrouploaded) | function |
| 116 | [`MED2026-LoadMedMenu`](#med2026-loadmedmenu) | function |
| 126 | [`MED2026-FixShortcut`](#med2026-fixshortcut) | function |
| 149 | [`MED2026-StripRunOnce`](#med2026-striprunonce) | function |
| 160 | [`c:MED2026SETUP`](#cmed2026setup) | command |

## MED2026-Root

`(MED2026-Root / root)`  - line 11-15

Returns the MED2026 install root (parent of Support).

- **Arguments**: none
- **Returns**: value of the last expression: `root`
- **Referenced**: 2

## MED2026-SupportRoot

`(MED2026-SupportRoot)`  - line 17-19

Returns the MED2026 Support folder path.

- **Arguments**: none
- **Returns**: value of the last expression: `(strcat (MED2026-Root) "\\Support")`
- **Referenced**: 2

## MED2026-FilesPref

`(MED2026-FilesPref)`  - line 21-23

Returns the AutoCAD Preferences.Files ActiveX object.

- **Arguments**: none
- **Returns**: value of the last expression: `(vla-get-files (vla-get-preferences (vlax-get-acad-object)))`
- **Referenced**: 3

## MED2026-EnsureSettings

`(MED2026-EnsureSettings / p f db)`  - line 25-41

Writes Support\MEDDataBaseSettings.dat from the example file if missing.

- **Arguments**: none
- **Returns**: value of the last expression: `(if (not (findfile p)) (progn (setq f (open p "w")) (if f (progn (write-line "Provider=SQLite" f) (write-line ...`
- **Referenced**: 1

## MED2026-EnsureTrusted

`(MED2026-EnsureTrusted support / files tp)`  - line 43-63

Adds the Support folder to TRUSTEDPATHS (profile variable) if missing.

- **Arguments**: `support`
- **Returns**: value of the last expression: `(vl-catch-all-apply '(lambda ( ) (setq files (MED2026-FilesPref) tp (vlax-get-property files 'TrustedPaths) ) ...`
- **Referenced**: 1

## MED2026-EnsureSupportPath

`(MED2026-EnsureSupportPath support / files acadPath)`  - line 65-72

Adds the Support folder to the AutoCAD support search path if missing.

- **Arguments**: `support`
- **Returns**: value of the last expression: `(if (not (vl-string-search (strcase support) (strcase acadPath))) (vla-put-SupportPath files (strcat support "...`
- **Referenced**: 1

## MED2026-ClearEnterpriseIfOurs

`(MED2026-ClearEnterpriseIfOurs support / files cur menubase)`  - line 74-99

Clears EnterpriseMenuFile when a previous MED installer put med.cuix there.

- **Arguments**: `support`
- **Returns**: value of the last expression: `(if (and (/= cur "") (or (vl-string-search (strcase menubase) (strcase cur)) (vl-string-search "\\MED.CUIX" (s...`
- **Referenced**: 1

## MED2026-UnloadRibbon

`(MED2026-UnloadRibbon)`  - line 101-107

Unloads the MEDRibbon partial CUI group if loaded.

- **Arguments**: none
- **Returns**: value of the last expression: `(foreach g '("MEDRibbon" "MEDRIBBON" "MedRibbon") (if (menugroup g) (vl-catch-all-apply 'command-s (list "_.CU...`
- **Referenced**: 1

## MED2026-MedGroupLoaded

`(MED2026-MedGroupLoaded)`  - line 109-114

T when the MED menu group is loaded.

- **Arguments**: none
- **Returns**: value of the last expression: `(or (menugroup "MED") (menugroup "Med") (menugroup "med") )`
- **Referenced**: 1

## MED2026-LoadMedMenu

`(MED2026-LoadMedMenu support / p)`  - line 116-124

CUILOADs med.cuix as a partial menu when MED is not already loaded.

- **Arguments**: `support`
- **Returns**: value of the last expression: `(vl-catch-all-apply 'setvar (list "MENUBAR" 1))`
- **Referenced**: 1

## MED2026-FixShortcut

`(MED2026-FixShortcut lnk / wsh sc args)`  - line 126-147

Repairs the MED2026 desktop shortcut target/profile arguments.

- **Arguments**: `lnk`
- **Returns**: value of the last expression: `(if (findfile lnk) (progn (setq wsh (vlax-create-object "WScript.Shell") sc (vlax-invoke-method wsh 'CreateSho...`
- **Referenced**: 1

## MED2026-StripRunOnce

`(MED2026-StripRunOnce / pub)`  - line 149-158

Removes the first-run script entry after setup.

- **Arguments**: none
- **Returns**: value of the last expression: `(foreach lnk (list (strcat (getenv "USERPROFILE") "\\Desktop\\MED2026 AutoCAD.lnk") (strcat pub "\\Desktop\\ME...`
- **Referenced**: 1

## c:MED2026SETUP

`(c:MED2026SETUP / support)`  - line 160-178

One-time profile setup: support + trusted paths, CUILOAD med.cuix, MENUBAR=1, clears an old enterprise-menu entry. See install.md. User entry: [MED2026SETUP](../command-reference.md#med2026setup).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Referenced**: 1


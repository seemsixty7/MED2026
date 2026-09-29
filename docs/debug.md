# MED debug mode

MED-DotNet (`Support\MED-DotNet.dll`) has one global debug switch, shared by the C# code and the LISP modules.

## Command

`MEDDEBUG` → `[On/Off/Verbose/Status] <Status>`

| Option  | Level     | What it does |
|---------|-----------|--------------|
| Off     | 0 Off     | Normal use (the default). |
| On      | 1 Errors  | Full error details on screen, plus debug notes in the log. |
| Verbose | 2 Verbose | Same as On, and also SQL text and row counts on the command line. |
| Status  | –         | Prints the current level, the log file and where the setting is stored. |

The level is saved per user in the registry, so it carries over to the next AutoCAD session (no admin rights needed):
`HKCU\Software\MooreDesign\MED2026`, string value `DebugLevel` = `Off` / `Errors` / `Verbose`.

## What changes

| | Off (normal) | On | Verbose |
|---|---|---|---|
| `n row(s)` / `No Rows` / `n row(s) affected` after `ProcessSQLStatementNET` | hidden | hidden | shown (unless `*MED-SQL-QUIET*` is set) |
| Error in a MED command / LISP function | one line: `MED-DotNet: <where>: <message>` (the first one in a session adds `(MEDDEBUG On for details)`) | exception type, message, inner exceptions, SQL text (with parameters), stack trace, log path | same as On |
| Error in a MED dialog (MEDTYPE, BOM, palettes) | plain message | full details in the dialog / on the command line | same as On |
| Startup / OD seed / background problems | log only | log + command line | log + command line |
| Log file | errors and warnings | + command start/end with ms, SQL statements, LISP `med-debug-log` lines | + row counts |

A failing command or LISP function never takes AutoCAD down: the exception is caught, reported as above, and a LISP function returns `nil`.

## Log file

`%LOCALAPPDATA%\MED2026\logs\med-YYYYMMDD.log` (for example `C:\Users\<you>\AppData\Local\MED2026\logs\med-20260929.log`). Each line starts with a timestamp (`yyyy-MM-dd HH:mm:ss.fff`, local time) and a tag: `[ERROR]`, `[WARN]`, `[INFO]`, `[DEBUG]`, `[VERBOSE]` or `[LISP]`.
Errors and warnings are always logged. Everything else is logged only when debug is On or Verbose. Log files older than 7 days are deleted the first time MED writes to the log in a session.

## LISP

| Name | Value |
|---|---|
| `(med-debug-p)` | `T` when the level is On or Verbose, else `nil`. This is the reliable way to ask. |
| `(med-debug-level)` | `0` Off, `1` On, `2` Verbose |
| `(med-debug-log "text" ...)` | Writes a `[LISP]` line to the log when debug is on; returns `T`. |
| `*MED-DEBUG*` | `T` / `nil`. Set by `MEDCore.lsp` when a drawing loads and by `MEDDEBUG` when the level changes. |
| `*MED-DEBUG-LEVEL*` | `0` / `1` / `2`. Set when MED-DotNet loads, when a drawing is activated and by `MEDDEBUG`. |
| `*MED-SQL-QUIET*` | When non-nil, `ProcessSQLStatementNET` never prints row counts, even in Verbose. Errors are still reported. |

MED3DPath (`M3D` / `C3D`): `*MED3D-DEBUG*` now defaults to `nil`, which means "follow the global flag". `(setq *MED3D-DEBUG* T)` forces the MED3DPath trace on, and `(setq *MED3D-DEBUG* "OFF")` forces it off even while MEDDEBUG is on.

## Guarded entry points

Commands: `MEDDEBUG`, `MEDTYPE`, `MEDTYPES`, `MEDSHOW`, `MEDSHOWBOM`, `MEDSHOWSUM`, `MEDPROPERTIES`, `MEDPROPS`, `MEDRECORDS`, `MEDCHG`, `MEDXDEDIT`, `MEDSETTINGS`, `MEDSET`, `MEDCABLE`, `CABLEPALETTE`, `CABLESET`, `MEDREBUILDMEDPROPSJSON` (sidecar JSON export).
LISP functions: `ProcessSQLStatementNET`, `MED-GetMedProperties`, `MED-SetMedProperties`, `MED-UpsertMedPropertiesJson`, `MED-RebuildMedPropertiesJson`, `MED-RebuildMedPropertiesJsonForFile`, `MED-CableApplyLayer`.
At load: the conduit/cable OD seed (`MedODSeed`) and the other startup steps report to the log (on screen only in debug).

## Troubleshooting

1. `MEDDEBUG` → `On` (or `Verbose` for SQL problems).
2. Repeat the failing step.
3. Send the newest `med-*.log` from `%LOCALAPPDATA%\MED2026\logs`.
4. `MEDDEBUG` → `Off`.

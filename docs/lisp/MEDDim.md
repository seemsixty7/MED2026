# MEDDim.lsp

`Support\MEDDim.lsp` - Dimension style helpers (MEDDIMSETUP, IOD).

Loaded by MEDCore (order 16). 4 defun(s): 2 command(s), 2 function(s).

Back to [lisp-reference.md](../lisp-reference.md). Commands are described for users in [command-reference.md](../command-reference.md).

"Globals set" lists symbols assigned with `setq` that are not in the argument or local list; many are leaks rather than intended globals. "Referenced" counts other mentions of the name in the LISP, menu macros and C# (0 = nothing calls it by name; it may still be called through a string built at run time).

| Line | Name | Kind |
| --- | --- | --- |
| 2 | [`GetDimStyleVariable`](#getdimstylevariable) | function |
| 29 | [`SetDimstyleVariable`](#setdimstylevariable) | function |
| 51 | [`c:MEDDIMSETUP`](#cmeddimsetup) | command |
| 78 | [`c:IOD`](#ciod) | command |

## GetDimStyleVariable

`(GetDimStyleVariable gdsv-stylename gdsv-dimvariable)`  - line 2-27

Reads a variable from a named dimension style (ActiveX).

- **Arguments**: `gdsv-stylename`, `gdsv-dimvariable`
- **Returns**: value of the last expression: `gdsv-ReturnValue`
- **Side effects**: Globals set (not declared local): `gdsv-AcadObject`, `gdsv-CurrentDwg`, `gdsv-ActiveDimStyle`, `gdsv-ReturnValue`, `gdsv-NewActiveDimstyle`
- **Referenced**: 0

## SetDimstyleVariable

`(SetDimstyleVariable udv-stylename udv-variable udv-newvalue)`  - line 29-48

Sets a variable in a named dimension style (ActiveX).

- **Arguments**: `udv-stylename`, `udv-variable`, `udv-newvalue`
- **Returns**: value of the last expression: `(if (tblsearch "dimstyle" udv-stylename nil) (progn (setq udv-NewActiveDimstyle (vla-item (vla-get-dimstyles u...`
- **Side effects**: Globals set (not declared local): `udv-AcadObject`, `udv-CurrentDwg`, `udv-ActiveDimStyle`, `udv-NewActiveDimstyle`
- **Referenced**: 9

## c:MEDDIMSETUP

`(c:MEDDIMSETUP)`  - line 51-76

Makes the "Standard" dimension style current and applies the UEI_DIMSETTINGS variables (loads text styles first if needed). User entry: [MEDDIMSETUP](../command-reference.md#meddimsetup).

- **Arguments**: none
- **Returns**: value of the last expression: `(vla-CopyFrom NewActiveDimstyle CurrentDwg)`
- **Side effects**: Globals set (not declared local): `dimspc`, `varname`, `varvalue`
- **Referenced**: 0

## c:IOD

`(c:IOD / All_Dimensions LayerTable FakeDimensionLayer DimensionDefinition DimensionText)`  - line 78-137

Finds dimensions with a text override and moves them to layer "_Faked Dimensions" so overridden (faked) dimensions stand out. User entry: [IOD](../command-reference.md#iod).

- **Arguments**: none
- **Returns**: nothing useful (quiet exit)
- **Side effects**: Globals set (not declared local): `DimensionCounter`, `IsolatedDimensionCounter`, `DimensionObject`, `Dimension`, `DimensionTextOverride`, `TrueMeasurement`; Layers: creates/sets layers
- **Referenced**: 0


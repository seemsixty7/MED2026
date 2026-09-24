# XData / MEDProperties findings (Navisworks 2024)

## What MED writes (AutoCAD)

- RegApp / XData application name: `MEDProperties`
- Typed values are DXF 1000 strings as `key=value` for:
  `ObjectType`, `Size`, `Description`, `Tag`, `Length`, `Weight`
- Source: `src\MED-DotNet\MED-DotNet\MedPropertiesXData.cs`

## What Navisworks 2024 exposes

From Autodesk forum / APS guidance and Api.xml on this machine:

1. **Raw AutoCAD XData is NOT readable** via Navisworks .NET or COM as a first-class
   XData API. There is no `ModelItem.GetXData("MEDProperties")`.
2. `ModelItem.PropertyCategories` only contains data the **DWG file reader / Object
   Enabler** chose to promote into property categories (e.g. Entity Handle under
   `PropertyCategoryNames.AutoCadEntityHandle`, generic AutoCAD category, geometry, etc.).
3. Custom Autodesk/third-party apps that show XData in Navis usually either:
   - Ship an **Object Enabler** that publishes properties, or
   - **Re-attach** values inside Navisworks with COM
     `InwGUIPropertyNode2.SetUserDefined(...)` (user-defined category).

## Plugin v1 behavior on this machine

| Path | Status |
|------|--------|
| Prefer `PropertyCategory` named `MEDProperties` | Implemented (`MedPropertyReader`) |
| Search all categories for the six keys / prefixed names | Implemented |
| Dump categories diagnostic | Dock pane button |
| Attach user-defined `MEDProperties` via COM | Implemented (`UserPropertyBridge` + demo button) |
| Automatic XData→properties on Append DWG | **Not available** without OE or side-channel |

**Honest expectation:** appending a MED DWG that only has XData will likely show
**no** MED fields until values are attached (bridge) or promoted by a convert/export
pipeline. Use **Dump categories** after append to confirm what the 2024 DWG reader
actually emitted on DC's machine (full GUI test left for DC).

## Practical bridge (implemented)

`UserPropertyBridge.AttachMedProperties(item, values)` writes a user-defined category
display name `MEDProperties` / internal `LcOaMEDProperties` with the six fields.
After that, native Properties and the dock pane both show them.

Next step (not in this task): AutoCAD export or RealDWG lookup by Entity Handle → call
the bridge when a DWG item is selected.

## JSON sidecar (implemented)

AutoCAD writes {dwgBasename}.medprops.json next to the DWG whenever MEDProperties is set
(via MedPropertiesXData.Set / MED-SetMedProperties), and can rebuild with command
MEDREBUILDMEDPROPSJSON / lisp (MED-RebuildMedPropertiesJson).

Navisworks plugin auto-loads an existing sibling JSON on document/model change and attaches
user-defined MEDProperties by matching AutoCAD Entity Handle. Manual: dock pane button
**Load MEDProperties JSON**.

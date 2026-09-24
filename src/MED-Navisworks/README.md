# MED-Navisworks (MEDPropertiesPlugin)

Navisworks Manage / Simulate **2024** plugin that shows MED identification fields
(`ObjectType`, `Size`, `Description`, `Tag`, `Length`, `Weight`) for the current
selection. Matches AutoCAD XData app `MEDProperties` (see MED-DotNet
`MedPropertiesXData.cs`). **Not BOM.**

## Build

Requirements: VS 2019+, .NET Framework 4.8 targeting pack, Navisworks Manage 2024
(for `Autodesk.Navisworks.Api.dll`). ADN/SDK is **not** required.

```bat
msbuild MED-Navisworks.sln /p:Configuration=Release /p:Platform=x64
```

Optional override if Manage is not in the default path:

```bat
msbuild MED-Navisworks.sln /p:Configuration=Release /p:Platform=x64 /p:NavisworksPath="C:\Program Files\Autodesk\Navisworks Manage 2024"
```

Outputs:

- `MED-Navisworks\bin\x64\Release\MEDPropertiesPlugin.dll`
- `MED-Navisworks\bin\x64\Release\Plugins\MEDPropertiesPlugin\MEDPropertiesPlugin.dll`
- `MED-Navisworks\bin\x64\Release\MED.MEDProperties.bundle\` (ApplicationPlugins layout)
- `bundle\Contents\Nw21\MEDPropertiesPlugin.dll` (+ `bundle\PackageContents.xml`)

## Load (Manage 2024)

**Option A — traditional Plugins folder (folder name must match DLL name):**

Copy folder:

```
...\bin\x64\Release\Plugins\MEDPropertiesPlugin\
```

to either:

1. `%APPDATA%\Autodesk\Navisworks Manage 2024\Plugins\MEDPropertiesPlugin\` (no admin), or
2. `C:\Program Files\Autodesk\Navisworks Manage 2024\Plugins\MEDPropertiesPlugin\` (admin)

**Option B — ApplicationPlugins bundle:**

Copy `MED.MEDProperties.bundle` to:

```
%APPDATA%\Autodesk\ApplicationPlugins\MED.MEDProperties.bundle\
```

(or `C:\ProgramData\Autodesk\ApplicationPlugins\` for machine-wide).

Restart Navisworks. Open the pane via **Add-Ins → MED Properties**, or enable the
dock window from the View / Windows list (`MED Properties`).

## Load (Simulate 2024)

Same layouts, substituting **Simulate** for **Manage**:

- `%APPDATA%\Autodesk\Navisworks Simulate 2024\Plugins\MEDPropertiesPlugin\`
- or install-dir `...\Navisworks Simulate 2024\Plugins\MEDPropertiesPlugin\`
- bundle `PackageContents.xml` already lists `Platform="NAVMAN|NAVSIM"` / `SeriesMin/Max="Nw21"`.

Simulate 2024 was **not** installed on the build machine; DLL is built against Manage
2024 Api.dll (same Nw21 API surface).

## XData caveat

Navisworks does **not** generally import AutoCAD XData into `ModelItem.PropertyCategories`.
Use **Dump categories** on a selected DWG solid to confirm. If fields are missing, use
**Attach demo User props** to verify the COM user-defined bridge, then plan a side-channel
(export from AutoCAD / RealDWG) to call the same attach path with real values.

See `docs\XDATA-FINDINGS.md`.

## Inno (later)

Do not modify the Inno script yet. Files to copy when ready are listed in
`docs\INNO-COPY.md`.

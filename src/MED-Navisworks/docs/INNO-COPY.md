# Inno copy list (Navisworks MEDPropertiesPlugin)

Implemented in `installer\MED2026.iss` (optional component **navis**) and `installer\MED2026-Patch.iss`.

## Detect

- Manage 2024: `C:\Program Files\Autodesk\Navisworks Manage 2024\Roamer.exe`
  (Api.dll: same folder, file version **21.0.1397.16**, assembly **21.0.0.0**)
- Simulate 2024: `C:\Program Files\Autodesk\Navisworks Simulate 2024\Roamer.exe`

## Files to ship

Staging (committed for reproducible ISCC builds):

- `installer\staging\Navis\MEDPropertiesPlugin\MEDPropertiesPlugin.dll`

Built from `src\MED-Navisworks\MED-Navisworks\bin\x64\Release\` (also mirrored under `bundle\Contents\Nw21\`).

## Destinations (per-user, no elevation)

- Manage: `{userappdata}\Autodesk\Navisworks Manage 2024\Plugins\MEDPropertiesPlugin\`
- Simulate: `{userappdata}\Autodesk\Navisworks Simulate 2024\Plugins\MEDPropertiesPlugin\`

Traditional Plugins layout: folder name **must** equal DLL base name (`MEDPropertiesPlugin`).

## Notes

- Copy Local is false for Autodesk.* refs — do **not** redistribute Api/ComApi DLLs.
- Series / API year folder in bundle: **Nw21** (Navisworks 2024).
- See `docs\updates.md` for full vs patch installer behaviour.

MED2026-OpenSource
==================
Working copy of keeper AutoLISP for a future clean MED set.
Nothing in D:\MEDConsolidate was changed. These are copies.

First file: ACAD.LSP from MED-DEV\Support (537 bytes, 2022 load chain).

Exceptions vs MED-DEV:
- MEDFunctions.lsp from MED2020\Support (2025 BOM override)
- MED3DCON.lsp from MEDNEW\LSP (2020 +gplen)
- MEDVariables.lsp from MED2020\Support (defaults only; MED-DEV has a live Azure SQL password and was not copied)

Also included because the load chain needs them:
- CSharpAdd.lsp (ACAD loads it; NetLoad inside is still commented out)
- MEDTextStyles.lsp (MEDCore 2022 loads it)
- medtray.lsp (not replaced by MEDCableTray; 30/45/60 + channel)

Omitted on purpose: ADOLISP_Library, BuildMED, plot files, CYA/trash, C# park files, Enbridge/Core dumps.
See MANIFEST.csv for source path, size, and SHA256 of each copy.

C# UI:
- MEDMainDialogs-RedoWithCSharp.lsp is the keeper LISP/DCL, renamed as the work flag.
  Replace with C# dialog interfaces. Do not treat this LISP as the long-term UI.

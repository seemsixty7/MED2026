MED seed database (SQLite)
==========================
Catalog only. MEDProject is empty (BOM is written at runtime).
MEDType has no private or shop-prefixed equipment rows.
MEDUsers is empty; setup inserts the current Windows login.
MEDConduitOD holds conduit outside diameters (inches) per conduit type and trade size.
MEDType.USER3 on CABLE rows holds cable outside diameter (inches).
MEDConduitBody holds rigid conduit body (Condulet) dimensions (inches) per form, shape and trade size.

seed\conduit_od.csv and seed\cable_od_sources.csv are the same OD data with a
source per row. MED-DotNet reads them at load to create/fill MEDConduitOD and
blank CABLE USER3 values in an existing database (patches ship these, not MED.db).
seed\conduit_body_dims.csv (+ conduit_body_sources.csv) fills MEDConduitBody the same
way; MED3DFittings.lsp reads the CSV directly when the table is not available.

Any MEDRegistrations.db beside this file is a local opt-in roster only.
It is not part of the product runtime and must never ship with Setup or Patch.

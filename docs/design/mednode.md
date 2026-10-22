# MEDNODE: routing nodes (design note)

Status: foundation only (2026-10-22). Nodes are placed and read; the only behavior that uses them today is the bend, which is the same as with no node.

## The block
- There is one standard block, `MED_NODE`: a unit circle, a cross and a POINT at the insertion (added to older definitions on the next tag). It sits on layer `MED_NODE` and is scaled 1/16" × plot scale.
- The block is always the same. What a node *is* lives only in its XData, so changing a fitting never swaps the block.

## XData (app `MED_NODE`, standard MED Data format)
The format is the same one `bld_app` / `bld_fitting` use: `1002 "{"`, then `1000 "KEY______=value"` records, then `1002 "}"`.

| Key | Meaning |
|---|---|
| `NODE_KIND=` | `VERTEX` (2 connections) / `JUNCTION` (>2) / `ENDPOINT` (1) / `INTERSECTION` (crossing, future) |
| `NODE_SYS_=` | `CONDUIT` / `TRAY` / `CABLE`, taken from the run's MED xdata |
| `NODE_CONN=` | One connected segment as `runhandle#segment` (1-based). There is one record per connection (N of them) |
| `ITEM_TAG_=`, `#ITEMCODE=`, `#ITEMSIZE=` | Fitting assignment. These are the same keys as `bld_fitting`. All empty = no fitting |

- A node never carries `MED_FITTING` xdata, so the BOM does not count a bare node.

## Node ID (Clint 2026-10-22)
- The ID is the live AutoCAD entity handle of the INSERT and is **not stored**. `med-node-read` returns it as `ID`.
- On extraction the unique key is drawing name + handle (`med-node-key-of` -> `DWGNAME|handle`). A copied node gets a new handle, so copies are unique without any re-id step.
- Clint may share an older Node ID system later; evaluate it against this before changing anything.

## Nodes move with their vertex (Clint 2026-10-22)
- The node is a visible block with its insertion on the vertex, so STRETCH (crossing over the vertex) and MOVE (route + node selected) take the node with the vertex. No reactors, no hidden helper entities.
- Edits that do not take the node (grip-dragging a vertex, MOVE of the route alone, erasing a route) leave it behind. `MEDNODEAUDIT` finds those.
- **`MEDNODEAUDIT`** finds orphaned nodes: no connections, a `NODE_CONN` handle that is deleted, or not on a vertex of its connected runs within `*MED-NODE-TOL*`.
  - It prints the count first: `MEDNODEAUDIT: 5 orphaned node(s) found (of 23 nodes).`, or `No orphaned nodes found (23 nodes checked).`
  - It then steps through them. Each one is zoomed to and boxed in yellow, using the same highlight as the MED Records find/show (`MedHalo` in MED-DotNet, via `MED-HALO-SHOW` / `MED-HALO-CLEAR`). The prompt is `Orphan 2 of 5: <reason> (dwg|handle) [Snap/Delete/Next/eXit] <Next>`.
  - `Snap` moves the node onto the nearest vertex of its live runs and drops dead connections. `Delete` erases it after Yes/No. `Next` skips it.
  - The box is a transient (or grvecs without the DLL), never a drawing entity. It is cleared after every step and on exit or Esc, and the original view is restored.
  - The command closes with `snapped X, deleted Y, skipped Z`.
## Rules
- **No fitting (the default) on a 2-connection conduit node:** the node is a standard field bend. Its radius comes from MEDBendRadius (Specific > Long 24/36/48 on the run > underground > table > 5×OD), and the bend counts as conduit length, not as a fitting.
- **The exporters:** `med3d-plan-ent` (M3D, C3D, MAKE3DCONDUIT/CABLE, MEDMAKE3D conduit stage) calls `med3d-plan-nodes`.
  - It finds a node within `*MED-NODE-TOL*` (default 0.5") of each corner and reads its XData. The result goes in the plan as `("NODES" (vertex-index id fitting) ...)`, and each node is logged in the dbg line.
  - With no fitting, the corner is unchanged (a bend).
  - With a fitting assigned, the corner is reported and still drawn as a bend. This is the dispatch point for later work.

## Commands
- `MEDNODE` → `Run` tags every interior corner of the selected routes.
- `MEDNODE` → `Pick` tags the route vertex nearest each pick.
- Tagging a vertex that already has a node adds the new segment ids to `NODE_CONN` and does not place a second block. A 3rd connection turns the node into a `JUNCTION`.

## Bend rules (Clint 2026-10-22)
- **Flexible conduit is bend to fit.** This covers ENT (code 5) and LFMC / PC flexible metallic (code 7), set in `*MED3D-FLEX-CODES*`. M3D uses the drawn route as is: drawn arcs/fillets are kept, sharp vertices are mitered, and there is no auto bend radius and no short-segment stop. M3D prints a note per flexible run. In MEDBendRadius these codes have one `N/A` row per size (blank radius); the seeder removes older Standard/LongRadius rows for them.
- **Long radius:** the choices are 24", 36" or 48", typically underground. The Long prompt (route Radius option and MEDBENDR) offers `24/36/48/Auto`. A number is stamped on the run (BEND_DATA 1040). Auto uses the table LongRadius row, seeded by size from the underground split (24 under 4", 36 at 4" and up), Source `Clint 2026-10-22`.
- **Cables:** 7 x OD stays the general rule; rigid cables may use up to 12 x later. A cable inside a conduit or tray is constrained to that raceway's bend radius (the larger of the two). **Not implemented:** cables do not yet know which raceway they are in; this needs the cable-routing path (Later 4).

## Tray and duct bank (future rule, not built)
- A duct bank gets nodes at its start and end, plus one at each conduit opening.
- A tray gets a node at each tray point/fitting.

## Later (not built)
1. **Set fitting:** tap a node, choose a fitting, and call `(med-node-set-fitting e code size tag)`. That call only rewrites the XData. Exporters then dispatch on `FITTING` in the plan's `NODES` (LB/LL/LR bodies, elbows, couplings).
2. **Tee / X fittings:** `JUNCTION` nodes with 3 or 4 `NODE_CONN` entries; the fitting key picks the body.
3. **Tray routing and intersections:** `NODE_SYS_=TRAY`. An `INTERSECTION` node joins crossing runs, which is the hook for tray tees, crosses and drop-outs.
4. **Cable routing through the network:** nodes are graph vertices and `NODE_CONN` handles are edges. A cable route is a path of node ids, so its length is the sum of the edges.
5. **Fill calcs:** for each edge (conduit or tray run), sum the cables whose path uses that edge and compare against NEC Ch 9 Table 4 / the tray fill rules.
6. **Sections:** cut at a node or an edge, then list the runs and cables through it.

## Open points
- `NODE_CONN` segment numbers go stale when vertices are added or removed from a run; the handle part stays valid. MEDNODEAUDIT checks handles and position, not segment numbers.
- Grip-stretching a single vertex leaves the node behind (no reactor, by choice). Run MEDNODEAUDIT -> Snap.

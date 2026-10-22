# MEDNODE: routing nodes (design note)

Status: foundation only (2026-10-22). Nodes are placed and read; the only behavior that uses them today is the bend, which is the same as with no node.

## The block
- There is one standard block, `MED_NODE`: a unit circle and a cross. It sits on layer `MED_NODE` and is scaled 1/16" × plot scale.
- The block is always the same. What a node *is* lives only in its XData, so changing a fitting never swaps the block.

## XData (app `MED_NODE`, standard MED Data format)
The format is the same one `bld_app` / `bld_fitting` use: `1002 "{"`, then `1000 "KEY______=value"` records, then `1002 "}"`.

| Key | Meaning |
|---|---|
| `NODE_ID__=` | Stable node id: `N` + the INSERT's handle when it was first tagged |
| `NODE_KIND=` | `VERTEX` (2 connections) / `JUNCTION` (>2) / `ENDPOINT` (1) / `INTERSECTION` (crossing, future) |
| `NODE_SYS_=` | `CONDUIT` / `TRAY` / `CABLE`, taken from the run's MED xdata |
| `NODE_CONN=` | One connected segment as `runhandle#segment` (1-based). There is one record per connection (N of them) |
| `ITEM_TAG_=`, `#ITEMCODE=`, `#ITEMSIZE=` | Fitting assignment. These are the same keys as `bld_fitting`. All empty = no fitting |

- A node never carries `MED_FITTING` xdata, so the BOM does not count a bare node.

## Rules
- **No fitting (the default) on a 2-connection conduit node:** the node is a standard field bend. Its radius comes from MEDBendRadius (Specific > underground > table > 5×OD), and the bend counts as conduit length, not as a fitting.
- **The exporters:** `med3d-plan-ent` (M3D, C3D, MAKE3DCONDUIT/CABLE, MEDMAKE3D conduit stage) calls `med3d-plan-nodes`.
  - It finds a node within `*MED-NODE-TOL*` (default 0.5") of each corner and reads its XData. The result goes in the plan as `("NODES" (vertex-index id fitting) ...)`, and each node is logged in the dbg line.
  - With no fitting, the corner is unchanged (a bend).
  - With a fitting assigned, the corner is reported and still drawn as a bend. This is the dispatch point for later work.

## Commands
- `MEDNODE` → `Run` tags every interior corner of the selected routes.
- `MEDNODE` → `Pick` tags the route vertex nearest each pick.
- Tagging a vertex that already has a node adds the new segment ids to `NODE_CONN` and does not place a second block. A 3rd connection turns the node into a `JUNCTION`.

## Later (not built)
1. **Set fitting:** tap a node, choose a fitting, and call `(med-node-set-fitting e code size tag)`. That call only rewrites the XData. Exporters then dispatch on `FITTING` in the plan's `NODES` (LB/LL/LR bodies, elbows, couplings).
2. **Tee / X fittings:** `JUNCTION` nodes with 3 or 4 `NODE_CONN` entries; the fitting key picks the body.
3. **Tray routing and intersections:** `NODE_SYS_=TRAY`. An `INTERSECTION` node joins crossing runs, which is the hook for tray tees, crosses and drop-outs.
4. **Cable routing through the network:** nodes are graph vertices and `NODE_CONN` handles are edges. A cable route is a path of node ids, so its length is the sum of the edges.
5. **Fill calcs:** for each edge (conduit or tray run), sum the cables whose path uses that edge and compare against NEC Ch 9 Table 4 / the tray fill rules.
6. **Sections:** cut at a node or an edge, then list the runs and cables through it.

## Open points
- A copied node keeps its old `NODE_ID__`, giving a duplicate id. A future `MEDNODE` audit should re-id duplicates.
- Stretching a route does not move its nodes. Nodes are matched by position within tolerance, so a node left off a vertex is simply ignored.

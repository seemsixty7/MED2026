# Database

Connection file: `Support\MEDDataBaseSettings.dat` (installer writes it; machine-local, not in git).

SQLite (default):

```
Provider=SQLite
ConnectString=Data Source=C:\MED2026\Data\MED.db
```

SQL Server (optional, shops that already have it):

```
Provider=SqlServer
ConnectString=Server=YOURSERVER\INSTANCE;Database=MED;Integrated Security=SSPI;
```

`ConnectString` is ADO.NET (`System.Data.SQLite` or SqlClient), not OLEDB. Template: `Support\MEDDataBaseSettings.example.dat`.

## Seed tables (`Data\MED.db`)

| Table | Role |
| --- | --- |
| MEDType | Catalog. Seeded. Primary key `ITEMTYPE` + `ITEMCODE`. |
| MEDProject | BOM extract. Empty at install. Written at runtime. |
| Layers1 | Layer standards. Seeded. |
| MEDUsers | Seed is empty. Installer inserts the current Windows login (`UserType=User`). |

Same split as the 2012 guide: `MEDType` is the warehouse; `MEDProject` is what this drawing used. Entity xdata stores the code (and sizes/tags). The description is looked up in `MEDType` by type+code.

SQL Server is optional. Do not point a fresh install at someone else's live instance.

The public seed has no client-specific catalog rows.

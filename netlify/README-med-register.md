# MED registration — MooreDesign Netlify only

**Do not deploy this to InstallHer / other Netlify teams.** Target site: **mooredesign.net** (Netlify confirmed).

## Endpoint

After deploy:

```text
https://mooredesign.net/.netlify/functions/med-register
```

(Or your MooreDesign Netlify subdomain if the custom domain path differs.)

### POST (installer)

```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "version": "2026.0.0924b",
  "channel": "full",
  "git": "abc1234",
  "buildDate": "2026-09-24",
  "machineName": "DESKTOP-XYZ",
  "timestamp": "2026-09-24T16:00:00-05:00"
}
```

Upserts by normalized email into Blobs store `med-registrations`.

### GET export (sync tool)

```text
GET /.netlify/functions/med-register?export=1
Header: X-Med-Export-Key: <value of MED_EXPORT_KEY site env>
```

## Deploy steps (Clint)

1. `cd` to this MED repo (or copy `netlify/functions` + `netlify.toml` into the MooreDesign site repo).
2. `cd netlify && npm install` (installs `@netlify/blobs`).
3. Log into Netlify CLI as the **MooreDesign** account (not InstallHer):
   ```powershell
   npm i -g netlify-cli
   netlify login
   netlify link   # pick mooredesign / mooredesign.net site
   ```
4. Site env (Netlify UI → Site settings → Environment variables):
   - `MED_EXPORT_KEY` = long random secret (for export/sync only)
5. Enable **Netlify Blobs** on the site plan if not already (Blobs is available on most modern plans; if `getStore` fails at runtime, upgrade or enable Blobs in the Netlify UI).
6. Deploy functions:
   ```powershell
   netlify deploy --prod --dir=.. --functions=functions
   ```
   Or add the `netlify/functions` folder to the existing MooreDesign site build and redeploy the site from its normal pipeline.
7. Smoke-test:
   ```powershell
   Invoke-RestMethod -Method Post -Uri "https://mooredesign.net/.netlify/functions/med-register" `
     -ContentType "application/json" `
     -Body '{"name":"Test","email":"test@example.com","version":"2026.0.0924b","channel":"full","git":"dev","buildDate":"2026-09-24"}'
   ```
8. Update `#define MedRegisterUrl` in `installer\MED2026.iss` and `MED2026-Patch.iss` if the live URL differs from the placeholder.

## Fallback if Blobs API is not available

If `@netlify/blobs` cannot run on the site plan, keep this function as the contract and temporarily store submissions via **Netlify Forms** (mooredesign.net already has an optional contact form) or a Git-backed JSON file written by a build plugin. Prefer Blobs for upsert-by-email.

## Privacy

Opt-in only. Payload is name, email, version, channel, git, build date, optional machine name, timestamp. No drawings, licenses, or paths beyond install metadata.

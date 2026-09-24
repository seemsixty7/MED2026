# MED registration — MooreDesign Netlify only

**Do not deploy this to InstallHer / other Netlify teams.** Target site: **mooredesign.net** (Netlify site id `c0e63eee-2792-470f-afd5-8b9d00f479e7`).

## Endpoint

```text
https://mooredesign.net/.netlify/functions/med-register
```

### Mode: email-only (no Netlify Blobs)

POST validates name + email, then delivers the registration toward `MED_REGISTER_TO` (locked: **clintmoore@mooredesign.net**).

**Subject (exact prefix for filters):**

```text
[MED-REGISTER] {name} | {email} | {version} | {channel}
```

**Body:** plain text with name, email, version, channel, git, buildDate, machineName, timestamp, plus a raw JSON block.

### Send path

1. **Resend** — if `RESEND_API_KEY` is set on the site (optional `MED_REGISTER_FROM`).
2. **FormSubmit ajax** — `POST https://formsubmit.co/ajax/{MED_REGISTER_TO}` with `_subject` and fields (zero-config). First mail to a new address may need a one-time confirmation click. Some serverless IPs hit Cloudflare challenges.
3. **Netlify Forms fallback** — hidden form `med-register` on `mooredesign-site/index.html`. Function POSTs form-urlencoded to the site root. Wire a form notification email to `clintmoore@mooredesign.net` (subject/body include the `[MED-REGISTER]` subject field).

Installer still expects JSON `{ "ok": true }`. Delivery failure returns HTTP 502 with `{ ok: false }`; the installer already ignores registration failures.

### GET (health)

```text
GET /.netlify/functions/med-register
→ { ok, service, site, mode: "email-only", to, usage }
```

There is **no** Blobs export endpoint anymore.

### Jane / Clint → local SQLite

Filter inbox (or Netlify form submissions) on `[MED-REGISTER]` and apply rows into `Data\MEDRegistrations.db` on the desktop (manual, or a future Jane routine). The Sync tool’s `-Pull` export path is obsolete for live data; `-ImportJson` / `-InitDb` remain useful for local DB maintenance.

Local reuse file for patch installs is unchanged: `{app}\Support\MED.registration.json`.

## Site env (mooredesign production)

| Var | Value |
|-----|-------|
| `MED_REGISTER_TO` | `clintmoore@mooredesign.net` |
| `RESEND_API_KEY` | optional |
| `MED_REGISTER_FROM` | optional Resend from address |

`BLOBS_*` / `MED_EXPORT_KEY` may still exist from the prior Blobs path; unused by this function (harmless).

## Deploy

Deploy **mooredesign.net only** (publish dir + this function). Do **not** deploy to InstallHer.

```bash
netlify deploy --prod --dir=mooredesign-site --functions=netlify/functions --site=c0e63eee-2792-470f-afd5-8b9d00f479e7
```

Smoke-test:

```powershell
Invoke-RestMethod -Method Get -Uri "https://mooredesign.net/.netlify/functions/med-register"
Invoke-RestMethod -Method Post -Uri "https://mooredesign.net/.netlify/functions/med-register" `
  -ContentType "application/json" `
  -Body '{"name":"Smoke Test","email":"smoke@example.com","version":"2026.0.0924b","channel":"full","git":"dev","buildDate":"2026-09-24","machineName":"smoke","timestamp":"2026-09-24T12:00:00-05:00"}'
```

Confirm `[MED-REGISTER]` mail / form submission for `clintmoore@mooredesign.net` (or complete FormSubmit’s one-time confirm if that path is used).

## Privacy

Opt-in only. Payload is name, email, version, channel, git, build date, optional machine name, timestamp. No drawings, licenses, or paths beyond install metadata.

## Netlify Forms note

Site setting `ignore_html_forms` must be **false** so the hidden `med-register` form is registered. Email notification hook type `email` / event `submission_created` → `clintmoore@mooredesign.net` for form `med-register`.

FormSubmit remains attempted first (zero-config); Netlify Functions IPs often hit Cloudflare, so production delivery typically lands on **Netlify Forms** → email notify.

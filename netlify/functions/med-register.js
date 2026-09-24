/**
 * MED install registration (Moore Design / mooredesign.net only).
 * Keep InstallHer branding OUT of this endpoint.
 *
 * Email-only (no Netlify Blobs). On POST:
 *   Validate name + email, then deliver to MED_REGISTER_TO.
 *   Subject: [MED-REGISTER] {name} | {email} | {version} | {channel}
 *
 * Send path (prefer first available):
 *   1) Resend API if RESEND_API_KEY is set
 *   2) FormSubmit ajax (default zero-config; first mail may need confirm;
 *      serverless IPs are sometimes Cloudflare-blocked)
 *   3) Netlify Forms fallback (hidden form "med-register" on mooredesign.net)
 *
 * GET: health JSON only (no export / blobs).
 * Jane/Clint apply [MED-REGISTER] into Data\MEDRegistrations.db manually
 * (or a future Jane routine). See netlify/README-med-register.md.
 *
 * Deploy: MooreDesign site only — not InstallHer.
 */
function normalizeEmail(email) {
  return String(email || "")
    .trim()
    .toLowerCase();
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Content-Type": "application/json",
  };
}

function badRequest(msg) {
  return {
    statusCode: 400,
    headers: corsHeaders(),
    body: JSON.stringify({ ok: false, error: msg }),
  };
}

function registerTo() {
  return (
    String(process.env.MED_REGISTER_TO || "").trim() ||
    "clintmoore@mooredesign.net"
  );
}

function siteOrigin(event) {
  const fromEnv =
    String(process.env.URL || process.env.DEPLOY_PRIME_URL || "").trim();
  if (fromEnv) return fromEnv.replace(/\/$/, "");
  const host =
    (event &&
      event.headers &&
      (event.headers["x-forwarded-host"] || event.headers.host)) ||
    "mooredesign.net";
  const proto =
    (event && event.headers && event.headers["x-forwarded-proto"]) || "https";
  return `${proto}://${String(host).split(",")[0].trim()}`;
}

function buildSubject(rec) {
  return `[MED-REGISTER] ${rec.name} | ${rec.email} | ${rec.version} | ${rec.channel}`;
}

function buildBody(rec) {
  const lines = [
    "MED install registration (opt-in)",
    "",
    `name:        ${rec.name}`,
    `email:       ${rec.email}`,
    `version:     ${rec.version}`,
    `channel:     ${rec.channel}`,
    `git:         ${rec.git}`,
    `buildDate:   ${rec.buildDate}`,
    `machineName: ${rec.machineName}`,
    `timestamp:   ${rec.timestamp}`,
    "",
    "--- raw JSON ---",
    JSON.stringify(rec, null, 2),
    "",
    "Apply into Data\\MEDRegistrations.db (filter subjects [MED-REGISTER]).",
  ];
  return lines.join("\n");
}

async function sendViaResend(to, subject, text, replyTo) {
  const key = process.env.RESEND_API_KEY;
  if (!key) return { sent: false, reason: "no_key" };

  const from =
    String(process.env.MED_REGISTER_FROM || "").trim() ||
    "MED Register <onboarding@resend.dev>";

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [to],
      subject,
      text,
      reply_to: replyTo || undefined,
    }),
  });

  if (!res.ok) {
    const detail = await res.text().catch(() => "");
    return {
      sent: false,
      reason: "resend_error",
      status: res.status,
      detail: detail.slice(0, 500),
    };
  }
  return { sent: true, via: "resend" };
}

async function sendViaFormSubmit(to, subject, rec, text) {
  // FormSubmit ajax — no API key. First submission to a new address may require
  // a one-time confirmation click. Cloudflare may block some serverless IPs.
  const url = `https://formsubmit.co/ajax/${encodeURIComponent(to)}`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      _subject: subject,
      name: rec.name,
      email: rec.email,
      version: rec.version,
      channel: rec.channel,
      git: rec.git,
      buildDate: rec.buildDate,
      machineName: rec.machineName,
      timestamp: rec.timestamp,
      message: text,
      _template: "table",
      _captcha: false,
    }),
  });

  const raw = await res.text().catch(() => "");
  if (!res.ok) {
    return {
      sent: false,
      reason: "formsubmit_error",
      status: res.status,
      detail: raw.slice(0, 500),
    };
  }
  // Cloudflare challenge HTML sometimes returns 200 with a challenge page
  if (/Just a moment|cf-browser-verification|cloudflare/i.test(raw) && !/"success"\s*:\s*true/i.test(raw)) {
    return {
      sent: false,
      reason: "formsubmit_cloudflare",
      status: res.status,
      detail: raw.slice(0, 200),
    };
  }
  return { sent: true, via: "formsubmit" };
}

async function sendViaNetlifyForms(origin, subject, rec, text) {
  // Same-site Netlify Forms — reliable from Functions; notification email
  // should be wired to MED_REGISTER_TO (see README).
  const body = new URLSearchParams();
  body.set("form-name", "med-register");
  body.set("subject", subject);
  body.set("name", rec.name);
  body.set("email", rec.email);
  body.set("version", rec.version);
  body.set("channel", rec.channel);
  body.set("git", rec.git);
  body.set("buildDate", rec.buildDate);
  body.set("machineName", rec.machineName);
  body.set("timestamp", rec.timestamp);
  body.set("message", text);

  const res = await fetch(`${origin}/`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
    redirect: "manual",
  });

  // Netlify Forms typically 200/302 on success
  if (res.status >= 200 && res.status < 400) {
    return { sent: true, via: "netlify-forms", status: res.status };
  }
  const detail = await res.text().catch(() => "");
  return {
    sent: false,
    reason: "netlify_forms_error",
    status: res.status,
    detail: detail.slice(0, 500),
  };
}

async function sendRegistrationEmail(rec, event) {
  const to = registerTo();
  const subject = buildSubject(rec);
  const text = buildBody(rec);
  const attempts = [];

  if (process.env.RESEND_API_KEY) {
    const r = await sendViaResend(to, subject, text, rec.email);
    attempts.push(r);
    if (r.sent) return r;
  }

  const fs = await sendViaFormSubmit(to, subject, rec, text);
  attempts.push(fs);
  if (fs.sent) return fs;

  const nf = await sendViaNetlifyForms(siteOrigin(event), subject, rec, text);
  attempts.push(nf);
  if (nf.sent) return nf;

  return { sent: false, attempts };
}

exports.handler = async (event) => {
  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 204, headers: corsHeaders(), body: "" };
  }

  if (event.httpMethod === "GET") {
    return {
      statusCode: 200,
      headers: corsHeaders(),
      body: JSON.stringify({
        ok: true,
        service: "med-register",
        site: "mooredesign",
        mode: "email-only",
        to: registerTo(),
        usage:
          "POST registration JSON; emails [MED-REGISTER] to MED_REGISTER_TO (Resend / FormSubmit / Netlify Forms). No Blobs export.",
      }),
    };
  }

  if (event.httpMethod !== "POST") {
    return {
      statusCode: 405,
      headers: corsHeaders(),
      body: JSON.stringify({ ok: false, error: "Method Not Allowed" }),
    };
  }

  let body;
  try {
    body = JSON.parse(event.body || "{}");
  } catch (_) {
    return badRequest("Invalid JSON");
  }

  const email = normalizeEmail(body.email);
  const name = String(body.name || "").trim();
  if (!email || email.indexOf("@") < 1 || email.indexOf(".") < 0) {
    return badRequest("Valid email required");
  }
  if (!name) {
    return badRequest("Name required");
  }

  const rec = {
    name,
    email,
    version: String(body.version || ""),
    channel: String(body.channel || ""),
    git: String(body.git || ""),
    buildDate: String(body.buildDate || ""),
    machineName: String(body.machineName || ""),
    timestamp: String(body.timestamp || new Date().toISOString()),
  };

  try {
    const result = await sendRegistrationEmail(rec, event);
    if (!result.sent) {
      return {
        statusCode: 502,
        headers: corsHeaders(),
        body: JSON.stringify({
          ok: false,
          error: "Email send failed",
          detail: result,
        }),
      };
    }
    return {
      statusCode: 200,
      headers: corsHeaders(),
      body: JSON.stringify({ ok: true, via: result.via }),
    };
  } catch (err) {
    return {
      statusCode: 502,
      headers: corsHeaders(),
      body: JSON.stringify({
        ok: false,
        error: "Email send failed",
        detail: String(err && err.message ? err.message : err),
      }),
    };
  }
};

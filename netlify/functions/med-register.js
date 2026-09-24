/**
 * MED install registration (Moore Design / mooredesign.net only).
 * Keep InstallHer branding OUT of this endpoint.
 *
 * POST JSON body:
 *   { name, email, version, channel, git, buildDate, machineName?, timestamp }
 * Upserts by normalized email into Netlify Blobs store "med-registrations".
 *
 * GET ?export=1 with header X-Med-Export-Key: <MED_EXPORT_KEY>
 *   returns JSON array of all registration records (for Sync-MEDRegistrations.ps1).
 *
 * Deploy: see netlify/README-med-register.md — deploy to MooreDesign site only.
 */
const { getStore } = require("@netlify/blobs");

function normalizeEmail(email) {
  return String(email || "")
    .trim()
    .toLowerCase();
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, X-Med-Export-Key",
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

exports.handler = async (event) => {
  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 204, headers: corsHeaders(), body: "" };
  }

  let store;
  try {
    store = getStore("med-registrations");
  } catch (err) {
    return {
      statusCode: 500,
      headers: corsHeaders(),
      body: JSON.stringify({
        ok: false,
        error:
          "Netlify Blobs unavailable. Enable Blobs on the MooreDesign site or check @netlify/blobs deploy.",
        detail: String(err && err.message ? err.message : err),
      }),
    };
  }

  if (event.httpMethod === "GET") {
    const qs = event.queryStringParameters || {};
    if (qs.export !== "1") {
      return {
        statusCode: 200,
        headers: corsHeaders(),
        body: JSON.stringify({
          ok: true,
          service: "med-register",
          site: "mooredesign",
          usage: "POST registration JSON; GET ?export=1 with X-Med-Export-Key",
        }),
      };
    }
    const key = event.headers["x-med-export-key"] || event.headers["X-Med-Export-Key"];
    const expected = process.env.MED_EXPORT_KEY;
    if (!expected || key !== expected) {
      return {
        statusCode: 401,
        headers: corsHeaders(),
        body: JSON.stringify({ ok: false, error: "Unauthorized export" }),
      };
    }
    const listed = await store.list();
    const blobs = (listed && listed.blobs) || [];
    const records = [];
    for (const b of blobs) {
      const raw = await store.get(b.key, { type: "text" });
      if (!raw) continue;
      try {
        records.push(JSON.parse(raw));
      } catch (_) {
        /* skip bad */
      }
    }
    return {
      statusCode: 200,
      headers: corsHeaders(),
      body: JSON.stringify({ ok: true, count: records.length, records }),
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

  const now = body.timestamp || new Date().toISOString();
  const existingRaw = await store.get(email, { type: "text" });
  let existing = null;
  if (existingRaw) {
    try {
      existing = JSON.parse(existingRaw);
    } catch (_) {
      existing = null;
    }
  }

  const record = {
    email,
    name,
    optIn: true,
    firstSeen: (existing && existing.firstSeen) || now,
    lastSeen: now,
    lastVersion: String(body.version || ""),
    lastChannel: String(body.channel || ""),
    lastGit: String(body.git || ""),
    buildDate: String(body.buildDate || ""),
    machineName: String(body.machineName || (existing && existing.machineName) || ""),
    history: Array.isArray(existing && existing.history) ? existing.history.slice(-19) : [],
  };
  record.history.push({
    at: now,
    version: record.lastVersion,
    channel: record.lastChannel,
    git: record.lastGit,
  });

  await store.setJSON(email, record);

  return {
    statusCode: 200,
    headers: corsHeaders(),
    body: JSON.stringify({ ok: true, email, upserted: true }),
  };
};

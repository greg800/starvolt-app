// Supabase Edge Function — Switchgrid v2 (search_contract + C68)
const SWITCHGRID_BASE = "https://app.switchgrid.tech/enedis/v2";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const SG_KEY = Deno.env.get("SWITCHGRID_API_KEY") ?? "";
const WELCOME_TOKEN = Deno.env.get("WELCOME_INTERNAL_TOKEN") ?? "";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};
// ── conso_profil : 8784 valeurs horaires (année bissextile 2024) ──────────────
const PROF_DAYS = [
  31,
  29,
  31,
  30,
  31,
  30,
  31,
  31,
  30,
  31,
  30,
  31
];
function buildMonthStarts() {
  const s = [];
  let a = 0;
  for (const n of PROF_DAYS){
    s.push(a);
    a += n * 24;
  }
  return s;
}
const MONTH_STARTS = buildMonthStarts();
const TOTAL_HOURS = 8784;
function profIdx(m, d, h) {
  return MONTH_STARTS[m - 1] + (d - 1) * 24 + h;
}
// Jour de la semaine du calendrier générique (référence 2024, 1er janv. = lundi).
// 0..4 = lun..ven ; 5..6 = sam/dim → week-end.
function isWeekendDay(dayIdx) {
  return dayIdx % 7 >= 5;
}
// Rebouche chaque JOUR entièrement absent du profil 8784 h en moyennant le profil
// horaire des jours du même type (semaine vs week-end) les plus proches qui ont
// des données → respecte les profils semaine / week-end des semaines encadrantes.
function fillMissingDays(profile, dayHasData) {
  const MAX_SAMPLES = 3;
  for(let d = 0; d < 366; d++){
    if (dayHasData[d]) continue;
    const wantWeekend = isWeekendDay(d);
    let samples = [];
    // 1) jours du MÊME type (semaine/week-end) les plus proches
    for(let delta = 1; delta < 366 && samples.length < MAX_SAMPLES; delta++){
      for (const cand of [
        d - delta,
        d + delta
      ]){
        if (cand < 0 || cand > 365 || !dayHasData[cand]) continue;
        if (isWeekendDay(cand) !== wantWeekend) continue;
        samples.push(cand);
        if (samples.length >= MAX_SAMPLES) break;
      }
    }
    // 2) repli : à défaut, les jours avec données les plus proches (tous types)
    if (samples.length === 0) {
      for(let delta = 1; delta < 366 && samples.length < MAX_SAMPLES; delta++){
        for (const cand of [
          d - delta,
          d + delta
        ]){
          if (cand < 0 || cand > 365 || !dayHasData[cand]) continue;
          samples.push(cand);
          if (samples.length >= MAX_SAMPLES) break;
        }
      }
    }
    if (samples.length === 0) continue; // aucune donnée nulle part (ne devrait pas arriver)
    for(let h = 0; h < 24; h++){
      let sum = 0;
      for (const s of samples)sum += profile[s * 24 + h];
      profile[d * 24 + h] = Math.round(sum / samples.length);
    }
  }
}
// ── parseLoadcurve ────────────────────────────────────────────────────────────
// Construit un profil horaire 8784 h à partir des points d'UNE fenêtre temporelle
// (loTs, hiTs]. Un seul passage par créneau calendaire → pas de double comptage
// (on n'appelle ce helper que sur des fenêtres ≤ 366 jours). Rebouche les petits
// trous internes. Renvoie aussi quels JOURS du calendrier ont des données.
function buildWindowProfile(allPoints, stepMs, loTs, hiTs) {
  const empty = {
    profile: new Array(TOTAL_HOURS).fill(0),
    dayHasData: new Array(366).fill(false),
    gaps: [],
    hasAny: false
  };
  // Map timestamp → Wh brut (v est en W, wh = W × durée_h)
  const tsMap = new Map(); // ts → Wh
  let minTs = Infinity, maxUsedTs = -Infinity;
  for (const p of allPoints){
    const ts = new Date(p.d).getTime();
    if (ts <= loTs || ts > hiTs) continue;
    const v = parseFloat(p.v) || 0;
    const dur = p.p === "PT15M" ? 0.25 : p.p === "PT60M" ? 1.0 : 0.5;
    tsMap.set(ts, Math.round(v * dur));
    if (ts < minTs) minTs = ts;
    if (ts > maxUsedTs) maxUsedTs = ts;
  }
  if (tsMap.size === 0) return empty;
  // Tous les timestamps attendus dans la plage
  const allTs = [];
  for(let t = minTs; t <= maxUsedTs; t += stepMs)allTs.push(t);
  // ── Rebouchage des petits trous internes ──────────────────────────────────
  const gaps = [];
  let i = 0;
  while(i < allTs.length){
    if (tsMap.has(allTs[i])) {
      i++;
      continue;
    }
    const g0 = i;
    while(i < allTs.length && !tsMap.has(allTs[i]))i++;
    const g1 = i - 1;
    const gCount = g1 - g0 + 1;
    const gHours = gCount * stepMs / 3600000;
    let method;
    if (gHours <= 4) {
      method = 'interpolation';
      const prevWh = tsMap.get(allTs[Math.max(0, g0 - 1)]) ?? 0;
      const nextWh = tsMap.get(allTs[Math.min(allTs.length - 1, g1 + 1)]) ?? 0;
      const avg = Math.round((prevWh + nextWh) / 2);
      for(let j = g0; j <= g1; j++)tsMap.set(allTs[j], avg);
    } else if (gHours <= 48) {
      method = 'jour précédent';
      for(let j = g0; j <= g1; j++)tsMap.set(allTs[j], tsMap.get(allTs[j] - 24 * 3600000) ?? 0);
    } else {
      method = 'semaine précédente';
      for(let j = g0; j <= g1; j++)tsMap.set(allTs[j], tsMap.get(allTs[j] - 7 * 24 * 3600000) ?? 0);
    }
    gaps.push({
      start: new Date(allTs[g0]).toISOString(),
      end: new Date(allTs[g1]).toISOString(),
      hours: Math.round(gHours * 10) / 10,
      method
    });
  }
  // ── Construire le profil horaire 8784 éléments ────────────────────────────
  const profile = new Array(TOTAL_HOURS).fill(0);
  for (const [ts, wh] of tsMap){
    const d = new Date(ts);
    const month = d.getUTCMonth() + 1;
    const day = d.getUTCDate();
    const hour = d.getUTCHours();
    const minute = d.getUTCMinutes();
    // Convention ENEDIS : le timestamp = FIN de période → "01:00" = conso 00h→01h
    let sm = month, sd = day, sh = hour;
    if (minute === 0 && hour === 0) {
      const prev = new Date(ts - 24 * 3600000);
      sm = prev.getUTCMonth() + 1;
      sd = prev.getUTCDate();
      sh = 23;
    } else if (minute === 0) {
      sh = hour - 1;
    }
    const idx = profIdx(sm, sd, sh);
    if (idx >= 0 && idx < TOTAL_HOURS) profile[idx] += wh;
  }
  // 29 février : copier le 28 si absent
  for(let h = 0; h < 24; h++){
    const i29 = profIdx(2, 29, h);
    if (!profile[i29]) profile[i29] = profile[profIdx(2, 28, h)];
  }
  const dayHasData = new Array(366).fill(false);
  for(let h = 0; h < TOTAL_HOURS; h++)if (profile[h] > 0) dayHasData[Math.floor(h / 24)] = true;
  return {
    profile,
    dayHasData,
    gaps,
    hasAny: true
  };
}
// Switchgrid LOADCURVE renvoie jusqu'à 24 mois de données.
// On reconstitue UNE année représentative en FUSIONNANT les 2 dernières années :
// pour chaque créneau (mois/jour/heure), on prend l'année la plus récente si elle
// a la donnée, sinon l'année précédente. On CHOISIT une valeur par créneau (jamais
// une addition) → aucun double comptage, et on garde la précision horaire.
// Si, même après fusion, >30 % des jours restent vides → insufficient=true
// (l'appelant bascule alors sur la mesure journalière R65).
function parseLoadcurve(raw) {
  const allPoints = raw.mesures[0].grandeur[0].points ?? [];
  if (!allPoints.length) return {
    profile: new Array(TOTAL_HOURS).fill(0),
    gaps: [],
    coverage: 0,
    daysPresent: 0,
    insufficient: true
  };
  // Trier chronologiquement (les dates ISO8601 sont triables lexicographiquement)
  allPoints.sort((a, b)=>a.d.localeCompare(b.d));
  // Détecter le pas de mesure (ms)
  let stepMs = 30 * 60 * 1000; // défaut : 30 min
  for(let i = 1; i < Math.min(20, allPoints.length); i++){
    const diff = new Date(allPoints[i].d).getTime() - new Date(allPoints[i - 1].d).getTime();
    if (diff > 0 && diff <= 90 * 60 * 1000) {
      stepMs = diff;
      break;
    }
  }
  const DAY = 24 * 3600 * 1000;
  const maxTs = new Date(allPoints[allPoints.length - 1].d).getTime();
  // Deux fenêtres glissantes de 366 jours : la récente puis la précédente
  const recent = buildWindowProfile(allPoints, stepMs, maxTs - 366 * DAY, maxTs);
  const prev = buildWindowProfile(allPoints, stepMs, maxTs - 732 * DAY, maxTs - 366 * DAY);
  if (!recent.hasAny && !prev.hasAny) {
    return {
      profile: new Array(TOTAL_HOURS).fill(0),
      gaps: [],
      coverage: 0,
      daysPresent: 0,
      insufficient: true
    };
  }
  // ── Fusion par JOUR : année récente prioritaire, sinon année précédente ────
  const profile = new Array(TOTAL_HOURS).fill(0);
  const dayHasData = new Array(366).fill(false);
  for(let d = 0; d < 366; d++){
    const src = recent.dayHasData[d] ? recent : prev.dayHasData[d] ? prev : null;
    if (!src) continue;
    for(let h = 0; h < 24; h++)profile[d * 24 + h] = src.profile[d * 24 + h];
    dayHasData[d] = true;
  }
  // Gaps internes signalés = ceux de la fenêtre récente (référence principale)
  const gaps = recent.gaps;
  const daysPresent = dayHasData.reduce((a, b)=>a + (b ? 1 : 0), 0);
  const coverage = daysPresent / 366;
  // Plus de 30 % de jours manquants MÊME après fusion → courbe trop partielle.
  if (coverage < 0.70) {
    return {
      profile,
      gaps,
      coverage,
      daysPresent,
      insufficient: true
    };
  }
  // Moins de 30 % manquants → reboucher les jours absents avec les jours du même
  // type (semaine / week-end) les plus proches qui ont des données.
  fillMissingDays(profile, dayHasData);
  return {
    profile,
    gaps,
    coverage,
    daysPresent,
    insufficient: false
  };
}
// ── C68 parsing ───────────────────────────────────────────────────────────────
function parseHcTime(t) {
  const m = t.trim().match(/^(\d+)[Hh](\d+)$/);
  if (!m) return null;
  return `${m[1].padStart(2, '0')}:${m[2].padStart(2, '0')}`;
}
function parseC68(raw) {
  try {
    const point = raw.point ?? {};
    const comptage = point?.situationComptage?.dispositifComptage ?? {};
    const contractuel = point?.situationContractuelle?.structureTarifaire ?? {};
    const plageStr = comptage?.relais?.plageHeuresCreuses ?? '';
    const hcMatch = plageStr.match(/HC\s*\(([^)]+)\)/i);
    const plages = [];
    if (hcMatch) {
      for (const rng of hcMatch[1].split(';')){
        const parts = rng.trim().split('-');
        if (parts.length === 2) {
          const debut = parseHcTime(parts[0]);
          const fin = parseHcTime(parts[1]);
          if (debut && fin) plages.push({
            debut,
            fin
          });
        }
      }
    }
    const puissanceStr = contractuel?.puissanceSouscriteMax?.valeur ?? null;
    const puissanceKva = puissanceStr ? parseFloat(puissanceStr) : null;
    const optionCode = contractuel?.formuleTarifaireAcheminement?.attributes?.code ?? null;
    return {
      hcDebut1: plages[0]?.debut ?? null,
      hcFin1: plages[0]?.fin ?? null,
      hcDebut2: plages[1]?.debut ?? null,
      hcFin2: plages[1]?.fin ?? null,
      puissanceKva,
      optionTarifaire: optionCode
    };
  } catch  {
    return {
      hcDebut1: null,
      hcFin1: null,
      hcDebut2: null,
      hcFin2: null,
      puissanceKva: null,
      optionTarifaire: null
    };
  }
}
// ── parseDaily (R65 — énergies quotidiennes, repli courbe de charge absente) ──
// Trouve le tableau de points {d, v} où qu'il soit dans le JSON Enedis.
function extractPoints(raw) {
  try {
    const p = raw?.mesures?.[0]?.grandeur?.[0]?.points;
    if (Array.isArray(p) && p.length) return p;
  } catch  {}
  const stack = [
    raw
  ];
  while(stack.length){
    const cur = stack.pop();
    if (Array.isArray(cur)) {
      if (cur.length && cur[0] && typeof cur[0] === "object" && "d" in cur[0] && "v" in cur[0]) return cur;
      for (const x of cur)if (x && typeof x === "object") stack.push(x);
    } else if (cur && typeof cur === "object") {
      for (const k of Object.keys(cur)){
        const v = cur[k];
        if (v && typeof v === "object") stack.push(v);
      }
    }
  }
  return [];
}
// Construit un profil 8784h APPROXIMATIF à partir des énergies quotidiennes :
// chaque jour est réparti uniformément sur 24 h (aucune granularité horaire réelle).
// Les jours manquants sont comblés par la moyenne journalière (estimation annuelle).
function parseDaily(raw) {
  const zeros = ()=>new Array(TOTAL_HOURS).fill(0);
  let points = extractPoints(raw);
  if (!points.length) return {
    profile: zeros(),
    total: 0,
    daysPresent: 0
  };
  points = points.filter((p)=>p && p.d).sort((a, b)=>String(a.d).localeCompare(String(b.d)));
  const last = points.slice(-400); // garde-fou (≈ 13 mois max)
  // Heuristique d'unité : conso journalière d'un foyer ≈ 5–50 kWh.
  // Si la médiane < 1000 → valeurs en kWh → convertir en Wh. Sinon déjà en Wh.
  const vals = last.map((p)=>parseFloat(p.v) || 0).filter((v)=>v > 0).sort((a, b)=>a - b);
  const median = vals.length ? vals[Math.floor(vals.length / 2)] : 0;
  const toWh = median > 0 && median < 1000 ? 1000 : 1;
  const dayMap = new Map(); // "m_d" → Wh du jour
  let sum = 0, cnt = 0;
  for (const p of last){
    const dayWh = (parseFloat(p.v) || 0) * toWh;
    if (dayWh <= 0) continue;
    const dt = new Date(p.d);
    const key = `${dt.getUTCMonth() + 1}_${dt.getUTCDate()}`;
    dayMap.set(key, dayWh);
    sum += dayWh;
    cnt++;
  }
  if (cnt === 0) return {
    profile: zeros(),
    total: 0,
    daysPresent: 0
  };
  const mean = sum / cnt;
  const profile = zeros();
  for(let m = 1; m <= 12; m++){
    for(let d = 1; d <= PROF_DAYS[m - 1]; d++){
      const dayWh = dayMap.get(`${m}_${d}`) ?? mean;
      const per = Math.round(dayWh / 24);
      for(let h = 0; h < 24; h++){
        const idx = profIdx(m, d, h);
        if (idx >= 0 && idx < TOTAL_HOURS) profile[idx] = per;
      }
    }
  }
  const total = profile.reduce((a, b)=>a + b, 0);
  return {
    profile,
    total,
    daysPresent: cnt
  };
}
// Applique les infos contractuelles C68 (HC/HP, puissance, option) au site.
async function applyC68(c68Req, siteUpdate) {
  if (c68Req?.status === "SUCCESS" && c68Req?.dataUrl) {
    try {
      const c68Resp = await fetch(c68Req.dataUrl);
      if (c68Resp.ok) {
        const c68Json = await c68Resp.json();
        const c68 = parseC68(c68Json);
        if (c68.hcDebut1) siteUpdate.hc_debut1 = c68.hcDebut1;
        if (c68.hcFin1) siteUpdate.hc_fin1 = c68.hcFin1;
        if (c68.hcDebut2) siteUpdate.hc_debut2 = c68.hcDebut2;
        if (c68.hcFin2) siteUpdate.hc_fin2 = c68.hcFin2;
        if (c68.puissanceKva !== null) siteUpdate.puissance_souscrite_kva = c68.puissanceKva;
        if (c68.optionTarifaire) siteUpdate.enedis_option_tarifaire = c68.optionTarifaire;
      }
    } catch  {}
  }
}
// ── Supabase REST helpers ────────────────────────────────────────────────────
function sbHeaders() {
  return {
    "apikey": SERVICE_KEY,
    "Authorization": `Bearer ${SERVICE_KEY}`,
    "Content-Type": "application/json",
    "Prefer": "return=representation"
  };
}
async function sbGet(table, filters) {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${filters}`, {
    headers: sbHeaders()
  });
  return await r.json();
}
async function sbInsert(table, row) {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
    method: "POST",
    headers: sbHeaders(),
    body: JSON.stringify(row)
  });
  const rows = await r.json();
  return rows[0];
}
async function sbUpdate(table, match, data) {
  await fetch(`${SUPABASE_URL}/rest/v1/${table}?${match}`, {
    method: "PATCH",
    headers: sbHeaders(),
    body: JSON.stringify(data)
  });
}
// ── Helpers Switchgrid : réutilisation de consentement + pose d'ordre ─────────
function sgHeaders() {
  return {
    "Authorization": `Bearer ${SG_KEY}`,
    "Content-Type": "application/json"
  };
}
// Cherche un ask dont le consentement est DÉJÀ signé (consentIds peuplé) — quel
// que soit le statut de la demande (done / error / pending). Permet de réutiliser
// une signature au lieu de régénérer un nouveau lien de consentement.
// Recherche d'abord par PDL (même compteur physique → même titulaire), ce qui
// couvre le cas où le consentement a été signé sur un AUTRE site/compte pour le
// même compteur (ex. site copié, compte admin). À défaut de PDL, repli sur le site.
async function findReusableConsent(site_id, fallbackPdl) {
  const pdl = (fallbackPdl ?? "").trim();
  const filter = pdl ? `pdl=eq.${encodeURIComponent(pdl)}&ask_id=not.is.null&select=ask_id,pdl,created_at&order=created_at.desc&limit=12` : `site_id=eq.${site_id}&ask_id=not.is.null&select=ask_id,pdl,created_at&order=created_at.desc&limit=6`;
  const rows = await sbGet("switchgrid_requests", filter);
  const seen = new Set();
  for (const r of rows){
    const askId = r.ask_id;
    if (!askId || seen.has(askId)) continue;
    seen.add(askId);
    try {
      const askResp = await fetch(`${SWITCHGRID_BASE}/ask/${askId}`, {
        headers: sgHeaders()
      });
      if (!askResp.ok) continue;
      const askData = await askResp.json();
      const consentIds = askData.consentIds ?? {};
      const consentId = Object.values(consentIds)[0];
      if (consentId) return {
        consentId,
        ask_id: askId,
        pdl: String(r.pdl ?? fallbackPdl ?? "")
      };
    } catch  {}
  }
  return null;
}
// Pose un ordre Switchgrid (courbe de charge + énergies journalières + contrat).
// Renvoie l'id de l'ordre, ou null si l'API refuse.
async function placeSwitchgridOrder(consentId, pdl) {
  const orderResp = await fetch(`${SWITCHGRID_BASE}/order`, {
    method: "POST",
    headers: sgHeaders(),
    body: JSON.stringify({
      consentId,
      requests: [
        {
          type: "LOADCURVE",
          direction: "CONSUMPTION",
          prms: [
            pdl
          ]
        },
        {
          type: "R65",
          prms: [
            pdl
          ]
        },
        {
          type: "C68",
          prms: [
            pdl
          ]
        }
      ]
    })
  });
  if (!orderResp.ok) return null;
  const order = await orderResp.json();
  return order.id ?? null;
}
async function getUser(token) {
  const r = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: {
      "apikey": SERVICE_KEY,
      "Authorization": `Bearer ${token}`
    }
  });
  if (!r.ok) return null;
  const u = await r.json();
  if (!u.id) return null;
  return {
    id: u.id,
    email: u.email ?? ""
  };
}
function jsonResp(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS,
      "Content-Type": "application/json"
    }
  });
}
// ════════════════════════════════════════════════════════════════════════════
Deno.serve(async (req)=>{
  if (req.method === "OPTIONS") return new Response("ok", {
    headers: CORS
  });
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace("Bearer ", "");
  const user = await getUser(token);
  if (!user) return jsonResp({
    error: "Unauthorized"
  }, 401);
  const sgH = {
    "Authorization": `Bearer ${SG_KEY}`,
    "Content-Type": "application/json"
  };
  // ──────────────────────────────────────────────────────────────────────────
  // POST → rechercher le contrat puis créer un ask Switchgrid
  // ──────────────────────────────────────────────────────────────────────────
  if (req.method === "POST") {
    const body = await req.json();
    const { site_id, pdl, firstName, lastName, address, codePostal, commune } = body;
    const inputPdl = (pdl ?? "").trim();
    const hasExplicitPdl = /^\d{14}$/.test(inputPdl);
    const name = `${firstName} ${lastName}`.trim();
    if (site_id) {
      // ── A. Réutiliser un consentement DÉJÀ signé (priorité) ───────────────
      // Si un ask du site a déjà un consentement signé (même issu d'une tentative
      // précédente en erreur/pending), on pose directement l'ordre au lieu de
      // régénérer un nouveau lien de consentement.
      // ⚠️ UNIQUEMENT si un PDL explicite (14 chiffres) est fourni : sans PDL
      // confirmé on ne réutilise jamais un consentement, sinon on risque de
      // reprendre le compteur d'un AUTRE site (bug : deux sites, même conso).
      try {
        const reuse = hasExplicitPdl ? await findReusableConsent(site_id, inputPdl) : null;
        if (reuse) {
          const orderId = await placeSwitchgridOrder(reuse.consentId, reuse.pdl);
          if (orderId) {
            const rec = await sbInsert("switchgrid_requests", {
              user_id: user.id,
              site_id,
              pdl: reuse.pdl,
              ask_id: reuse.ask_id,
              order_id: orderId,
              status: "ordering"
            });
            return jsonResp({
              request_id: rec.id,
              status: "ordering"
            });
          }
        }
      } catch  {}
      // ── B. Garde anti-relance / reprise d'une demande existante ───────────
      try {
        const recentRows = await sbGet("switchgrid_requests", `site_id=eq.${site_id}&order=created_at.desc&limit=1&select=*`);
        const last = recentRows[0];
        if (last) {
          const ageMs = Date.now() - new Date(last.created_at).getTime();
          const st = last.status;
          // Demande déjà en cours → la renvoyer plutôt que d'en créer une nouvelle
          if (st === "pending" || st === "ordering") {
            return jsonResp({
              request_id: last.id,
              status: st
            });
          }
          // Erreur de quota / absence de mesure récente → cooldown 6 h
          const em = last.error_message ?? "";
          const COOLDOWN_MS = 6 * 3600 * 1000;
          if (st === "error" && /quota|mesure|SGT720/i.test(em) && ageMs < COOLDOWN_MS) {
            const hoursLeft = Math.max(1, Math.ceil((COOLDOWN_MS - ageMs) / 3600000));
            return jsonResp({
              error: "COOLDOWN",
              message: `ENEDIS limite le nombre de demandes par jour pour ce compteur. Une tentative a déjà eu lieu récemment — réessayez dans ~${hoursLeft} h.`,
              retry_after_hours: hoursLeft
            }, 429);
          }
          // Erreur non-quota avec un ask encore exploitable → REPRENDRE le même
          // lien de consentement (ne pas multiplier les asks orphelins).
          if (st === "error" && last.ask_id) {
            try {
              const askResp = await fetch(`${SWITCHGRID_BASE}/ask/${last.ask_id}`, {
                headers: sgHeaders()
              });
              if (askResp.ok) {
                const askData = await askResp.json();
                const userUrl = askData.consentCollectionDetails?.userUrl ?? null;
                if (userUrl) {
                  await sbUpdate("switchgrid_requests", `id=eq.${last.id}`, {
                    status: "pending",
                    error_message: null
                  });
                  return jsonResp({
                    request_id: last.id,
                    status: "pending",
                    userUrl
                  });
                }
              }
            } catch  {}
          }
        }
      } catch  {}
    }
    // ── Étape 1 : rechercher le contrat ENEDIS ────────────────────────────
    // ENEDIS stocke les noms en majuscules → on force l'uppercase pour maximiser les correspondances
    const nameUpper = name.toUpperCase();
    const fullAddress = address && codePostal && commune ? `${address} ${codePostal} ${commune}` : null;
    if (!inputPdl && !fullAddress) {
      return jsonResp({
        error: "Renseignez le PDL ou l'adresse complète (rue, CP, ville)."
      }, 400);
    }
    // Fonction helper pour appeler search_contract
    const doSearch = async (params)=>{
      const sp = new URLSearchParams({
        name: nameUpper,
        ...params
      });
      const r = await fetch(`${SWITCHGRID_BASE}/search_contract?${sp.toString()}`, {
        headers: {
          "Authorization": `Bearer ${SG_KEY}`
        }
      });
      if (!r.ok) return [];
      const d = await r.json();
      return d.results ?? [];
    };
    let results = [];
    // Tentative 1 : par PDL si disponible
    if (inputPdl) {
      results = await doSearch({
        prm: inputPdl
      });
    }
    // Tentative 2 : par adresse si PDL a échoué (ou pas de PDL)
    if (results.length === 0 && fullAddress) {
      results = await doSearch({
        address: fullAddress
      });
    }
    if (results.length === 0) {
      return jsonResp({
        error: "Aucun contrat ENEDIS trouvé pour ce nom et cette adresse. Vérifiez l'orthographe du nom et l'adresse."
      }, 400);
    }
    // ── Validation du compteur AVANT toute extraction ─────────────────────
    // On ne lance la collecte que si le compteur est validé sans ambiguïté :
    //   • soit l'utilisateur a fourni le PDL EXACT (choix explicite),
    //   • soit la recherche par adresse ne renvoie qu'UN compteur ET son
    //     adresse normalisée ENEDIS correspond au code postal saisi.
    // Sinon → on renvoie les candidats (nom + adresse) pour que l'utilisateur
    // confirme lui-même. On n'invente rien, on ne crée aucun ask, aucune extraction.
    const norm = (s)=> (s ?? "").toString().toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^a-z0-9]+/g, " ").trim();
    const meterAddrStr = (r)=> norm(`${r.adresseInstallationNormalisee?.ligne4 ?? ""} ${r.adresseInstallationNormalisee?.ligne6 ?? ""}`);
    const cpNorm = norm(codePostal);
    const addrMatches = (r)=> !!cpNorm && meterAddrStr(r).includes(cpNorm);
    const explicitMatch = hasExplicitPdl ? results.find((r)=> String(r.prm) === inputPdl) : null;
    const chosen = explicitMatch || (results.length === 1 && addrMatches(results[0]) ? results[0] : null);
    if (!chosen) {
      return jsonResp({
        error: "CONFIRM_METER",
        message: results.length > 1
          ? `${results.length} compteurs correspondent à ce nom. Sélectionnez celui qui correspond à votre adresse.`
          : `Le compteur trouvé ne correspond pas exactement à l'adresse saisie. Vérifiez qu'il s'agit bien du bon compteur avant de lancer la collecte.`,
        results: results.map((r)=>({
            prm: r.prm,
            nom: r.nomClientFinalOuDenominationSociale,
            adresse: [
              r.adresseInstallationNormalisee?.ligne4,
              r.adresseInstallationNormalisee?.ligne6
            ].filter(Boolean).join(", ")
          }))
      }, 409);
    }
    // ── Compteur validé ───────────────────────────────────────────────────
    const contractUuid = chosen.id;
    const foundPdl = chosen.prm;
    const nomContrat = chosen.nomClientFinalOuDenominationSociale;
    // Sauvegarder le PDL si découvert ou corrigé
    const pdlChanged = foundPdl !== inputPdl;
    if (pdlChanged) {
      await sbUpdate("sites", `id=eq.${site_id}`, {
        pdl: foundPdl
      });
    }
    // ── Étape 2 : créer l'ask avec l'UUID du contrat ──────────────────────
    const askBody = {
      electricityContracts: [
        contractUuid
      ],
      signer: {
        firstName: firstName.toUpperCase(),
        lastName: lastName.toUpperCase()
      },
      consentCollectionMedium: {
        service: "WEB_HOSTED"
      },
      consentDuration: "3 years",
      purposes: [
        "DEMAND_RESPONSE"
      ]
    };
    const askResp = await fetch(`${SWITCHGRID_BASE}/ask`, {
      method: "POST",
      headers: sgH,
      body: JSON.stringify(askBody)
    });
    if (!askResp.ok) {
      const err = await askResp.text();
      return jsonResp({
        error: `Switchgrid ask: ${err}`
      }, 500);
    }
    const ask = await askResp.json();
    if (ask.status === "ADDRESS_CHECK_FAILED") {
      return jsonResp({
        error: "L'adresse saisie ne correspond pas à ce compteur ENEDIS. Vérifiez l'adresse du site."
      }, 400);
    }
    const userUrl = ask.consentCollectionDetails?.userUrl ?? null;
    const rec = await sbInsert("switchgrid_requests", {
      user_id: user.id,
      site_id,
      pdl: foundPdl,
      ask_id: ask.id,
      status: "pending"
    });
    return jsonResp({
      request_id: rec.id,
      status: "pending",
      userUrl,
      pdl_found: pdlChanged ? foundPdl : undefined,
      nom_contrat: nomContrat
    });
  }
  // ──────────────────────────────────────────────────────────────────────────
  // GET → sonder le statut d'une demande existante
  // ──────────────────────────────────────────────────────────────────────────
  if (req.method === "GET") {
    const url = new URL(req.url);
    const requestId = url.searchParams.get("request_id");
    if (!requestId) return jsonResp({
      error: "Missing request_id"
    }, 400);
    const rows = await sbGet("switchgrid_requests", `id=eq.${requestId}&user_id=eq.${user.id}&select=*`);
    const rec = rows[0];
    if (!rec) return jsonResp({
      error: "Not found"
    }, 404);
    if (rec.status === "done") return jsonResp({
      status: "done"
    });
    if (rec.status === "error") return jsonResp({
      status: "error",
      error_message: rec.error_message
    });
    // ── pending : vérifier si consentement obtenu ──
    if (rec.status === "pending") {
      const askResp = await fetch(`${SWITCHGRID_BASE}/ask/${rec.ask_id}`, {
        headers: {
          "Authorization": `Bearer ${SG_KEY}`
        }
      });
      const askData = await askResp.json();
      if (askData.status === "ADDRESS_CHECK_FAILED") {
        await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
          status: "error",
          error_message: "L'adresse ne correspond pas au compteur ENEDIS."
        });
        return jsonResp({
          status: "error",
          error_message: "L'adresse ne correspond pas au compteur ENEDIS. Mettez à jour l'adresse du site."
        });
      }
      const userUrl = askData.consentCollectionDetails?.userUrl ?? null;
      const consentIds = askData.consentIds ?? {};
      const consentId = Object.values(consentIds)[0];
      if (!consentId) {
        // Ce ask n'est pas (encore) signé. Mais une demande sœur du même site
        // a peut-être DÉJÀ un consentement signé (ex. l'utilisateur a signé sur
        // un lien précédent, puis recliqué « Récupérer » créant un nouveau ask).
        // On réutilise cette signature au lieu de rester bloqué en pending.
        const reuse = await findReusableConsent(rec.site_id, String(rec.pdl ?? ""));
        if (reuse) {
          const reuseOrderId = await placeSwitchgridOrder(reuse.consentId, reuse.pdl);
          if (reuseOrderId) {
            await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
              order_id: reuseOrderId,
              ask_id: reuse.ask_id,
              status: "ordering"
            });
            return jsonResp({
              status: "ordering"
            });
          }
        }
        return jsonResp({
          status: "pending",
          userUrl
        });
      }
      // Consentement OK → commander LOADCURVE (courbe de charge précise) + R65
      // (énergies quotidiennes, repli si la courbe de charge est absente) + C68
      const orderResp = await fetch(`${SWITCHGRID_BASE}/order`, {
        method: "POST",
        headers: sgH,
        body: JSON.stringify({
          consentId,
          requests: [
            {
              type: "LOADCURVE",
              direction: "CONSUMPTION",
              prms: [
                String(rec.pdl ?? "")
              ]
            },
            {
              type: "R65",
              prms: [
                String(rec.pdl ?? "")
              ]
            },
            {
              type: "C68",
              prms: [
                String(rec.pdl ?? "")
              ]
            }
          ]
        })
      });
      if (!orderResp.ok) {
        const err = await orderResp.text();
        await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
          status: "error",
          error_message: `Order: ${err}`
        });
        return jsonResp({
          status: "error",
          error_message: `Order: ${err}`
        });
      }
      const order = await orderResp.json();
      await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
        order_id: order.id,
        status: "ordering"
      });
      return jsonResp({
        status: "ordering"
      });
    }
    // ── ordering : sonder la commande ──
    if (rec.status === "ordering") {
      const orderResp = await fetch(`${SWITCHGRID_BASE}/order/${rec.order_id}`, {
        headers: {
          "Authorization": `Bearer ${SG_KEY}`
        }
      });
      const order = await orderResp.json();
      const requests = order.requests ?? [];
      const lcReq = requests.find((r)=>r.type === "LOADCURVE");
      const r65Req = requests.find((r)=>r.type === "R65");
      const c68Req = requests.find((r)=>r.type === "C68");
      const lcDone = lcReq?.status === "SUCCESS" && !!lcReq?.dataUrl;
      // "SUCCESS sans dataUrl" = inexploitable → traité comme un échec (repli)
      const lcFailed = lcReq?.status === "FAILED" || lcReq?.status === "SUCCESS" && !lcReq?.dataUrl;
      const r65Done = r65Req?.status === "SUCCESS";
      const r65Failed = r65Req?.status === "FAILED";
      const orderDead = order.status === "FAILED";
      // ════════════════════════════════════════════════════════════════════
      // CAS 1 — Courbe de charge disponible → profil PRÉCIS (idéal)
      // ════════════════════════════════════════════════════════════════════
      if (lcDone && lcReq.dataUrl) {
        const siteUpdate = {
          conso_imported_at: new Date().toISOString(),
          conso_source: "loadcurve"
        };
        const dataResp = await fetch(lcReq.dataUrl);
        if (!dataResp.ok) {
          await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
            status: "error",
            error_message: "Cannot fetch LOADCURVE data"
          });
          return jsonResp({
            status: "error",
            error_message: "Cannot fetch LOADCURVE data"
          });
        }
        const rawJson = await dataResp.json();
        // parseLoadcurve : filtre 12 mois + rebouche les petits trous + mesure la couverture
        const { profile: consoProfile, gaps: consoGaps, insufficient, coverage } = parseLoadcurve(rawJson);
        // ── Courbe trop partielle (>30 % de jours manquants) ─────────────────
        // → on préfère la mesure JOURNALIÈRE (R65), plus représentative sur l'année,
        //   avec le bandeau « approximatif ». À défaut de R65, on garde la courbe
        //   partielle mais marquée approximative.
        if (insufficient) {
          const pct = Math.round((1 - coverage) * 100);
          if (r65Done && r65Req?.dataUrl) {
            const dResp = await fetch(r65Req.dataUrl);
            if (dResp.ok) {
              const dRaw = await dResp.json();
              const { profile: dProfile, total: dTotal, daysPresent: dDays } = parseDaily(dRaw);
              if (dDays > 0) {
                const su = {
                  conso_imported_at: new Date().toISOString(),
                  conso_source: "daily",
                  conso_gaps: null,
                  conso_profil: dProfile,
                  conso_annuelle_kwh: Math.round(dTotal / 100) / 10
                };
                await applyC68(c68Req, su);
                await sbUpdate("sites", `id=eq.${rec.site_id}`, su);
                await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
                  status: "done",
                  error_message: `Courbe de charge partielle chez ENEDIS (${pct}% de jours manquants) — données journalières (approximatives) utilisées.`
                });
                return jsonResp({
                  status: "done",
                  conso_source: "daily"
                });
              }
            }
          }
          // Pas de R65 exploitable → courbe partielle conservée mais marquée approximative
          const totalP = consoProfile.reduce((a, b)=>a + b, 0);
          siteUpdate.conso_source = "daily";
          siteUpdate.conso_profil = consoProfile;
          siteUpdate.conso_annuelle_kwh = Math.round(totalP / 100) / 10;
          siteUpdate.conso_gaps = consoGaps.length > 0 ? consoGaps : null;
          await applyC68(c68Req, siteUpdate);
          await sbUpdate("sites", `id=eq.${rec.site_id}`, siteUpdate);
          await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
            status: "done",
            error_message: `Courbe de charge partielle chez ENEDIS (${pct}% de jours manquants) et énergies journalières indisponibles — estimation approximative.`
          });
          return jsonResp({
            status: "done",
            conso_source: "daily"
          });
        }
        // ── Couverture suffisante (trous rebouchés par semaines encadrantes) → PRÉCIS
        const total = consoProfile.reduce((a, b)=>a + b, 0);
        siteUpdate.conso_profil = consoProfile;
        siteUpdate.conso_annuelle_kwh = Math.round(total / 100) / 10;
        siteUpdate.conso_gaps = consoGaps.length > 0 ? consoGaps : null;
        await applyC68(c68Req, siteUpdate);
        await sbUpdate("sites", `id=eq.${rec.site_id}`, siteUpdate);
        await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
          status: "done"
        });
        return jsonResp({
          status: "done",
          conso_source: "loadcurve"
        });
      }
      // ════════════════════════════════════════════════════════════════════
      // CAS 2 — Courbe de charge absente MAIS énergies quotidiennes dispo
      //         → profil APPROXIMATIF (réparti uniformément sur 24 h)
      // ════════════════════════════════════════════════════════════════════
      if ((lcFailed || orderDead) && r65Done && r65Req.dataUrl) {
        const siteUpdate = {
          conso_imported_at: new Date().toISOString(),
          conso_source: "daily",
          conso_gaps: null
        };
        const dataResp = await fetch(r65Req.dataUrl);
        if (dataResp.ok) {
          const rawJson = await dataResp.json();
          const { profile, total, daysPresent } = parseDaily(rawJson);
          if (daysPresent > 0) {
            siteUpdate.conso_profil = profile;
            siteUpdate.conso_annuelle_kwh = Math.round(total / 100) / 10;
            await applyC68(c68Req, siteUpdate);
            await sbUpdate("sites", `id=eq.${rec.site_id}`, siteUpdate);
            await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
              status: "done",
              error_message: "Courbe de charge indisponible chez ENEDIS — données journalières (approximatives) utilisées."
            });
            return jsonResp({
              status: "done",
              conso_source: "daily"
            });
          }
        }
      // R65 inexploitable → on tombe en erreur ci-dessous
      }
      // ════════════════════════════════════════════════════════════════════
      // CAS 3 — Tout a échoué → erreur
      // ════════════════════════════════════════════════════════════════════
      if ((lcFailed || orderDead) && (r65Failed || !r65Req || r65Done && !r65Req.dataUrl)) {
        const errMsg = lcReq?.errorMessage ?? requests?.[0]?.errorMessage ?? "Order failed";
        await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
          status: "error",
          error_message: errMsg
        });
        return jsonResp({
          status: "error",
          error_message: errMsg
        });
      }
      // Sinon : au moins une donnée est encore en cours → on attend.
      return jsonResp({
        status: "ordering"
      });
    }
    return jsonResp({
      status: rec.status
    });
  }
  return jsonResp({
    error: "Method not allowed"
  }, 405);
});

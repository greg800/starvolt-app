// Supabase Edge Function — Switchgrid API v0
// Remplace l'implémentation v2 (app.switchgrid.tech/enedis/v2), obsolète.
// Flux v0 : search_contract -> /ask (consentement) -> /integration/enedis/order
//           (R63 courbe de charge + R65 journalier + C68_ASYNC technique)
//           -> poll /integration/enedis/order/{id} -> écriture du profil 8784 h.
const SG_BASE = "https://api.switchgrid.tech";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const SG_KEY = Deno.env.get("SWITCHGRID_API_KEY") ?? "";
const SG_CRON_SECRET = Deno.env.get("SWITCHGRID_CRON_SECRET") ?? "";
// Repli journalier : couverture minimale (jours) pour accepter un R65 comme
// candidat fiable. En-dessous, on considère le R65 encore partiel et on attend.
const MIN_DAILY_DAYS = 300;
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};
// PRM résidentiel de test fourni par Switchgrid (environnement de test).
const TEST_PRM = "00056092042209";
const isTestPdl = (p)=>String(p ?? "").trim() === TEST_PRM;
// ── conso_profil : 8784 valeurs horaires (année bissextile 2024) ─────────────
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
const zeros = ()=>new Array(TOTAL_HOURS).fill(0);
// Jour de la semaine du calendrier générique (référence 2024, 1er janv. = lundi).
function isWeekendDay(dayIdx) {
  return dayIdx % 7 >= 5;
}
// Rebouche chaque JOUR entièrement absent en moyennant les jours du même type
// (semaine vs week-end) les plus proches qui ont des données.
function fillMissingDays(profile, dayHasData) {
  const MAX_SAMPLES = 3;
  let filled = 0, unfilled = 0;
  for(let d = 0; d < 366; d++){
    if (dayHasData[d]) continue;
    const wantWeekend = isWeekendDay(d);
    let samples = [];
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
    if (samples.length === 0) { unfilled++; continue; }
    for(let h = 0; h < 24; h++){
      let sum = 0;
      for (const s of samples)sum += profile[s * 24 + h];
      profile[d * 24 + h] = Math.round(sum / samples.length);
    }
    filled++;
  }
  return { filled, unfilled };
}
// ── Analyse des bascules HC/HP (détection du contacteur jour/nuit) ───────────
// À l'instant exact où le Linky bascule HP→HC, un contacteur asservi enclenche le
// cumulus : la puissance appelée fait un saut. À la bascule HC→HP, elle rechute.
// Si ces sauts n'apparaissent pas, c'est que le contacteur n'est pas câblé entre
// le Linky et l'armoire (ou que le ballon est piloté autrement).
// On travaille sur la courbe BRUTE (pas 30 min) : le profil horaire stocké écrase
// justement la marche qu'on cherche à mesurer.
const PARIS_HM_FMT = new Intl.DateTimeFormat("en-GB", {
  timeZone: "Europe/Paris",
  hour: "numeric",
  minute: "numeric",
  hour12: false
});
function parisHM(ms) {
  const parts = PARIS_HM_FMT.formatToParts(new Date(ms));
  let h = 0, mi = 0;
  for (const x of parts){
    if (x.type === "hour") h = parseInt(x.value, 10);
    else if (x.type === "minute") mi = parseInt(x.value, 10);
  }
  if (h === 24) h = 0;
  return h * 60 + mi;
}
const HC_STEP_W = 1000; // seuil de variation considéré comme un enclenchement
function hhmmToMin(s) {
  const m = String(s ?? "").trim().match(/^(\d{1,2}):(\d{2})$/);
  if (!m) return null;
  const v = +m[1] * 60 + +m[2];
  return v >= 0 && v < 1440 ? v : null;
}
// Moyenne des `n` pas juste avant / juste après l'index i. null si un trou.
function meanSlots(values, from, n) {
  if (from < 0 || from + n > values.length) return null;
  let sum = 0;
  for(let k = 0; k < n; k++){
    const v = values[from + k];
    if (v == null || !Number.isFinite(Number(v))) return null;
    sum += Number(v);
  }
  return sum / n;
}
// windows : [{debut,fin}] en "HH:MM" (heures creuses). Renvoie null si inexploitable.
function analyzeHcTransitions(lc, windows) {
  if (!lc || !Array.isArray(lc.values) || !lc.values.length || !lc.startsAt) return null;
  const wins = (windows ?? []).map((w)=>({
      debut: hhmmToMin(w?.debut),
      fin: hhmmToMin(w?.fin)
    })).filter((w)=>w.debut != null && w.fin != null);
  if (!wins.length) return null;
  const step = periodMs(lc.period);
  const start = new Date(lc.startsAt).getTime();
  if (!Number.isFinite(start) || step <= 0 || step > 3600000) return null;
  const stepMin = step / 60000;
  // Fenêtre de comparaison : 1 h de part et d'autre de la bascule (le cumulus tire
  // 1,5-2,5 kW pendant plusieurs heures ; 1 h lisse le bruit sans noyer la marche).
  const n = Math.max(1, Math.round(60 / stepMin));
  // Instants de bascule attendus, en minutes locales.
  const starts = [ ...new Set(wins.map((w)=>w.debut)) ]; // HP→HC : hausse attendue
  const ends = [ ...new Set(wins.map((w)=>w.fin)) ]; // HC→HP : baisse attendue
  const acc = {
    up: { matched: 0, detected: 0, sumDelta: 0 },
    down: { matched: 0, detected: 0, sumDelta: 0 }
  };
  // ENEDIS décale très souvent les heures creuses à la minute près (ex. 01H36-07H36)
  // pour étaler l'appel de puissance sur le réseau : la bascule tombe alors AU MILIEU
  // d'un pas de 30 min. Ce pas-là est à cheval (moitié HP, moitié HC) → on l'écarte et
  // on compare l'heure qui le précède à l'heure qui le suit. Exiger un pas aligné pile
  // sur la bascule ne marcherait que pour les rares plages à l'heure ronde.
  const straddleMax = { up: 0, down: 0 }; // suivi du décalage réel (diagnostic)
  for(let i = 0; i < lc.values.length; i++){
    const slotStart = parisHM(start + i * step);
    for (const [dir, targets] of [
      [ "up", starts ],
      [ "down", ends ]
    ]){
      for (const t of targets){
        const rel = (t - slotStart + 1440) % 1440; // position de la bascule dans le pas
        if (rel !== 0 && rel >= stepMin) continue; // bascule hors de ce pas
        const before = meanSlots(lc.values, i - n, n);
        // rel===0 : le pas démarre pile sur la bascule → il est déjà « après ».
        // rel>0   : le pas est à cheval → on démarre l'« après » au pas suivant.
        const after = meanSlots(lc.values, rel === 0 ? i : i + 1, n);
        if (before == null || after == null) continue; // journée trouée → ignorée
        if (rel > straddleMax[dir]) straddleMax[dir] = rel;
        const delta = after - before;
        const a = acc[dir];
        a.matched++;
        if (dir === "up" ? delta > HC_STEP_W : delta < -HC_STEP_W) {
          a.detected++;
          a.sumDelta += delta;
        }
      }
    }
  }
  if (!acc.up.matched && !acc.down.matched) return null; // aucune bascule exploitable
  // NB : `count` = nombre de BASCULES analysées, pas de jours — un compteur à deux
  // plages HC (ex. nuit + méridienne) bascule deux fois par jour dans chaque sens.
  const side = (a)=>({
      count: a.matched,
      detected: a.detected,
      pct: a.matched ? Math.round(a.detected / a.matched * 1000) / 10 : null,
      avg_delta_w: a.detected ? Math.round(a.sumDelta / a.detected) : null
    });
  const up = side(acc.up), down = side(acc.down);
  const pcts = [ up.pct, down.pct ].filter((p)=>p != null);
  const best = pcts.length ? Math.max(...pcts) : null;
  const verdict = best == null ? "unknown" : best >= 50 ? "likely" : best >= 20 ? "partial" : "unlikely";
  return {
    computed_at: new Date().toISOString(),
    step_min: stepMin,
    threshold_w: HC_STEP_W,
    // Décalage (min) de la bascule à l'intérieur d'un pas : 0 = bascule à l'heure ronde,
    // >0 = plage HC décalée par ENEDIS, le pas à cheval a été écarté de la comparaison.
    straddle_min: Math.max(straddleMax.up, straddleMax.down),
    windows: wins.map((w)=>`${String(Math.floor(w.debut / 60)).padStart(2, "0")}:${String(w.debut % 60).padStart(2, "0")}-${String(Math.floor(w.fin / 60)).padStart(2, "0")}:${String(w.fin % 60).padStart(2, "0")}`),
    hp_to_hc: up,
    hc_to_hp: down,
    verdict
  };
}
// ── Construction du profil horaire à partir d'une courbe de charge v0 ────────
// Entrée : { period, startsAt, values:[wattsMoyens|null, ...] } à pas constant.
// Les valeurs sont en WATTS moyens sur l'intervalle ; Wh = W * durée_h.
// Mapping en heure locale Europe/Paris (alignement HC/HP, gère l'heure d'été).
const PARIS_FMT = new Intl.DateTimeFormat("en-GB", {
  timeZone: "Europe/Paris",
  month: "numeric",
  day: "numeric",
  hour: "numeric",
  hour12: false
});
function parisMDH(ms) {
  const parts = PARIS_FMT.formatToParts(new Date(ms));
  let m = 0, d = 0, h = 0;
  for (const x of parts){
    if (x.type === "month") m = parseInt(x.value, 10);
    else if (x.type === "day") d = parseInt(x.value, 10);
    else if (x.type === "hour") h = parseInt(x.value, 10);
  }
  if (h === 24) h = 0;
  return [
    m,
    d,
    h
  ];
}
function periodMs(period) {
  const s = String(period ?? "").toUpperCase();
  const pt = s.match(/PT(\d+)([HM])/);
  if (pt) return pt[2] === "H" ? +pt[1] * 3600000 : +pt[1] * 60000;
  if (s.includes("5MIN")) return 300000;
  if (s.includes("10MIN")) return 600000;
  if (s.includes("15MIN")) return 900000;
  if (s.includes("30MIN")) return 1800000;
  if (s.includes("1D")) return 86400000;
  if (s.includes("1H")) return 3600000;
  return 3600000;
}
// Renvoie { profile, dayHasData, coverage, daysPresent, hasAny }.
function buildProfileV0(lc) {
  const empty = {
    profile: zeros(),
    dayHasData: new Array(366).fill(false),
    coverage: 0,
    daysPresent: 0,
    hasAny: false
  };
  if (!lc || !Array.isArray(lc.values) || !lc.values.length || !lc.startsAt) return empty;
  const step = periodMs(lc.period);
  const start = new Date(lc.startsAt).getTime();
  if (!Number.isFinite(start)) return empty;
  // Étape A : agréger les points sous-horaires en Wh par HEURE absolue.
  const absHourWh = new Map();
  for(let i = 0; i < lc.values.length; i++){
    const raw = lc.values[i];
    const v = raw == null ? null : Number(raw);
    if (v === null || !Number.isFinite(v)) continue;
    const ts = start + i * step;
    const absH = Math.floor(ts / 3600000);
    const wh = v * (step / 3600000);
    absHourWh.set(absH, (absHourWh.get(absH) ?? 0) + wh);
  }
  if (absHourWh.size === 0) return empty;
  // Étape B : projeter sur le calendrier générique. Plusieurs années peuvent se
  // recouvrir : on trie du plus ancien au plus récent, le plus récent l'emporte.
  const profile = zeros();
  const entries = [
    ...absHourWh.entries()
  ].sort((a, b)=>a[0] - b[0]);
  for (const [absH, wh] of entries){
    const [m, d, h] = parisMDH(absH * 3600000);
    const idx = profIdx(m, d, h);
    if (idx >= 0 && idx < TOTAL_HOURS) profile[idx] = Math.round(wh);
  }
  // 29 février : copier le 28 si absent.
  for(let h = 0; h < 24; h++){
    const i29 = profIdx(2, 29, h);
    if (!profile[i29]) profile[i29] = profile[profIdx(2, 28, h)];
  }
  const dayHasData = new Array(366).fill(false);
  for(let i = 0; i < TOTAL_HOURS; i++)if (profile[i] > 0) dayHasData[Math.floor(i / 24)] = true;
  const daysPresent = dayHasData.reduce((a, b)=>a + (b ? 1 : 0), 0);
  return {
    profile,
    dayHasData,
    coverage: daysPresent / 366,
    daysPresent,
    hasAny: true
  };
}
// ── C68 (données techniques / contractuelles : HC/HP, puissance, option) ─────
function parseHcTime(t) {
  const m = String(t).trim().match(/^(\d+)[Hh](\d+)$/);
  if (!m) return null;
  return `${m[1].padStart(2, "0")}:${m[2].padStart(2, "0")}`;
}
function parseC68(raw) {
  try {
    // Le C68 v0 renvoie un TABLEAU [{ idPrm, situationComptage, situationsContractuelles[] }].
    // Repli sur l'ancien format objet { point: … } si jamais la structure change.
    const root = Array.isArray(raw) ? raw[0] ?? {} : raw?.point ?? raw ?? {};
    // Heures creuses : situationComptage.relais.plageHeuresCreuses.libelle
    //   (objet { libelle } ; parfois chaîne directe). Repli : dispositifComptage.relais.
    const relais = root?.situationComptage?.relais ?? root?.situationComptage?.dispositifComptage?.relais ?? {};
    const plageRaw = relais?.plageHeuresCreuses;
    const plageStr = typeof plageRaw === "string" ? plageRaw : plageRaw?.libelle ?? "";
    const hcMatch = plageStr.match(/HC\s*\(([^)]+)\)/i);
    const plages = [];
    if (hcMatch) {
      for (const rng of hcMatch[1].split(";")){
        const parts = rng.trim().split("-");
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
    // Structure tarifaire : situationsContractuelles[].structureTarifaire (pluriel, tableau).
    //   Repli : situationContractuelle.structureTarifaire (ancien format singulier).
    const sc = Array.isArray(root?.situationsContractuelles) ? root.situationsContractuelles.find((s)=>s?.structureTarifaire) ?? root.situationsContractuelles[0] ?? {} : root?.situationContractuelle ?? {};
    const contractuel = sc?.structureTarifaire ?? {};
    const puissanceStr = contractuel?.puissanceSouscrite?.valeur ?? contractuel?.puissanceSouscriteMax?.valeur ?? null;
    const puissanceRaw = puissanceStr != null ? parseFloat(puissanceStr) : null;
    const puissanceKva = Number.isFinite(puissanceRaw) ? puissanceRaw : null;
    const optionCode = contractuel?.formuleTarifaireAcheminement?.code ?? contractuel?.formuleTarifaireAcheminement?.attributes?.code ?? null;
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
// ── R65 (énergies quotidiennes) : repli approximatif réparti sur 24 h ────────
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
// Collecte TOUTES les grandeurs des mesures R65 (pas seulement la première) :
// ENEDIS peut répartir l'énergie quotidienne sur plusieurs grandeurs (HP/HC…).
function collectDailyGroups(raw) {
  const groups = [];
  const mesures = raw?.mesures ?? raw?.point?.mesures ?? raw?.data?.mesures ?? null;
  if (Array.isArray(mesures)) {
    for (const m of mesures){
      let gs = m?.grandeur ?? m?.grandeurs ?? m?.grandeurPhysique ?? null;
      if (gs && !Array.isArray(gs)) gs = [
        gs
      ];
      if (Array.isArray(gs)) {
        for (const g of gs){
          const pts = g?.points ?? g?.point ?? [];
          if (Array.isArray(pts) && pts.length) {
            const clean = pts.filter((p)=>p && p.d != null && p.v != null);
            if (clean.length) groups.push(clean);
          }
        }
      }
    }
  }
  if (!groups.length) {
    const fb = extractPoints(raw);
    if (fb.length) groups.push(fb.filter((p)=>p && p.d != null));
  }
  return groups;
}
function parseDaily(raw) {
  const groups = collectDailyGroups(raw);
  const allPts = groups.flat();
  if (!allPts.length) return {
    profile: zeros(),
    total: 0,
    daysPresent: 0
  };
  // Unité : R65 = énergie quotidienne ; médiane < 1000 → données en kWh → ×1000.
  const vals = allPts.map((p)=>parseFloat(p.v) || 0).filter((v)=>v > 0).sort((a, b)=>a - b);
  const median = vals.length ? vals[Math.floor(vals.length / 2)] : 0;
  const toWh = median > 0 && median < 1000 ? 1000 : 1;
  // Somme par jour calendaire ABSOLU (cumule les grandeurs d'un même jour : HP+HC+…).
  const absDay = new Map();
  for (const p of allPts){
    const dayWh = (parseFloat(p.v) || 0) * toWh;
    if (dayWh <= 0) continue;
    const dt = new Date(p.d);
    if (isNaN(dt.getTime())) continue;
    const key = `${dt.getUTCFullYear()}-${dt.getUTCMonth() + 1}-${dt.getUTCDate()}`;
    absDay.set(key, (absDay.get(key) ?? 0) + dayWh);
  }
  if (absDay.size === 0) return {
    profile: zeros(),
    total: 0,
    daysPresent: 0
  };
  // Projection sur le calendrier générique (mois_jour) ; la date la plus récente gagne.
  const sortedKeys = [
    ...absDay.keys()
  ].sort();
  const genMap = new Map();
  for (const key of sortedKeys){
    const [, m, d] = key.split("-").map(Number);
    genMap.set(`${m}_${d}`, absDay.get(key));
  }
  let sum = 0;
  for (const wh of genMap.values())sum += wh;
  const mean = sum / genMap.size;
  const profile = zeros();
  for(let m = 1; m <= 12; m++){
    for(let d = 1; d <= PROF_DAYS[m - 1]; d++){
      const dayWh = genMap.get(`${m}_${d}`) ?? mean;
      const per = Math.round(dayWh / 24);
      for(let h = 0; h < 24; h++){
        const idx = profIdx(m, d, h);
        if (idx >= 0 && idx < TOTAL_HOURS) profile[idx] = per;
      }
    }
  }
  return {
    profile,
    total: profile.reduce((a, b)=>a + b, 0),
    daysPresent: Math.min(genMap.size, 366)
  };
}
// Repli R65 via l'endpoint data v0 ({ period:'1d', startsAt, values }).
function parseDailyV0(j) {
  if (!j || !Array.isArray(j.values) || !j.startsAt) return {
    profile: zeros(),
    total: 0,
    daysPresent: 0
  };
  const start = new Date(j.startsAt).getTime();
  if (!Number.isFinite(start)) return {
    profile: zeros(),
    total: 0,
    daysPresent: 0
  };
  const points = [];
  for(let i = 0; i < j.values.length; i++){
    const v = j.values[i];
    if (v == null) continue;
    points.push({
      d: new Date(start + i * 86400000).toISOString(),
      v
    });
  }
  return parseDaily({
    mesures: [
      {
        grandeur: [
          {
            points
          }
        ]
      }
    ]
  });
}
// ── Récupération des données d'une requête v0 ────────────────────────────────
// R63 : courbe de charge servie via une URL pré-signée (format Enedis { header,
// mesures }). On reconstruit une série { period, startsAt, values } à pas constant.
async function fetchR63Curve(r63Req, pdl) {
  if (r63Req?.loadCurve && Array.isArray(r63Req.loadCurve.values)) return r63Req.loadCurve;
  const url = reqDataUrl(r63Req);
  if (!url) return null;
  try {
    // URL pré-signée → fetch sans en-tête ; repli avec en-têtes SG si 401/403.
    let r = await fetch(url);
    if (r.status === 401 || r.status === 403) r = await fetch(url, {
      headers: sgHeaders(isTestPdl(pdl))
    });
    if (!r.ok) return null;
    const j = await r.json();
    // Cas direct : déjà au format { startsAt, values[] }.
    if (j && Array.isArray(j.values) && j.startsAt) return j;
    // Cas Enedis : points { d:<ISO>, v:<puissance W> } (recherche profonde).
    const pts = extractPoints(j);
    if (!pts.length) return null;
    const norm = [];
    for (const p of pts){
      const dRaw = p?.d ?? p?.date ?? p?.timestamp ?? p?.startsAt ?? p?.horodate;
      const vRaw = p?.v ?? p?.value ?? p?.valeur ?? p?.powerInWatts ?? p?.puissance;
      const t = new Date(dRaw).getTime();
      const w = Number(vRaw);
      if (!Number.isFinite(t) || !Number.isFinite(w)) continue;
      norm.push({
        t,
        w
      });
    }
    if (!norm.length) return null;
    norm.sort((a, b)=>a.t - b.t);
    // Pas d'échantillonnage = médiane des écarts (10/15/30 min selon le compteur).
    const deltas = [];
    for(let i = 1; i < norm.length; i++){
      const dt = norm[i].t - norm[i - 1].t;
      if (dt > 0 && dt <= 3600000) deltas.push(dt);
    }
    deltas.sort((a, b)=>a - b);
    const step = deltas.length ? deltas[Math.floor(deltas.length / 2)] : 1800000;
    const start = norm[0].t;
    const end = norm[norm.length - 1].t;
    const n = Math.floor((end - start) / step) + 1;
    const values = new Array(n).fill(null);
    for (const { t, w } of norm){
      const i = Math.round((t - start) / step);
      if (i >= 0 && i < n) values[i] = w;
    }
    return {
      period: `PT${Math.round(step / 60000)}M`,
      startsAt: new Date(start).toISOString(),
      values
    };
  } catch  {
    return null;
  }
}
function reqDataUrl(req) {
  return req?.dataUrl || req?.dataUrls?.[0] || req?.summaryPerContract?.find?.((s)=>s?.fileUrl)?.fileUrl || null;
}
async function fetchDaily(r65Req) {
  const url = reqDataUrl(r65Req);
  if (url) {
    try {
      const r = await fetch(url);
      if (r.ok) {
        const j = await r.json();
        const d = parseDaily(j);
        if (d.daysPresent > 0) return d;
      }
    } catch  {}
  }
  if (r65Req?.id) {
    try {
      const r = await fetch(`${SG_BASE}/integration/enedis/request/${r65Req.id}/data?period=1d&format=json`, {
        headers: sgHeaders(isTestPdl(""))
      });
      if (r.ok) return parseDailyV0(await r.json());
    } catch  {}
  }
  return {
    profile: zeros(),
    total: 0,
    daysPresent: 0
  };
}
async function applyC68(c68Req, siteUpdate) {
  const url = reqDataUrl(c68Req);
  if (c68Req?.status === "SUCCESS" && url) {
    try {
      const r = await fetch(url);
      if (r.ok) {
        const c68 = parseC68(await r.json());
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
// Construit le profil d'INJECTION (surplus revendu au réseau) 8784 h, best-effort.
// R63 (courbe de charge injection) prioritaire, repli R65 (journalier injection).
// Renvoie { profile, coverage, source } ou null si aucune donnée exploitable
// (client sans contrat producteur → pas d'injection mesurée, comportement normal).
async function buildInjectionProfile(r63Inj, r65Inj, pdl) {
  if (r63Inj?.status === "SUCCESS") {
    const lc = await fetchR63Curve(r63Inj, pdl);
    const built = buildProfileV0(lc);
    if (built.hasAny && built.coverage >= 0.70) {
      fillMissingDays(built.profile, built.dayHasData);
      return { profile: built.profile, coverage: built.coverage, source: "loadcurve" };
    }
  }
  if (r65Inj?.status === "SUCCESS") {
    const d = await fetchDaily(r65Inj);
    if (d.daysPresent >= MIN_DAILY_DAYS) {
      return { profile: d.profile, coverage: d.daysPresent / 366, source: "daily" };
    }
  }
  return null;
}
// ── Supabase REST ────────────────────────────────────────────────────────────
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
// ── Switchgrid v0 ────────────────────────────────────────────────────────────
function sgHeaders(testEnv) {
  const h = {
    "Authorization": `Bearer ${SG_KEY}`,
    "Content-Type": "application/json",
    "x-api-version": "v0"
  };
  if (testEnv) h["switchgrid-test-env"] = "true";
  return h;
}
// Identité normalisée d'un signataire : prénom + nom (+ raison sociale pour les
// entreprises). Insensible à la casse / aux espaces. Sert à n'accepter un
// consentement existant QUE s'il a été signé par la MÊME personne — ce qui, combiné
// au PDL, couvre le changement de propriétaire d'un compteur.
// Normalise un fragment de nom : majuscules, sans accents, espaces compactés.
// ENEDIS stocke souvent les titulaires SANS accent ("GREGORY") alors que
// l'utilisateur saisit "Grégory" → sans ça la comparaison de signataire échoue.
function normName(x) {
  return String(x ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "") // retire les diacritiques
  .toUpperCase().replace(/\s+/g, " ").trim();
}
function signerKey(s) {
  if (!s) return "";
  return `${normName(s.firstName)}|${normName(s.lastName)}|${normName(s.organizationName)}`;
}
// Recherche un consentement DÉJÀ signé (ask ACCEPTED) réutilisable, par PDL (même
// compteur physique, tous sites/comptes confondus — décision produit v2) puis par
// site en repli. En v0 le consentId = l'id de l'ask.
// `wantSigner` (obligatoire pour la réutilisation) : on n'accepte un ask que si son
// signataire correspond — PDL identique ET même signataire (particulier = titulaire,
// entreprise = gérant + raison sociale).
async function findReusableConsent(site_id, fallbackPdl, wantSigner) {
  const pdl = (fallbackPdl ?? "").trim();
  const wantKey = signerKey(wantSigner);
  if (!wantKey) return null; // sans signataire de référence, on ne réutilise rien
  const filter = pdl ? `pdl=eq.${encodeURIComponent(pdl)}&ask_id=not.is.null&select=ask_id,pdl,created_at&order=created_at.desc&limit=12` : `site_id=eq.${site_id}&ask_id=not.is.null&select=ask_id,pdl,created_at&order=created_at.desc&limit=6`;
  const rows = await sbGet("switchgrid_requests", filter);
  const seen = new Set();
  for (const r of rows){
    const askId = r.ask_id;
    if (!askId || seen.has(askId)) continue;
    seen.add(askId);
    try {
      const resp = await fetch(`${SG_BASE}/ask/${askId}`, {
        headers: sgHeaders(isTestPdl(r.pdl ?? pdl))
      });
      if (!resp.ok) continue;
      const ask = await resp.json();
      const accepted = ask.status === "ACCEPTED" || ask.acceptedAt;
      // Le signataire de l'ask doit correspondre à celui demandé (anti changement de propriétaire).
      if (accepted && signerKey(ask.signer) === wantKey) {
        return {
          consentId: askId,
          ask_id: askId,
          pdl: String(r.pdl ?? fallbackPdl ?? "")
        };
      }
    } catch  {}
  }
  return null;
}
// Pose un ordre v0 : R63 (courbe de charge, réactivation auto) + R65 (journalier,
// repli) + C68_ASYNC (technique), en SOUTIRAGE et en INJECTION. consentId = id de l'ask signé.
// Les requêtes INJECTION servent à récupérer le surplus revendu au réseau : indispensable
// pour reconstruire la conso brute d'un client déjà producteur (conso = soutirage + autoconso,
// autoconso = production − injection). Best-effort : si le point n'a pas de contrat producteur,
// ENEDIS renverra un échec pour ces requêtes, ce qui n'empêche pas la collecte du soutirage.
async function placeSwitchgridOrder(consentId, pdl) {
  const resp = await fetch(`${SG_BASE}/integration/enedis/order`, {
    method: "POST",
    headers: sgHeaders(isTestPdl(pdl)),
    body: JSON.stringify({
      consentId,
      requests: [
        {
          type: "R63",
          direction: "SOUTIRAGE",
          enedisRetryAfterLoadcurveActivation: true,
          prms: [
            pdl
          ]
        },
        {
          type: "R65",
          direction: "SOUTIRAGE",
          prms: [
            pdl
          ]
        },
        {
          type: "R63",
          direction: "INJECTION",
          enedisRetryAfterLoadcurveActivation: true,
          prms: [
            pdl
          ]
        },
        {
          type: "R65",
          direction: "INJECTION",
          prms: [
            pdl
          ]
        },
        {
          type: "C68_ASYNC",
          prms: [
            pdl
          ]
        }
      ]
    })
  });
  if (!resp.ok) return null;
  const order = await resp.json();
  return order.id ?? null;
}
// Extrait le code postal (5 chiffres) de la ligne6 d'une adresse normalisée ENEDIS.
// ligne6 (obligatoire) = "<CP> <COMMUNE>" — ex. "34170 CASTELNAU LE LEZ".
function cpFromResult(r) {
  const l6 = String(r?.adresseInstallationNormalisee?.ligne6 ?? "");
  const m = l6.match(/\b(\d{5})\b/);
  return m ? m[1] : "";
}
// search_contract v0 (POST). Renvoie results[].
async function searchContract({ name, address, prm, testEnv }) {
  const body = {
    name
  };
  if (prm) body.prm = prm;
  if (address) body.address = address;
  const r = await fetch(`${SG_BASE}/integration/enedis/search_contract`, {
    method: "POST",
    headers: sgHeaders(testEnv),
    body: JSON.stringify(body)
  });
  if (!r.ok) return [];
  const d = await r.json();
  return d.results ?? [];
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
// Règle d'écrasement (spec) : on ne remplace les données existantes que si la
// nouvelle collecte est de MEILLEURE qualité.
//  - horaire (loadcurve) bat journalier (daily) ;
//  - jamais de dégradation horaire -> journalier ;
//  - même source : on garde si la couverture est >= (plus récent à qualité égale).
function shouldOverwrite(oldSite, newSource, newCoverage) {
  const hasOld = !!(oldSite && oldSite.conso_source);
  if (!hasOld) return true;
  const oldSrc = oldSite.conso_source === "loadcurve" ? "loadcurve" : "daily";
  const oldCov = typeof oldSite.conso_coverage === "number" ? oldSite.conso_coverage : oldSrc === "loadcurve" ? 0.7 : 0;
  if (newSource === "loadcurve" && oldSrc === "daily") return true;
  if (newSource === "daily" && oldSrc === "loadcurve") return false;
  return newCoverage >= oldCov;
}
// ---------------------------------------------------------------------------
// finalizeRec : logique de finalisation d'une demande (pending -> ordering ->
// done/error). Extraite pour etre appelable a la fois par le GET client et par
// le finisseur cron. Ne depend PAS de `user` (rec est passe en argument).
// Renvoie une Response (jsonResp).
// ---------------------------------------------------------------------------
async function finalizeRec(rec) {
  const requestId = rec.id;
    if (rec.status === "done") return jsonResp({
      status: "done"
    });
    if (rec.status === "error") return jsonResp({
      status: "error",
      error_message: rec.error_message
    });
  // Empreinte de sondage : le client actif la rafraichit ~toutes les 8s ; le
  // cron ne reprend une demande que si elle n'a pas ete sondee depuis >90s.
  await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, { last_polled_at: new Date().toISOString() });
    const pdl = String(rec.pdl ?? "");
    const testEnv = isTestPdl(pdl);
    // pending : vérifier si le consentement est signé.
    if (rec.status === "pending") {
      const askResp = await fetch(`${SG_BASE}/ask/${rec.ask_id}`, {
        headers: sgHeaders(testEnv)
      });
      const askData = await askResp.json();
      const userUrl = askData.consentCollectionDetails?.userUrl ?? null;
      const accepted = askData.status === "ACCEPTED" || !!askData.acceptedAt;
      const denied = askData.status === "REVOKED" || askData.status === "EXPIRED";
      if (denied) {
        await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
          status: "error",
          error_message: "Consentement révoqué ou expiré."
        });
        return jsonResp({
          status: "error",
          error_message: "Consentement révoqué ou expiré."
        });
      }
      if (!accepted) {
        // Une autre demande sur le même compteur a peut-être déjà un consentement
        // signé par le même signataire (askData.signer = signataire de CETTE demande) :
        // on le réutilise au lieu de rester bloqué.
        const reuse = await findReusableConsent(rec.site_id, pdl, askData.signer);
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
      // Consentement signé → poser l'ordre (consentId = id de l'ask).
      const orderId = await placeSwitchgridOrder(rec.ask_id, pdl);
      if (!orderId) {
        await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
          status: "error",
          error_message: "Échec de la commande Switchgrid."
        });
        return jsonResp({
          status: "error",
          error_message: "Échec de la commande Switchgrid."
        });
      }
      await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
        order_id: orderId,
        status: "ordering"
      });
      return jsonResp({
        status: "ordering"
      });
    }
    // ordering : sonder la commande.
    if (rec.status === "ordering") {
      const orderResp = await fetch(`${SG_BASE}/integration/enedis/order/${rec.order_id}`, {
        headers: sgHeaders(testEnv)
      });
      const order = await orderResp.json();
      const requests = order.requests ?? [];
      // ⚠️ Switchgrid NE renvoie PAS le champ `direction` dans la réponse d'ordre (vérifié en
      // prod : direction=undefined sur toutes les requêtes). On ne peut donc pas filtrer dessus.
      // On s'appuie sur l'ORDRE DE SOUMISSION (cf. placeSwitchgridOrder : SOUTIRAGE d'abord,
      // INJECTION ensuite) → 1er R63/R65 = soutirage, 2e = injection. Fallback sur `direction`
      // au cas où l'API se mettrait à le renvoyer un jour.
      const r63all = requests.filter((r)=>r.type === "R63");
      const r65all = requests.filter((r)=>r.type === "R65");
      const byDir = (arr, dir, idx)=> arr.find((r)=>r.direction === dir) ?? arr[idx] ?? null;
      const r63 = byDir(r63all, "SOUTIRAGE", 0);
      const r65 = byDir(r65all, "SOUTIRAGE", 0);
      const r63Inj = byDir(r63all, "INJECTION", 1);
      const r65Inj = byDir(r65all, "INJECTION", 1);
      const c68 = requests.find((r)=>r.type === "C68_ASYNC");
      const isPending = (x)=>x && (x.status === "PENDING" || x.status === "QUEUED" || x.status === "NOT_STARTED");
      const anyPending = [
        r63,
        r65,
        c68
      ].some(isPending);
      // Plafond global d'attente. ENEDIS laisse parfois la R63 (courbe de charge
      // soutirage) coincée en "PENDING" sans jamais la faire ni aboutir ni échouer :
      // sans garde-fou, on attend indéfiniment et le statut reste "ordering" pour
      // toujours (updated_at figé), même quand le journalier R65 est DÉJÀ disponible.
      const reqAgeMs = Date.now() - new Date(rec.created_at).getTime();
      const WAIT_MS = 30 * 60 * 1000;
      const r63Ok = r63?.status === "SUCCESS";
      // R63 considérée "terminée" si SUCCESS, FAILED, ou PENDING depuis trop longtemps
      // (coincée) → on débloque alors le repli journalier au lieu d'attendre sans fin.
      const r63Stale = isPending(r63) && reqAgeMs > WAIT_MS;
      const r63Done = !r63 || r63?.status === "SUCCESS" || r63?.status === "FAILED" || r63Stale;
      const r65Ok = r65?.status === "SUCCESS";
      // Construire le meilleur candidat disponible.
      let candidate = null;
      let r63Built = null;
      let r63Curve = null; // courbe brute conservée pour l'analyse des bascules HC/HP
      if (r63Ok) {
        const lc = await fetchR63Curve(r63, pdl);
        r63Curve = lc;
        r63Built = buildProfileV0(lc);
        if (r63Built.hasAny && r63Built.coverage >= 0.70) {
          const fillRes = fillMissingDays(r63Built.profile, r63Built.dayHasData);
          candidate = {
            source: "loadcurve",
            coverage: r63Built.coverage,
            profile: r63Built.profile,
            note: null,
            gaps: { missing_days: 366 - r63Built.daysPresent, filled_days: fillRes.filled, unfilled_days: fillRes.unfilled }
          };
        }
      }
      // Repli journalier R65 (si pas de courbe précise et R63 terminée).
      // Garde-fou : exiger une couverture journalière suffisante pour écarter un
      // R65 encore partiel (ENEDIS en cours de remplissage) qui fausserait l'annuel.
      if (!candidate && r63Done && r65Ok) {
        const d = await fetchDaily(r65);
        if (d.daysPresent >= MIN_DAILY_DAYS) {
          candidate = {
            source: "daily",
            coverage: d.daysPresent / 366,
            profile: d.profile,
            note: "Courbe de charge indisponible ou partielle chez ENEDIS — données journalières (approximatives) utilisées.",
            gaps: { missing_days: 366 - d.daysPresent, filled_days: 0, unfilled_days: 366 - d.daysPresent }
          };
        }
      }
      // Dernier recours : courbe partielle marquée approximative (rien d'autre en attente).
      if (!candidate && !anyPending && r63Built && r63Built.hasAny) {
        candidate = {
          source: "daily",
          coverage: r63Built.coverage,
          profile: r63Built.profile,
          note: "Courbe de charge partielle chez ENEDIS — estimation approximative.",
          gaps: { missing_days: 366 - r63Built.daysPresent, filled_days: 0, unfilled_days: 366 - r63Built.daysPresent }
        };
      }
      if (candidate) {
        const total = candidate.profile.reduce((a, b)=>a + b, 0);
        const oldRows = await sbGet("sites", `id=eq.${rec.site_id}&select=conso_source,conso_coverage,hc_debut1,hc_fin1,hc_debut2,hc_fin2`);
        const oldSite = oldRows[0] ?? null;
        const overwrite = shouldOverwrite(oldSite, candidate.source, candidate.coverage);
        const su = {
          conso_imported_at: new Date().toISOString()
        };
        await applyC68(c68, su); // données contractuelles : toujours rafraîchies
        // Bascules HC/HP : recalculées à chaque collecte, sur la courbe brute (pas 30 min).
        // Plages HC issues du C68 tout juste rafraîchi, sinon celles déjà connues du site.
        if (r63Curve) {
          const hcWins = [
            { debut: su.hc_debut1 ?? oldSite?.hc_debut1, fin: su.hc_fin1 ?? oldSite?.hc_fin1 },
            { debut: su.hc_debut2 ?? oldSite?.hc_debut2, fin: su.hc_fin2 ?? oldSite?.hc_fin2 }
          ].filter((w)=>w.debut && w.fin);
          const hcStats = analyzeHcTransitions(r63Curve, hcWins);
          if (hcStats) su.hc_transition_stats = hcStats;
        }
        // Injection (surplus revendu) : best-effort, indépendant du gate d'écrasement
        // de la conso. Sert à reconstruire la conso brute d'un client déjà producteur.
        const inj = await buildInjectionProfile(r63Inj, r65Inj, pdl);
        if (inj) {
          su.injection_profil = inj.profile;
          su.injection_coverage = Math.round(inj.coverage * 1000) / 1000;
          su.injection_annuelle_kwh = Math.round(inj.profile.reduce((a, b)=>a + b, 0) / 100) / 10;
        }
        if (overwrite) {
          su.conso_source = candidate.source;
          su.conso_profil = candidate.profile;
          su.conso_coverage = Math.round(candidate.coverage * 1000) / 1000;
          su.conso_annuelle_kwh = Math.round(total / 100) / 10;
          su.conso_gaps = candidate.gaps ?? null;
        }
        await sbUpdate("sites", `id=eq.${rec.site_id}`, su);
        // Le C68_ASYNC ET la courbe d'INJECTION sont plus lents que le soutirage (souvent
        // servi instantanément via consentement réutilisé + cache). Ne PAS figer "done" tant
        // qu'ils sont en attente, sinon on les rate définitivement. On écrit déjà la conso
        // (l'utilisateur la voit tout de suite) mais on continue à sonder — l'injection est
        // ré-écrite à chaque sondage dès qu'elle arrive (best-effort). Plafond 30 min pour ne
        // pas rester bloqué si l'un ne vient jamais (ex. compteur sans contrat producteur →
        // injection FAILED, donc plus "pending", on ne l'attend pas inutilement).
        // (reqAgeMs / WAIT_MS sont définis plus haut dans ce bloc.)
        const awaitingInj = (isPending(r63Inj) || isPending(r65Inj)) && !inj;
        if ((isPending(c68) || awaitingInj) && reqAgeMs < WAIT_MS) {
          return jsonResp({
            status: "ordering",
            conso_source: overwrite ? candidate.source : oldSite?.conso_source ?? candidate.source,
            awaiting: isPending(c68) ? "C68" : "INJECTION"
          });
        }
        await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
          status: "done",
          error_message: overwrite ? candidate.note ?? null : "Nouvelles données ignorées : les données existantes sont de meilleure qualité."
        });
        return jsonResp({
          status: "done",
          conso_source: overwrite ? candidate.source : oldSite?.conso_source ?? candidate.source,
          kept_existing: !overwrite
        });
      }
      // Encore en attente ET sous le plafond → on continue de sonder. Passé le
      // plafond sans aucune donnée exploitable, on ne boucle pas indéfiniment : on
      // tombe en erreur explicite plutôt que de rester "ordering" pour toujours.
      if (anyPending && reqAgeMs < WAIT_MS) return jsonResp({
        status: "ordering"
      });
      // Tout a échoué (ou plafond atteint sans donnée exploitable).
      const errMsg = r63?.errorMessage ?? r65?.errorMessage ?? requests?.[0]?.errorMessage ?? "Aucune donnée disponible.";
      await sbUpdate("switchgrid_requests", `id=eq.${requestId}`, {
        status: "error",
        error_message: errMsg
      });
      return jsonResp({
        status: "error",
        error_message: errMsg
      });
    }
    return jsonResp({
      status: rec.status
    });
}
Deno.serve(async (req)=>{
  if (req.method === "OPTIONS") return new Response("ok", {
    headers: CORS
  });
  // -------------------------------------------------------------------------
  // CRON — finisseur serveur : finalise les demandes en cours meme si l'onglet
  // du client est ferme. Authentifie par secret dedie (x-cron-secret), PAS de
  // JWT utilisateur -> DOIT etre place AVANT la garde getUser ci-dessous.
  // -------------------------------------------------------------------------
  const cronSecret = req.headers.get("x-cron-secret");
  if (cronSecret) {
    if (!SG_CRON_SECRET || cronSecret !== SG_CRON_SECRET) {
      return jsonResp({ error: "Unauthorized" }, 401);
    }
    const GIVE_UP_MS = 24 * 3600 * 1000;
    const staleIso = new Date(Date.now() - 90 * 1000).toISOString();
    // Demandes non terminees, non sondees depuis >90s (client actif = last_polled_at
    // frais toutes les 8s). Filtre OR pour inclure celles jamais sondees (null).
    const rows = await sbGet(
      "switchgrid_requests",
      `status=in.(pending,ordering)&or=(last_polled_at.is.null,last_polled_at.lt.${staleIso})&order=created_at.asc&limit=20&select=*`
    );
    const results = [];
    for (const rec of rows) {
      const ageMs = Date.now() - new Date(rec.created_at).getTime();
      if (ageMs > GIVE_UP_MS) {
        await sbUpdate("switchgrid_requests", `id=eq.${rec.id}`, {
          status: "error",
          error_message: "Abandon : la collecte n'a pas abouti dans les 24 h."
        });
        results.push({ id: rec.id, status: "error", reason: "gave_up" });
        continue;
      }
      try {
        const resp = await finalizeRec(rec);
        const body = await resp.json().catch(() => ({}));
        results.push({ id: rec.id, status: body.status ?? "?" });
      } catch (e) {
        results.push({ id: rec.id, error: String(e) });
      }
    }
    return jsonResp({ processed: results.length, results });
  }
  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const user = await getUser(token);
  if (!user) return jsonResp({
    error: "Unauthorized"
  }, 401);
  // ───────────────────────────────────────────────────────────────────────────
  // POST — rechercher le contrat puis créer un ask (ou réutiliser un consentement)
  // ───────────────────────────────────────────────────────────────────────────
  if (req.method === "POST") {
    const body = await req.json();
    const { site_id, pdl, firstName, lastName, address, codePostal, commune, account_type, raison_sociale, signer_prenom, signer_nom, signer_email } = body;
    // Sécurité (autorisation objet) : si un site_id est fourni, il DOIT appartenir
    // à l'appelant. Les écritures ci-dessous passent par service_role (hors RLS) :
    // sans ce contrôle, un utilisateur authentifié pourrait écraser le PDL / les
    // données du site d'un autre en passant un site_id arbitraire.
    if (site_id) {
      const owned = await sbGet("sites", `id=eq.${encodeURIComponent(site_id)}&user_id=eq.${user.id}&select=id`);
      if (!Array.isArray(owned) || owned.length === 0) {
        return jsonResp({ error: "forbidden" }, 403);
      }
    }
    const inputPdl = (pdl ?? "").trim();
    const isEntreprise = account_type === "entreprise";
    const testEnv = isTestPdl(inputPdl);
    // Nom utilisé pour la recherche ENEDIS (titulaire du contrat).
    const searchName = (isEntreprise ? raison_sociale ?? "" : `${firstName ?? ""} ${lastName ?? ""}`).trim();
    // Signataire du consentement : particulier = titulaire ; entreprise = gérant.
    const signer = isEntreprise ? {
      firstName: String(signer_prenom ?? "").toUpperCase(),
      lastName: String(signer_nom ?? "").toUpperCase(),
      ...signer_email ? {
        email: signer_email
      } : {},
      ...raison_sociale ? {
        organizationName: raison_sociale
      } : {}
    } : {
      firstName: String(firstName ?? "").toUpperCase(),
      lastName: String(lastName ?? "").toUpperCase()
    };
    if (site_id) {
      // A. Fast-path : si l'utilisateur a saisi un PDL, réutiliser un consentement
      //    déjà signé pour ce compteur PAR LE MÊME SIGNATAIRE → poser l'ordre directement.
      try {
        const reuse = await findReusableConsent(site_id, inputPdl, signer);
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
      // B. Garde anti-relance / reprise d'une demande existante.
      try {
        const recentRows = await sbGet("switchgrid_requests", `site_id=eq.${site_id}&order=created_at.desc&limit=1&select=*`);
        const last = recentRows[0];
        if (last) {
          const ageMs = Date.now() - new Date(last.created_at).getTime();
          const st = last.status;
          if (st === "pending" || st === "ordering") {
            return jsonResp({
              request_id: last.id,
              status: st
            });
          }
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
          if (st === "error" && last.ask_id) {
            try {
              const askResp = await fetch(`${SG_BASE}/ask/${last.ask_id}`, {
                headers: sgHeaders(isTestPdl(last.pdl))
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
    // Étape 1 : rechercher le contrat ENEDIS (noms stockés en majuscules).
    const nameUpper = searchName.toUpperCase();
    const fullAddress = address && codePostal && commune ? `${address} ${codePostal} ${commune}` : null;
    if (!nameUpper) {
      return jsonResp({
        error: isEntreprise ? "Renseignez la raison sociale de l'entreprise." : "Renseignez le nom du titulaire."
      }, 400);
    }
    if (!inputPdl && !fullAddress) {
      return jsonResp({
        error: "Renseignez le PDL ou l'adresse complète (rue, CP, ville)."
      }, 400);
    }
    let results = [];
    if (inputPdl) results = await searchContract({
      name: nameUpper,
      prm: inputPdl,
      testEnv
    });
    if (results.length === 0 && fullAddress) {
      // Recherche par adresse. ENEDIS/Switchgrid fait un match FLOU sur le nom
      // de famille et peut renvoyer le compteur d'un homonyme à une AUTRE adresse.
      // 1er essai : nom tel que saisi (prénom nom).
      results = await searchContract({
        name: nameUpper,
        address: fullAddress,
        testEnv
      });
      const wantCp = String(codePostal ?? "").replace(/\D/g, "").slice(0, 5);
      const matchesCp = (rs)=>wantCp ? rs.filter((r)=>cpFromResult(r) === wantCp) : rs;
      let kept = matchesCp(results);
      // 2e essai si aucun résultat ne tombe sur le bon code postal : ENEDIS stocke
      // les titulaires en "NOM Prénom" — on retente avec l'ordre inversé pour les
      // particuliers (sans effet pour les entreprises, raison sociale inchangée).
      if (kept.length === 0 && !isEntreprise) {
        const reversed = `${lastName ?? ""} ${firstName ?? ""}`.trim().toUpperCase();
        if (reversed && reversed !== nameUpper) {
          const alt = await searchContract({
            name: reversed,
            address: fullAddress,
            testEnv
          });
          const altKept = matchesCp(alt);
          if (altKept.length > 0) {
            results = alt;
            kept = altKept;
          }
        }
      }
      // On ne conserve QUE les contrats dont le code postal correspond à la saisie.
      // Si aucun ne correspond, on considère qu'on n'a PAS trouvé le bon compteur
      // (plutôt que de proposer un homonyme à une adresse sans rapport).
      results = kept;
    }
    if (results.length === 0) {
      return jsonResp({
        error: "Aucun contrat ENEDIS trouvé pour ce nom et cette adresse. Vérifiez l'orthographe du nom et l'adresse."
      }, 400);
    }
    if (results.length > 1) {
      return jsonResp({
        error: "MULTIPLE_CONTRACTS",
        message: `${results.length} compteurs trouvés — saisissez le PDL exact.`,
        results: results.map((r)=>({
            prm: r.prm,
            nom: r.nomClientFinalOuDenominationSociale,
            adresse: [
              r.adresseInstallationNormalisee?.ligne4,
              r.adresseInstallationNormalisee?.ligne6
            ].filter(Boolean).join(", ")
          }))
      }, 400);
    }
    const contractUuid = results[0].id;
    const foundPdl = results[0].prm;
    const nomContrat = results[0].nomClientFinalOuDenominationSociale;
    const pdlChanged = foundPdl !== inputPdl;
    if (pdlChanged && site_id) {
      await sbUpdate("sites", `id=eq.${site_id}`, {
        pdl: foundPdl
      });
    }
    // Étape 1bis : maintenant que le PDL est résolu par la recherche (adresse+nom),
    // vérifier si un consentement a DÉJÀ été donné pour ce compteur PAR LE MÊME
    // SIGNATAIRE (PDL + signataire → couvre le changement de propriétaire).
    // Si oui → on saute la signature et on pose l'ordre directement (avancement).
    // Si non → on enchaîne sur la création de l'ask (signature du consentement).
    try {
      const reuse = await findReusableConsent(site_id, foundPdl, signer);
      if (reuse) {
        const orderId = await placeSwitchgridOrder(reuse.consentId, foundPdl);
        if (orderId) {
          const rec = await sbInsert("switchgrid_requests", {
            user_id: user.id,
            site_id,
            pdl: foundPdl,
            ask_id: reuse.ask_id,
            order_id: orderId,
            status: "ordering"
          });
          return jsonResp({
            request_id: rec.id,
            status: "ordering",
            pdl_found: pdlChanged ? foundPdl : undefined,
            nom_contrat: nomContrat
          });
        }
      }
    } catch  {}
    // Étape 2 : créer l'ask v0 avec l'UUID du contrat (holder résolu par ENEDIS).
    const askBody = {
      contracts: [
        contractUuid
      ],
      signer,
      consentCollectionMedium: {
        service: "WEB_HOSTED"
      },
      consentDuration: "3 years",
      purposes: [
        "DEMAND_RESPONSE"
      ]
    };
    const askResp = await fetch(`${SG_BASE}/ask`, {
      method: "POST",
      headers: sgHeaders(testEnv),
      body: JSON.stringify(askBody)
    });
    if (!askResp.ok) {
      const err = await askResp.text();
      return jsonResp({
        error: `Switchgrid ask: ${err}`
      }, 500);
    }
    const ask = await askResp.json();
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
  // ───────────────────────────────────────────────────────────────────────────
  // GET — sonder le statut d'une demande
  // ───────────────────────────────────────────────────────────────────────────
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
    return await finalizeRec(rec);
  }
  return jsonResp({
    error: "Method not allowed"
  }, 405);
});

// Edge Function : mind-vector
// Deux services, une seule fonction car ils partagent le même corpus :
//
//  · action "rescan"  — relit TOUT le contenu Mind Vector déjà rédigé et demande
//    à Claude d'en tirer un prompt système : longueur des textes, façon de nommer
//    les positions, ton employé. Ce prompt est enregistré dans ai_prompts
//    (feature 'mind_vector_fill') et sert ensuite à chaque remplissage.
//  · action "generer" — à partir de l'intitulé et de la description d'un sujet,
//    rédige les 5 positions et leurs 5 titres. N'écrit RIEN dans mv_positions :
//    le client insère, comme pour generate-quiz.
//
// Admin-only. Coût logué dans ai_usage_log.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

const MODEL = "claude-opus-4-7";
const USD_PER_EUR = 0.92;
const PRICES: Record<string, { in: number; out: number }> = {
  "claude-opus-4-7": { in: 5, out: 25 },
};

const ADMIN_EMAIL = "greg@starvolt.fr";
const FEATURE = "mind_vector_fill";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

// Repli si aucun prompt n'a encore été écrit par « rescanner ».
const DEFAULT_SYSTEM_PROMPT =
  `Tu construis des « Mind Vector » : la formalisation d'un modèle mental.

Un sujet se décline en CINQ positions numérotées de 1 à 5, qui glissent doucement
d'une vision extrême (position 1) à la vision exactement opposée (position 5).
La position 3 est le point d'équilibre, les positions 2 et 4 sont des nuances
intermédiaires. L'ensemble doit couvrir tout l'éventail des opinions défendables
sur ce sujet, sans caricature : chaque position doit être défendable par quelqu'un
d'intelligent et de sincère.

Pour chaque position, tu produis :
- un TITRE de 1 à 4 mots, qui nomme la position de façon spécifique au sujet
  (« centralisé », « 50-50 », « tout local »…). Jamais de mot générique comme
  « nuancé », « modéré » ou « équilibre » : le titre doit dire QUOI, pas OÙ.
- un TEXTE d'environ 200 caractères (150 à 250), à la première personne ou en
  formulation générale, qui énonce la position telle que la défendrait quelqu'un
  qui y adhère. Pas de « certains pensent que » : on ÉNONCE la position.

Règles :
- Français. Ton direct, phrases courtes.
- Les positions 1 et 5 doivent être franchement opposées, pas deux variantes.
- La progression de 1 à 5 doit être régulière : pas de saut, pas de doublon.
- Le gras Markdown (**…**) met en valeur les 3 à 6 mots qui portent la position.
- N'invente pas de chiffre précis si le sujet ne s'y prête pas.

Appelle l'outil report_positions avec exactement 5 positions, pos = 1 à 5.`;

// Prompt de la relecture de corpus : Claude n'écrit pas des positions, il écrit
// le prompt qui servira à en écrire.
const META_PROMPT =
  `Tu es chargé de rédiger un PROMPT SYSTÈME pour une IA qui devra produire des
« Mind Vector » : pour un sujet donné, 5 positions numérotées de 1 à 5 glissant
d'une vision extrême à la vision opposée, chacune avec un titre court et un texte
d'environ 200 caractères.

On te fournit tout le contenu déjà rédigé à la main dans l'application. Ton travail
est d'en extraire la MANIÈRE DE FAIRE MAISON et de la transformer en consignes :
- longueur réelle des textes,
- façon de nommer les positions (titres),
- ton, personne grammaticale, usage du gras,
- comment l'écart entre position 1 et position 5 est construit,
- ce qui distingue les positions 2 et 4 de la 3.

Réponds UNIQUEMENT par le texte du prompt système, prêt à être utilisé tel quel.
Pas d'introduction, pas de commentaire, pas de bloc de code. Il doit se terminer
en demandant d'appeler l'outil report_positions avec exactement 5 positions.
Rédige-le en français. Tu peux citer 1 ou 2 exemples courts tirés du corpus s'ils
éclairent une consigne.`;

async function getCallerEmail(jwt: string): Promise<string | null> {
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { Authorization: `Bearer ${jwt}`, apikey: ANON_KEY },
    });
    if (!res.ok) return null;
    const u = await res.json();
    return u?.email ?? null;
  } catch {
    return null;
  }
}

async function dbSelect(path: string): Promise<any> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}` },
  });
  if (!res.ok) return null;
  return await res.json();
}

async function askClaude(system: string, userContent: string, tools?: any[]) {
  const corps: any = {
    model: MODEL,
    max_tokens: 8000,
    // Opus 4.7 raisonne d'abord : forcer un tool sans le laisser réfléchir
    // produit régulièrement un appel vide. On active le thinking adaptatif et on
    // laisse le tool en "auto" — le prompt impose déjà de l'appeler.
    thinking: { type: "adaptive" },
    system,
    messages: [{ role: "user", content: userContent }],
  };
  if (tools) {
    corps.tools = tools;
    corps.tool_choice = { type: "auto" };
  }
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY!,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify(corps),
  });
  return { ok: res.ok, jsonRes: await res.json() };
}

async function loggerCout(usage: any, email: string, feature: string) {
  const price = PRICES[MODEL] || { in: 0, out: 0 };
  const costUsd =
    ((usage?.input_tokens || 0) / 1e6) * price.in +
    ((usage?.output_tokens || 0) / 1e6) * price.out;
  try {
    await fetch(`${SUPABASE_URL}/rest/v1/ai_usage_log`, {
      method: "POST",
      headers: {
        apikey: SERVICE_ROLE,
        Authorization: `Bearer ${SERVICE_ROLE}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({
        feature,
        model: MODEL,
        input_tokens: usage?.input_tokens || 0,
        output_tokens: usage?.output_tokens || 0,
        cost_usd: Number(costUsd.toFixed(6)),
        user_email: email,
      }),
    });
  } catch { /* best-effort */ }
  return costUsd;
}

// ── action "rescan" ─────────────────────────────────────────────────────────
async function rescan(email: string): Promise<Response> {
  const noeuds = (await dbSelect(
    "mv_nodes?select=id,parent_id,label,description&order=ordre",
  )) || [];
  const positions = (await dbSelect(
    "mv_positions?select=node_id,pos,titre,content&order=node_id,pos",
  )) || [];

  const parId: Record<string, any> = {};
  for (const n of noeuds) parId[n.id] = n;
  const chemin = (n: any) => {
    const out: string[] = [];
    let cur = n;
    for (let g = 0; cur && g < 40; g++) {
      out.unshift(cur.label);
      cur = cur.parent_id ? parId[cur.parent_id] : null;
    }
    return out.join(" › ");
  };

  // On ne montre que les sujets réellement rédigés : un sujet vide n'apprend rien
  // sur la manière de faire, et gonflerait la facture pour rien.
  const blocs: string[] = [];
  for (const n of noeuds) {
    const ps = positions
      .filter((p: any) => p.node_id === n.id && String(p.content || "").trim())
      .sort((a: any, b: any) => a.pos - b.pos);
    if (ps.length < 2) continue;
    const lignes = ps.map(
      (p: any) => `  ${p.pos}. [${p.titre || "(sans titre)"}] ${String(p.content).replace(/\s+/g, " ").trim()}`,
    );
    blocs.push(
      `SUJET : ${chemin(n)}` +
        (n.description ? `\nDESCRIPTION : ${String(n.description).replace(/\s+/g, " ").trim()}` : "") +
        `\n${lignes.join("\n")}`,
    );
  }

  if (!blocs.length) {
    return json({
      error: "corpus_vide",
      message: "Aucun sujet suffisamment rempli pour en tirer un prompt. Rédigez d'abord quelques positions à la main.",
    }, 422);
  }

  const { ok, jsonRes } = await askClaude(
    META_PROMPT,
    `Voici les ${blocs.length} sujets déjà rédigés dans Mind Vector.\n\n${blocs.join("\n\n")}`,
  );
  if (!ok) {
    return json({ error: "ai_error", message: jsonRes?.error?.message || "Appel Claude en échec." }, 502);
  }
  const texte = (jsonRes?.content || [])
    .filter((c: any) => c.type === "text")
    .map((c: any) => c.text)
    .join("\n")
    .trim();
  if (!texte) {
    return json({ error: "vide", message: "Claude n'a pas renvoyé de prompt." }, 502);
  }

  // Enregistrement dans ai_prompts (service_role : contourne la garde e-mail du
  // RPC set_ai_prompt, l'appelant est déjà vérifié plus haut).
  const maj = await fetch(
    `${SUPABASE_URL}/rest/v1/ai_prompts?on_conflict=feature`,
    {
      method: "POST",
      headers: {
        apikey: SERVICE_ROLE,
        Authorization: `Bearer ${SERVICE_ROLE}`,
        "Content-Type": "application/json",
        Prefer: "resolution=merge-duplicates,return=minimal",
      },
      body: JSON.stringify({
        feature: FEATURE,
        label: "Remplissage auto Mind Vector",
        system_prompt: texte,
        updated_at: new Date().toISOString(),
        updated_by: email,
      }),
    },
  );
  if (!maj.ok) {
    return json({ error: "ecriture", message: await maj.text() }, 500);
  }

  const usage = jsonRes?.usage || {};
  const costUsd = await loggerCout(usage, email, FEATURE);
  return json({
    prompt: texte,
    scanned: blocs.length,
    usage,
    cost: { usd: costUsd, eur: costUsd / USD_PER_EUR },
  });
}

// ── action "generer" ────────────────────────────────────────────────────────
async function generer(body: any, email: string): Promise<Response> {
  const label = String(body?.label || "").trim();
  const description = String(body?.description || "").trim();
  // Documentation de fond du sujet, si l'auteur en a rédigé une : c'est la
  // matière la plus solide dont on dispose (chiffres, contexte), et elle borne
  // ce que le modèle peut avancer.
  const contenu = String(body?.contenu || "").trim().slice(0, 12000);
  if (!label) return json({ error: "bad_request", message: "Intitulé manquant." }, 400);

  let systemPrompt = DEFAULT_SYSTEM_PROMPT;
  try {
    const pr = await dbSelect(`ai_prompts?feature=eq.${FEATURE}&select=system_prompt`);
    const p = Array.isArray(pr) ? pr[0] : null;
    if (p?.system_prompt) systemPrompt = p.system_prompt;
  } catch { /* repli sur le prompt codé */ }

  const tool = {
    name: "report_positions",
    description: "Renvoie les 5 positions du sujet, de l'extrême 1 à l'extrême opposé 5.",
    input_schema: {
      type: "object",
      properties: {
        positions: {
          type: "array",
          items: {
            type: "object",
            properties: {
              pos: { type: "integer", description: "Rang de 1 à 5" },
              titre: { type: "string", description: "1 à 4 mots nommant la position" },
              contenu: { type: "string", description: "~200 caractères énonçant la position" },
            },
            required: ["pos", "titre", "contenu"],
          },
        },
      },
      required: ["positions"],
    },
  };

  // La consigne d'usage de la documentation vit ICI et non dans le prompt
  // système : celui-ci est réécrit par « rescanner », et une consigne qui n'y
  // survivrait pas serait perdue au premier rescan.
  const userContent =
    `SUJET : ${label}` +
    (description ? `\n\nCE QUE CE SUJET RECOUVRE :\n${description}` : "") +
    (contenu
      ? `\n\n=== DOCUMENTATION DE FOND RÉDIGÉE PAR L'AUTEUR ===\n${contenu}\n=== FIN DE LA DOCUMENTATION ===\n\n` +
        `Appuie-toi sur cette documentation : c'est la matière de référence. Les chiffres,` +
        ` faits et repères que tu emploies doivent en venir — n'en invente pas d'autres et` +
        ` n'écris rien qui la contredise. Elle décrit le sujet, pas une position : chacune` +
        ` des 5 positions reste à formuler, en s'appuyant sur ces éléments.`
      : "") +
    `\n\nProduis les 5 positions.`;

  const { ok, jsonRes } = await askClaude(systemPrompt, userContent, [tool]);
  if (!ok) {
    return json({ error: "ai_error", message: jsonRes?.error?.message || "Appel Claude en échec." }, 502);
  }
  const bloc = (jsonRes?.content || []).find(
    (x: any) => x.type === "tool_use" && x.name === "report_positions",
  );
  const brut = Array.isArray(bloc?.input?.positions) ? bloc.input.positions : [];

  // Garde-fou : exactement 5 rangs, 1 à 5, sans trou ni doublon. On range par
  // pos et on complète les manquants plutôt que d'écrire une grille bancale.
  const parRang: Record<number, any> = {};
  for (const p of brut) {
    const r = parseInt(p?.pos, 10);
    if (r >= 1 && r <= 5 && !parRang[r]) {
      parRang[r] = {
        pos: r,
        titre: String(p?.titre || "").trim().slice(0, 60),
        contenu: String(p?.contenu || "").trim(),
      };
    }
  }
  const positions = [1, 2, 3, 4, 5].map((r) => parRang[r] || { pos: r, titre: "", contenu: "" });
  const remplies = positions.filter((p) => p.contenu).length;
  if (remplies < 3) {
    return json({ error: "vide", message: "L'IA n'a pas produit de positions exploitables. Réessayez." }, 502);
  }

  const usage = jsonRes?.usage || {};
  const costUsd = await loggerCout(usage, email, FEATURE);
  return json({
    positions,
    usage,
    cost: { usd: costUsd, eur: costUsd / USD_PER_EUR },
  });
}

async function handle(req: Request): Promise<Response> {
  const auth = req.headers.get("Authorization") || "";
  const jwt = auth.replace(/^Bearer\s+/i, "");
  if (!jwt) return json({ error: "no_token", message: "Token manquant." }, 401);
  const email = await getCallerEmail(jwt);
  if (!email) return json({ error: "invalid_token", message: "Session invalide." }, 401);
  if (email.toLowerCase() !== ADMIN_EMAIL) {
    return json({ error: "forbidden", message: "Accès réservé à l'administrateur." }, 403);
  }
  if (!ANTHROPIC_API_KEY) {
    return json({ error: "missing_key", message: "ANTHROPIC_API_KEY non configurée." }, 500);
  }

  let body: any = {};
  try { body = await req.json(); } catch { /* corps vide accepté */ }

  return body?.action === "rescan" ? await rescan(email) : await generer(body, email);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  try {
    return await handle(req);
  } catch (e) {
    console.error("mind-vector unhandled error:", e);
    return json({ error: "unhandled", message: String((e as any)?.message || e) }, 500);
  }
});

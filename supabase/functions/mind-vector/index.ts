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
const FEATURE_PROFIL = "mind_vector_profil";

// Repli si le prompt n'a pas encore été semé en base.
const DEFAULT_PROFIL_PROMPT =
  `Tu dresses le portrait d'une personne à partir de ses positions sur une série
de sujets. Chaque sujet propose 5 positions qui vont d'un extrême à l'extrême
opposé ; on te donne, pour chacun, celle qu'elle a retenue.

Ce n'est PAS un test de personnalité : ce sont des opinions. Tu en tires
néanmoins ce qu'elles révèlent d'une manière de voir le monde.

Produis, en français et en Markdown léger (## titres, **gras**, - listes) :

## Le portrait
Un portrait-robot en 6 à 10 phrases : ce qui structure sa façon de penser, ce à
quoi elle tient, ses lignes de force et ses angles morts. Écris-le en t'adressant
à elle (« tu »). Sois précis et incarné, jamais complaisant ni flatteur.

## Ce que disent les grilles
Trois lectures courtes, 2 à 3 phrases chacune, en assumant qu'il s'agit
d'hypothèses et non de mesures :
- **Process Communication** — la base et la phase les plus probables ;
- **MBTI** — le type le plus probable, avec les deux axes les plus nets ;
- **Ennéagramme** — le type dominante et son aile.
Pour chacune, dis en une phrase CE QUI, dans ses réponses, te fait pencher là.

## Les tensions
1 à 3 endroits où ses positions se contredisent ou se tendent, s'il y en a.

## À toi de dire
Termine en lui demandant si ce portrait lui paraît juste, et, si ce n'est pas le
cas, sur quoi précisément il se trompe — pour qu'on puisse l'affiner.

Règles :
- Tu ne juges pas les opinions, tu les lis.
- N'invente aucune position qu'elle n'a pas prise.
- Si les réponses sont trop peu nombreuses pour trancher, dis-le franchement
  plutôt que de broder.`;

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

async function dbSelect(path: string): Promise<any> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}` },
  });
  if (!res.ok) return null;
  return await res.json();
}

async function askClaude(system: string, userContent: string, tools?: any[], maxTokens = 8000) {
  const corps: any = {
    model: MODEL,
    max_tokens: maxTokens,
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

// ── action "profil" ─────────────────────────────────────────────────────────
// Ouverte à tout utilisateur connecté, mais STRICTEMENT sur ses propres
// classements : on lit les réponses dont il est l'auteur, jamais celles d'un
// autre. Le service_role contourne la RLS, c'est donc ici que la garde se joue.
async function profil(body: any, caller: { id: string; email: string }): Promise<Response> {
  const personneId = String(body?.personne_id || "").trim();
  if (!personneId) return json({ error: "bad_request", message: "Personne manquante." }, 400);

  const reps = (await dbSelect(
    `mv_reponses?personne_id=eq.${personneId}&auteur_id=eq.${caller.id}&select=node_id,pos`,
  )) || [];
  if (!reps.length) {
    return json({ error: "vide", message: "Aucune réponse à analyser." }, 422);
  }

  const noeuds    = (await dbSelect("mv_nodes?select=id,parent_id,label,description")) || [];
  const positions = (await dbSelect("mv_positions?select=node_id,pos,titre,content")) || [];
  const parId: Record<string, any> = {};
  for (const n of noeuds) parId[n.id] = n;
  const chemin = (n: any) => {
    const out: string[] = [];
    let cur = n;
    for (let g = 0; cur && g < 40; g++) { out.unshift(cur.label); cur = cur.parent_id ? parId[cur.parent_id] : null; }
    return out.join(" › ");
  };

  const blocs: string[] = [];
  for (const r of reps) {
    const n = parId[r.node_id];
    if (!n) continue;
    const ps = positions.filter((p: any) => p.node_id === r.node_id).sort((a: any, b: any) => a.pos - b.pos);
    const retenue = ps.find((p: any) => p.pos === r.pos);
    if (!retenue) continue;
    // On donne aussi les deux extrêmes : sans eux, « position 4 » ne dit rien.
    const p1 = ps.find((p: any) => p.pos === 1), p5 = ps.find((p: any) => p.pos === 5);
    blocs.push(
      `SUJET : ${chemin(n)}` +
      (n.description ? `\n  (${String(n.description).replace(/\s+/g, " ").trim()})` : "") +
      (p1 || p5 ? `\n  Éventail : 1 = ${p1?.titre || "?"} … 5 = ${p5?.titre || "?"}` : "") +
      `\n  RETENU → position ${r.pos}${retenue.titre ? ` « ${retenue.titre} »` : ""} : ` +
      String(retenue.content || "").replace(/\s+/g, " ").trim(),
    );
  }
  if (!blocs.length) return json({ error: "vide", message: "Aucune réponse exploitable." }, 422);

  let systemPrompt = DEFAULT_PROFIL_PROMPT;
  let versionPrompt = "defaut";
  try {
    const pr = await dbSelect(`ai_prompts?feature=eq.${FEATURE_PROFIL}&select=system_prompt,updated_at`);
    const p = Array.isArray(pr) ? pr[0] : null;
    if (p?.system_prompt) { systemPrompt = p.system_prompt; versionPrompt = String(p.updated_at || ""); }
  } catch { /* repli sur le prompt codé */ }

  // Portrait déjà en mémoire ? On ne repaie un appel que si quelque chose a
  // bougé : les réponses, le prompt, ou le commentaire laissé par l'intéressé.
  const stocke = ((await dbSelect(
    `mv_portraits?personne_id=eq.${personneId}&auteur_id=eq.${caller.id}&select=texte,signature,commentaire`,
  )) || [])[0] || null;
  const commentaire = String(body?.commentaire ?? stocke?.commentaire ?? "").trim();
  const signature = JSON.stringify({
    r: reps.map((r: any) => `${r.node_id}:${r.pos}`).sort(),
    p: versionPrompt,
    c: commentaire,
  });
  if (stocke && stocke.signature === signature && !body?.forcer) {
    return json({ texte: stocke.texte, sujets: blocs.length, commentaire, cache: true });
  }

  const { ok, jsonRes } = await askClaude(
    systemPrompt,
    `Voici les ${blocs.length} positions retenues.\n\n${blocs.join("\n\n")}` +
    (commentaire
      ? `\n\n=== CE QUE LA PERSONNE A RÉPONDU AU PORTRAIT PRÉCÉDENT ===\n${commentaire}\n` +
        `Prends-le au sérieux : corrige ce qu'elle conteste, et affine le reste en conséquence.`
      : ""),
  );
  if (!ok) return json({ error: "ai_error", message: jsonRes?.error?.message || "Appel Claude en échec." }, 502);
  const texte = (jsonRes?.content || [])
    .filter((c: any) => c.type === "text").map((c: any) => c.text).join("\n").trim();
  if (!texte) return json({ error: "vide", message: "Claude n'a rien renvoyé." }, 502);

  // On garde le texte ET l'état qui l'a produit : le prochain clic n'appellera
  // l'IA que si l'un des deux a bougé.
  try {
    await fetch(`${SUPABASE_URL}/rest/v1/mv_portraits?on_conflict=personne_id,auteur_id`, {
      method: "POST",
      headers: {
        apikey: SERVICE_ROLE,
        Authorization: `Bearer ${SERVICE_ROLE}`,
        "Content-Type": "application/json",
        Prefer: "resolution=merge-duplicates,return=minimal",
      },
      body: JSON.stringify({
        personne_id: personneId, auteur_id: caller.id,
        texte, signature, commentaire: commentaire || null,
        updated_at: new Date().toISOString(),
      }),
    });
  } catch { /* le portrait est rendu même si la mémorisation échoue */ }

  const usage = jsonRes?.usage || {};
  const costUsd = await loggerCout(usage, caller.email, FEATURE_PROFIL);
  return json({ texte, sujets: blocs.length, commentaire, usage, cost: { usd: costUsd, eur: costUsd / USD_PER_EUR } });
}

// ── action "branche" ────────────────────────────────────────────────────────
// Crée d'un coup plusieurs sujets sous une même branche, chacun avec ses 5
// positions. Lit d'abord TOUT ce qui existe déjà pour ne pas reposer une
// question sous un autre nom : c'est le principal risque quand on génère en lot.
async function branche(body: any, email: string): Promise<Response> {
  const label = String(body?.label || "").trim();
  const description = String(body?.description || "").trim();
  const consignes = String(body?.instructions || "").trim().slice(0, 12000);
  if (!label) return json({ error: "bad_request", message: "Intitulé manquant." }, 400);

  // Le catalogue existant : intitulé complet et titres des 5 positions.
  const noeuds    = (await dbSelect("mv_nodes?select=id,parent_id,label")) || [];
  const positions = (await dbSelect("mv_positions?select=node_id,pos,titre")) || [];
  const parId: Record<string, any> = {};
  for (const n of noeuds) parId[n.id] = n;
  const chemin = (n: any) => {
    const out: string[] = [];
    let cur = n;
    for (let g = 0; cur && g < 40; g++) { out.unshift(cur.label); cur = cur.parent_id ? parId[cur.parent_id] : null; }
    return out.join(" › ");
  };
  const deja = noeuds.map((n: any) => {
    const ts = positions.filter((p: any) => p.node_id === n.id && p.titre)
      .sort((a: any, b: any) => a.pos - b.pos).map((p: any) => p.titre);
    return `- ${chemin(n)}${ts.length ? `  [${ts.join(" · ")}]` : ""}`;
  }).join("\n");

  let systemPrompt = DEFAULT_SYSTEM_PROMPT;
  try {
    const pr = await dbSelect(`ai_prompts?feature=eq.${FEATURE}&select=system_prompt`);
    const p = Array.isArray(pr) ? pr[0] : null;
    if (p?.system_prompt) systemPrompt = p.system_prompt;
  } catch { /* repli sur le prompt codé */ }

  // Ce prompt se termine par « appelle report_positions » — l'outil du
  // remplissage d'UN sujet. Ici on en produit plusieurs d'un coup, avec un autre
  // outil : sans cette mise au point, le modèle réclamait un outil absent et ne
  // renvoyait aucun appel exploitable. On garde le prompt pour son style, on
  // corrige la seule consigne qui ne vaut plus.
  systemPrompt += `

=== POUR CETTE DEMANDE ===
Tu ne produis PAS un seul sujet mais PLUSIEURS d'un coup. L'outil à appeler est
report_branche (et non report_positions) : il attend une liste de sujets, chacun
avec son intitulé, une description d'une phrase, et ses 5 positions numérotées de
1 à 5. Toutes les règles d'écriture ci-dessus restent valables pour chaque sujet.`;

  const tool = {
    name: "report_branche",
    description: "Renvoie les sujets de la branche, chacun avec ses 5 positions.",
    input_schema: {
      type: "object",
      properties: {
        sujets: {
          type: "array",
          items: {
            type: "object",
            properties: {
              label: { type: "string", description: "Intitulé du sujet" },
              description: { type: "string", description: "Ce que le sujet recouvre, une phrase" },
              positions: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    pos: { type: "integer" },
                    titre: { type: "string" },
                    contenu: { type: "string" },
                  },
                  required: ["pos", "titre", "contenu"],
                },
              },
            },
            required: ["label", "positions"],
          },
        },
      },
      required: ["sujets"],
    },
  };

  const userContent =
    `BRANCHE À CRÉER : ${label}` +
    (description ? `\n\nCE QUE CETTE BRANCHE RECOUVRE :\n${description}` : "") +
    (consignes ? `\n\n=== CONSIGNES DE L'AUTEUR ===\n${consignes}\n=== FIN DES CONSIGNES ===` : "") +
    `\n\nCombien de sujets : si les consignes ci-dessus indiquent un nombre, produis EXACTEMENT ce nombre` +
    ` (8 au maximum). Si elles n'en indiquent aucun, produis-en 3.` +
    (deja
      ? `\n\n=== SUJETS DÉJÀ POSÉS DANS MIND VECTOR — n'en reproduis AUCUN ===\n${deja}\n` +
        `Ne repose pas une de ces questions sous un autre nom, et ne reprends pas leurs` +
        ` façons de trancher : cherche des angles que ce catalogue ne couvre pas encore.`
      : "") +
    `\n\nPour CHAQUE sujet, produis les 5 positions selon les règles du prompt système,` +
    ` plus une description d'une phrase disant ce que le sujet recouvre.` +
    ` Appelle l'outil report_branche.`;

  // Jusqu'à 8 sujets de 5 positions : la réponse est longue, et le raisonnement
  // adaptatif consomme lui aussi du plafond.
  const { ok, jsonRes } = await askClaude(systemPrompt, userContent, [tool], 24000);
  if (!ok) return json({ error: "ai_error", message: jsonRes?.error?.message || "Appel Claude en échec." }, 502);

  const bloc = (jsonRes?.content || []).find(
    (x: any) => x.type === "tool_use" && x.name === "report_branche",
  );
  const brut = Array.isArray(bloc?.input?.sujets) ? bloc.input.sujets : [];
  if (!bloc) {
    // Diagnostic utile plutôt qu'un « échec » opaque : on dit ce qu'on a reçu.
    const raison = jsonRes?.stop_reason === "max_tokens"
      ? "La réponse a été coupée avant la fin : demandez moins de sujets."
      : "Le modèle n'a pas appelé l'outil attendu. Réessayez.";
    return json({ error: "vide", message: raison, stop_reason: jsonRes?.stop_reason || null }, 502);
  }

  // Garde-fous : au plus 8 sujets, 5 rangs chacun, rien de vide.
  const sujets = brut.slice(0, 8).map((s: any) => {
    const parRang: Record<number, any> = {};
    for (const p of (Array.isArray(s?.positions) ? s.positions : [])) {
      const r = parseInt(p?.pos, 10);
      if (r >= 1 && r <= 5 && !parRang[r]) {
        parRang[r] = { pos: r, titre: String(p?.titre || "").trim().slice(0, 60), contenu: String(p?.contenu || "").trim() };
      }
    }
    return {
      label: String(s?.label || "").trim().slice(0, 120),
      description: String(s?.description || "").trim() || null,
      positions: [1, 2, 3, 4, 5].map((r) => parRang[r] || { pos: r, titre: "", contenu: "" }),
    };
  }).filter((s: any) => s.label && s.positions.filter((p: any) => p.contenu).length >= 3);

  if (!sujets.length) {
    return json({ error: "vide", message: "L'IA n'a produit aucun sujet exploitable. Réessayez." }, 502);
  }

  const usage = jsonRes?.usage || {};
  const costUsd = await loggerCout(usage, email, FEATURE);
  return json({ sujets, connus: noeuds.length, usage, cost: { usd: costUsd, eur: costUsd / USD_PER_EUR } });
}

async function getCaller(jwt: string): Promise<{ id: string; email: string } | null> {
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { Authorization: `Bearer ${jwt}`, apikey: ANON_KEY },
    });
    if (!res.ok) return null;
    const u = await res.json();
    return u?.id ? { id: u.id, email: u.email || "" } : null;
  } catch { return null; }
}

async function handle(req: Request): Promise<Response> {
  const auth = req.headers.get("Authorization") || "";
  const jwt = auth.replace(/^Bearer\s+/i, "");
  if (!jwt) return json({ error: "no_token", message: "Token manquant." }, 401);
  const caller = await getCaller(jwt);
  if (!caller) return json({ error: "invalid_token", message: "Session invalide." }, 401);
  if (!ANTHROPIC_API_KEY) {
    return json({ error: "missing_key", message: "ANTHROPIC_API_KEY non configurée." }, 500);
  }

  let body: any = {};
  try { body = await req.json(); } catch { /* corps vide accepté */ }

  // Le portrait est à tout le monde — sur ses propres réponses. Rédiger les
  // questions et réécrire le prompt restent des gestes d'administrateur.
  if (body?.action === "profil") return await profil(body, caller);

  if (caller.email.toLowerCase() !== ADMIN_EMAIL) {
    return json({ error: "forbidden", message: "Accès réservé à l'administrateur." }, 403);
  }
  if (body?.action === "rescan")  return await rescan(caller.email);
  if (body?.action === "branche") return await branche(body, caller.email);
  return await generer(body, caller.email);
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

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
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const EMAIL_FROM = Deno.env.get("EMAIL_FROM") ?? "Starvolt <noreply@starvolt.fr>";

const MODEL = "claude-opus-4-7";
const USD_PER_EUR = 0.92;
const PRICES: Record<string, { in: number; out: number }> = {
  "claude-opus-4-8":  { in: 5, out: 25 },
  "claude-opus-4-7":  { in: 5, out: 25 },
  "claude-sonnet-5":  { in: 3, out: 15 },
  "claude-haiku-4-5": { in: 1, out: 5 },
};

// Une requête de recherche web est facturée à part des jetons : 10 $ les 1 000.
// Sans cette ligne le compteur de l'écran mentait par omission — il ne comptait
// que le texte, jamais les recherches qui l'avaient produit.
const USD_PAR_RECHERCHE = 0.01;

// Les modèles ouverts au remplissage automatique. Deux choses varient d'un
// modèle à l'autre, et les confondre coûte un 400 :
//   · `outil` — la version de la recherche web. `_20260209` filtre les
//     résultats avant qu'ils n'entrent dans le contexte, ce qui borne la
//     facture (87 % du coût mesuré est en entrée). Haiku 4.5 n'a que la version
//     de base : moins cher au jeton, mais sans ce filtrage.
//   · `adaptatif` — le raisonnement adaptatif et le réglage `effort` sont
//     apparus avec la génération 4.6. Sur Haiku 4.5 les deux sont refusés
//     (« adaptive thinking is not supported on this model ») : on retombe sur
//     le raisonnement à budget, sa forme d'époque. Le laisser réfléchir un peu
//     n'est pas un luxe — sans cela le modèle rend régulièrement un appel
//     d'outil vide.
const MODELES_RECHERCHE: Record<string, { outil: string; adaptatif: boolean }> = {
  "claude-opus-4-8":  { outil: "web_search_20260209", adaptatif: true },
  "claude-opus-4-7":  { outil: "web_search_20260209", adaptatif: true },
  "claude-sonnet-5":  { outil: "web_search_20260209", adaptatif: true },
  "claude-haiku-4-5": { outil: "web_search_20250305", adaptatif: false },
};

// Tout identifiant venu du client part dans une URL PostgREST : on ne laisse
// passer que la forme d'un uuid.
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// ⚠️ Le catalogue se lit d'un bloc, avec une borne explicite. Elle valait 500 ;
// l'arbre est monté à 430 positions le 2026-08-29 et une borne atteinte ne
// lèverait AUCUNE erreur : des sujets disparaîtraient simplement des analyses.
// 3 000 laisse de la marge ; si l'arbre s'en approche, il faudra paginer.

const FEATURE = "mind_vector_fill";
const FEATURE_PROFIL = "mind_vector_profil";
const FEATURE_INVITE = "mind_vector_invite";
const FEATURE_PUBLIC = "mind_vector_public";
const FEATURE_POLITIQUE = "mind_vector_politique";

// Recherche web côté serveur : Anthropic exécute la requête, on ne fournit
// aucune clé de moteur. Le nombre de recherches est le premier levier de coût,
// avant même le choix du modèle : chaque recherche verse ses résultats dans le
// contexte, et l'entrée fait 87 % de la facture.
const RECHERCHES_DEFAUT = 4;
const RECHERCHES_MAX = 10;

// Repli si le prompt n'a pas été semé (migration_mind_vector_public.sql).
const DEFAULT_PUBLIC_PROMPT =
  `Tu documentes la position publique d'une personnalité ou d'une organisation
sur un sujet donné, en cherchant sur Internet.

LE PROFIL ÉTUDIÉ
#profil-public

On te donne UN sujet et ses cinq positions possibles. Cherche ce que ce profil
a dit, écrit ou fait qui permet de le situer, puis choisis la position qui lui
correspond. Chaque réponse porte un pourcentage de précision : 100 % pour une
prise de position explicite et sourcée, 70–90 % pour une déduction sans effort
à partir de propos documentés, 40–60 % pour de simples indices. En dessous de
40 %, ne renseigne PAS la position — une case vide vaut mieux qu'une case
inventée. Ne devine jamais à partir de ce que « les gens comme lui » pensent.

Rends la position, la précision, l'URL de la source, son nom, et une ou deux
phrases de justification, en appelant l'outil prévu à cet effet.`;

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

// Variante avec recherche web. Un outil serveur peut atteindre sa limite
// d'itérations et rendre `stop_reason: "pause_turn"` : ce n'est pas une erreur,
// c'est « j'ai encore du travail ». On renvoie le tour tel quel et le serveur
// reprend où il s'est arrêté ; sans cette boucle la réponse revient tronquée,
// sans appel d'outil, et l'écran croit à un échec.
// ⚠️ Budget mémoire. Une réponse avec recherche web ramène le TEXTE de chaque
// résultat : 50 000 jetons d'entrée mesurés, soit des centaines de kilo-octets
// de JSON. Sur `pause_turn`, reprendre la main impose de renvoyer le tour de
// l'assistant tel quel — donc de garder ET de re-sérialiser tout cela. Une
// boucle de six tours faisait grossir la charge à chaque passage, et Supabase a
// fini par tuer l'isolat (« not enough compute resources », sans exception
// applicative dans les journaux). Trois reprises : assez pour qu'un sujet
// difficile aboutisse, assez peu pour que la charge reste bornée.
//
// ⚠️ `max_tokens` compte la RÉFLEXION autant que la réponse. Les sorties
// mesurées montent à 3 000 jetons ; l'avoir baissé à 4 000 pour économiser de
// la mémoire coupait les sujets difficiles au milieu de leur raisonnement, et
// le tour revenait sans appel d'outil — donc « aucun classement », en ayant
// pourtant payé. La mémoire se gagne sur l'ENTRÉE (nombre de recherches,
// reprises bornées), jamais sur ce plafond-là.
async function askClaudeWeb(
  system: string, question: string, tools: any[],
  modele: string, recherchesMax: number, maxTokens = 8000,
) {
  const cap = MODELES_RECHERCHE[modele] || MODELES_RECHERCHE[MODEL];
  const outilWeb = { type: cap.outil, name: "web_search", max_uses: recherchesMax };
  const messages: any[] = [{ role: "user", content: question }];
  let jsonRes: any = null;
  for (let tour = 0; tour < 3; tour++) {
    const corps: any = {
      model: modele,
      max_tokens: maxTokens,
      system,
      messages,
      tools: [outilWeb, ...tools],
      tool_choice: { type: "auto" },
    };
    if (cap.adaptatif) {
      corps.thinking = { type: "adaptive" };
      // Choisir une position parmi cinq et citer sa source ne demande pas la
      // profondeur maximale : `high` (le défaut) payait du raisonnement dont la
      // tâche n'a pas besoin.
      corps.output_config = { effort: "medium" };
    } else {
      // Génération d'avant l'adaptatif : budget explicite, obligatoirement
      // inférieur à max_tokens. `effort` n'existe pas non plus ici.
      corps.thinking = { type: "enabled", budget_tokens: 2000 };
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
    if (!res.ok) return { ok: false, jsonRes: await res.json() };
    jsonRes = await res.json();
    if (jsonRes?.stop_reason !== "pause_turn") return { ok: true, jsonRes };
    messages.push({ role: "assistant", content: jsonRes.content });
  }
  return { ok: true, jsonRes };
}

// `modele` et `recherches` sont facultatifs : les actions historiques tournent
// toutes sur MODEL et n'appellent aucun outil serveur.
async function loggerCout(usage: any, email: string, feature: string,
                          modele: string = MODEL, recherches = 0) {
  const price = PRICES[modele] || { in: 0, out: 0 };
  const costUsd =
    ((usage?.input_tokens || 0) / 1e6) * price.in +
    ((usage?.output_tokens || 0) / 1e6) * price.out +
    recherches * USD_PAR_RECHERCHE;
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
        model: modele,
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
    "mv_nodes?select=id,parent_id,label,description&order=ordre&limit=3000",
  )) || [];
  const positions = (await dbSelect(
    "mv_positions?select=node_id,pos,titre,content&order=node_id,pos&limit=3000",
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
// Par défaut STRICTEMENT sur les classements de l'appelant : le service_role
// contourne la RLS, c'est donc ici que la garde se joue. `portee` permet
// d'élargir — mais seulement au propriétaire du profil ou à un superadmin, la
// même règle que mv_synthese : personne ne lit les évaluations reçues par un
// autre.
//   moi   — mes classements seuls (défaut, comportement historique)
//   auto  — l'auto-évaluation de la personne
//   tous  — tous les évaluateurs, pondérés par leur précision
//   choix — les évaluateurs nommés dans portee.auteurs, pondérés de même
// Ce que `caller` a le droit de lire du profil `personneId`, et les avis
// regroupés par sujet. PARTAGÉ par « profil » et « politique » : les deux
// analyses doivent porter sur exactement le même profil, sinon le portrait et
// l'analyse politique, affichés dans la même page, se contrediraient.
// Rend `{ erreur }` — une réponse HTTP toute faite — ou le contexte.
type CtxReponses = {
  erreur?: Response;
  fiche?: any;
  mode?: string;
  auteurs?: string[] | null;
  idsPresents?: string[];
  libelle?: (id: string) => string;
  parNoeud?: Record<string, { auteur: string; pos: number; w: number }[]>;
};

async function contexteReponses(
  personneId: string,
  caller: { id: string; email: string },
  portee: any,
): Promise<CtxReponses> {
  const fiche = ((await dbSelect(
    `mv_personnes?id=eq.${personneId}&select=id,user_id,nom,prenom,type_entite&limit=1`,
  )) || [])[0];
  if (!fiche) return { erreur: json({ error: "bad_request", message: "Profil introuvable." }, 400) };

  const p = portee || {};
  const mode = ["moi", "auto", "tous", "choix"].includes(String(p?.mode)) ? String(p.mode) : "moi";
  if (mode !== "moi") {
    const proprio = !!fiche.user_id && fiche.user_id === caller.id;
    if (!proprio && !(await estSuperadmin(caller.id))) {
      return { erreur: json({
        error: "forbidden",
        message: "Seul le titulaire du profil peut analyser les évaluations reçues.",
      }, 403) };
    }
  }

  // Les auteurs retenus. `null` = tout le monde.
  let auteurs: string[] | null = null;
  if (mode === "moi") auteurs = [caller.id];
  else if (mode === "auto") auteurs = [fiche.user_id || caller.id];
  else if (mode === "choix") {
    auteurs = (Array.isArray(p.auteurs) ? p.auteurs : []).map(String).filter((a: string) => UUID.test(a));
    if (!auteurs.length) return { erreur: json({ error: "bad_request", message: "Aucun évaluateur retenu." }, 400) };
  }

  const reps = (await dbSelect(
    `mv_reponses?personne_id=eq.${personneId}` +
    (auteurs ? `&auteur_id=in.(${auteurs.join(",")})` : "") +
    `&select=node_id,pos,auteur_id`,
  )) || [];
  if (!reps.length) {
    return { erreur: json({ error: "vide", message: "Aucune réponse à analyser." }, 422) };
  }

  // ── Pondération ───────────────────────────────────────────────────────────
  // Chaque évaluateur a dit la précision qu'il accordait à son propre regard.
  // Sur un sujet classé par plusieurs, la position retenue est la moyenne
  // pondérée par ces précisions, arrondie au rang le plus proche. Les valeurs
  // par défaut reprennent la règle posée à l'origine : 80 % pour la personne
  // elle-même, 60 % pour un tiers.
  const idsPresents = [...new Set(reps.map((r: any) => r.auteur_id))].filter((a) => UUID.test(String(a)));
  const prec: Record<string, number> = {};
  for (const q of (await dbSelect(
    `mv_precisions?personne_id=eq.${personneId}&select=auteur_id,taux`,
  )) || []) prec[q.auteur_id] = Number(q.taux) || 0;
  const poids = (id: string) => prec[id] || (fiche.user_id && fiche.user_id === id ? 80 : 60);

  const nomAuteur: Record<string, string> = {};
  if (idsPresents.length) {
    for (const q of (await dbSelect(
      `profiles?id=in.(${idsPresents.join(",")})&select=id,prenom,nom`,
    )) || []) {
      nomAuteur[q.id] = [q.prenom, q.nom].filter(Boolean).join(" ").trim();
    }
  }
  const libelle = (id: string) =>
    (fiche.user_id && fiche.user_id === id) ? "auto-évaluation" : (nomAuteur[id] || "un évaluateur");

  // node_id → avis de chaque auteur.
  const parNoeud: Record<string, { auteur: string; pos: number; w: number }[]> = {};
  for (const r of reps) {
    const w = poids(r.auteur_id);
    if (w <= 0) continue;   // précision nulle = voix qui ne pèse pas
    (parNoeud[r.node_id] = parNoeud[r.node_id] || []).push({ auteur: r.auteur_id, pos: Number(r.pos), w });
  }

  return { fiche, mode, auteurs, idsPresents, libelle, parNoeud };
}

// Position retenue par sujet : moyenne pondérée des avis, arrondie et bornée.
function retenuesParSujet(parNoeud: Record<string, { pos: number; w: number }[]>): Record<string, number> {
  const out: Record<string, number> = {};
  for (const [nodeId, avis] of Object.entries(parNoeud)) {
    const somme = avis.reduce((s, a) => s + a.w, 0);
    if (!somme) continue;
    const moyenne = avis.reduce((s, a) => s + a.pos * a.w, 0) / somme;
    out[nodeId] = Math.min(5, Math.max(1, Math.round(moyenne)));
  }
  return out;
}

async function profil(body: any, caller: { id: string; email: string }): Promise<Response> {
  const personneId = String(body?.personne_id || "").trim();
  if (!personneId) return json({ error: "bad_request", message: "Personne manquante." }, 400);
  if (!UUID.test(personneId)) return json({ error: "bad_request", message: "Personne invalide." }, 400);

  const ctx = await contexteReponses(personneId, caller, body?.portee);
  if (ctx.erreur) return ctx.erreur;
  const { fiche, mode, auteurs, idsPresents, libelle, parNoeud } = ctx as Required<CtxReponses>;

  const noeuds  = (await dbSelect("mv_nodes?select=id,parent_id,label,description&limit=3000")) || [];
  const positions = (await dbSelect("mv_positions?select=node_id,pos,titre,content&limit=3000")) || [];
  const parId: Record<string, any> = {};
  for (const n of noeuds) parId[n.id] = n;
  const chemin = (n: any) => {
    const out: string[] = [];
    let cur = n;
    for (let g = 0; cur && g < 40; g++) { out.unshift(cur.label); cur = cur.parent_id ? parId[cur.parent_id] : null; }
    return out.join(" › ");
  };

  const blocs: string[] = [];
  const retenues: string[] = [];   // pour la signature du cache
  for (const [nodeId, avis] of Object.entries(parNoeud)) {
    const n = parId[nodeId];
    if (!n) continue;
    const somme = avis.reduce((s, a) => s + a.w, 0);
    const moyenne = avis.reduce((s, a) => s + a.pos * a.w, 0) / somme;
    const pos = Math.min(5, Math.max(1, Math.round(moyenne)));
    const ps = positions.filter((p: any) => p.node_id === nodeId).sort((a: any, b: any) => a.pos - b.pos);
    const retenue = ps.find((p: any) => p.pos === pos);
    if (!retenue) continue;
    retenues.push(`${nodeId}:${pos}`);
    // On donne aussi les deux extrêmes : sans eux, « position 4 » ne dit rien.
    const p1 = ps.find((p: any) => p.pos === 1), p5 = ps.find((p: any) => p.pos === 5);
    // Plusieurs regards sur le même sujet : on les nomme. L'écart entre eux dit
    // quelque chose que la moyenne, seule, effacerait.
    const detail = avis.length > 1
      ? `\n  Avis : ${avis.map((a) => `${libelle(a.auteur)} → ${a.pos} (précision ${a.w} %)`).join(", ")}` +
        `\n  Position pondérée : ${moyenne.toFixed(2)} → ${pos}`
      : "";
    blocs.push(
      `SUJET : ${chemin(n)}` +
      (n.description ? `\n  (${String(n.description).replace(/\s+/g, " ").trim()})` : "") +
      (p1 || p5 ? `\n  Éventail : 1 = ${p1?.titre || "?"} … 5 = ${p5?.titre || "?"}` : "") +
      detail +
      `\n  RETENU → position ${pos}${retenue.titre ? ` « ${retenue.titre} »` : ""} : ` +
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
    `mv_portraits?personne_id=eq.${personneId}&auteur_id=eq.${caller.id}` +
    `&select=texte,signature,commentaire,politique_texte,politique_scores`,
  )) || [])[0] || null;
  // L'analyse politique, si elle a déjà été faite, se lit à la suite du
  // portrait : c'est la même page. Elle ne dépend pas du portrait et n'est donc
  // jamais recalculée ici — on la ressert telle quelle.
  const politiqueTexte = stocke?.politique_texte || null;
  const politiqueScores = stocke?.politique_scores || null;
  const commentaire = String(body?.commentaire ?? stocke?.commentaire ?? "").trim();
  // La portée entre dans la signature : passer de « moi seul » à « tout le
  // monde » change le portrait, et doit donc bien relancer l'analyse.
  const signature = JSON.stringify({
    r: retenues.sort(),
    p: versionPrompt,
    c: commentaire,
    m: mode,
    a: (auteurs || [...idsPresents]).map(String).sort(),
  });
  // Ce que l'appelant verra en tête du portrait : sur quoi il a été bâti.
  const nbAuteurs = idsPresents.length;
  const provenance = mode === "moi" ? "mes réponses"
    : mode === "auto" ? "l'auto-évaluation"
    : `${nbAuteurs} évaluation${nbAuteurs > 1 ? "s" : ""}`;

  if (stocke && stocke.signature === signature && !body?.forcer) {
    return json({ texte: stocke.texte, sujets: blocs.length, auteurs: nbAuteurs, provenance, commentaire,
                  politique: politiqueTexte, politique_scores: politiqueScores, cache: true });
  }

  // Quand plusieurs personnes ont répondu, le modèle doit savoir d'où sort la
  // position retenue — sans quoi il lirait les avis divergents comme des
  // contradictions de la personne elle-même.
  const preambule = nbAuteurs > 1
    ? `Ce portrait croise ${nbAuteurs} regards sur la même personne : son auto-évaluation ` +
      `et/ou celle de proches. Chaque évaluateur a estimé la précision de son propre regard ` +
      `(80 % pour une auto-évaluation, moins pour un tiers) ; la position retenue est la moyenne ` +
      `pondérée par ces précisions. Là où les avis divergent, dis-le : l'écart entre la façon ` +
      `dont la personne se voit et celle dont on la voit fait partie du portrait.\n\n`
    : "";

  const { ok, jsonRes } = await askClaude(
    systemPrompt,
    preambule +
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
  return json({ texte, sujets: blocs.length, auteurs: nbAuteurs, provenance, commentaire, usage,
                politique: politiqueTexte, politique_scores: politiqueScores,
                cost: { usd: costUsd, eur: costUsd / USD_PER_EUR } });
}

// ── action "politique" ──────────────────────────────────────────────────────
// De quels partis les opinions d'un profil le rapprochent-elles ? On croise ses
// positions retenues avec celles de TOUTES les personnes morales, et on rend un
// texte qui explique le classement.
//
// ⚠️ Le CHIFFRE est calculé ici, pas par le modèle. Un modèle de langage compte
// mal, et surtout il recompterait différemment d'une fois sur l'autre : le score
// doit être reproductible et vérifiable. Le modèle ne fait que l'expliquer.
//
// Barème, par sujet commun : même position = +100 %, un rang d'écart = +50 %,
// deux rangs = 0 %, trois = -50 %, quatre (les deux extrêmes) = -100 %. Le score
// du parti est la moyenne sur les sujets communs. D'où l'échelle demandée :
// +100 % « toutes les réponses identiques », -100 % « toutes aussi éloignées
// que possible ».
const PROXIMITE = (a: number, b: number) => 1 - Math.abs(a - b) / 2;

// Repli si le prompt n'a pas été semé (migration_mind_vector_politique_analyse.sql).
const DEFAULT_POLITIQUE_PROMPT =
  `Tu expliques à quelqu'un de quels partis politiques ses opinions le rapprochent,
à partir d'un calcul déjà fait, que tu ne dois ni refaire ni discuter.

Produis en français, en Markdown léger (## titres, **gras**, - listes) :
## Le parti le plus proche — lequel, son score, ce que ça veut dire et ce que ça
ne veut pas dire.
## Ce qui vous rapproche — 3 à 6 points d'accord, sujet par sujet.
## Ce qui vous en sépare — les principaux désaccords avec ce même parti.
## Les autres partis, du plus proche au plus éloigné — un paragraphe chacun.
## Ce qu'il faut en retenir — la ligne de force, et la confiance à accorder au
résultat vu le nombre de sujets comparés.

Règles : tu ne juges aucune opinion et ne conseilles aucun vote ; tu tutoies la
personne ; français simple et sobre, aucun mot anglais ; n'invente aucune
position ; dis-le si moins de huit sujets ont pu être comparés.`;

async function politique(body: any, caller: { id: string; email: string }): Promise<Response> {
  const personneId = String(body?.personne_id || "").trim();
  if (!personneId) return json({ error: "bad_request", message: "Personne manquante." }, 400);
  if (!UUID.test(personneId)) return json({ error: "bad_request", message: "Personne invalide." }, 400);

  const ctx = await contexteReponses(personneId, caller, body?.portee);
  if (ctx.erreur) return ctx.erreur;
  const { fiche, mode, auteurs, idsPresents, parNoeud } = ctx as Required<CtxReponses>;
  const miennes = retenuesParSujet(parNoeud);
  if (!Object.keys(miennes).length) {
    return json({ error: "vide", message: "Aucune réponse exploitable." }, 422);
  }

  // Les partis = les personnes morales, moins le profil analysé lui-même
  // (comparer La France insoumise à elle-même donnerait +100 % et ne dirait rien).
  const morales = (await dbSelect(
    "mv_personnes?type_entite=eq.morale&select=id,nom,commentaire&limit=200",
  )) || [];
  const partis = morales.filter((m: any) => m.id !== personneId);
  if (!partis.length) {
    return json({ error: "vide", message: "Aucun profil d'organisation à comparer." }, 422);
  }

  // ⚠️ On lit les réponses des partis SANS filtrer sur l'auteur : une position de
  // parti est un fait documenté, pas un avis de l'appelant, et elle a le plus
  // souvent été saisie par quelqu'un d'autre. Quand plusieurs lignes existent
  // pour le même sujet, celle issue d'une recherche sourcée prime ; à défaut, la
  // plus récente.
  const repsPartis = (await dbSelect(
    `mv_reponses?personne_id=in.(${partis.map((p: any) => p.id).join(",")})` +
    `&select=personne_id,node_id,pos,origine,updated_at&limit=30000`,
  )) || [];
  const leurs: Record<string, Record<string, number>> = {};
  const meilleur: Record<string, { r: number; d: string }> = {};
  for (const r of repsPartis) {
    const cle = `${r.personne_id}:${r.node_id}`;
    const rang = r.origine === "recherche" ? 2 : 1;
    const date = String(r.updated_at || "");
    const en_place = meilleur[cle];
    if (en_place && (en_place.r > rang || (en_place.r === rang && en_place.d >= date))) continue;
    meilleur[cle] = { r: rang, d: date };
    (leurs[r.personne_id] = leurs[r.personne_id] || {})[r.node_id] = Number(r.pos);
  }

  const classement = partis.map((p: any) => {
    const communs = Object.keys(miennes).filter((id) => leurs[p.id]?.[id] != null);
    const total = communs.reduce((s, id) => s + PROXIMITE(miennes[id], leurs[p.id][id]), 0);
    return {
      id: p.id,
      nom: String(p.nom || "").trim(),
      contexte: String(p.commentaire || "").trim(),
      sujets: communs.length,
      score: communs.length ? Math.round((total / communs.length) * 100) : null,
      communs,
    };
  }).filter((c) => c.score !== null)
    .sort((a, b) => (b.score as number) - (a.score as number));

  if (!classement.length) {
    return json({
      error: "vide",
      message: "Aucun sujet en commun entre ce profil et les partis enregistrés.",
    }, 422);
  }

  // ── Le dossier remis au modèle ────────────────────────────────────────────
  const noeuds    = (await dbSelect("mv_nodes?select=id,parent_id,label&limit=3000")) || [];
  const positions = (await dbSelect("mv_positions?select=node_id,pos,titre,content&limit=3000")) || [];
  const parId: Record<string, any> = {};
  for (const n of noeuds) parId[n.id] = n;
  const chemin = (n: any) => {
    const out: string[] = [];
    let cur = n;
    for (let g = 0; cur && g < 40; g++) { out.unshift(cur.label); cur = cur.parent_id ? parId[cur.parent_id] : null; }
    return out.join(" › ");
  };
  const titre = (nodeId: string, pos: number) => {
    const p = positions.find((q: any) => q.node_id === nodeId && q.pos === pos);
    return p?.titre ? String(p.titre).replace(/^\[|\]$/g, "") : `position ${pos}`;
  };
  const texteDe = (nodeId: string, pos: number) => {
    const p = positions.find((q: any) => q.node_id === nodeId && q.pos === pos);
    return String(p?.content || "").replace(/\s+/g, " ").replace(/\*\*/g, "").trim();
  };

  const nomProfil = [fiche.prenom, fiche.nom].filter(Boolean).join(" ").trim() || "ce profil";
  const dossier: string[] = [];
  dossier.push(
    `PROFIL ANALYSÉ : ${nomProfil}` +
    (fiche.type_entite === "morale" ? " (une organisation, pas une personne)" : "") +
    `\nSujets classés par ce profil : ${Object.keys(miennes).length}.`,
  );
  dossier.push(
    "CLASSEMENT CALCULÉ (chiffres définitifs, à reprendre tels quels)\n" +
    classement.map((c, i) =>
      `${i + 1}. ${c.nom} : ${c.score! >= 0 ? "+" : ""}${c.score} % sur ${c.sujets} sujet${c.sujets > 1 ? "s" : ""} comparé${c.sujets > 1 ? "s" : ""}`,
    ).join("\n"),
  );
  for (const c of classement) {
    const lignes = c.communs.map((id) => {
      const mien = miennes[id], sien = leurs[c.id][id];
      const ecart = Math.abs(mien - sien);
      return { id, mien, sien, ecart };
    }).sort((a, b) => a.ecart - b.ecart);
    dossier.push(
      `=== ${c.nom} — ${c.score! >= 0 ? "+" : ""}${c.score} % ===` +
      (c.contexte ? `\n(${c.contexte})` : "") +
      "\n" + lignes.map((l) =>
        `- ${chemin(parId[l.id]) || "sujet inconnu"}\n` +
        `    le profil : ${l.mien} « ${titre(l.id, l.mien)} » — ${texteDe(l.id, l.mien)}\n` +
        `    le parti  : ${l.sien} « ${titre(l.id, l.sien)} »` +
        (l.ecart ? ` — ${texteDe(l.id, l.sien)}` : " (même position)") +
        `\n    écart : ${l.ecart} rang${l.ecart > 1 ? "s" : ""} (${PROXIMITE(l.mien, l.sien) >= 0 ? "+" : ""}${Math.round(PROXIMITE(l.mien, l.sien) * 100)} %)`,
      ).join("\n"),
    );
  }

  let systemPrompt = DEFAULT_POLITIQUE_PROMPT;
  let versionPrompt = "defaut";
  try {
    const pr = await dbSelect(`ai_prompts?feature=eq.${FEATURE_POLITIQUE}&select=system_prompt,updated_at`);
    const p = Array.isArray(pr) ? pr[0] : null;
    if (p?.system_prompt) { systemPrompt = p.system_prompt; versionPrompt = String(p.updated_at || ""); }
  } catch { /* repli sur le prompt codé */ }

  // Même principe de cache que le portrait : on ne repaie que si le profil, les
  // positions des partis ou le prompt ont bougé. Les positions des partis entrent
  // dans la signature — sans elles, documenter un parti ne rafraîchirait rien.
  const signature = JSON.stringify({
    r: Object.entries(miennes).map(([k, v]) => `${k}:${v}`).sort(),
    q: classement.map((c) => `${c.id}:${c.score}:${c.sujets}`).sort(),
    p: versionPrompt,
    m: mode,
    a: (auteurs || [...idsPresents]).map(String).sort(),
  });
  const scores = classement.map((c) => ({ id: c.id, nom: c.nom, score: c.score, sujets: c.sujets }));
  const stocke = ((await dbSelect(
    `mv_portraits?personne_id=eq.${personneId}&auteur_id=eq.${caller.id}&select=politique_texte,politique_signature`,
  )) || [])[0] || null;
  if (stocke?.politique_texte && stocke.politique_signature === signature && !body?.forcer) {
    return json({ texte: stocke.politique_texte, scores, sujets: Object.keys(miennes).length, cache: true });
  }

  const { ok, jsonRes } = await askClaude(systemPrompt, dossier.join("\n\n"), undefined, 12000);
  if (!ok) return json({ error: "ai_error", message: jsonRes?.error?.message || "Appel Claude en échec." }, 502);
  const texte = (jsonRes?.content || [])
    .filter((c: any) => c.type === "text").map((c: any) => c.text).join("\n").trim();
  if (!texte) return json({ error: "vide", message: "Claude n'a rien renvoyé." }, 502);

  // La ligne peut ne pas exister encore (analyse politique lancée avant tout
  // portrait) : `texte` et `signature` du portrait ont un défaut en base.
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
        politique_texte: texte, politique_signature: signature, politique_scores: scores,
        updated_at: new Date().toISOString(),
      }),
    });
  } catch { /* l'analyse est rendue même si la mémorisation échoue */ }

  const usage = jsonRes?.usage || {};
  const costUsd = await loggerCout(usage, caller.email, FEATURE_POLITIQUE);
  return json({ texte, scores, sujets: Object.keys(miennes).length, usage,
                cost: { usd: costUsd, eur: costUsd / USD_PER_EUR } });
}

// ── action "public_position" ────────────────────────────────────────────────
// Cherche sur Internet la position d'un profil PUBLIC sur UN sujet. Un sujet
// par appel : la recherche prend des dizaines de secondes, et l'écran doit
// pouvoir montrer l'avancement et s'arrêter en cours de route. Le résultat est
// écrit dans mv_recherches, qui garde le détail (extrait, précision, source) ;
// c'est l'ÉCRAN qui promeut aussitôt la position en réponse ferme, sujet par
// sujet (`appliquerRecherche`). La fonction ne le fait pas elle-même : elle
// ignore si l'appelant a déjà classé ce sujet à la main, et un classement à la
// main prime toujours sur une recherche.
//
// ⚠️ Réservé aux fiches marquées `est_public`. Lancer une recherche Internet
// nominative sur un particulier — les comptes Starvolt portent nom et e-mail —
// serait une collecte de données personnelles, pas une documentation. La garde
// est ici parce que le service_role contourne la RLS.
async function publicPosition(body: any, caller: { id: string; email: string }): Promise<Response> {
  const personneId = String(body?.personne_id || "").trim();
  const nodeId     = String(body?.node_id || "").trim();
  if (!UUID.test(personneId) || !UUID.test(nodeId)) {
    return json({ error: "bad_request", message: "Profil ou sujet invalide." }, 400);
  }

  const fiche = ((await dbSelect(
    `mv_personnes?id=eq.${personneId}&select=id,prenom,nom,commentaire,est_public,type_entite&limit=1`,
  )) || [])[0];
  if (!fiche) return json({ error: "bad_request", message: "Profil introuvable." }, 400);
  if (!fiche.est_public) {
    return json({
      error: "forbidden",
      message: "La recherche automatique n'est ouverte qu'aux profils publics : "
             + "chercher sur Internet au nom d'un particulier n'est pas de la documentation.",
    }, 403);
  }

  const noeuds = (await dbSelect("mv_nodes?select=id,parent_id,label,description&limit=3000")) || [];
  const parId: Record<string, any> = {};
  for (const n of noeuds) parId[n.id] = n;
  const sujet = parId[nodeId];
  if (!sujet) return json({ error: "bad_request", message: "Sujet introuvable." }, 400);
  const chemin: string[] = [];
  for (let cur = sujet, g = 0; cur && g < 40; g++) {
    chemin.unshift(cur.label); cur = cur.parent_id ? parId[cur.parent_id] : null;
  }

  const ps = ((await dbSelect(
    `mv_positions?node_id=eq.${nodeId}&select=pos,titre,content&order=pos`,
  )) || []);
  if (!ps.length) return json({ error: "vide", message: "Ce sujet n'a pas de positions rédigées." }, 422);

  // Qui est ce profil : l'intitulé et le contexte saisi à la création. Sans le
  // commentaire, deux homonymes publics sont indiscernables — c'est pour ça
  // qu'il est obligatoire sur une personne morale.
  const identite = (fiche.type_entite === "morale"
    ? String(fiche.nom || "").trim()
    : [fiche.prenom, fiche.nom].filter(Boolean).join(" ").trim())
    + (fiche.commentaire ? `\n(${String(fiche.commentaire).replace(/\s+/g, " ").trim()})` : "");

  let systemPrompt = DEFAULT_PUBLIC_PROMPT;
  try {
    const pr = await dbSelect(`ai_prompts?feature=eq.${FEATURE_PUBLIC}&select=system_prompt`);
    const p = Array.isArray(pr) ? pr[0] : null;
    if (p?.system_prompt) systemPrompt = p.system_prompt;
  } catch { /* repli sur le prompt codé */ }
  // Le jeton du prompt : c'est ici que le profil entre dans les consignes.
  systemPrompt = systemPrompt.split("#profil-public").join(identite);

  const outil = {
    name: "report_position",
    description: "Rendre la position trouvée pour ce profil sur ce sujet, avec sa source.",
    input_schema: {
      type: "object",
      properties: {
        pos:     { type: ["integer", "null"], description: "Position retenue de 1 à 5, ou null si rien de solide." },
        taux:    { type: "integer", description: "Précision de 0 à 100. Sous 40, laisser pos à null." },
        url:     { type: ["string", "null"], description: "URL de la source principale." },
        source:  { type: ["string", "null"], description: "Nom de la source (média, institution, auteur)." },
        extrait: { type: "string", description: "Une ou deux phrases : ce qui fonde le classement, ou pourquoi rien n'a été trouvé." },
      },
      required: ["pos", "taux", "extrait"],
    },
  };

  const question =
    `SUJET : ${chemin.join(" › ")}` +
    (sujet.description ? `\n(${String(sujet.description).replace(/\s+/g, " ").trim()})` : "") +
    `\n\nLES CINQ POSITIONS POSSIBLES :\n` +
    ps.map((p: any) =>
      `${p.pos}. ${p.titre || "(sans titre)"} — ${String(p.content || "").replace(/\s+/g, " ").trim()}`,
    ).join("\n") +
    `\n\nCherche sur Internet, puis appelle report_position.`;

  // Le modèle et le nombre de recherches viennent de l'écran, mais c'est ici
  // qu'ils sont bornés : une valeur libre venue du client choisirait un modèle
  // hors tarif — donc un coût que le compteur ne saurait pas calculer.
  const modele = MODELES_RECHERCHE[String(body?.model || "")] ? String(body.model) : MODEL;
  const recherchesMax = Math.max(1, Math.min(RECHERCHES_MAX,
    Number.isFinite(Number(body?.recherches_max)) ? Math.round(Number(body.recherches_max)) : RECHERCHES_DEFAUT));

  const { ok, jsonRes } = await askClaudeWeb(systemPrompt, question, [outil], modele, recherchesMax);
  if (!ok) {
    return json({ error: "ai_error", message: jsonRes?.error?.message || "Appel Claude en échec." }, 502);
  }
  const appel = (jsonRes?.content || []).find((c: any) => c.type === "tool_use" && c.name === "report_position");
  if (!appel) {
    // ⚠️ Une réponse inexploitable a quand même été FACTURÉE. Ne pas la
    // journaliser laissait dépenser sans trace : le compteur de l'écran et
    // `ai_usage_log` montraient zéro pendant qu'Anthropic débitait. On enregistre
    // le coût d'abord, on rend l'erreur ensuite.
    const u = jsonRes?.usage || {};
    const perdu = await loggerCout(u, caller.email, FEATURE_PUBLIC, modele,
                                   Number(u?.server_tool_use?.web_search_requests) || 0);
    const texte = (jsonRes?.content || []).filter((c: any) => c.type === "text").map((c: any) => c.text).join(" ").trim();
    // Dire POURQUOI : « max_tokens » = réponse coupée, « pause_turn » = le
    // modèle cherchait encore. Sans ce mot, l'écran ne montre qu'un échec muet.
    return json({
      error: "vide",
      message: `Réponse sans classement (${jsonRes?.stop_reason || "raison inconnue"})`
             + (texte ? ` — ${texte.slice(0, 200)}` : "")
             + ` · ${(perdu / USD_PER_EUR).toFixed(3)} € tout de même facturés`,
    }, 502);
  }

  const a = appel.input || {};
  const taux = Math.max(0, Math.min(100, Number(a.taux) || 0));
  // La règle du prompt est aussi tenue ici : sous 40 %, pas de position. Un
  // modèle qui l'oublierait ne doit pas pouvoir remplir une case sur une
  // intuition.
  let pos: number | null = Number.isInteger(a.pos) ? Number(a.pos) : null;
  if (pos !== null && (pos < 1 || pos > 5)) pos = null;
  if (taux < 40) pos = null;

  const ligne = {
    personne_id: personneId,
    node_id: nodeId,
    pos,
    taux,
    url: a.url ? String(a.url).slice(0, 2000) : null,
    source: a.source ? String(a.source).slice(0, 300) : null,
    extrait: String(a.extrait || "").slice(0, 2000),
    retenu: false,
    cherche_le: new Date().toISOString(),
  };
  try {
    await fetch(`${SUPABASE_URL}/rest/v1/mv_recherches?on_conflict=personne_id,node_id`, {
      method: "POST",
      headers: {
        apikey: SERVICE_ROLE,
        Authorization: `Bearer ${SERVICE_ROLE}`,
        "Content-Type": "application/json",
        Prefer: "resolution=merge-duplicates,return=minimal",
      },
      body: JSON.stringify(ligne),
    });
  } catch { /* le résultat est rendu même si la mémorisation échoue */ }

  const usage = jsonRes?.usage || {};
  const recherches = Number(usage?.server_tool_use?.web_search_requests) || 0;
  const costUsd = await loggerCout(usage, caller.email, FEATURE_PUBLIC, modele, recherches);
  return json({ ...ligne, usage, modele, recherches,
                cost: { usd: costUsd, eur: costUsd / USD_PER_EUR } });
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
  const noeuds    = (await dbSelect("mv_nodes?select=id,parent_id,label&limit=3000")) || [];
  const positions = (await dbSelect("mv_positions?select=node_id,pos,titre&limit=3000")) || [];
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

// ── action "invite" ─────────────────────────────────────────────────────────
// Inviter par e-mail quelqu'un qui n'a pas encore de compte à en créer un, pour
// qu'il puisse évaluer le profil du demandeur. Ouvert à tout compte connecté.
// Le demandeur est mis en copie ; le contenu est fixé côté serveur (le seul
// paramètre libre est l'adresse cible) pour éviter tout détournement.
function inviteHtml(demandeur: string, appUrl: string): string {
  const bgMain = "#061e2a", bgCard = "#0d2d3e", green = "#7dd940", gold = "#f7c948";
  return `<!DOCTYPE html>
<html lang="fr"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Invitation Starvolt</title></head>
<body style="margin:0;padding:0;background:${bgMain};font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:${bgMain};padding:32px 16px;"><tr><td align="center">
    <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;">
      <tr><td style="padding:0 0 24px;text-align:center;">
        <div style="font-size:28px;letter-spacing:2px;color:${gold};font-weight:900;">✦ STARVOLT</div>
        <div style="font-size:12px;color:rgba(255,255,255,.35);letter-spacing:3px;text-transform:uppercase;margin-top:4px;">La constellation énergétique</div>
      </td></tr>
      <tr><td style="background:${bgCard};border-radius:18px;border:1px solid rgba(255,255,255,.1);padding:32px 28px;">
        <p style="margin:0 0 8px;font-size:22px;font-weight:800;color:#fff;">${demandeur} vous invite ✦</p>
        <p style="margin:0 0 22px;font-size:15px;color:rgba(255,255,255,.72);line-height:1.7;">
          <strong style="color:${green};">${demandeur}</strong> aimerait connaître votre regard. Sur Starvolt, l'outil <strong style="color:#fff;">Mind Vector</strong> permet de situer chacun sur les grands sujets — et de comparer sa vision de soi à celle des autres.
        </p>
        <div style="background:rgba(125,217,64,.08);border:1px solid rgba(125,217,64,.22);border-radius:12px;padding:18px 20px;margin-bottom:24px;">
          <p style="margin:0;font-size:14px;color:rgba(255,255,255,.8);line-height:1.65;">
            Créez votre compte en quelques secondes, puis retrouvez le profil de ${demandeur} dans « les profils auxquels j'ai accès » pour l'évaluer.
          </p>
        </div>
        <table width="100%" cellpadding="0" cellspacing="0"><tr><td align="center">
          <a href="${appUrl}" style="display:inline-block;background:${green};color:#0a2b00;text-decoration:none;font-size:16px;font-weight:800;padding:15px 34px;border-radius:12px;">Créer mon compte →</a>
        </td></tr></table>
        <p style="margin:22px 0 0;font-size:12px;color:rgba(255,255,255,.4);line-height:1.6;text-align:center;">
          Vous recevez cet e-mail parce que ${demandeur} vous a invité·e sur Starvolt. Si cela ne vous dit rien, ignorez-le simplement.
        </p>
      </td></tr>
      <tr><td style="padding:20px 0 0;text-align:center;font-size:11px;color:rgba(255,255,255,.3);">✦ Starvolt — l'énergie, ensemble</td></tr>
    </table>
  </td></tr></table>
</body></html>`;
}

async function invite(body: any, caller: { id: string; email: string }): Promise<Response> {
  const email = String(body?.email || "").trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return json({ error: "bad_email", message: "Adresse e-mail invalide." }, 400);
  }
  if (!RESEND_API_KEY) {
    return json({ error: "missing_resend", message: "RESEND_API_KEY non configurée." }, 500);
  }
  const appUrl = String(body?.appUrl || "").trim() || "https://app.starvolt.fr";
  const profs = await dbSelect(`profiles?id=eq.${caller.id}&select=prenom,nom`);
  const p = (profs && profs[0]) || {};
  const demandeur = [p.prenom, p.nom].filter(Boolean).join(" ") || caller.email;
  const resendResp = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { "Authorization": `Bearer ${RESEND_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: EMAIL_FROM,
      to: [email],
      cc: [caller.email],
      reply_to: caller.email,
      subject: `${demandeur} vous invite à rejoindre Starvolt ✦`,
      html: inviteHtml(demandeur, appUrl),
    }),
  });
  if (!resendResp.ok) {
    const t = await resendResp.text().catch(() => "");
    console.error("resend invite failed:", resendResp.status, t);
    return json({ error: "resend_failed", message: "L'envoi de l'e-mail a échoué." }, 502);
  }
  return json({ sent: true, cc: caller.email });
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

async function isAdminOrSuperadmin(userId: string): Promise<boolean> {
  const rows = await dbSelect(`profiles?id=eq.${userId}&select=role&limit=1`);
  const role = Array.isArray(rows) ? rows[0]?.role : null;
  return role === "admin" || role === "superadmin";
}

// Élargir une analyse aux évaluations reçues par quelqu'un d'autre est un droit
// de superadmin — la même borne que mv_synthese et mv_auteurs. Un admin simple
// peut évaluer autrui, pas lire ce que les autres en pensent.
async function estSuperadmin(userId: string): Promise<boolean> {
  const rows = await dbSelect(`profiles?id=eq.${userId}&select=role&limit=1`);
  return (Array.isArray(rows) ? rows[0]?.role : null) === "superadmin";
}

async function checkRateLimit(feature: string, userEmail: string, maxPerHour: number): Promise<boolean> {
  try {
    const since = new Date(Date.now() - 3600_000).toISOString();
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/ai_usage_log?feature=eq.${feature}&user_email=eq.${encodeURIComponent(userEmail)}&created_at=gte.${encodeURIComponent(since)}&select=id`,
      {
        headers: {
          apikey: SERVICE_ROLE,
          Authorization: `Bearer ${SERVICE_ROLE}`,
          "Prefer": "count=exact",
          "Range-Unit": "items",
          "Range": "0-0",
        },
      },
    );
    const range = res.headers.get("Content-Range") || "";
    const total = parseInt(range.split("/")[1] || "0", 10);
    return total >= maxPerHour;
  } catch { return false; }
}

async function logInviteUsage(userEmail: string): Promise<void> {
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
        feature: FEATURE_INVITE,
        model: "",
        input_tokens: 0,
        output_tokens: 0,
        cost_usd: 0,
        user_email: userEmail,
      }),
    });
  } catch { /* best-effort */ }
}

async function handle(req: Request): Promise<Response> {
  const auth = req.headers.get("Authorization") || "";
  const jwt = auth.replace(/^Bearer\s+/i, "");
  if (!jwt) return json({ error: "no_token", message: "Token manquant." }, 401);
  const caller = await getCaller(jwt);
  if (!caller) return json({ error: "invalid_token", message: "Session invalide." }, 401);

  let body: any = {};
  try { body = await req.json(); } catch { /* corps vide accepté */ }

  // Inviter par e-mail ne dépend pas d'Anthropic : on le traite avant le reste,
  // et c'est ouvert à tout compte connecté (chacun invite pour son profil).
  if (body?.action === "invite") {
    if (await checkRateLimit(FEATURE_INVITE, caller.email, 10)) {
      return json({ error: "rate_limited", message: "Limite de 10 invitations par heure atteinte." }, 429);
    }
    const res = await invite(body, caller);
    if (res.status < 400) await logInviteUsage(caller.email);
    return res;
  }

  if (!ANTHROPIC_API_KEY) {
    return json({ error: "missing_key", message: "ANTHROPIC_API_KEY non configurée." }, 500);
  }

  // Le portrait est à tout le monde — sur ses propres réponses. Rédiger les
  // questions et réécrire le prompt restent des gestes d'administrateur.
  if (body?.action === "profil") {
    if (await checkRateLimit(FEATURE_PROFIL, caller.email, 5)) {
      return json({ error: "rate_limited", message: "Limite de 5 portraits par heure atteinte." }, 429);
    }
    return await profil(body, caller);
  }

  // Même porte que le portrait : chacun sur ses propres classements, la portée
  // élargie restant réservée au titulaire du profil.
  if (body?.action === "politique") {
    if (await checkRateLimit(FEATURE_POLITIQUE, caller.email, 5)) {
      return json({ error: "rate_limited", message: "Limite de 5 analyses politiques par heure atteinte." }, 429);
    }
    return await politique(body, caller);
  }

  if (!(await isAdminOrSuperadmin(caller.id))) {
    return json({ error: "forbidden", message: "Accès réservé à l'administrateur." }, 403);
  }
  if (body?.action === "rescan")  return await rescan(caller.email);
  if (body?.action === "branche") return await branche(body, caller.email);
  // Un appel par sujet : le plafond horaire doit tenir un arbre entier, tout en
  // bornant la dépense si une boucle d'écran s'emballe.
  if (body?.action === "public_position") {
    if (await checkRateLimit(FEATURE_PUBLIC, caller.email, 150)) {
      return json({ error: "rate_limited", message: "Limite de 150 recherches par heure atteinte." }, 429);
    }
    return await publicPosition(body, caller);
  }
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

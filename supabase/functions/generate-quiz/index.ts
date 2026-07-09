// Edge Function : generate-quiz
// Génère des questions de quiz pour un thème (learn_subject) du module Comprendre.
// Admin-only. Lit le contenu du thème, applique le prompt (envoyé par le client ou
// lu dans ai_prompts feature='generate_quiz', fallback codé en dur), appelle Claude
// avec un tool forcé `report_questions`, logge le coût dans ai_usage_log.
// Ne touche PAS la base : renvoie les questions, l'insertion est faite côté client.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

const MODEL = "claude-opus-4-7";
const USD_PER_EUR = 0.92;
// $/M tokens
const PRICES: Record<string, { in: number; out: number }> = {
  "claude-opus-4-7": { in: 5, out: 25 },
};

const ADMIN_EMAIL = "greg@starvolt.fr";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

const DEFAULT_SYSTEM_PROMPT = `Tu es un concepteur pédagogique pour Starvolt, une application grand public sur l'énergie solaire, l'autoconsommation et la flexibilité électrique.

À partir UNIQUEMENT du contenu du thème fourni, rédige des questions de quiz qui vérifient la bonne compréhension du lecteur.

Règles :
- Français, tutoiement, ton clair et accessible (grand public, pas de jargon non expliqué).
- Chaque question a entre 3 et 5 réponses possibles.
- PLUSIEURS bonnes réponses sont possibles pour une même question (au moins une bonne réponse obligatoire ; varie : parfois une seule bonne réponse, parfois deux ou trois).
- Les mauvaises réponses (distracteurs) doivent être plausibles, pas absurdes.
- N'invente AUCUN fait, chiffre ou notion qui ne soit pas dans le contenu du thème.
- Ne pose pas deux fois la même question. Couvre des aspects différents du thème.
- Questions courtes et directes, réponses courtes.

Appelle l'outil report_questions avec exactement le nombre de questions demandé.`;

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
    headers: {
      apikey: SERVICE_ROLE,
      Authorization: `Bearer ${SERVICE_ROLE}`,
    },
  });
  if (!res.ok) return null;
  return await res.json();
}

async function handle(req: Request): Promise<Response> {
  // 1) Auth — admin only
  const auth = req.headers.get("Authorization") || "";
  const jwt = auth.replace(/^Bearer\s+/i, "");
  if (!jwt) return json({ error: "no_token", message: "Token manquant." }, 401);
  const email = await getCallerEmail(jwt);
  if (!email) return json({ error: "invalid_token", message: "Session invalide." }, 401);
  if (email.toLowerCase() !== ADMIN_EMAIL) {
    return json({ error: "forbidden", message: "Accès réservé à l'administrateur." }, 403);
  }

  // 2) Clé Anthropic
  if (!ANTHROPIC_API_KEY) {
    return json({ error: "missing_key", message: "ANTHROPIC_API_KEY non configurée." }, 500);
  }

  // 3) Body
  let body: any = {};
  try {
    body = await req.json();
  } catch {
    /* body vide ok */
  }
  const subjectId = body?.subject_id;
  const count = Math.min(Math.max(parseInt(body?.count) || 3, 1), 10);
  if (!subjectId) {
    return json({ error: "bad_request", message: "subject_id manquant." }, 400);
  }

  // 4) Lire le thème
  const subs = await dbSelect(
    `learn_subjects?id=eq.${subjectId}&select=id,title,content,group_id`
  );
  const subject = Array.isArray(subs) ? subs[0] : null;
  if (!subject) {
    return json({ error: "not_found", message: "Thème introuvable." }, 404);
  }
  const groupRows = await dbSelect(
    `learn_groups?id=eq.${subject.group_id}&select=title`
  );
  const groupTitle = Array.isArray(groupRows) ? groupRows[0]?.title : null;

  const themeText = (subject.content || "").trim();
  if (!themeText) {
    return json(
      { error: "empty_theme", message: "Ce thème n'a pas de contenu à exploiter." },
      400
    );
  }

  // 4b) Questions DÉJÀ enregistrées pour ce thème (pour ne jamais les reproduire).
  //     On les liste avec leurs réponses afin que le modèle varie les angles.
  //     `existingQuestions` sert aussi au filtre anti-doublons DÉTERMINISTE (7c).
  let existingBlock = "";
  const existingQuestions: string[] = [];
  try {
    const existing = await dbSelect(
      `learn_questions?subject_id=eq.${subjectId}&select=question,ordre,learn_choices(text,is_correct)&order=ordre`
    );
    if (Array.isArray(existing) && existing.length) {
      const lines = existing.map((q: any, i: number) => {
        existingQuestions.push(String(q.question || "").trim());
        const ch = (q.learn_choices || [])
          .map((c: any) => `${c.is_correct ? "[bonne]" : "[fausse]"} ${String(c.text || "").trim()}`)
          .join(" / ");
        return `${i + 1}. ${String(q.question || "").trim()}${ch ? `  [${ch}]` : ""}`;
      });
      existingBlock =
        `\n\nQUESTIONS DÉJÀ POSÉES SUR CE THÈME (${existing.length}) — INTERDICTION d'en reproduire ` +
        `une seule, même reformulée : chaque nouvelle question doit porter sur un angle, un chiffre ` +
        `ou une notion DIFFÉRENTS. En cas de doute, change de sujet :\n` +
        lines.join("\n");
    }
  } catch {
    /* best-effort : si la lecture échoue, on génère quand même */
  }

  // 5) Prompt système : body.prompt (édité par l'admin) > ai_prompts > défaut
  let systemPrompt = DEFAULT_SYSTEM_PROMPT;
  if (typeof body?.prompt === "string" && body.prompt.trim()) {
    systemPrompt = body.prompt.trim();
  } else {
    try {
      const pr = await dbSelect(
        `ai_prompts?feature=eq.generate_quiz&select=system_prompt`
      );
      const sp = Array.isArray(pr) ? pr[0]?.system_prompt : null;
      if (sp && sp.trim()) systemPrompt = sp.trim();
    } catch {
      /* fallback défaut */
    }
  }

  // 6) Appel Claude avec tool forcé
  const baseContent =
    `GROUPE : ${groupTitle || "—"}\n` +
    `THÈME : ${subject.title || "—"}\n\n` +
    `CONTENU DU THÈME :\n${themeText}`;
  // Objectif : ${count} questions NEUVES. L'unicité prime : mieux vaut renvoyer
  // moins de questions que reproduire une question déjà posée (le serveur filtre
  // de toute façon les doublons — les reproduire ne sert donc à rien).
  const userContent =
    baseContent +
    existingBlock +
    `\n\nGénère ${count} questions de quiz d'après ce contenu` +
    (existingBlock
      ? `. Chacune doit être NOUVELLE : n'aborde aucune question déjà posée ci-dessus, ` +
        `même reformulée. Explore d'autres aspects, chiffres, conséquences ou nuances du thème. ` +
        `Si tu ne trouves pas ${count} angles réellement distincts, renvoie-en moins plutôt que ` +
        `de répéter une question existante.`
      : `. Ne renvoie JAMAIS de liste vide.`);

  const tool = {
    name: "report_questions",
    description:
      "Renvoie les questions de quiz générées pour le thème, avec leurs réponses.",
    input_schema: {
      type: "object",
      properties: {
        questions: {
          type: "array",
          minItems: 1,
          items: {
            type: "object",
            properties: {
              question: { type: "string", description: "Énoncé de la question" },
              choices: {
                type: "array",
                minItems: 3,
                maxItems: 5,
                description:
                  "Entre 3 et 5 réponses possibles ; au moins une is_correct=true, plusieurs possibles.",
                items: {
                  type: "object",
                  properties: {
                    text: { type: "string" },
                    is_correct: { type: "boolean" },
                  },
                  required: ["text", "is_correct"],
                },
              },
            },
            required: ["question", "choices"],
          },
        },
      },
      required: ["questions"],
    },
  };

  const askClaude = async (uc: string) => {
    const aiRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 8000,
        // Opus 4.7 est "thinking-first" : forcer le tool sans le laisser
        // raisonner produit régulièrement un report_questions VIDE
        // (stop=tool_use · brut=0). On active le thinking adaptatif et on
        // passe le tool en "auto" (forcer un tool est incompatible avec le
        // thinking). Le prompt impose déjà d'appeler report_questions.
        thinking: { type: "adaptive" },
        system: systemPrompt,
        tools: [tool],
        tool_choice: { type: "auto" },
        messages: [{ role: "user", content: uc }],
      }),
    });
    const jsonRes = await aiRes.json();
    return { ok: aiRes.ok, jsonRes };
  };

  const extractRaw = (aj: any) => {
    const b = (aj?.content || []).find(
      (x: any) => x.type === "tool_use" && x.name === "report_questions"
    );
    return { block: b, raw: Array.isArray(b?.input?.questions) ? b.input.questions : [] };
  };

  // Mélange Fisher-Yates : le modèle liste toujours les bonnes réponses en tête,
  // on répartit l'ordre aléatoirement pour ne pas trahir la solution.
  const shuffle = <T,>(arr: T[]): T[] => {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  };

  // Normalisation d'un énoncé pour comparer deux questions (casse, accents et
  // ponctuation ignorés) — base du filtre anti-doublons déterministe.
  const norm = (s: string) => String(s || "")
    .toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9\s]/g, " ").replace(/\s+/g, " ").trim();
  // Quasi-doublon : énoncé normalisé identique OU ≥ 80 % de tokens communs (Jaccard).
  const isDup = (q: string, refs: string[]) => {
    const a = new Set(norm(q).split(" ").filter(Boolean));
    return refs.some((r) => {
      if (norm(r) === norm(q)) return true;
      const b = new Set(norm(r).split(" ").filter(Boolean));
      if (!a.size || !b.size) return false;
      let inter = 0; for (const t of a) if (b.has(t)) inter++;
      return inter / (a.size + b.size - inter) >= 0.8;
    });
  };

  // Garde-fous : 3-5 choix, au moins une bonne réponse (réponses mélangées).
  const validate = (raw: any[]) => (raw || [])
    .map((q: any) => ({
      question: String(q.question || "").trim(),
      choices: shuffle(
        (q.choices || [])
          .map((c: any) => ({ text: String(c.text || "").trim(), is_correct: !!c.is_correct }))
          .filter((c: any) => c.text)
          .slice(0, 5)
      ),
    }))
    .filter((q: any) => q.question && q.choices.length >= 3 && q.choices.some((c: any) => c.is_correct));

  // Génère → valide → écarte les doublons (vs questions existantes ET lot en cours).
  // On accumule les questions NEUVES sur (au plus) deux tentatives Claude.
  const totalUsage = { input_tokens: 0, output_tokens: 0 };
  const accepted: any[] = [];
  const seen: string[] = [...existingQuestions]; // énoncés interdits (existants + déjà retenus)
  let lastRaw: any[] = [];
  let lastJson: any = null;
  let lastBlock: any = null;

  const runAttempt = async (uc: string): Promise<{ ok: boolean; err?: string }> => {
    const res = await askClaude(uc);
    if (!res.ok) return { ok: false, err: res.jsonRes?.error?.message };
    lastJson = res.jsonRes;
    totalUsage.input_tokens += res.jsonRes?.usage?.input_tokens || 0;
    totalUsage.output_tokens += res.jsonRes?.usage?.output_tokens || 0;
    const { block, raw } = extractRaw(res.jsonRes);
    lastBlock = block; lastRaw = raw;
    for (const q of validate(raw)) {
      if (accepted.length >= count) break;
      if (isDup(q.question, seen)) continue; // jamais une question déjà posée/retenue
      seen.push(q.question);
      accepted.push(q);
    }
    return { ok: true };
  };

  try {
    const first = await runAttempt(userContent);
    if (!first.ok) {
      return json({ error: "ai_error", message: first.err || "Erreur Claude." }, 502);
    }
    // Relance ciblée si on n'a pas encore `count` questions NEUVES : on rappelle
    // explicitement TOUT ce qu'il faut éviter (existantes + déjà retenues) et on
    // ne demande que le complément manquant, radicalement différent.
    if (accepted.length < count) {
      const need = count - accepted.length;
      const avoid = seen.length
        ? `\n\nÀ NE REPRODUIRE SOUS AUCUNE FORME (questions déjà posées ou déjà retenues) :\n` +
          seen.map((q, i) => `${i + 1}. ${q}`).join("\n")
        : "";
      const retryContent =
        baseContent + avoid +
        `\n\nPropose ${need} question(s) de quiz SUPPLÉMENTAIRE(S), radicalement différentes de ` +
        `toutes celles listées ci-dessus (autres angles, chiffres, notions, conséquences). ` +
        `N'en reformule aucune. S'il ne reste pas ${need} angle(s) réellement distinct(s), renvoie-en moins.`;
      await runAttempt(retryContent);
    }
  } catch (e) {
    return json({ error: "ai_fetch_failed", message: String(e) }, 502);
  }

  let questions = accepted;

  // 7b) Diagnostic : si rien de NEUF ni d'exploitable ne survit, expliquer pourquoi.
  if (!questions.length) {
    const reasons: Record<string, number> = {};
    for (const q of lastRaw as any[]) {
      const choices = (q?.choices || []).filter((c: any) => String(c?.text || "").trim());
      let r = "ok";
      if (!String(q?.question || "").trim()) r = "enonce_vide";
      else if (choices.length < 3) r = `moins_de_3_choix(${choices.length})`;
      else if (!choices.some((c: any) => c?.is_correct)) r = "aucune_bonne_reponse";
      else if (isDup(String(q.question), existingQuestions)) r = "doublon_existant";
      reasons[r] = (reasons[r] || 0) + 1;
    }
    const onlyDups = existingQuestions.length > 0
      && (reasons["doublon_existant"] || 0) > 0
      && Object.keys(reasons).every((k) => k === "doublon_existant");
    const dbg =
      `stop=${lastJson?.stop_reason} · block=${!!lastBlock} · brut=${lastRaw.length} · ` +
      `motifs=${JSON.stringify(reasons)}`;
    console.error("generate-quiz vide:", dbg, JSON.stringify(lastJson?.content || []).slice(0, 800));
    const message = onlyDups
      ? `Toutes les questions proposées existaient déjà pour ce thème — enrichis le contenu du thème ou réessaie. [diag] ${dbg}`
      : `Aucune question exploitable. [diag] ${dbg}`;
    return json({ error: "empty_result", message }, 422);
  }

  // 8) Coût + log (cumul des tentatives Claude)
  const usage = {
    input_tokens: totalUsage.input_tokens,
    output_tokens: totalUsage.output_tokens,
  };
  const price = PRICES[MODEL] || { in: 0, out: 0 };
  const costUsd =
    (usage.input_tokens / 1e6) * price.in +
    (usage.output_tokens / 1e6) * price.out;

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
        feature: "generate_quiz",
        model: MODEL,
        input_tokens: usage.input_tokens,
        output_tokens: usage.output_tokens,
        cost_usd: Number(costUsd.toFixed(6)),
        user_email: email,
      }),
    });
  } catch {
    /* best-effort */
  }

  return json({
    questions,
    usage,
    cost: { usd: costUsd, eur: costUsd / USD_PER_EUR },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  try {
    return await handle(req);
  } catch (e) {
    // Toute erreur non gérée renvoie quand même les en-têtes CORS,
    // sinon le navigateur affiche "Failed to send a request to the Edge Function".
    console.error("generate-quiz unhandled error:", e);
    return json({ error: "unhandled", message: String((e as any)?.message || e) }, 500);
  }
});

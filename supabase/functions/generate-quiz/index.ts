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
  const userContent =
    `GROUPE : ${groupTitle || "—"}\n` +
    `THÈME : ${subject.title || "—"}\n\n` +
    `CONTENU DU THÈME :\n${themeText}\n\n` +
    `Génère ${count} questions de quiz d'après ce contenu.`;

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

  let aiJson: any;
  try {
    const aiRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 2000,
        system: systemPrompt,
        tools: [tool],
        tool_choice: { type: "tool", name: "report_questions" },
        messages: [{ role: "user", content: userContent }],
      }),
    });
    aiJson = await aiRes.json();
    if (!aiRes.ok) {
      return json(
        { error: "ai_error", message: aiJson?.error?.message || "Erreur Claude." },
        502
      );
    }
  } catch (e) {
    return json({ error: "ai_fetch_failed", message: String(e) }, 502);
  }

  // 7) Extraire le tool_use
  const block = (aiJson.content || []).find(
    (b: any) => b.type === "tool_use" && b.name === "report_questions"
  );
  let questions = block?.input?.questions || [];

  // Garde-fous : 3-5 choix, au moins une bonne réponse
  questions = (questions as any[])
    .map((q) => ({
      question: String(q.question || "").trim(),
      choices: (q.choices || [])
        .map((c: any) => ({
          text: String(c.text || "").trim(),
          is_correct: !!c.is_correct,
        }))
        .filter((c: any) => c.text)
        .slice(0, 5),
    }))
    .filter(
      (q) =>
        q.question &&
        q.choices.length >= 3 &&
        q.choices.some((c: any) => c.is_correct)
    );

  // 8) Coût + log
  const usage = {
    input_tokens: aiJson?.usage?.input_tokens || 0,
    output_tokens: aiJson?.usage?.output_tokens || 0,
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

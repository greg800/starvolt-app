// Supabase Edge Function — Email de bienvenue Starvolt
// Envoie via Resend (https://resend.com)
// Secrets requis :
//   RESEND_API_KEY        → clé API Resend (ex: re_xxxxxxxxxxxx)
//   EMAIL_FROM            → adresse expéditeur (ex: Starvolt <hello@starvolt.app>)
//   APP_URL               → URL de l'app (ex: https://app.starvolt.fr)
//   WELCOME_INTERNAL_TOKEN → token pour appels serveur-serveur
//
// Auth acceptée :
//   1) Bearer WELCOME_INTERNAL_TOKEN  (appels internes depuis switchgrid)
//   2) Bearer <user_jwt> + apikey: <anon_key>  (appels depuis le frontend)

const RESEND_API_KEY   = Deno.env.get("RESEND_API_KEY")         ?? "";
const EMAIL_FROM       = Deno.env.get("EMAIL_FROM")             ?? "Starvolt <noreply@starvolt.fr>";
const APP_URL          = Deno.env.get("APP_URL")                ?? "https://app.starvolt.fr";
const INTERNAL_TOKEN   = Deno.env.get("WELCOME_INTERNAL_TOKEN") ?? "";
// Clé anon publique — acceptée pour les appels frontend légitimes
const ANON_KEY         = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhreGtod2VncWthcGRic2lzeHd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MjY4NjksImV4cCI6MjA5MzAwMjg2OX0.9-_oHRJfwXZkl3bRYDMb5K56UzB8O1NOfa5QfrXFfkQ";

const CORS = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function emailHtml(firstName: string, loginEmail: string, appUrl: string): string {
  const btnColor = "#7dd940";
  const bgMain   = "#061e2a";
  const bgCard   = "#0d2d3e";
  return `<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Bienvenue chez Starvolt</title>
</head>
<body style="margin:0;padding:0;background:${bgMain};font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:${bgMain};padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;">

        <!-- Logo / Header -->
        <tr><td style="padding:0 0 24px;text-align:center;">
          <div style="font-size:28px;letter-spacing:2px;color:#f7c948;font-weight:900;">✦ STARVOLT</div>
          <div style="font-size:12px;color:rgba(255,255,255,.35);letter-spacing:3px;text-transform:uppercase;margin-top:4px;">La constellation énergétique</div>
        </td></tr>

        <!-- Carte principale -->
        <tr><td style="background:${bgCard};border-radius:18px;border:1px solid rgba(255,255,255,.1);padding:32px 28px;">

          <p style="margin:0 0 8px;font-size:22px;font-weight:800;color:#fff;">
            Bienvenue ${firstName} ! ✦
          </p>
          <p style="margin:0 0 24px;font-size:15px;color:rgba(255,255,255,.7);line-height:1.7;">
            Toute la constellation Starvolt est ravie de vous accueillir 🌟. Votre compte est créé et nous sommes déjà en train de préparer votre <strong style="color:#7dd940;">proposition d'économie sur mesure</strong>.
          </p>

          <!-- Identifiant de connexion -->
          <div style="background:rgba(247,201,72,.08);border:1px solid rgba(247,201,72,.2);border-radius:12px;padding:20px;margin-bottom:22px;">
            <p style="margin:0 0 6px;font-size:12px;color:rgba(255,255,255,.55);line-height:1.6;text-transform:uppercase;letter-spacing:.05em;">
              Votre identifiant de connexion
            </p>
            <p style="margin:0;font-size:17px;font-weight:800;color:#f7c948;word-break:break-all;">
              ${loginEmail}
            </p>
            <p style="margin:10px 0 0;font-size:13px;color:rgba(255,255,255,.55);line-height:1.6;">
              Gardez cet email précieusement : c'est avec cette adresse que vous vous connecterez à l'application.
            </p>
          </div>

          <!-- CTA application -->
          <table cellpadding="0" cellspacing="0" width="100%"><tr><td align="center">
            <a href="${appUrl}" target="_blank"
              style="display:inline-block;padding:14px 36px;background:${btnColor};color:#061e2a;font-weight:800;font-size:15px;text-decoration:none;border-radius:10px;letter-spacing:.3px;">
              🚀 Ouvrir l'application Starvolt
            </a>
          </td></tr></table>

          <p style="margin:18px 0 0;font-size:13px;color:rgba(255,255,255,.55);line-height:1.7;text-align:center;">
            Rendez-vous dans l'app pour signer votre consentement ENEDIS et suivre, en direct, la récupération de vos données de consommation.
          </p>
        </td></tr>

        <!-- Footer -->
        <tr><td style="padding:24px 0 0;text-align:center;">
          <p style="margin:0;font-size:11px;color:rgba(255,255,255,.25);line-height:1.6;">
            Starvolt — La constellation énergétique<br/>
            Cet email a été envoyé automatiquement après la création de votre compte.
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST")
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: CORS });

  // Auth : token interne (server→server) OU JWT utilisateur + anon key (frontend)
  const auth    = req.headers.get("Authorization") ?? "";
  const token   = auth.replace("Bearer ", "");
  const apikey  = req.headers.get("apikey") ?? "";
  const isInternal = INTERNAL_TOKEN && token === INTERNAL_TOKEN;
  const isFrontend = apikey === ANON_KEY && token.length > 50; // JWT Supabase = ~200 chars
  if (!isInternal && !isFrontend) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: CORS });
  }

  if (!RESEND_API_KEY) {
    console.warn("send-welcome: RESEND_API_KEY not configured, skipping email");
    return new Response(JSON.stringify({ ok: true, skipped: true }), { status: 200, headers: CORS });
  }

  const { email, firstName, appUrl } = await req.json() as Record<string,string>;
  if (!email) {
    return new Response(JSON.stringify({ error: "Missing email" }), { status: 400, headers: CORS });
  }

  const effectiveAppUrl = appUrl || APP_URL;
  const html = emailHtml(firstName || "là", email, effectiveAppUrl);

  const resendResp = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from:    EMAIL_FROM,
      to:      [email],
      subject: `Bienvenue dans la constellation Starvolt ✦`,
      html,
    }),
  });

  if (!resendResp.ok) {
    const err = await resendResp.text();
    console.error("Resend error:", err);
    return new Response(JSON.stringify({ error: err }), { status: 500, headers: CORS });
  }

  const result = await resendResp.json();
  return new Response(JSON.stringify({ ok: true, id: (result as any).id }), {
    status: 200,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
});

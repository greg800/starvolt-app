// Supabase Edge Function — alerte « nouveau compte » aux admins
// Appelée UNIQUEMENT par le trigger public.notify_admins_signup (pg_net) à la
// création d'un profil : l'inscription passe toujours par là, même si le
// front est contourné. Limite les abus (ex. inscriptions « Staff » publiques).
//
// Auth : en-tête x-notify-secret = NOTIFY_SECRET (même valeur rangée dans
// Vault sous « notify_signup_secret »). verify_jwt reste à true : le trigger
// envoie aussi Authorization: Bearer <anon> + apikey (cf. piège pg_net).
// Le payload (nouveau compte + destinataires admins) est construit côté base.
//
// Secrets : RESEND_API_KEY, EMAIL_FROM, APP_URL, NOTIFY_SECRET.

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const EMAIL_FROM     = Deno.env.get("EMAIL_FROM")     ?? "Starvolt <noreply@starvolt.fr>";
const APP_URL        = Deno.env.get("APP_URL")        ?? "https://app.starvolt.fr";
const NOTIFY_SECRET  = Deno.env.get("NOTIFY_SECRET")  ?? "";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

// Prénom, nom et email viennent de l'inscrit : jamais injectés bruts dans le HTML.
const esc = (s: unknown) => String(s ?? "").replace(/[&<>"']/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!NOTIFY_SECRET || req.headers.get("x-notify-secret") !== NOTIFY_SECRET)
    return json({ error: "Unauthorized" }, 401);
  if (!RESEND_API_KEY) return json({ ok: true, skipped: "no_resend_key" });

  const p = await req.json().catch(() => null) as null | {
    prenom?: string; nom?: string; email?: string; role?: string; role_label?: string;
    created_at?: string; admins?: string[];
  };
  const admins = (p?.admins ?? []).filter((a) => typeof a === "string" && a.includes("@"));
  if (!p || !admins.length) return json({ ok: true, skipped: "no_admin" });

  const qui   = `${p.prenom ?? ""} ${p.nom ?? ""}`.trim() || "(sans nom)";
  const role  = p.role_label || p.role || "—";
  const quand = new Date(p.created_at ?? Date.now()).toLocaleString("fr-FR", { timeZone: "Europe/Paris" });
  const staff = p.role === "staff";

  const ligne = (k: string, v: string) =>
    `<tr><td style="padding:6px 12px 6px 0;color:#667;font-size:13px;white-space:nowrap">${k}</td>` +
    `<td style="padding:6px 0;font-size:14px;font-weight:600;color:#111">${v}</td></tr>`;
  const html = `<!DOCTYPE html><html lang="fr"><body style="margin:0;padding:24px;background:#f4f6f8;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif">
  <div style="max-width:520px;margin:0 auto;background:#fff;border-radius:12px;padding:24px;border:1px solid #e3e7eb">
    <div style="font-size:12px;letter-spacing:2px;color:#b8860b;font-weight:800">✦ STARVOLT · ADMIN</div>
    <h1 style="font-size:20px;margin:8px 0 16px;color:#111">Nouveau compte créé</h1>
    ${staff ? `<div style="background:#fff4e0;border:1px solid #f5c26b;border-radius:8px;padding:10px 12px;font-size:13px;color:#7a4b00;margin-bottom:14px">
      Compte <strong>Staff</strong> : il accède aux pages Prix spot et Tarifs et à une copie de « Greg Site 5 ».
      S'il n'est pas de l'équipe, changez son rôle dans Gestion des utilisateurs.</div>` : ""}
    <table style="border-collapse:collapse">
      ${ligne("Nom", esc(qui))}
      ${ligne("Email", esc(p.email))}
      ${ligne("Rôle", esc(role))}
      ${ligne("Créé le", esc(quand))}
    </table>
    <a href="${APP_URL}" style="display:inline-block;margin-top:18px;padding:10px 20px;background:#7dd940;color:#061e2a;font-weight:800;font-size:14px;text-decoration:none;border-radius:8px">Ouvrir l'administration</a>
  </div></body></html>`;

  const r = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${RESEND_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: EMAIL_FROM,
      to: admins,
      subject: `${staff ? "⚠️ Compte Staff" : "Nouveau compte"} : ${qui}`,
      html,
    }),
  });
  if (!r.ok) {
    const err = await r.text();
    console.error("Resend error:", err);
    return json({ error: err }, 502);
  }
  return json({ ok: true, id: ((await r.json()) as { id?: string }).id, to: admins.length });
});

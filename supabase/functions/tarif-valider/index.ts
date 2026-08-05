// Edge Function: tarif-valider
// Promotion d'un brouillon de tarif (lu sur une facture) vers le catalogue
// vérifié — le geste central de la file admin. L'admin ne CRÉE pas un tarif,
// il VALIDE un brouillon pré-rempli, en un clic (spec §5).
//
// Body : { extraction_id, action: 'valider' | 'rejeter', corrections?: {...} }
// Effets d'une validation :
//   1. le tarif passe 'brouillon' → 'verifie' (il entre dans le catalogue public)
//   2. les autres brouillons de la même offre sont fusionnés dessus
//   3. les clients concernés reçoivent l'email « votre tarif est confirmé »
//
// Admin uniquement (profiles.role in admin/superadmin).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const EMAIL_FROM = Deno.env.get("EMAIL_FROM") ?? "Starvolt <noreply@starvolt.fr>";
const APP_URL = Deno.env.get("APP_URL") ?? "https://app.starvolt.fr";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status, headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Honnêteté du montant (spec §7) : le vrai tarif peut donner une économie plus
// faible, voire nulle. L'email annonce des montants EXACTS, jamais un gain.
function emailHtml(prenom: string, offre: string, appUrl: string): string {
  return `<!DOCTYPE html>
<html lang="fr"><head><meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Votre tarif est confirmé</title></head>
<body style="margin:0;padding:0;background:#061e2a;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#061e2a;padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;">
        <tr><td style="padding:0 0 24px;text-align:center;">
          <div style="font-size:28px;letter-spacing:2px;color:#f7c948;font-weight:900;">✦ STARVOLT</div>
        </td></tr>
        <tr><td style="background:#0d2d3e;border-radius:18px;border:1px solid rgba(255,255,255,.1);padding:32px 28px;">
          <p style="margin:0 0 8px;font-size:22px;font-weight:800;color:#fff;">Votre tarif est confirmé ${prenom ? ", " + prenom : ""} ✦</p>
          <p style="margin:0 0 22px;font-size:15px;color:rgba(255,255,255,.7);line-height:1.7;">
            Nous avons vérifié la grille tarifaire de votre offre <strong style="color:#7dd940;">${offre}</strong>,
            lue sur la facture que vous nous aviez transmise. Vos estimations ne sont plus provisoires :
            elles sont maintenant calculées sur vos <strong style="color:#fff;">montants réels</strong>.
          </p>
          <table cellpadding="0" cellspacing="0" width="100%"><tr><td align="center">
            <a href="${appUrl}" target="_blank"
              style="display:inline-block;padding:14px 36px;background:#7dd940;color:#061e2a;font-weight:800;font-size:15px;text-decoration:none;border-radius:10px;">
              Voir mes vrais montants
            </a>
          </td></tr></table>
          <p style="margin:18px 0 0;font-size:13px;color:rgba(255,255,255,.5);line-height:1.7;text-align:center;">
            Selon votre contrat réel, le montant affiché peut être différent de l'estimation
            que vous aviez vue — en mieux comme en moins bien. C'est le chiffre juste.
          </p>
        </td></tr>
        <tr><td style="padding:24px 0 0;text-align:center;">
          <p style="margin:0;font-size:11px;color:rgba(255,255,255,.25);line-height:1.6;">
            Starvolt — La constellation énergétique
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body></html>`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

  const token = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);
  const authClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: userData, error: userErr } = await authClient.auth.getUser(token);
  if (userErr || !userData?.user) return json({ error: "unauthorized" }, 401);

  const db = createClient(SUPABASE_URL, SERVICE_KEY);

  // --- Admin uniquement ---
  const { data: prof } = await db.from("profiles").select("role").eq("id", userData.user.id).maybeSingle();
  if (!prof || !["admin", "superadmin"].includes(prof.role)) return json({ error: "forbidden" }, 403);
  const adminEmail = userData.user.email || "admin";

  let body: Record<string, any> = {};
  try { body = await req.json(); } catch (_) { return json({ error: "bad_request" }, 400); }
  const { extraction_id, action = "valider", corrections = {} } = body;
  if (!extraction_id) return json({ error: "bad_request", message: "extraction_id manquant" }, 400);

  const { data: ext } = await db.from("factures_extractions").select("*").eq("id", extraction_id).maybeSingle();
  if (!ext) return json({ error: "not_found" }, 404);
  if (ext.statut !== "brouillon") return json({ error: "deja_resolue" }, 409);

  // ── Rejet : le brouillon disparaît, les sites qui pointaient dessus sont
  //    détachés (ils repartent sans tarif plutôt qu'avec un faux).
  if (action === "rejeter") {
    if (ext.tarif_id) {
      // Sans tarif du tout, le site n'a plus de facture calculable : on le
      // rattache à la grille de repli plutôt que de le laisser vide.
      const { data: parDefaut } = await db.from("tarifs_electricite")
        .select("id").eq("par_defaut", true).maybeSingle();
      await db.from("sites").update({ tarif_id: parDefaut?.id ?? null }).eq("tarif_id", ext.tarif_id);
      await db.from("tarifs_electricite").delete().eq("id", ext.tarif_id).eq("statut", "brouillon");
    }
    await db.from("factures_extractions").update({
      statut: "rejete", resolu_le: new Date().toISOString(), resolu_par: adminEmail,
    }).eq("id", extraction_id);
    return json({ ok: true, action: "rejete" });
  }

  // ── Validation : corrections de l'admin, puis promotion ──
  const maj: Record<string, any> = {
    statut: "verifie", verifie_le: new Date().toISOString(), verifie_par: adminEmail,
  };
  for (const champ of ["nom", "fournisseur", "abo_annuel", "prix_hp", "prix_hc", "type_tarif", "puissance_kva"]) {
    if (corrections[champ] !== undefined) maj[champ] = corrections[champ];
  }

  // Facture lue avec une confiance trop faible : aucun brouillon n'a été créé
  // (on refuse de calculer sur des prix incertains). C'est précisément le cas
  // qui remonte à l'admin — la validation CRÉE alors le tarif à partir des
  // valeurs qu'il vient de relire sur le PDF et de corriger.
  let tarifId: string | null = ext.tarif_id;
  if (!tarifId) {
    if (!maj.nom) return json({ error: "nom_requis", message: "Le nom de l'offre est obligatoire." }, 400);
    if (maj.prix_hp == null && maj.prix_hc == null) {
      return json({ error: "prix_requis", message: "Renseignez au moins un prix du kWh." }, 400);
    }
    const { data: cree, error: insErr } = await db.from("tarifs_electricite")
      .insert({ ...maj, source: "ocr" }).select("id").single();
    if (insErr || !cree) return json({ error: "insert_failed", detail: insErr?.message }, 500);
    tarifId = cree.id;
    // Le site du déposant part de zéro : on le rattache au tarif désormais réel.
    if (ext.site_id) await db.from("sites").update({ tarif_id: tarifId }).eq("id", ext.site_id);
  } else {
    const { error: upErr } = await db.from("tarifs_electricite").update(maj).eq("id", tarifId);
    if (upErr) return json({ error: "update_failed", detail: upErr.message }, 500);
  }

  // ── Fusion des autres brouillons de la MÊME offre : leurs sites basculent
  //    sur le tarif désormais vérifié, leurs brouillons sont supprimés.
  const { data: jumelles } = await db.from("factures_extractions")
    .select("id,tarif_id").eq("cle_offre", ext.cle_offre)
    .eq("statut", "brouillon").neq("id", extraction_id);
  for (const j of jumelles || []) {
    if (j.tarif_id && j.tarif_id !== tarifId) {
      await db.from("sites").update({ tarif_id: tarifId }).eq("tarif_id", j.tarif_id);
      await db.from("tarifs_electricite").delete().eq("id", j.tarif_id).eq("statut", "brouillon");
    }
  }
  const aResoudre = [extraction_id, ...(jumelles || []).map((j: Record<string, any>) => j.id)];
  await db.from("factures_extractions").update({
    statut: "promu", resolu_le: new Date().toISOString(), resolu_par: adminEmail, tarif_id: tarifId,
  }).in("id", aResoudre);

  // ── Notification des clients concernés ──
  // Destinataires = les sites qui pointent sur ce tarif (ils avaient des
  // montants provisoires). Un client n'est notifié qu'une fois par tarif.
  const { data: sites } = await db.from("sites").select("id,user_id").eq("tarif_id", tarifId);
  const { data: tarif } = await db.from("tarifs_electricite").select("nom").eq("id", tarifId).maybeSingle();
  const vus = new Set<string>();
  let envoyes = 0, echecs = 0;

  for (const s of sites || []) {
    if (!s.user_id || vus.has(s.user_id)) continue;
    vus.add(s.user_id);

    const { data: deja } = await db.from("recalcul_notifs")
      .select("id").eq("user_id", s.user_id).eq("tarif_id", tarifId).maybeSingle();
    if (deja) continue;

    const { data: u } = await db.auth.admin.getUserById(s.user_id);
    const email = u?.user?.email;
    if (!email) continue;
    const { data: p } = await db.from("profiles").select("prenom").eq("id", s.user_id).maybeSingle();

    const notifToken = crypto.randomUUID();
    await db.from("recalcul_notifs").insert({
      user_id: s.user_id, site_id: s.id, tarif_id: tarifId, token: notifToken,
    });

    if (!RESEND_API_KEY) { echecs++; continue; }
    try {
      const r = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { "Authorization": `Bearer ${RESEND_API_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          from: EMAIL_FROM, to: [email],
          subject: "Votre tarif est confirmé — vos vrais montants sont disponibles",
          html: emailHtml(p?.prenom || "", tarif?.nom || "votre offre", APP_URL),
        }),
      });
      if (r.ok) {
        await db.from("recalcul_notifs").update({ envoye_le: new Date().toISOString() }).eq("token", notifToken);
        envoyes++;
      } else { echecs++; }
    } catch (_) { echecs++; }
  }

  return json({
    ok: true, action: "valide", tarif_id: tarifId,
    fusionnees: (jumelles || []).length, emails_envoyes: envoyes, emails_echoues: echecs,
  });
});

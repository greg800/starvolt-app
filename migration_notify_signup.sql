-- Alerte « nouveau compte » : à chaque profil créé (= chaque inscription),
-- la fonction edge notify-signup écrit à tous les admin/superadmin.
-- Côté base pour qu'un contournement du front ne la saute pas.
-- Le secret x-notify-secret vit dans Vault (« notify_signup_secret »), jamais
-- dans le code de la fonction (pg_proc est lisible par tous les rôles).
begin;

create or replace function public.notify_admins_signup()
returns trigger language plpgsql security definer set search_path to 'public' as $fn$
declare
  secret text;
  payload jsonb;
begin
  begin
    select decrypted_secret into secret from vault.decrypted_secrets where name = 'notify_signup_secret';
    if secret is null then return new; end if;
    select jsonb_build_object(
      'prenom', new.prenom, 'nom', new.nom, 'role', new.role,
      'role_label', (select label from public.app_roles where key = new.role),
      'email', (select email from auth.users where id = new.id),
      'created_at', now(),
      'admins', coalesce((select jsonb_agg(u.email) from public.profiles p join auth.users u on u.id = p.id
                          where p.role in ('admin','superadmin') and u.email is not null), '[]'::jsonb))
      into payload;
    perform net.http_post(
      url     := 'https://hkxkhwegqkapdbsisxwv.supabase.co/functions/v1/notify-signup',
      headers := jsonb_build_object('Content-Type','application/json',
                   'Authorization','Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhreGtod2VncWthcGRic2lzeHd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MjY4NjksImV4cCI6MjA5MzAwMjg2OX0.9-_oHRJfwXZkl3bRYDMb5K56UzB8O1NOfa5QfrXFfkQ', 'apikey','eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhreGtod2VncWthcGRic2lzeHd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MjY4NjksImV4cCI6MjA5MzAwMjg2OX0.9-_oHRJfwXZkl3bRYDMb5K56UzB8O1NOfa5QfrXFfkQ',
                   'x-notify-secret', secret),
      body    := payload);
  exception when others then
    -- Une alerte ratée ne doit jamais bloquer une inscription.
    raise warning 'notify_admins_signup: %', sqlerrm;
  end;
  return new;
end;
$fn$;
revoke execute on function public.notify_admins_signup() from anon, public, authenticated;

drop trigger if exists notify_admins_signup on public.profiles;
create trigger notify_admins_signup after insert on public.profiles
  for each row execute function public.notify_admins_signup();

commit;

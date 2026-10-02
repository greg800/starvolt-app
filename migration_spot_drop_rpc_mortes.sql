-- Prix spot : suppression de deux RPC sans appelant
-- get_spot_all() et get_spot_averages() lisaient prix_spot mais plus rien ne
-- les appelle (ni starvolt.html, ni comwatt-app, ni socrate.me — vérifié le
-- 2026-10-02). Toute l'app passe par get_spot_json().
drop function if exists public.get_spot_all();
drop function if exists public.get_spot_averages();

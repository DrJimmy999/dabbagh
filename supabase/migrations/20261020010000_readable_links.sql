-- Readable client links: ?m=<slug>-<random>. The whole string is the secret; only its hash is stored.
create or replace function public.create_client_model(p_client_name text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_slug text;
  v_token text;
begin
  v_slug := left(regexp_replace(lower(coalesce(p_client_name, '')), '[^a-z0-9]+', '', 'g'), 12);
  if v_slug = '' then v_slug := 'client'; end if;
  v_token := v_slug || '-' || encode(extensions.gen_random_bytes(12), 'hex');
  insert into public.client_models (client_name, token_hash)
  values (p_client_name, encode(extensions.digest(v_token, 'sha256'), 'hex'));
  return v_token;
end;
$$;
revoke all on function public.create_client_model(text) from public, anon, authenticated;

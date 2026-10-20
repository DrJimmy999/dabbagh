-- One model per client. A client opens a private link that carries a long random token.
-- The tables are locked: the public API can only call the two functions below, and both
-- check the token first. Only a hash of each token is stored.

create extension if not exists pgcrypto with schema extensions;

create table public.client_models (
  id uuid primary key default gen_random_uuid(),
  client_name text not null,
  token_hash text not null unique,
  created_at timestamptz not null default now()
);

create table public.model_sections (
  model_id uuid not null references public.client_models (id) on delete cascade,
  section text not null check (section in (
    'general', 'streams', 'opex', 'employees',
    'p0', 'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9'
  )),
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (model_id, section)
);

-- Row level security on, with no policies: nobody can read or write these tables directly.
alter table public.client_models enable row level security;
alter table public.model_sections enable row level security;
revoke all on public.client_models from anon, authenticated;
revoke all on public.model_sections from anon, authenticated;

-- Read a whole model by its link token. Returns null when the token is unknown.
create or replace function public.get_model(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  m public.client_models;
begin
  select * into m
  from public.client_models
  where token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex');
  if not found then
    return null;
  end if;
  return jsonb_build_object(
    'client', m.client_name,
    'sections', coalesce(
      (select jsonb_object_agg(s.section, jsonb_build_object('data', s.data, 'updated_at', to_jsonb(s.updated_at) #>> '{}'))
       from public.model_sections s
       where s.model_id = m.id),
      '{}'::jsonb)
  );
end;
$$;

-- Save one section of a model. Returns the save time as text.
create or replace function public.save_section(p_token text, p_section text, p_data jsonb)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  mid uuid;
  ts timestamptz := now();
begin
  select id into mid
  from public.client_models
  where token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex');
  if mid is null then
    raise exception 'invalid link' using errcode = '28000';
  end if;
  if pg_column_size(p_data) > 200000 then
    raise exception 'section too large' using errcode = '54000';
  end if;
  insert into public.model_sections (model_id, section, data, updated_at)
  values (mid, p_section, p_data, ts)
  on conflict (model_id, section)
  do update set data = excluded.data, updated_at = excluded.updated_at;
  return to_jsonb(ts) #>> '{}';
end;
$$;

-- Create a client model and return its private token (shown once, only the hash is kept).
-- Not callable from the public API: run it from the Supabase SQL editor or the CLI.
create or replace function public.create_client_model(p_client_name text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  tok text := encode(extensions.gen_random_bytes(24), 'hex');
begin
  insert into public.client_models (client_name, token_hash)
  values (p_client_name, encode(extensions.digest(tok, 'sha256'), 'hex'));
  return tok;
end;
$$;

revoke all on function public.create_client_model(text) from public, anon, authenticated;
revoke all on function public.get_model(text) from public;
revoke all on function public.save_section(text, text, jsonb) from public;
grant execute on function public.get_model(text) to anon, authenticated;
grant execute on function public.save_section(text, text, jsonb) to anon, authenticated;

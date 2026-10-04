-- WEEKLY IDEAS: Listas de ideas de contenido semanal que el asistenten genera automáticamente
create table public.weekly_ideas (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  message jsonb null,
  session_id text not null,
  raw_content jsonb null,
  constraint weekly_ideas_pkey primary key (id)
) TABLESPACE pg_default;
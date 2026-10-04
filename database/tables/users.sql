-- USERS: Usuarios que han iniciado una conversación con el asistente
create table public.users (
  phone character varying(50) not null,
  description text null,
  weekly_tips boolean null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  survey_completed boolean not null default false,
  constraint users_pkey primary key (phone)
) TABLESPACE pg_default;
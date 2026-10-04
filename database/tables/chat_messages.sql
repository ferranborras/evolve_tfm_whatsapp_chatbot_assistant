-- CHAT MESSAGES
create table public.chat_messages (
  id uuid not null,
  session_id text not null,
  message jsonb not null,
  created_at timestamp without time zone null default now(),
  constraint n8n_chat_histories_pkey primary key (id)
) TABLESPACE pg_default;
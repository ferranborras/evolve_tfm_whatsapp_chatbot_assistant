-- WHATSAPP LOGS: Incluye los mensajes enviado y procesados como los errores y excepciones de la automatización
create table public.whatsapp_logs (
  wamid text not null,
  created_at timestamp with time zone not null default now(),
  message jsonb null,
  edited_at timestamp with time zone null,
  session_id text not null,
  is_error boolean not null,
  constraint whatsapp_logs_pkey primary key (wamid)
) TABLESPACE pg_default;
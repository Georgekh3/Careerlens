create table if not exists public.interview_coaching_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  raw_job_text text not null,
  location text,
  current_readiness_score integer not null default 1,
  session_summary text not null default '',
  focus_areas jsonb not null default '[]'::jsonb,
  performance_trend jsonb not null default '[]'::jsonb,
  ai_model text,
  started_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint interview_coaching_sessions_focus_areas_chk
    check (jsonb_typeof(focus_areas) = 'array'),
  constraint interview_coaching_sessions_performance_trend_chk
    check (jsonb_typeof(performance_trend) = 'array'),
  constraint interview_coaching_sessions_readiness_chk
    check (current_readiness_score between 1 and 100)
);

create table if not exists public.interview_coaching_turns (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.interview_coaching_sessions(id) on delete cascade,
  turn_no integer not null,
  question_payload jsonb not null,
  answer_text text,
  evaluation_payload jsonb,
  readiness_score integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint interview_coaching_turns_turn_no_unique unique (session_id, turn_no),
  constraint interview_coaching_turns_question_payload_chk
    check (jsonb_typeof(question_payload) = 'object'),
  constraint interview_coaching_turns_evaluation_payload_chk
    check (evaluation_payload is null or jsonb_typeof(evaluation_payload) = 'object'),
  constraint interview_coaching_turns_readiness_chk
    check (readiness_score is null or readiness_score between 1 and 100)
);

create index if not exists idx_interview_coaching_sessions_user_started_at
  on public.interview_coaching_sessions (user_id, started_at desc);

create index if not exists idx_interview_coaching_turns_session_turn_no
  on public.interview_coaching_turns (session_id, turn_no);

alter table public.interview_coaching_sessions enable row level security;
alter table public.interview_coaching_turns enable row level security;

drop policy if exists interview_coaching_sessions_select_own on public.interview_coaching_sessions;
create policy interview_coaching_sessions_select_own
  on public.interview_coaching_sessions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists interview_coaching_sessions_insert_own on public.interview_coaching_sessions;
create policy interview_coaching_sessions_insert_own
  on public.interview_coaching_sessions
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists interview_coaching_sessions_update_own on public.interview_coaching_sessions;
create policy interview_coaching_sessions_update_own
  on public.interview_coaching_sessions
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists interview_coaching_turns_select_own on public.interview_coaching_turns;
create policy interview_coaching_turns_select_own
  on public.interview_coaching_turns
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.interview_coaching_sessions s
      where s.id = interview_coaching_turns.session_id
        and s.user_id = (select auth.uid())
    )
  );

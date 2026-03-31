create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    full_name,
    avatar_url,
    auth_provider,
    authoritative_profile,
    profile_completion_score,
    current_profile_version
  )
  values (
    new.id,
    lower(coalesce(new.email, '')),
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'avatar_url',
    'google',
    jsonb_build_object(
      'basics', jsonb_build_object(
        'headline', '',
        'location', '',
        'summary', ''
      ),
      'skills', '[]'::jsonb,
      'experience', '[]'::jsonb,
      'education', '[]'::jsonb,
      'certifications', '[]'::jsonb
    ),
    0,
    0
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique check (email = lower(email)),
  full_name text,
  avatar_url text,
  auth_provider text not null default 'google' check (auth_provider = 'google'),
  authoritative_profile jsonb not null default jsonb_build_object(
    'basics', jsonb_build_object(
      'headline', '',
      'location', '',
      'summary', ''
    ),
    'skills', '[]'::jsonb,
    'experience', '[]'::jsonb,
    'education', '[]'::jsonb,
    'certifications', '[]'::jsonb
  ),
  profile_completion_score numeric not null default 0,
  current_profile_version integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_authoritative_profile_object_chk
    check (jsonb_typeof(authoritative_profile) = 'object'),
  constraint profiles_profile_completion_score_chk
    check (profile_completion_score >= 0 and profile_completion_score <= 100),
  constraint profiles_current_profile_version_chk
    check (current_profile_version >= 0)
);

create table if not exists public.cv_uploads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_bucket text not null default 'cvs',
  storage_path text not null,
  original_filename text not null,
  mime_type text not null,
  file_size_bytes bigint,
  checksum_sha256 text,
  extraction_status text not null default 'uploaded',
  parser_engine text,
  extracted_text text,
  parsing_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cv_uploads_file_size_bytes_chk
    check (file_size_bytes is null or file_size_bytes > 0),
  constraint cv_uploads_mime_type_chk
    check (mime_type in (
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    )),
  constraint cv_uploads_extraction_status_chk
    check (extraction_status in ('uploaded', 'extracting', 'parsed', 'failed'))
);

create table if not exists public.profile_versions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  cv_upload_id uuid references public.cv_uploads(id) on delete set null,
  version_no integer not null,
  source text not null default 'ai_parse',
  snapshot jsonb not null,
  ai_model text,
  validation_status text not null default 'valid',
  change_note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profile_versions_snapshot_object_chk
    check (jsonb_typeof(snapshot) = 'object'),
  constraint profile_versions_version_no_chk
    check (version_no > 0),
  constraint profile_versions_source_chk
    check (source in ('ai_parse', 'user_edit', 'system_merge')),
  constraint profile_versions_validation_status_chk
    check (validation_status in ('valid', 'repair_attempted', 'invalid'))
);

create table if not exists public.async_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  task_type text not null,
  status text not null default 'queued',
  progress_percent numeric not null default 0,
  input_payload jsonb not null default '{}'::jsonb,
  result jsonb,
  error jsonb,
  related_entity_type text,
  related_entity_id uuid,
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint async_tasks_task_type_chk
    check (task_type in ('cv_parse', 'job_analysis', 'interview_generation', 'answer_evaluation')),
  constraint async_tasks_status_chk
    check (status in ('queued', 'processing', 'done', 'failed')),
  constraint async_tasks_progress_percent_chk
    check (progress_percent >= 0 and progress_percent <= 100),
  constraint async_tasks_input_payload_object_chk
    check (jsonb_typeof(input_payload) = 'object'),
  constraint async_tasks_error_object_chk
    check (error is null or jsonb_typeof(error) = 'object')
);

create table if not exists public.job_descriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  company text,
  location text,
  source text not null default 'pasted',
  raw_text text not null,
  normalized_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint job_descriptions_source_chk
    check (source in ('manual', 'pasted', 'imported')),
  constraint job_descriptions_normalized_json_object_chk
    check (jsonb_typeof(normalized_json) = 'object')
);

create table if not exists public.job_analyses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  job_description_id uuid not null references public.job_descriptions(id) on delete cascade,
  profile_version_id uuid references public.profile_versions(id) on delete set null,
  overall_fit_score integer not null,
  skills_match_score integer not null,
  experience_match_score integer not null,
  education_cert_score integer not null,
  domain_relevance_score integer not null,
  matched_skills jsonb not null default '[]'::jsonb,
  missing_skills jsonb not null default '[]'::jsonb,
  missing_requirements jsonb not null default '[]'::jsonb,
  recommendations jsonb not null default '[]'::jsonb,
  score_explanation jsonb not null default '{}'::jsonb,
  raw_result jsonb not null default '{}'::jsonb,
  ai_model text,
  created_at timestamptz not null default now(),
  constraint job_analyses_overall_score_chk
    check (overall_fit_score between 1 and 100),
  constraint job_analyses_skills_score_chk
    check (skills_match_score between 0 and 40),
  constraint job_analyses_experience_score_chk
    check (experience_match_score between 0 and 35),
  constraint job_analyses_education_score_chk
    check (education_cert_score between 0 and 15),
  constraint job_analyses_domain_score_chk
    check (domain_relevance_score between 0 and 10),
  constraint job_analyses_matched_skills_array_chk
    check (jsonb_typeof(matched_skills) = 'array'),
  constraint job_analyses_missing_skills_array_chk
    check (jsonb_typeof(missing_skills) = 'array'),
  constraint job_analyses_missing_requirements_array_chk
    check (jsonb_typeof(missing_requirements) = 'array'),
  constraint job_analyses_recommendations_array_chk
    check (jsonb_typeof(recommendations) = 'array'),
  constraint job_analyses_score_explanation_object_chk
    check (jsonb_typeof(score_explanation) = 'object'),
  constraint job_analyses_raw_result_object_chk
    check (jsonb_typeof(raw_result) = 'object')
);

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

create unique index if not exists idx_cv_uploads_storage_path
  on public.cv_uploads (storage_bucket, storage_path);

create unique index if not exists idx_profile_versions_user_version_no
  on public.profile_versions (user_id, version_no);

create index if not exists idx_async_tasks_user_id_created_at
  on public.async_tasks (user_id, created_at desc);

create index if not exists idx_cv_uploads_user_id_created_at
  on public.cv_uploads (user_id, created_at desc);

create index if not exists idx_job_descriptions_user_id_created_at
  on public.job_descriptions (user_id, created_at desc);

create index if not exists idx_job_analyses_user_id_created_at
  on public.job_analyses (user_id, created_at desc);

create index if not exists idx_job_analyses_job_description_id
  on public.job_analyses (job_description_id);

create index if not exists idx_job_analyses_raw_result_gin
  on public.job_analyses using gin (raw_result);

create index if not exists idx_interview_coaching_sessions_user_started_at
  on public.interview_coaching_sessions (user_id, started_at desc);

create index if not exists idx_interview_coaching_turns_session_turn_no
  on public.interview_coaching_turns (session_id, turn_no);

drop trigger if exists trg_profiles_set_updated_at on public.profiles;
create trigger trg_profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_async_tasks_set_updated_at on public.async_tasks;
create trigger trg_async_tasks_set_updated_at
before update on public.async_tasks
for each row execute function public.set_updated_at();

drop trigger if exists trg_cv_uploads_set_updated_at on public.cv_uploads;
create trigger trg_cv_uploads_set_updated_at
before update on public.cv_uploads
for each row execute function public.set_updated_at();

drop trigger if exists trg_profile_versions_set_updated_at on public.profile_versions;
create trigger trg_profile_versions_set_updated_at
before update on public.profile_versions
for each row execute function public.set_updated_at();

drop trigger if exists trg_job_descriptions_set_updated_at on public.job_descriptions;
create trigger trg_job_descriptions_set_updated_at
before update on public.job_descriptions
for each row execute function public.set_updated_at();

drop trigger if exists trg_interview_coaching_sessions_set_updated_at on public.interview_coaching_sessions;
create trigger trg_interview_coaching_sessions_set_updated_at
before update on public.interview_coaching_sessions
for each row execute function public.set_updated_at();

drop trigger if exists trg_interview_coaching_turns_set_updated_at on public.interview_coaching_turns;
create trigger trg_interview_coaching_turns_set_updated_at
before update on public.interview_coaching_turns
for each row execute function public.set_updated_at();

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.async_tasks enable row level security;
alter table public.cv_uploads enable row level security;
alter table public.profile_versions enable row level security;
alter table public.job_descriptions enable row level security;
alter table public.job_analyses enable row level security;
alter table public.interview_coaching_sessions enable row level security;
alter table public.interview_coaching_turns enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists async_tasks_select_own on public.async_tasks;
create policy async_tasks_select_own
  on public.async_tasks
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists async_tasks_insert_own on public.async_tasks;
create policy async_tasks_insert_own
  on public.async_tasks
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists async_tasks_update_own on public.async_tasks;
create policy async_tasks_update_own
  on public.async_tasks
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists cv_uploads_select_own on public.cv_uploads;
create policy cv_uploads_select_own
  on public.cv_uploads
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists cv_uploads_insert_own on public.cv_uploads;
create policy cv_uploads_insert_own
  on public.cv_uploads
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists cv_uploads_update_own on public.cv_uploads;
create policy cv_uploads_update_own
  on public.cv_uploads
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists profile_versions_select_own on public.profile_versions;
create policy profile_versions_select_own
  on public.profile_versions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists job_descriptions_select_own on public.job_descriptions;
create policy job_descriptions_select_own
  on public.job_descriptions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists job_descriptions_insert_own on public.job_descriptions;
create policy job_descriptions_insert_own
  on public.job_descriptions
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists job_descriptions_update_own on public.job_descriptions;
create policy job_descriptions_update_own
  on public.job_descriptions
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists job_descriptions_delete_own on public.job_descriptions;
create policy job_descriptions_delete_own
  on public.job_descriptions
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists job_analyses_select_own on public.job_analyses;
create policy job_analyses_select_own
  on public.job_analyses
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

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

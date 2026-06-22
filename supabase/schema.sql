-- R6 Care Supabase schema
-- Fresh database, username + password login, no email dependency.
-- Important: if Supabase asks about RLS, choose "Run without RLS".

create table if not exists public.app_users (
  id uuid primary key,
  username text not null unique,
  password_hash text not null,
  password_salt text not null,
  display_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_login_at timestamptz
);

create table if not exists public.app_sessions (
  token text primary key,
  user_id uuid not null references public.app_users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 days')
);

create table if not exists public.user_profiles (
  user_id uuid primary key references public.app_users(id) on delete cascade,
  display_name text,
  sex text check (sex in ('female', 'male', 'other')),
  birth_date date,
  height_cm numeric(5,2) check (height_cm between 50 and 260),
  activity_level text default 'moderate'
    check (activity_level in ('sedentary', 'light', 'moderate', 'active', 'very_active')),
  calorie_goal_kcal integer check (calorie_goal_kcal between 800 and 6000),
  protein_goal_g numeric(6,2) check (protein_goal_g between 0 and 400),
  fat_goal_g numeric(6,2) check (fat_goal_g between 0 and 300),
  carb_goal_g numeric(6,2) check (carb_goal_g between 0 and 800),
  timezone text not null default 'Asia/Hong_Kong',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.food_items (
  id bigint generated always as identity primary key,
  owner_user_id uuid not null references public.app_users(id) on delete cascade,
  name text not null,
  category text,
  serving_grams numeric(7,2) not null default 100 check (serving_grams > 0),
  calories_kcal numeric(8,2) not null check (calories_kcal >= 0),
  protein_g numeric(8,2) not null default 0 check (protein_g >= 0),
  carbs_g numeric(8,2) not null default 0 check (carbs_g >= 0),
  fat_g numeric(8,2) not null default 0 check (fat_g >= 0),
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.exercise_items (
  id bigint generated always as identity primary key,
  owner_user_id uuid not null references public.app_users(id) on delete cascade,
  activity_name text not null,
  category text,
  intensity text,
  met numeric(5,2) check (met >= 0),
  calories_30min_70kg numeric(8,2) check (calories_30min_70kg >= 0),
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.food_logs (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.app_users(id) on delete cascade,
  logged_at timestamptz not null default now(),
  food_item_id bigint references public.food_items(id) on delete set null,
  food_name text not null,
  grams numeric(7,2) not null check (grams > 0),
  calories_kcal numeric(8,2) not null check (calories_kcal >= 0),
  protein_g numeric(8,2) not null default 0 check (protein_g >= 0),
  carbs_g numeric(8,2) not null default 0 check (carbs_g >= 0),
  fat_g numeric(8,2) not null default 0 check (fat_g >= 0),
  source_label text not null default 'default',
  per_100_kcal numeric(8,2) check (per_100_kcal >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.exercise_logs (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.app_users(id) on delete cascade,
  logged_at timestamptz not null default now(),
  exercise_item_id bigint references public.exercise_items(id) on delete set null,
  activity_id text,
  activity_name text not null,
  category text,
  intensity text,
  met numeric(5,2) check (met >= 0),
  duration_min integer not null check (duration_min between 1 and 600),
  calories_kcal numeric(8,2) not null check (calories_kcal >= 0),
  weight_kg numeric(5,2) check (weight_kg between 20 and 400),
  created_at timestamptz not null default now()
);

create table if not exists public.weight_logs (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.app_users(id) on delete cascade,
  logged_on date not null default current_date,
  weight_kg numeric(5,2) not null check (weight_kg between 20 and 400),
  body_fat_percent numeric(5,2) check (body_fat_percent between 2 and 80),
  waist_cm numeric(5,2) check (waist_cm between 30 and 250),
  note text,
  created_at timestamptz not null default now()
);

alter table public.weight_logs
  drop constraint if exists weight_logs_user_id_logged_on_key;

create table if not exists public.daily_targets (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.app_users(id) on delete cascade,
  target_on date not null default current_date,
  calories_kcal integer not null check (calories_kcal between 800 and 6000),
  protein_g numeric(6,2) check (protein_g between 0 and 400),
  fat_g numeric(6,2) check (fat_g between 0 and 300),
  carbs_g numeric(6,2) check (carbs_g between 0 and 800),
  created_at timestamptz not null default now(),
  unique (user_id, target_on)
);

create index if not exists app_users_username_idx on public.app_users (username);
create index if not exists app_sessions_token_idx on public.app_sessions (token, expires_at);
create index if not exists food_items_owner_name_idx on public.food_items (owner_user_id, lower(name));
create index if not exists exercise_items_owner_name_idx on public.exercise_items (owner_user_id, lower(activity_name));
create index if not exists food_logs_user_logged_at_idx on public.food_logs (user_id, logged_at desc);
create index if not exists exercise_logs_user_logged_at_idx on public.exercise_logs (user_id, logged_at desc);
create index if not exists weight_logs_user_logged_on_idx on public.weight_logs (user_id, logged_on desc, created_at desc);
create index if not exists daily_targets_user_target_on_idx on public.daily_targets (user_id, target_on desc);

alter table public.app_users enable row level security;
alter table public.app_sessions enable row level security;
alter table public.user_profiles enable row level security;
alter table public.food_items enable row level security;
alter table public.exercise_items enable row level security;
alter table public.food_logs enable row level security;
alter table public.exercise_logs enable row level security;
alter table public.weight_logs enable row level security;
alter table public.daily_targets enable row level security;

create or replace function public.app_register(
  p_display_name text,
  p_password_hash text,
  p_password_salt text,
  p_token text,
  p_user_id uuid,
  p_username text
)
returns table (user_id uuid, token text, display_name text, username text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text := lower(trim(p_username));
  v_display_name text := coalesce(nullif(trim(p_display_name), ''), trim(p_username), 'R6 User');
  v_user_id uuid := p_user_id;
  v_token text := p_token;
begin
  if v_username is null or v_username = '' then
    raise exception 'Username is required';
  end if;
  if p_password_hash is null or length(p_password_hash) < 32 then
    raise exception 'Password hash is invalid';
  end if;
  if p_password_salt is null or length(p_password_salt) < 16 then
    raise exception 'Password salt is invalid';
  end if;
  if v_user_id is null then
    raise exception 'User id is required';
  end if;
  if v_token is null or length(v_token) < 32 then
    raise exception 'Session token is invalid';
  end if;
  if exists (select 1 from public.app_users u where u.username = v_username) then
    raise exception 'Username already exists';
  end if;

  insert into public.app_users (id, username, password_hash, password_salt, display_name)
  values (v_user_id, v_username, p_password_hash, p_password_salt, v_display_name);

  insert into public.user_profiles (user_id, display_name, sex, activity_level)
  values (v_user_id, v_display_name, 'other', 'moderate');

  insert into public.app_sessions (token, user_id)
  values (v_token, v_user_id);

  user_id := v_user_id;
  token := v_token;
  display_name := v_display_name;
  username := v_username;
  return next;
end;
$$;

create or replace function public.app_login(
  p_identifier text,
  p_password_hash text,
  p_token text
)
returns table (user_id uuid, token text, display_name text, username text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_identifier text := lower(trim(p_identifier));
  v_user public.app_users%rowtype;
  v_token text := p_token;
begin
  if v_identifier is null or v_identifier = '' then
    raise exception 'Username is required';
  end if;

  select *
  into v_user
  from public.app_users u
  where u.username = v_identifier
  limit 1;

  if not found or v_user.id is null then
    raise exception 'Invalid username or password';
  end if;
  if v_user.password_hash <> p_password_hash then
    raise exception 'Invalid username or password';
  end if;
  if v_token is null or length(v_token) < 32 then
    raise exception 'Session token is invalid';
  end if;

  insert into public.app_sessions (token, user_id)
  values (v_token, v_user.id);

  update public.app_users
  set last_login_at = now(),
      updated_at = now()
  where id = v_user.id;

  user_id := v_user.id;
  token := v_token;
  display_name := v_user.display_name;
  username := v_user.username;
  return next;
end;
$$;

create or replace function public.app_password_salt(p_identifier text)
returns table (password_salt text)
language sql
security definer
set search_path = public
as $$
  select u.password_salt
  from public.app_users u
  where u.username = lower(trim(p_identifier))
  limit 1;
$$;

create or replace function public.app_logout(p_token text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.app_sessions s where s.token = p_token;
$$;

create or replace function public.app_current_user(p_token text)
returns table (user_id uuid, display_name text, username text)
language sql
security definer
set search_path = public
as $$
  select u.id, u.display_name, u.username
  from public.app_sessions s
  join public.app_users u on u.id = s.user_id
  where s.token = p_token
    and s.expires_at > now();
$$;

create or replace function public.app_profile_get(p_token text)
returns table (
  user_id uuid,
  display_name text,
  sex text,
  birth_date date,
  height_cm numeric,
  activity_level text,
  calorie_goal_kcal integer
)
language sql
security definer
set search_path = public
as $$
  select p.user_id, p.display_name, p.sex, p.birth_date, p.height_cm, p.activity_level, p.calorie_goal_kcal
  from public.app_sessions s
  join public.user_profiles p on p.user_id = s.user_id
  where s.token = p_token
    and s.expires_at > now();
$$;

create or replace function public.app_profile_save(
  p_token text,
  p_display_name text,
  p_sex text,
  p_birth_date date,
  p_height_cm numeric,
  p_activity_level text,
  p_calorie_goal_kcal integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  select s.user_id into v_user_id
  from public.app_sessions s
  where s.token = p_token
    and s.expires_at > now();

  if v_user_id is null then
    raise exception 'Not signed in';
  end if;

  insert into public.user_profiles (
    user_id, display_name, sex, birth_date, height_cm, activity_level, calorie_goal_kcal
  )
  values (
    v_user_id, p_display_name, p_sex, p_birth_date, p_height_cm, p_activity_level, p_calorie_goal_kcal
  )
  on conflict (user_id) do update
    set display_name = excluded.display_name,
        sex = excluded.sex,
        birth_date = excluded.birth_date,
        height_cm = excluded.height_cm,
        activity_level = excluded.activity_level,
        calorie_goal_kcal = excluded.calorie_goal_kcal,
        updated_at = now();

  update public.app_users
  set display_name = coalesce(nullif(trim(p_display_name), ''), display_name),
      updated_at = now()
  where id = v_user_id;
end;
$$;

create or replace function public.app_food_list(p_token text)
returns setof public.food_logs
language sql
security definer
set search_path = public
as $$
  select f.*
  from public.app_sessions s
  join public.food_logs f on f.user_id = s.user_id
  where s.token = p_token
    and s.expires_at > now()
  order by f.logged_at desc;
$$;

create or replace function public.app_food_add(
  p_token text,
  p_food_name text,
  p_grams numeric,
  p_calories_kcal numeric,
  p_protein_g numeric,
  p_carbs_g numeric,
  p_fat_g numeric,
  p_source_label text,
  p_per_100_kcal numeric
)
returns setof public.food_logs
language sql
security definer
set search_path = public
as $$
  insert into public.food_logs (
    user_id, food_name, grams, calories_kcal, protein_g, carbs_g, fat_g, source_label, per_100_kcal
  )
  select
    s.user_id,
    p_food_name,
    p_grams,
    p_calories_kcal,
    p_protein_g,
    p_carbs_g,
    p_fat_g,
    coalesce(p_source_label, 'default'),
    p_per_100_kcal
  from public.app_sessions s
  where s.token = p_token
    and s.expires_at > now()
  returning *;
$$;

create or replace function public.app_food_delete(p_token text, p_id bigint)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.food_logs f
  using public.app_sessions s
  where s.token = p_token
    and s.expires_at > now()
    and s.user_id = f.user_id
    and f.id = p_id;
$$;

create or replace function public.app_custom_food_list(p_token text)
returns setof public.food_items
language sql
security definer
set search_path = public
as $$
  select f.*
  from public.app_sessions s
  join public.food_items f on f.owner_user_id = s.user_id
  where s.token = p_token
    and s.expires_at > now()
  order by f.created_at desc;
$$;

create or replace function public.app_custom_food_save(
  p_token text,
  p_name text,
  p_calories_kcal numeric
)
returns setof public.food_items
language sql
security definer
set search_path = public
as $$
  insert into public.food_items (
    owner_user_id, name, category, serving_grams, calories_kcal, protein_g, carbs_g, fat_g
  )
  select
    s.user_id,
    trim(p_name),
    '我的自定义摄入',
    1,
    p_calories_kcal,
    0,
    0,
    0
  from public.app_sessions s
  where s.token = p_token
    and s.expires_at > now()
    and nullif(trim(p_name), '') is not null
    and p_calories_kcal > 0
  returning *;
$$;

create or replace function public.app_custom_food_delete(p_token text, p_id bigint)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.food_items f
  using public.app_sessions s
  where s.token = p_token
    and s.expires_at > now()
    and s.user_id = f.owner_user_id
    and f.id = p_id;
$$;

create or replace function public.app_exercise_list(p_token text)
returns setof public.exercise_logs
language sql
security definer
set search_path = public
as $$
  select e.*
  from public.app_sessions s
  join public.exercise_logs e on e.user_id = s.user_id
  where s.token = p_token
    and s.expires_at > now()
  order by e.logged_at desc;
$$;

create or replace function public.app_exercise_add(
  p_token text,
  p_activity_id text,
  p_activity_name text,
  p_category text,
  p_intensity text,
  p_met numeric,
  p_duration_min integer,
  p_calories_kcal numeric,
  p_weight_kg numeric
)
returns setof public.exercise_logs
language sql
security definer
set search_path = public
as $$
  insert into public.exercise_logs (
    user_id, activity_id, activity_name, category, intensity, met, duration_min, calories_kcal, weight_kg
  )
  select
    s.user_id,
    p_activity_id,
    p_activity_name,
    p_category,
    p_intensity,
    p_met,
    p_duration_min,
    p_calories_kcal,
    p_weight_kg
  from public.app_sessions s
  where s.token = p_token
    and s.expires_at > now()
  returning *;
$$;

create or replace function public.app_exercise_delete(p_token text, p_id bigint)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.exercise_logs e
  using public.app_sessions s
  where s.token = p_token
    and s.expires_at > now()
    and s.user_id = e.user_id
    and e.id = p_id;
$$;

create or replace function public.app_custom_exercise_list(p_token text)
returns setof public.exercise_items
language sql
security definer
set search_path = public
as $$
  select e.*
  from public.app_sessions s
  join public.exercise_items e on e.owner_user_id = s.user_id
  where s.token = p_token
    and s.expires_at > now()
  order by e.created_at desc;
$$;

create or replace function public.app_custom_exercise_save(
  p_token text,
  p_activity_name text,
  p_calories_kcal numeric
)
returns setof public.exercise_items
language sql
security definer
set search_path = public
as $$
  insert into public.exercise_items (
    owner_user_id, activity_name, category, intensity, met, calories_30min_70kg
  )
  select
    s.user_id,
    trim(p_activity_name),
    '自定义',
    '自定义',
    1,
    p_calories_kcal
  from public.app_sessions s
  where s.token = p_token
    and s.expires_at > now()
    and nullif(trim(p_activity_name), '') is not null
    and p_calories_kcal > 0
  returning *;
$$;

create or replace function public.app_custom_exercise_delete(p_token text, p_id bigint)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.exercise_items e
  using public.app_sessions s
  where s.token = p_token
    and s.expires_at > now()
    and s.user_id = e.owner_user_id
    and e.id = p_id;
$$;

create or replace function public.app_weight_list(p_token text)
returns table (logged_on date, weight_kg numeric, created_at timestamptz)
language sql
security definer
set search_path = public
as $$
  select w.logged_on, w.weight_kg, w.created_at
  from public.app_sessions s
  join public.weight_logs w on w.user_id = s.user_id
  where s.token = p_token
    and s.expires_at > now()
  order by w.logged_on desc, w.created_at desc, w.id desc
  limit 12;
$$;

create or replace function public.app_weight_save(
  p_token text,
  p_weight_kg numeric,
  p_logged_on date default current_date
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.weight_logs (user_id, logged_on, weight_kg)
  select s.user_id, coalesce(p_logged_on, current_date), p_weight_kg
  from public.app_sessions s
  where s.token = p_token
    and s.expires_at > now();
$$;

create or replace function public.app_target_get(
  p_token text,
  p_target_on date default current_date
)
returns table (calories_kcal integer, protein_g numeric, fat_g numeric, carbs_g numeric)
language sql
security definer
set search_path = public
as $$
  select t.calories_kcal, t.protein_g, t.fat_g, t.carbs_g
  from public.app_sessions s
  join public.daily_targets t on t.user_id = s.user_id
  where s.token = p_token
    and s.expires_at > now()
    and t.target_on = coalesce(p_target_on, current_date);
$$;

create or replace function public.app_target_list(
  p_token text,
  p_date_from date,
  p_date_to date
)
returns table (
  target_on date,
  calories_kcal integer,
  protein_g numeric,
  fat_g numeric,
  carbs_g numeric
)
language sql
security definer
set search_path = public
as $$
  select t.target_on, t.calories_kcal, t.protein_g, t.fat_g, t.carbs_g
  from public.app_sessions s
  join public.daily_targets t on t.user_id = s.user_id
  where s.token = p_token
    and s.expires_at > now()
    and t.target_on between p_date_from and p_date_to
  order by t.target_on asc;
$$;

create or replace function public.app_target_save(
  p_token text,
  p_target_on date,
  p_calories_kcal integer,
  p_protein_g numeric,
  p_fat_g numeric,
  p_carbs_g numeric
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.daily_targets (user_id, target_on, calories_kcal, protein_g, fat_g, carbs_g)
  select
    s.user_id,
    coalesce(p_target_on, current_date),
    p_calories_kcal,
    p_protein_g,
    p_fat_g,
    p_carbs_g
  from public.app_sessions s
  where s.token = p_token
    and s.expires_at > now()
  on conflict (user_id, target_on) do update
    set calories_kcal = excluded.calories_kcal,
        protein_g = excluded.protein_g,
        fat_g = excluded.fat_g,
        carbs_g = excluded.carbs_g;
$$;

notify pgrst, 'reload schema';

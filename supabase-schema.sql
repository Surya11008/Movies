create table if not exists public.movie_admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.movie_admins enable row level security;

create or replace function public.is_movie_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.movie_admins
    where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_movie_admin() from public;
grant execute on function public.is_movie_admin() to anon, authenticated;

drop policy if exists "Admins can view their own admin record" on public.movie_admins;
create policy "Admins can view their own admin record"
  on public.movie_admins
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create table if not exists public.movies (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 120),
  year integer not null check (year between 1888 and 2100),
  genre text not null check (char_length(genre) between 1 and 40),
  language text not null default 'English' check (char_length(language) between 1 and 40),
  duration text not null default '',
  rating numeric(3, 1) not null default 0 check (rating between 0 and 10),
  description text not null default '' check (char_length(description) <= 2000),
  poster_url text not null default '',
  video_url text not null default '',
  created_at timestamptz not null default now(),
  unique (title, year)
);

alter table public.movies enable row level security;

drop policy if exists "Anyone can view movies" on public.movies;
create policy "Anyone can view movies"
  on public.movies
  for select
  to anon, authenticated
  using (true);

drop policy if exists "Admins can add movies" on public.movies;
create policy "Admins can add movies"
  on public.movies
  for insert
  to authenticated
  with check ((select public.is_movie_admin()));

drop policy if exists "Admins can edit movies" on public.movies;
create policy "Admins can edit movies"
  on public.movies
  for update
  to authenticated
  using ((select public.is_movie_admin()))
  with check ((select public.is_movie_admin()));

drop policy if exists "Admins can delete movies" on public.movies;
create policy "Admins can delete movies"
  on public.movies
  for delete
  to authenticated
  using ((select public.is_movie_admin()));

grant select on public.movies to anon, authenticated;
grant insert, update, delete on public.movies to authenticated;
grant select on public.movie_admins to authenticated;

insert into public.movies (title, year, genre, language, duration, rating, description, poster_url, video_url)
values
  ('The Grand Budapest Hotel', 2014, 'Comedy', 'English', '1h 39m', 8.1, 'A charming tale of friendship and adventure following a legendary hotel concierge and his young protégé.', 'https://images.unsplash.com/photo-1478720568477-152d9b164e26?auto=format&fit=crop&w=600&q=80', ''),
  ('Into the Wild', 2007, 'Drama', 'English', '2h 28m', 8.0, 'A moving true story of a young man who ventures into the wilderness in search of himself.', 'https://images.unsplash.com/photo-1472396961693-142e6e269027?auto=format&fit=crop&w=600&q=80', ''),
  ('Midnight in Paris', 2011, 'Romance', 'English', '1h 34m', 7.7, 'A writer''s magical Parisian adventure takes him each night into the enchanting world of the past.', 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?auto=format&fit=crop&w=600&q=80', ''),
  ('Interstellar', 2014, 'Sci-Fi', 'English', '2h 49m', 8.7, 'A father''s epic journey through space to save humanity — a story about love, time, and hope.', 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=600&q=80', ''),
  ('The Secret Life of Walter Mitty', 2013, 'Adventure', 'English', '1h 54m', 7.3, 'A daydreaming office worker embarks on the greatest real-life adventure of his life.', 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=600&q=80', ''),
  ('La La Land', 2016, 'Musical', 'English', '2h 8m', 8.0, 'Two ambitious artists fall in love while chasing their dreams in the colorful city of Los Angeles.', 'https://images.unsplash.com/photo-1519608487953-e999c86e7455?auto=format&fit=crop&w=600&q=80', ''),
  ('The Shawshank Redemption', 1994, 'Drama', 'English', '2h 22m', 9.3, 'An unforgettable story of friendship, resilience, and the hope that carries us through.', 'https://images.unsplash.com/photo-1511497584788-876760111969?auto=format&fit=crop&w=600&q=80', ''),
  ('Amélie', 2001, 'Romance', 'French', '2h 2m', 8.3, 'A whimsical tale of a young woman bringing small joys into the lives of people around her in Paris.', 'https://images.unsplash.com/photo-1490730141103-6cac27aaab94?auto=format&fit=crop&w=600&q=80', ''),
  ('The Martian', 2015, 'Sci-Fi', 'English', '2h 24m', 8.0, 'An astronaut stranded alone on Mars uses ingenuity and determination to survive against the odds.', 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=600&q=80', ''),
  ('Life of Pi', 2012, 'Adventure', 'English', '2h 7m', 7.9, 'A visually stunning survival story about a young man and a tiger adrift in the ocean.', 'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=600&q=80', '')
on conflict (title, year) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'movie-posters',
  'movie-posters',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/avif']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Anyone can view movie posters" on storage.objects;
create policy "Anyone can view movie posters"
  on storage.objects
  for select
  to anon, authenticated
  using (bucket_id = 'movie-posters');

drop policy if exists "Admins can upload movie posters" on storage.objects;
create policy "Admins can upload movie posters"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'movie-posters'
    and (select public.is_movie_admin())
  );

drop policy if exists "Admins can update movie posters" on storage.objects;
create policy "Admins can update movie posters"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'movie-posters'
    and (select public.is_movie_admin())
  )
  with check (
    bucket_id = 'movie-posters'
    and (select public.is_movie_admin())
  );

drop policy if exists "Admins can delete movie posters" on storage.objects;
create policy "Admins can delete movie posters"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'movie-posters'
    and (select public.is_movie_admin())
  );

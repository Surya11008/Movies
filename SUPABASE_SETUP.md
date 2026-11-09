# Chitra admin setup

The public movie catalog and admin tools use Supabase. Movie edits are shared with all visitors. Poster uploads are limited to 5 MB per image; add trailers or videos by embedding a YouTube/Vimeo link or a direct MP4/WebM link that you have permission to use. This site embeds videos; it does not host full-length video files.

## 1. Supabase project connection

The Project URL and publishable key for your project are already configured in `supabase-config.js`. These browser keys are public identifiers, not admin secrets. Never put a `service_role` or secret key in this website.

## 2. Create the tables and storage policies

Open your project's **SQL Editor**, paste the contents of `supabase-schema.sql`, and run it. This creates the database tables, public movie read policies, admin-only edit policies, poster storage, and the initial demo movies. Until this step is complete, the site continues to show its demo catalog.

## 3. Create and authorize your admin account

In **Authentication → Settings**, turn off public sign-ups. In **Authentication → Users**, add a user with your email and a strong password. Then run the following in the SQL Editor, replacing the email with that user's email:

```sql
insert into public.movie_admins (user_id)
select id from auth.users where email = 'you@example.com'
on conflict (user_id) do nothing;
```

Only users added to `movie_admins` can edit the catalog or upload posters. Do not enable a public sign-up form or share your admin password.

## 4. Publish and manage movies

Commit and push `index.html`, `supabase-config.js`, and `supabase-schema.sql` to the GitHub Pages repository. Open the site and choose **Admin** to sign in. Add a poster image URL or upload an image; paste an authorized YouTube/Vimeo embed link or a direct MP4/WebM link to show a video in the movie details.

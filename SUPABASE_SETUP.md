# Chitra admin setup

The public movie catalog and admin tools use Supabase. Movie edits are shared with all visitors. Poster uploads are limited to 5 MB per image; add trailers or videos by embedding a YouTube/Vimeo link or a direct MP4/WebM link that you have permission to use. This site embeds videos; it does not host full-length video files.

## 1. Create a Supabase project

Create a project in the Supabase dashboard. In **Project Settings → API**, copy the Project URL and the publishable key (or legacy `anon` key). These browser keys are public identifiers, not admin secrets.

Edit `supabase-config.js` and set:

```js
window.CHITRA_SUPABASE_URL = "https://YOUR_PROJECT.supabase.co";
window.CHITRA_SUPABASE_ANON_KEY = "YOUR_PUBLISHABLE_OR_ANON_KEY";
```

Never put a `service_role` or secret key in this website.

## 2. Create the tables and storage policies

In the Supabase dashboard, open **SQL Editor**, paste the contents of `supabase-schema.sql`, and run it.

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

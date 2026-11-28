# Supabase security audit findings — 2026-11-28

Source: user-exported read-only Supabase audit CSV. This is a review of the exported snapshot, not a live connection. No SQL changes were executed.

## Confirmed findings

### 1. Account-closure fields are not present
The exported `public.profiles` columns are: `id`, `role`, `display_name`, `username`, `bio`, `avatar_url`, `created_at`, `discipline`.
There is no `account_status` or `closed_at`. The proposed account-closure migration has therefore not been applied in the database snapshot.

### 2. Current creator write policies do not check account status
The exported policies for `wall_posts` and `wall_post_media` authorize INSERT/UPDATE/DELETE mainly by checking `creator_id = auth.uid()`. Since no account-status field exists, these policies cannot enforce the planned closed-account restriction.

### 3. Storage read policy appears broader than its name
The policy on `storage.objects` named `Anyone can view public post media files` checks the bucket id and whether an entry exists in `wall_post_media` with `m.media_url = objects.name`. It does not join to `wall_posts` or check `visibility = PUBLIC` (or an already-published scheduled post). If `media_url` stores the object path, this may allow anonymous reads of media attached to private posts. Verify the stored path format and replace this policy with one that checks the parent post's public visibility before changing it.

### 4. Extra table privileges are granted
The export shows `TRUNCATE`, `TRIGGER`, and `REFERENCES` privileges for `anon` and/or `authenticated` on several public tables. These are not needed by the browser app's normal CRUD flows. Review effective grants and revoke unnecessary privileges, especially `TRUNCATE`, from API roles. Do not apply a blanket revoke until default privileges and required app operations have been checked.

### 5. Existing policies and trigger
- `on_auth_user_created` exists on `auth.users`, AFTER INSERT, calling `handle_new_user()`.
- Policies exist for `profiles`, `wall_posts`, `wall_post_media`, `wall_post_interactions`, and `storage.objects`.
- Bucket `wall media` is private and has a 50 MiB file-size limit.

## Important limits of this export

- It does not report whether RLS is enabled or forced on each table.
- It does not include function definitions (including `handle_new_user()`).
- It does not show effective inherited/schema-level privileges or default privileges.
- It does not inspect actual media_url values or prove that a private file is currently readable.
- It is a point-in-time export; it is not a live connection.

## Safe next checks

1. Query `pg_class.relrowsecurity` and `relforcerowsecurity` for the four public tables and `storage.objects`.
2. Inspect `handle_new_user()` definition and grants on relevant schemas/functions.
3. Inspect sample `wall_post_media.media_url` values (paths only; no personal data) and compare with `storage.objects.name`.
4. Test anonymous access to a private-post media object in a controlled test post.
5. Review and prepare narrowly scoped changes for storage visibility and account-status enforcement.
6. Only after review, apply migrations in a controlled sequence and retest public media, private posts, profile editing, creator uploads, likes, and saved posts.

## Safety status

No production SQL was run by this audit. No profiles, posts, media, storage objects, or auth users were modified or deleted.

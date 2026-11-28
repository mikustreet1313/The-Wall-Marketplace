# Supabase security audit findings — 2026-11-28

Source: user-exported read-only Supabase audit CSVs. This is a review of exported snapshots, not a live connection. No SQL changes were executed.

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

### 5. RLS status
The separate RLS-status export confirms RLS is enabled on `profiles`, `wall_posts`, `wall_post_media`, `wall_post_interactions`, and `storage.objects`. `relforcerowsecurity` is false for all five. This is not automatically a vulnerability; FORCE RLS has separate effects and should not be enabled blindly.

### 6. Registration trigger and function
- `on_auth_user_created` exists on `auth.users`, AFTER INSERT, calling `public.handle_new_user()`.
- The exported function definition shows `SECURITY DEFINER` enabled and `search_path = ''`.
- The function uses schema-qualified references (`public.profiles`, `public.user_role`) and inserts the new user's id, display name, role and discipline.
- It assigns `CREATOR` only when the submitted metadata role is exactly CREATOR (case-insensitive); otherwise it assigns `CUSTOMER`. It does not assign ADMIN from metadata.
- The owner is `postgres`; the exported explicit ACL (`proacl`) is NULL.
- The effective privilege check reports EXECUTE = true for `anon`, `authenticated`, `postgres`, `service_role`, and `supabase_auth_admin`.
- A NULL ACL is consistent with PostgreSQL's default function ACL, which commonly grants EXECUTE to PUBLIC. The effective-privilege result confirms the listed roles can execute, but the CSV did not independently show the exact grant source.
- A proposed, narrow hardening script has been added at `docs/PROPOSED_RESTRICT_HANDLE_NEW_USER_EXECUTE.sql`. It revokes only EXECUTE from PUBLIC, keeps the function owner intact, includes pre/post checks, and does not drop or recreate the existing trigger. It has NOT been executed. After applying, test registration with a new test account and verify profile creation; if `supabase_auth_admin` still has EXECUTE, inspect direct grants/membership rather than revoking blindly.

## Important limits of these exports

- They do not show effective inherited/schema-level privileges or default privileges.
- They do not inspect actual `media_url` values or prove that a private file is currently readable.
- They do not show all ACL paths and role memberships.
- They are point-in-time exports; they are not a live connection.

## Safe next checks

1. Inspect ACL entries for `handle_new_user()` and role memberships if any role retains EXECUTE after the proposed PUBLIC revoke.
2. Apply the proposed function hardening only after review, then test a new test-account registration.
3. Inspect sample `wall_post_media.media_url` values (paths only; no personal data) and compare with `storage.objects.name`.
4. Test anonymous access to a private-post media object in a controlled test post.
5. Review and prepare narrowly scoped changes for storage visibility and account-status enforcement.
6. Review effective grants and default privileges before revoking unnecessary API-role privileges.
7. Only after review, apply migrations in a controlled sequence and retest public media, private posts, profile editing, creator uploads, likes, and saved posts.

## Safety status

No production SQL was run by this audit. No profiles, posts, media, storage objects, or auth users were modified or deleted.

# Supabase Database & Storage Setup for Secure File Vault

Run the following SQL in your Supabase project's **SQL Editor** (`>_` in the left sidebar):

```sql
-- 1. Create table for encrypted files metadata
CREATE TABLE IF NOT EXISTS public.vault_files (
  file_id BIGINT PRIMARY KEY,
  user_id BIGINT,
  original_filename TEXT NOT NULL,
  encrypted_filename TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  upload_date BIGINT NOT NULL,
  sha TEXT,
  storage_path TEXT,
  tries INT DEFAULT 0
);

-- 2. Create table for users
CREATE TABLE IF NOT EXISTS public.vault_users (
  user_id BIGINT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  salt TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  created BIGINT NOT NULL
);

-- 3. Create table for tamper-evident activity logs
CREATE TABLE IF NOT EXISTS public.vault_audit_logs (
  id BIGSERIAL PRIMARY KEY,
  log_id BIGINT,
  user_id BIGINT,
  username TEXT,
  action TEXT NOT NULL,
  timestamp BIGINT NOT NULL,
  prev_hash TEXT,
  hash TEXT
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.vault_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_audit_logs ENABLE ROW LEVEL SECURITY;

-- 5. Open access policies for client-side encrypted vault operations
DROP POLICY IF EXISTS "Public access to vault_files" ON public.vault_files;
CREATE POLICY "Public access to vault_files" ON public.vault_files FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access to vault_users" ON public.vault_users;
CREATE POLICY "Public access to vault_users" ON public.vault_users FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access to vault_audit_logs" ON public.vault_audit_logs;
CREATE POLICY "Public access to vault_audit_logs" ON public.vault_audit_logs FOR ALL USING (true) WITH CHECK (true);

-- 6. Create the Storage Bucket for encrypted files
INSERT INTO storage.buckets (id, name, public)
VALUES ('vault-files', 'vault-files', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 7. Storage bucket policies for client uploads and downloads
DROP POLICY IF EXISTS "Allow public uploads to vault-files" ON storage.objects;
CREATE POLICY "Allow public uploads to vault-files"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'vault-files');

DROP POLICY IF EXISTS "Allow public downloads from vault-files" ON storage.objects;
CREATE POLICY "Allow public downloads from vault-files"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'vault-files');

DROP POLICY IF EXISTS "Allow public deletions from vault-files" ON storage.objects;
CREATE POLICY "Allow public deletions from vault-files"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'vault-files');
```

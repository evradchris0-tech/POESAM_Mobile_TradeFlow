-- ============================================================
-- TRADEFLOW AFRICA — CRÉATION DES BUCKETS SUPABASE STORAGE
-- À exécuter dans le SQL Editor Supabase (service role)
-- ============================================================

-- ── 1. BUCKETS ───────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  -- Avatars : public (affiché partout sans token)
  ('avatars',
   'avatars',
   true,
   5242880,   -- 5 Mo
   ARRAY['image/jpeg','image/png','image/webp']),

  -- Documents KYC : privé (sensibles)
  ('kyc-documents',
   'kyc-documents',
   false,
   10485760,  -- 10 Mo
   ARRAY['image/jpeg','image/png','image/webp','image/heic','application/pdf']),

  -- Documents transactionnels : privé
  ('transaction-docs',
   'transaction-docs',
   false,
   10485760,  -- 10 Mo
   ARRAY['image/jpeg','image/png','image/webp','image/heic','application/pdf'])

ON CONFLICT (id) DO UPDATE SET
  public             = EXCLUDED.public,
  file_size_limit    = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;


-- ── 2. RLS POLICIES — AVATARS (lecture publique) ─────────────

CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_owner_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "avatars_owner_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
  );


-- ── 3. RLS POLICIES — KYC-DOCUMENTS (propriétaire seul) ──────
-- Chemin attendu : {user_id}/{doc_type}_{timestamp}.jpg
-- (storage.foldername(name))[1] = premier segment du chemin = user_id

CREATE POLICY "kyc_owner_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc_owner_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc_owner_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );


-- ── 4. RLS POLICIES — TRANSACTION-DOCS (vendeur + acheteur) ──
-- Chemin attendu : {user_id}/{transaction_id}/{type}_{timestamp}.jpg
-- Le premier segment est le user_id de l'uploader.
-- La lecture est autorisée si l'utilisateur est le vendeur OU l'acheteur
-- de la transaction (vérifié via sous-requête).

CREATE POLICY "txdocs_owner_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'transaction-docs'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "txdocs_parties_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'transaction-docs'
    AND (
      -- Uploader (premier segment = son user_id)
      (storage.foldername(name))[1] = auth.uid()::text
      OR
      -- Acheteur de la transaction (deuxième segment = transaction_id)
      EXISTS (
        SELECT 1 FROM public.transactions t
        WHERE t.id = (storage.foldername(name))[2]::uuid
          AND t.buyer_id = auth.uid()
      )
    )
  );

CREATE POLICY "txdocs_owner_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'transaction-docs'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );


-- ── 5. VÉRIFICATION ──────────────────────────────────────────
SELECT id, name, public, file_size_limit
FROM storage.buckets
WHERE id IN ('avatars', 'kyc-documents', 'transaction-docs');

-- Résultat attendu :
--   id                | name              | public | file_size_limit
--   avatars           | avatars           | true   | 5242880
--   kyc-documents     | kyc-documents     | false  | 10485760
--   transaction-docs  | transaction-docs  | false  | 10485760

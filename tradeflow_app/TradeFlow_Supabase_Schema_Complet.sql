-- ============================================================
-- TRADEFLOW AFRICA — SCHÉMA SUPABASE COMPLET
-- Version 2.0 — Architecture Souveraine POESAM 2026
-- Équipe LA RUCHE
-- ============================================================
-- ORDRE D'EXÉCUTION :
-- 1. Extensions
-- 2. Types ENUM
-- 3. Tables principales
-- 4. Tables transactionnelles
-- 5. Tables RAG & données commerciales
-- 6. Fonctions & Triggers
-- 7. Row Level Security (RLS)
-- 8. Indexes
-- 9. Seed data démo
-- ============================================================
  
-- ============================================================
-- PARTIE 1 — EXTENSIONS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";          -- pgvector pour le RAG
-- CREATE EXTENSION IF NOT EXISTS "pg_cron";          -- DESACTIVE pour Supabase Free

-- ============================================================
-- PARTIE 2 — TYPES ENUM
-- ============================================================

CREATE TYPE user_role AS ENUM (
  'pme',          -- PME exportatrice camerounaise
  'buyer',        -- Acheteur/Importateur dans pays cible
  'agent',        -- Agent de coopérative (apporteur d'affaires)
  'admin',        -- Équipe LA RUCHE
  'institutional' -- GUCE, CCIMA, MINCOMMERCE (lecture seule)
);

CREATE TYPE kyc_status AS ENUM (
  'pending',      -- Dossier soumis, en attente de validation
  'basic',        -- KYC léger validé (Orange Money + ID) — accès Market Intelligence
  'verified',     -- KYC complet validé (RCCM + ID + Selfie) — accès escrow
  'premium',      -- KYC renforcé — escrow illimité
  'rejected',     -- Dossier rejeté
  'suspended'     -- Compte suspendu (fraude détectée)
);

CREATE TYPE transaction_status AS ENUM (
  'pending',         -- Créée, paiement en attente
  'escrowed',        -- Fonds déposés chez banque PAPSS
  'shipped',         -- Vendeur a expédié, docs uploadés
  'in_transit',      -- Cargaison en route
  'delivered',       -- Livraison confirmée par acheteur
  'releasing',       -- Libération des fonds en cours
  'completed',       -- Transaction finalisée, fonds libérés
  'disputed',        -- Litige ouvert
  'cancelled',       -- Annulée avant escrow
  'refunded'         -- Remboursé à l'acheteur
);

CREATE TYPE corridor AS ENUM (
  'CMR-CIV',  -- Cameroun → Côte d'Ivoire
  'CMR-SEN',  -- Cameroun → Sénégal
  'CMR-GAB',  -- Cameroun → Gabon
  'CMR-COG',  -- Cameroun → Congo
  'CMR-TCD',  -- Cameroun → Tchad
  'CMR-NGA',  -- Cameroun → Nigeria
  'CMR-MAR',  -- Cameroun → Maroc
  'CMR-KEN',  -- Cameroun → Kenya
  'OTHER'     -- Autre corridor
);

CREATE TYPE document_type AS ENUM (
  'rccm',               -- Registre du Commerce
  'nif',                -- Numéro Identifiant Fiscal
  'national_id',        -- Pièce d'identité nationale
  'passport',           -- Passeport
  'selfie',             -- Photo selfie KYC
  'certificate_origin', -- Certificat d'origine CEMAC
  'phytosanitary',      -- Certificat phytosanitaire MINADER
  'commercial_invoice', -- Facture commerciale
  'packing_list',       -- Liste de colisage
  'bill_of_lading',     -- Connaissement / Bon de livraison
  'dipe',               -- Déclaration d'Intention Préalable d'Exportation
  'guce_declaration',   -- Déclaration GUCE
  'other'
);

CREATE TYPE obstacle_type AS ENUM (
  'missing_document',   -- Document manquant
  'excessive_delay',    -- Délai excessif
  'informal_fees',      -- Frais informels
  'customs_block',      -- Blocage douanier
  'transport_issue',    -- Problème transport
  'payment_issue',      -- Problème paiement
  'quality_rejection',  -- Rejet qualité
  'other'
);

CREATE TYPE rag_domain AS ENUM (
  'customs',        -- Douanes et tarifs
  'exchange',       -- Réglementation des changes BEAC
  'trade',          -- Commerce international
  'phytosanitary',  -- Normes phytosanitaires
  'certifications', -- Certifications et labels
  'transport',      -- Transport et logistique
  'other'
);

CREATE TYPE notification_channel AS ENUM (
  'sms',       -- Orange SMS API
  'whatsapp',  -- WhatsApp Business Cloud API
  'email',     -- Email via Resend
  'push',      -- Push notification app
  'in_app'     -- Notification in-app
);

CREATE TYPE plan_type AS ENUM (
  'free',        -- 3 mises en relation/mois, sans escrow
  'pro',         -- 25 000 FCFA/mois, illimité
  'enterprise',  -- Coopératives, tarif négocié
  'institutional'-- GUCE, CCIMA, accès B2G
);

-- ============================================================
-- PARTIE 3 — TABLES PRINCIPALES (USERS & PROFILS)
-- ============================================================

-- Extension de auth.users (géré par Supabase Auth)
CREATE TABLE profiles (
  id              UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  role            user_role NOT NULL DEFAULT 'pme',
  full_name       TEXT NOT NULL,
  phone           TEXT UNIQUE NOT NULL,         -- Numéro Orange Money principal
  phone_verified  BOOLEAN DEFAULT FALSE,
  country         CHAR(2) NOT NULL DEFAULT 'CM', -- ISO 3166-1 alpha-2
  city            TEXT,
  kyc_status      kyc_status NOT NULL DEFAULT 'pending',
  trust_score     INTEGER DEFAULT 0 CHECK (trust_score BETWEEN 0 AND 100),
  escrow_limit    BIGINT DEFAULT 500000,         -- Plafond escrow en FCFA
  plan            plan_type DEFAULT 'free',
  plan_expires_at TIMESTAMPTZ,
  language        TEXT DEFAULT 'fr',
  avatar_url      TEXT,                          -- Supabase Storage URL
  is_active       BOOLEAN DEFAULT TRUE,
  last_login_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Profil détaillé PME Exportatrice
CREATE TABLE pme_profiles (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  business_name        TEXT NOT NULL,
  rccm                 TEXT UNIQUE,               -- Ex: RC/BFM/2020/B/1234
  nif                  TEXT,                      -- Numéro Identifiant Fiscal
  sector               TEXT,                      -- agro-alimentaire, manufactures...
  production_capacity  TEXT,                      -- "5 tonnes/mois" (texte libre)
  certifications       TEXT[],                    -- ['EUDR', 'BIO', 'ISO22000']
  export_experience    INTEGER DEFAULT 0,          -- Années d'expérience export
  location_lat         DECIMAL(10,8),
  location_lng         DECIMAL(11,8),
  region               TEXT,                      -- Région administrative Cameroun
  city                 TEXT,
  address              TEXT,
  website              TEXT,
  description          TEXT,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- Profil Acheteur/Importateur
CREATE TABLE buyer_profiles (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  company_name         TEXT NOT NULL,
  registration_number  TEXT,                      -- Numéro d'enregistrement local
  sector               TEXT,
  annual_import_volume BIGINT,                    -- Volume d'import annuel en FCFA
  products_wanted      TEXT[],                    -- Codes SH ou descriptions
  preferred_origins    CHAR(2)[],                 -- Pays d'origine préférés
  location_lat         DECIMAL(10,8),
  location_lng         DECIMAL(11,8),
  city                 TEXT,
  country              CHAR(2),
  website              TEXT,
  notes                TEXT,
  created_at           TIMESTAMPTZ DEFAULT NOW(),
  updated_at           TIMESTAMPTZ DEFAULT NOW()
);

-- Agent de Coopérative (apporteur d'affaires, payé à la transaction)
CREATE TABLE agent_profiles (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  cooperative_name  TEXT NOT NULL,
  region            TEXT,
  pme_count         INTEGER DEFAULT 0,           -- Nombre de PME gérées
  commission_rate   DECIMAL(5,4) DEFAULT 0.005,  -- 0.5% de la transaction par défaut
  total_earnings    BIGINT DEFAULT 0,             -- Total commissions gagnées (FCFA)
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- Lien agent → PMEs sous sa responsabilité
CREATE TABLE agent_pme_links (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id   UUID REFERENCES agent_profiles(id) ON DELETE CASCADE,
  pme_id     UUID REFERENCES pme_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (agent_id, pme_id)
);

-- Documents KYC uploadés
CREATE TABLE kyc_documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  doc_type        document_type NOT NULL,
  storage_path    TEXT NOT NULL,                 -- Chemin Supabase Storage
  file_name       TEXT,
  file_size       INTEGER,                       -- Bytes
  mime_type       TEXT,
  is_verified     BOOLEAN DEFAULT FALSE,
  verified_by     UUID REFERENCES profiles(id), -- Admin qui a validé
  verified_at     TIMESTAMPTZ,
  rejection_note  TEXT,                          -- Motif de rejet si applicable
  expires_at      DATE,                          -- Date d'expiration du document
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Abonnements PME Pro
CREATE TABLE subscriptions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  plan          plan_type NOT NULL DEFAULT 'free',
  status        TEXT DEFAULT 'active' CHECK (status IN ('active','expired','cancelled','paused')),
  price_fcfa    INTEGER DEFAULT 25000,
  om_reference  TEXT,                            -- Référence Orange Money du paiement
  billing_day   INTEGER DEFAULT 1,               -- Jour du mois de facturation
  starts_at     TIMESTAMPTZ DEFAULT NOW(),
  ends_at       TIMESTAMPTZ,
  auto_renew    BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PARTIE 4 — TABLES CATALOGUE PRODUITS
-- ============================================================

CREATE TABLE products (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pme_id           UUID REFERENCES pme_profiles(id) ON DELETE CASCADE NOT NULL,
  name             TEXT NOT NULL,
  sh_code          TEXT,                          -- Code SH douanier (ex: 0803.10)
  sh_description   TEXT,                          -- Description officielle du code SH
  description      TEXT,
  category         TEXT,                          -- agro-alimentaire, épices, huiles...
  unit             TEXT NOT NULL DEFAULT 'kg',    -- kg, tonne, litre, unite
  min_quantity     DECIMAL,
  max_quantity     DECIMAL,
  price_fcfa       DECIMAL,                        -- Prix indicatif en FCFA
  price_negotiable BOOLEAN DEFAULT TRUE,
  photos           TEXT[],                         -- URLs Supabase Storage
  certifications   TEXT[],                         -- Certifications spécifiques au produit
  available_from   DATE,
  available_until  DATE,
  origin_region    TEXT,                           -- Région de production
  is_active        BOOLEAN DEFAULT TRUE,
  views_count      INTEGER DEFAULT 0,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PARTIE 5 — TABLES MARKET INTELLIGENCE
-- ============================================================

-- Résultats du moteur de matching IA
CREATE TABLE matches (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pme_id            UUID REFERENCES pme_profiles(id) ON DELETE CASCADE NOT NULL,
  product_id        UUID REFERENCES products(id),
  sh_code           TEXT,
  target_country    CHAR(2) NOT NULL,
  corridor          corridor NOT NULL,
  opportunity_score INTEGER CHECK (opportunity_score BETWEEN 0 AND 100),
  buyers_list       JSONB,                    -- [{name, contact, import_vol, score, verified}]
  price_range       JSONB,                    -- {min, max, avg, currency, source, date}
  agl_quote         JSONB,                    -- {route, days, cost_fcfa, service_type}
  ai_reasoning      TEXT,                     -- Explication du score par Claude
  data_sources      TEXT[],                   -- ['ITC_TradeMap', 'UN_Comtrade', 'INS_CMR']
  is_active         BOOLEAN DEFAULT TRUE,
  expires_at        TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days',
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- Données de prix par corridor (historique)
CREATE TABLE price_data (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sh_code      TEXT NOT NULL,
  corridor     corridor NOT NULL,
  price_fcfa   DECIMAL NOT NULL,
  unit         TEXT DEFAULT 'kg',
  volume       DECIMAL,                       -- Volume échangé associé à ce prix
  source       TEXT NOT NULL,                 -- 'transaction', 'itc_trademap', 'afreximbank', 'field_report'
  transaction_id UUID,                        -- Lien vers la transaction source si applicable
  recorded_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Données commerciales ITC TradeMap (importées mensuellement)
CREATE TABLE trade_data (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_iso    CHAR(2) NOT NULL,           -- Pays exportateur (CM)
  partner_iso     CHAR(2) NOT NULL,           -- Pays importateur (CI, SN, GA...)
  sh_code         TEXT NOT NULL,
  sh_description  TEXT,
  trade_value_usd DECIMAL,                    -- Valeur en USD (source ITC)
  trade_value_fcfa DECIMAL,                   -- Valeur convertie en FCFA
  quantity        DECIMAL,
  unit            TEXT,
  year            INTEGER NOT NULL,
  month           INTEGER,                    -- NULL = données annuelles
  source          TEXT DEFAULT 'ITC_TradeMap',
  imported_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (reporter_iso, partner_iso, sh_code, year, month)
);

-- Signalements terrain des agents (données en temps réel)
CREATE TABLE field_reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id        UUID REFERENCES profiles(id),
  pme_id          UUID REFERENCES pme_profiles(id),
  corridor        corridor NOT NULL,
  report_type     obstacle_type NOT NULL,
  description     TEXT NOT NULL,
  sh_code         TEXT,                       -- Produit concerné
  price_observed  DECIMAL,                    -- Prix observé sur le terrain
  delay_days      INTEGER,                    -- Délai observé en jours
  location        TEXT,                       -- Poste frontière, port, etc.
  severity        INTEGER DEFAULT 3 CHECK (severity BETWEEN 1 AND 5),
  is_verified     BOOLEAN DEFAULT FALSE,
  verified_by     UUID REFERENCES profiles(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Prix des matières premières (World Bank Pink Sheet + FAO)
CREATE TABLE commodity_prices (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  commodity    TEXT NOT NULL,                 -- 'Cocoa', 'Palm Oil', 'Coffee Robusta'...
  price_usd    DECIMAL,
  price_fcfa   DECIMAL,
  unit         TEXT,                          -- '$/tonne', '$/litre'
  source       TEXT,                          -- 'World_Bank_Pink_Sheet', 'FAO_FAOSTAT'
  period_year  INTEGER NOT NULL,
  period_month INTEGER,
  recorded_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (commodity, period_year, period_month, source)
);

-- ============================================================
-- PARTIE 6 — TABLES TRANSACTIONNELLES (ESCROW)
-- ============================================================

CREATE TABLE transactions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Parties
  seller_id        UUID REFERENCES profiles(id) NOT NULL,
  buyer_id         UUID REFERENCES profiles(id) NOT NULL,
  agent_id         UUID REFERENCES profiles(id),            -- Agent apporteur (optionnel)
  product_id       UUID REFERENCES products(id),

  -- Produit & corridor
  corridor         corridor NOT NULL,
  product_name     TEXT NOT NULL,
  product_emoji    TEXT DEFAULT '📦',
  sh_code          TEXT,
  quantity         DECIMAL NOT NULL,
  unit             TEXT NOT NULL DEFAULT 'kg',
  unit_price_fcfa  DECIMAL NOT NULL,

  -- Financier
  total_fcfa        DECIMAL NOT NULL,
  commission_fcfa   DECIMAL,                               -- 1.5% de total_fcfa
  agent_commission  DECIMAL,                               -- Commission agent (si applicable)
  transport_cost    DECIMAL,                               -- Devis AGL
  customs_duty      DECIMAL DEFAULT 0,                     -- Droits de douane applicables
  total_buyer_pays  DECIMAL,                               -- total + commission + transport

  -- Statut
  status            transaction_status DEFAULT 'pending',
  risk_score        INTEGER CHECK (risk_score BETWEEN 0 AND 100),
  risk_flags        JSONB,                                  -- [{flag, severity, details}]

  -- Escrow & Paiement
  escrow_bank        TEXT,                                  -- 'Ecobank_PAPSS' | 'UBA_PAPSS'
  escrow_account_ref TEXT,                                  -- Référence compte séquestre
  papss_reference    TEXT,                                  -- Référence PAPSS
  om_seller_reference TEXT,                                 -- Référence Orange Money vendeur
  om_buyer_reference  TEXT,                                 -- Référence Orange Money acheteur
  payment_proof_url   TEXT,                                 -- Preuve de paiement

  -- Logistique
  agl_tracking       TEXT,                                  -- Numéro tracking AGL
  agl_route          TEXT,                                  -- Route descriptive
  transport_days     INTEGER,
  shipping_docs      TEXT[],                                -- URLs docs transport Supabase Storage
  border_crossing    TEXT,                                  -- Poste frontière utilisé

  -- Documents
  customs_docs       JSONB,                                 -- [{type, url, status, verified_at}]

  -- Litige
  dispute_reason     TEXT,
  dispute_opened_by  UUID REFERENCES profiles(id),
  dispute_opened_at  TIMESTAMPTZ,
  dispute_resolved_at TIMESTAMPTZ,
  dispute_resolution  TEXT,

  -- Timestamps cycle de vie
  escrowed_at      TIMESTAMPTZ,
  shipped_at       TIMESTAMPTZ,
  delivered_at     TIMESTAMPTZ,
  completed_at     TIMESTAMPTZ,
  cancelled_at     TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Historique des changements de statut (audit trail)
CREATE TABLE transaction_events (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id   UUID REFERENCES transactions(id) ON DELETE CASCADE NOT NULL,
  from_status      transaction_status,
  to_status        transaction_status NOT NULL,
  triggered_by     UUID REFERENCES profiles(id),           -- Admin ou système
  is_automated     BOOLEAN DEFAULT FALSE,
  note             TEXT,
  metadata         JSONB,                                   -- Données additionnelles
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Messages de litige (thread de communication)
CREATE TABLE dispute_messages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id   UUID REFERENCES transactions(id) ON DELETE CASCADE NOT NULL,
  sender_id        UUID REFERENCES profiles(id) NOT NULL,
  content          TEXT NOT NULL,
  attachments      TEXT[],                                  -- URLs preuves
  is_admin_note    BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PARTIE 7 — TABLE RAG (CUSTOMS NAVIGATOR)
-- ============================================================

CREATE TABLE documents_rag (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content      TEXT NOT NULL,                              -- Chunk de texte officiel
  embedding    vector(1536),                               -- OpenAI text-embedding-3-small
  source       TEXT NOT NULL,                              -- 'JO_CMR_2025_01_15.pdf'
  source_url   TEXT,                                       -- URL officielle du document
  article_ref  TEXT,                                       -- 'Article 47, Loi Finances 2025'
  country      CHAR(2) NOT NULL DEFAULT 'CM',
  domain       rag_domain DEFAULT 'customs',
  pub_date     DATE,
  is_active    BOOLEAN DEFAULT TRUE,
  chunk_index  INTEGER,                                    -- Position du chunk dans le doc
  total_chunks INTEGER,                                    -- Nb total de chunks du doc
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Historique des interrogations RAG (pour monitoring qualité)
CREATE TABLE rag_queries (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID REFERENCES profiles(id),
  question         TEXT NOT NULL,
  product          TEXT,
  corridor         corridor,
  answer           TEXT,
  chunks_retrieved INTEGER DEFAULT 0,
  confidence_score DECIMAL(4,3),                          -- 0.000 à 1.000
  sources_cited    TEXT[],                                -- ['JO_CMR_2025.pdf Art.47']
  user_feedback    INTEGER CHECK (user_feedback IN (-1, 0, 1)), -- -1 négatif / 0 neutre / 1 positif
  feedback_note    TEXT,
  response_time_ms INTEGER,
  channel          TEXT DEFAULT 'app',                    -- 'app' | 'whatsapp' | 'api'
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PARTIE 8 — TABLES NOTIFICATIONS & ALERTES
-- ============================================================

CREATE TABLE notifications (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  channel          notification_channel NOT NULL,
  title            TEXT,
  body             TEXT NOT NULL,
  transaction_id   UUID REFERENCES transactions(id),
  is_read          BOOLEAN DEFAULT FALSE,
  is_sent          BOOLEAN DEFAULT FALSE,
  sent_at          TIMESTAMPTZ,
  delivery_status  TEXT,                                  -- 'delivered' | 'failed' | 'pending'
  external_ref     TEXT,                                  -- Référence provider SMS/WA
  metadata         JSONB,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE fraud_alerts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id   UUID REFERENCES transactions(id),
  user_id          UUID REFERENCES profiles(id),
  alert_type       TEXT NOT NULL,                         -- 'new_account_high_value', 'pattern_anomaly'...
  risk_score       INTEGER,
  flags            JSONB,                                 -- [{signal, weight, description}]
  is_resolved      BOOLEAN DEFAULT FALSE,
  resolved_by      UUID REFERENCES profiles(id),
  resolved_at      TIMESTAMPTZ,
  resolution_note  TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PARTIE 9 — TABLES INSTITUTIONNELLES (B2G)
-- ============================================================

-- Taux de change (BEAC quotidien)
CREATE TABLE exchange_rates (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_currency CHAR(3) NOT NULL,                        -- XAF, XOF, USD, EUR
  to_currency   CHAR(3) NOT NULL,
  rate          DECIMAL(18,6) NOT NULL,
  source        TEXT DEFAULT 'BEAC',
  recorded_date DATE NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (from_currency, to_currency, recorded_date)
);

-- Cache des rapports B2G (évite de recalculer à chaque requête)
CREATE TABLE report_cache (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type      TEXT NOT NULL,                        -- 'corridor_stats', 'barriers', 'monthly'
  corridor         corridor,
  period_start     DATE,
  period_end       DATE,
  payload          JSONB NOT NULL,                       -- Données agrégées du rapport
  generated_at     TIMESTAMPTZ DEFAULT NOW(),
  expires_at       TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours'
);

-- Partenaires institutionnels avec accès B2G
CREATE TABLE institutional_partners (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  organization  TEXT NOT NULL,                           -- 'GUCE', 'CCIMA', 'MINCOMMERCE'
  country       CHAR(2) DEFAULT 'CM',
  contact_email TEXT,
  access_level  TEXT DEFAULT 'readonly',                 -- 'readonly' | 'reports' | 'full'
  corridors_access corridor[],                           -- Corridors auxquels ils ont accès
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PARTIE 10 — FONCTION MATCH_DOCUMENTS (RAG Retrieval)
-- ============================================================

CREATE OR REPLACE FUNCTION match_documents(
  query_embedding  vector(1536),
  match_threshold  FLOAT DEFAULT 0.75,
  match_count      INT DEFAULT 5,
  filter_country   CHAR(2) DEFAULT NULL,
  filter_domain    rag_domain DEFAULT NULL
)
RETURNS TABLE (
  id           UUID,
  content      TEXT,
  source       TEXT,
  article_ref  TEXT,
  country      CHAR(2),
  domain       rag_domain,
  pub_date     DATE,
  similarity   FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    d.content,
    d.source,
    d.article_ref,
    d.country,
    d.domain,
    d.pub_date,
    1 - (d.embedding <=> query_embedding) AS similarity
  FROM documents_rag d
  WHERE
    d.is_active = TRUE
    AND (filter_country IS NULL OR d.country = filter_country)
    AND (filter_domain IS NULL OR d.domain = filter_domain)
    AND 1 - (d.embedding <=> query_embedding) > match_threshold
  ORDER BY d.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- ============================================================
-- PARTIE 11 — FONCTION TRUST SCORE
-- ============================================================

CREATE OR REPLACE FUNCTION compute_trust_score(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_score           INTEGER := 0;
  v_tx_completed    INTEGER := 0;
  v_tx_disputed     INTEGER := 0;
  v_delivery_rate   DECIMAL := 0;
  v_avg_delay       DECIMAL := 0;
  v_account_days    INTEGER := 0;
  v_kyc_bonus       INTEGER := 0;
  v_kyc_level       kyc_status;
BEGIN
  -- Nombre de transactions complétées
  SELECT COUNT(*) INTO v_tx_completed
  FROM transactions
  WHERE seller_id = p_user_id AND status = 'completed';

  -- Nombre de litiges ouverts
  SELECT COUNT(*) INTO v_tx_disputed
  FROM transactions
  WHERE seller_id = p_user_id AND status = 'disputed';

  -- Taux de livraison (ratio complétées / (complétées + disputées))
  IF (v_tx_completed + v_tx_disputed) > 0 THEN
    v_delivery_rate := v_tx_completed::DECIMAL / (v_tx_completed + v_tx_disputed);
  END IF;

  -- Délai moyen de livraison (jours entre shipped_at et delivered_at)
  SELECT COALESCE(AVG(EXTRACT(DAY FROM (delivered_at - shipped_at))), 0)
  INTO v_avg_delay
  FROM transactions
  WHERE seller_id = p_user_id
    AND status IN ('delivered', 'completed')
    AND shipped_at IS NOT NULL
    AND delivered_at IS NOT NULL;

  -- Ancienneté du compte (jours)
  SELECT EXTRACT(DAY FROM NOW() - created_at)::INTEGER
  INTO v_account_days
  FROM profiles WHERE id = p_user_id;

  -- Niveau KYC
  SELECT kyc_status INTO v_kyc_level FROM profiles WHERE id = p_user_id;
  v_kyc_bonus := CASE v_kyc_level
    WHEN 'basic'   THEN 5
    WHEN 'verified' THEN 15
    WHEN 'premium' THEN 25
    ELSE 0
  END;

  -- Calcul du score total (max 100)
  v_score :=
    LEAST(v_tx_completed * 8, 40)          -- Max 40 pts (5 tx = 40 pts)
    + ROUND(v_delivery_rate * 25)           -- Max 25 pts (100% livraison = 25 pts)
    + LEAST(v_account_days / 10, 10)        -- Max 10 pts (100 jours = 10 pts)
    + v_kyc_bonus                           -- Max 25 pts selon KYC
    - (v_tx_disputed * 15);                 -- -15 pts par litige

  -- Clamp entre 0 et 100
  v_score := GREATEST(0, LEAST(100, v_score));

  RETURN v_score;
END;
$$;

-- Trigger pour recalculer le Trust Score après chaque transaction complétée
CREATE OR REPLACE FUNCTION trigger_update_trust_score()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status IN ('completed', 'disputed', 'cancelled') AND
     (OLD.status IS NULL OR OLD.status != NEW.status) THEN
    UPDATE profiles
    SET
      trust_score = compute_trust_score(NEW.seller_id),
      updated_at  = NOW()
    WHERE id = NEW.seller_id;

    -- Mettre à jour l'escrow_limit selon le Trust Score
    UPDATE profiles SET
      escrow_limit = CASE
        WHEN compute_trust_score(NEW.seller_id) >= 80 THEN 10000000  -- 10M FCFA
        WHEN compute_trust_score(NEW.seller_id) >= 60 THEN 5000000   -- 5M FCFA
        WHEN compute_trust_score(NEW.seller_id) >= 40 THEN 2000000   -- 2M FCFA
        WHEN compute_trust_score(NEW.seller_id) >= 20 THEN 1000000   -- 1M FCFA
        ELSE 500000                                                    -- 500K FCFA
      END
    WHERE id = NEW.seller_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER after_transaction_status_change
  AFTER UPDATE OF status ON transactions
  FOR EACH ROW EXECUTE FUNCTION trigger_update_trust_score();

-- Trigger updated_at automatique sur toutes les tables
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_pme_updated_at
  BEFORE UPDATE ON pme_profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_transactions_updated_at
  BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_subscriptions_updated_at
  BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Trigger audit trail sur chaque changement de statut transaction
CREATE OR REPLACE FUNCTION log_transaction_event()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO transaction_events (
      transaction_id, from_status, to_status, is_automated
    ) VALUES (
      NEW.id, OLD.status, NEW.status, TRUE
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_transaction_event_log
  AFTER UPDATE OF status ON transactions
  FOR EACH ROW EXECUTE FUNCTION log_transaction_event();

-- Trigger création profil après inscription Supabase Auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, phone, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Utilisateur'),
    COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone', ''),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'pme')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- PARTIE 12 — ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pme_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE buyer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_pme_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents_rag ENABLE ROW LEVEL SECURITY;
ALTER TABLE rag_queries ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE fraud_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE field_reports ENABLE ROW LEVEL SECURITY;

-- Helper function : rôle de l'utilisateur courant
CREATE OR REPLACE FUNCTION current_user_role()
RETURNS user_role LANGUAGE sql STABLE AS $$
  SELECT role FROM profiles WHERE id = auth.uid()
$$;

-- Helper function : is_admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
$$;

-- ── profiles ─────────────────────────────────────────────────
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (id = auth.uid() OR is_admin());

CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_select_public_info" ON profiles
  FOR SELECT USING (TRUE);  -- Le nom et le Trust Score sont publics pour le matching

-- ── pme_profiles ─────────────────────────────────────────────
CREATE POLICY "pme_select_own" ON pme_profiles
  FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "pme_select_public" ON pme_profiles
  FOR SELECT USING (TRUE);  -- Profils PME visibles pour les acheteurs (matching)

CREATE POLICY "pme_insert_own" ON pme_profiles
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "pme_update_own" ON pme_profiles
  FOR UPDATE USING (user_id = auth.uid());

-- ── buyer_profiles ────────────────────────────────────────────
CREATE POLICY "buyer_select_own" ON buyer_profiles
  FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "buyer_insert_own" ON buyer_profiles
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "buyer_update_own" ON buyer_profiles
  FOR UPDATE USING (user_id = auth.uid());

-- ── kyc_documents ─────────────────────────────────────────────
CREATE POLICY "kyc_select_own" ON kyc_documents
  FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "kyc_insert_own" ON kyc_documents
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "kyc_admin_update" ON kyc_documents
  FOR UPDATE USING (is_admin());

-- ── products ──────────────────────────────────────────────────
CREATE POLICY "products_select_all" ON products
  FOR SELECT USING (is_active = TRUE OR is_admin());

CREATE POLICY "products_insert_own" ON products
  FOR INSERT WITH CHECK (
    pme_id IN (SELECT id FROM pme_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "products_update_own" ON products
  FOR UPDATE USING (
    pme_id IN (SELECT id FROM pme_profiles WHERE user_id = auth.uid())
    OR is_admin()
  );

-- ── matches ───────────────────────────────────────────────────
CREATE POLICY "matches_select_own" ON matches
  FOR SELECT USING (
    pme_id IN (SELECT id FROM pme_profiles WHERE user_id = auth.uid())
    OR is_admin()
  );

CREATE POLICY "matches_insert_system" ON matches
  FOR INSERT WITH CHECK (is_admin());  -- Seulement via Edge Functions (service role)

-- ── transactions ─────────────────────────────────────────────
CREATE POLICY "tx_select_parties" ON transactions
  FOR SELECT USING (
    seller_id = auth.uid()
    OR buyer_id = auth.uid()
    OR agent_id = auth.uid()
    OR is_admin()
  );

CREATE POLICY "tx_insert_seller" ON transactions
  FOR INSERT WITH CHECK (seller_id = auth.uid());

CREATE POLICY "tx_update_parties" ON transactions
  FOR UPDATE USING (
    seller_id = auth.uid()
    OR buyer_id = auth.uid()
    OR is_admin()
  );

-- ── transaction_events ────────────────────────────────────────
CREATE POLICY "events_select_parties" ON transaction_events
  FOR SELECT USING (
    transaction_id IN (
      SELECT id FROM transactions
      WHERE seller_id = auth.uid()
         OR buyer_id = auth.uid()
         OR is_admin()
    )
  );

-- ── dispute_messages ─────────────────────────────────────────
CREATE POLICY "dispute_select_parties" ON dispute_messages
  FOR SELECT USING (
    transaction_id IN (
      SELECT id FROM transactions
      WHERE seller_id = auth.uid()
         OR buyer_id = auth.uid()
         OR is_admin()
    )
  );

CREATE POLICY "dispute_insert_parties" ON dispute_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND transaction_id IN (
      SELECT id FROM transactions
      WHERE seller_id = auth.uid() OR buyer_id = auth.uid()
    )
  );

-- ── documents_rag (lecture publique, écriture admin) ──────────
CREATE POLICY "rag_select_all" ON documents_rag
  FOR SELECT USING (is_active = TRUE);

CREATE POLICY "rag_admin_manage" ON documents_rag
  FOR ALL USING (is_admin());

-- ── rag_queries ───────────────────────────────────────────────
CREATE POLICY "rag_queries_own" ON rag_queries
  FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "rag_queries_insert_own" ON rag_queries
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- ── notifications ─────────────────────────────────────────────
CREATE POLICY "notif_select_own" ON notifications
  FOR SELECT USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "notif_update_read" ON notifications
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ── fraud_alerts (admin seulement) ───────────────────────────
CREATE POLICY "fraud_admin_only" ON fraud_alerts
  FOR ALL USING (is_admin());

-- ── price_data (lecture publique authentifiée) ────────────────
CREATE POLICY "price_select_authenticated" ON price_data
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ── field_reports ─────────────────────────────────────────────
CREATE POLICY "field_select_authenticated" ON field_reports
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "field_insert_agent" ON field_reports
  FOR INSERT WITH CHECK (
    agent_id = auth.uid()
    AND current_user_role() IN ('agent', 'pme', 'admin')
  );

-- ============================================================
-- PARTIE 13 — INDEX (performances)
-- ============================================================

-- Profils
CREATE INDEX idx_profiles_phone ON profiles(phone);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_kyc ON profiles(kyc_status);
CREATE INDEX idx_profiles_trust ON profiles(trust_score DESC);

-- PME
CREATE INDEX idx_pme_user ON pme_profiles(user_id);
CREATE INDEX idx_pme_rccm ON pme_profiles(rccm);

-- Produits
CREATE INDEX idx_products_pme ON products(pme_id);
CREATE INDEX idx_products_sh ON products(sh_code);
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = TRUE;

-- Transactions
CREATE INDEX idx_tx_seller ON transactions(seller_id);
CREATE INDEX idx_tx_buyer ON transactions(buyer_id);
CREATE INDEX idx_tx_status ON transactions(status);
CREATE INDEX idx_tx_corridor ON transactions(corridor);
CREATE INDEX idx_tx_created ON transactions(created_at DESC);
CREATE INDEX idx_tx_sh_code ON transactions(sh_code);

-- Trade data (Market Intelligence)
CREATE INDEX idx_trade_reporter ON trade_data(reporter_iso, partner_iso);
CREATE INDEX idx_trade_sh ON trade_data(sh_code);
CREATE INDEX idx_trade_period ON trade_data(year, month);

-- Price data
CREATE INDEX idx_price_corridor ON price_data(corridor, sh_code);
CREATE INDEX idx_price_date ON price_data(recorded_at DESC);

-- RAG
CREATE INDEX idx_rag_country ON documents_rag(country);
CREATE INDEX idx_rag_domain ON documents_rag(domain);
CREATE INDEX idx_rag_active ON documents_rag(is_active) WHERE is_active = TRUE;
-- Index IVFFlat pour la recherche vectorielle rapide
CREATE INDEX idx_rag_embedding ON documents_rag
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- RAG queries (monitoring)
CREATE INDEX idx_rag_queries_user ON rag_queries(user_id);
CREATE INDEX idx_rag_queries_date ON rag_queries(created_at DESC);

-- Notifications
CREATE INDEX idx_notif_user ON notifications(user_id, is_read);
CREATE INDEX idx_notif_pending ON notifications(is_sent) WHERE is_sent = FALSE;

-- Matches
CREATE INDEX idx_matches_pme ON matches(pme_id);
CREATE INDEX idx_matches_corridor ON matches(corridor);
CREATE INDEX idx_matches_score ON matches(opportunity_score DESC);

-- ============================================================
-- PARTIE 14 — SEED DATA (données démo POESAM)
-- ============================================================

-- Note : les UUID des users auth doivent être créés via Supabase Auth d'abord
-- Ces seeds utilisent des UUID fictifs pour la démo locale

DO $$
DECLARE
  v_jean_paul   UUID := '11111111-0001-0001-0001-000000000001';
  v_hawa        UUID := '11111111-0002-0002-0002-000000000002';
  v_albert      UUID := '11111111-0003-0003-0003-000000000003';
  v_kouadio     UUID := '22222222-0001-0001-0001-000000000001';
  v_fatou       UUID := '22222222-0002-0002-0002-000000000002';
  v_pierre      UUID := '22222222-0003-0003-0003-000000000003';
  v_admin       UUID := '33333333-0001-0001-0001-000000000001';
  v_pme1        UUID := 'aaaaaaaa-0001-0001-0001-000000000001';
  v_pme2        UUID := 'aaaaaaaa-0002-0002-0002-000000000002';
  v_pme3        UUID := 'aaaaaaaa-0003-0003-0003-000000000003';
  v_prod1       UUID := 'bbbbbbbb-0001-0001-0001-000000000001';
  v_prod2       UUID := 'bbbbbbbb-0002-0002-0002-000000000002';
  v_prod3       UUID := 'bbbbbbbb-0003-0003-0003-000000000003';
BEGIN

-- Création des utilisateurs Supabase Auth (mot de passe demo: 'demo123')
-- Le trigger on_auth_user_created créera automatiquement les profils minimaux
-- à partir de raw_user_meta_data (full_name, phone, role)
INSERT INTO auth.users (instance_id, id, aud, role, email, phone, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at) VALUES
  ('00000000-0000-0000-0000-000000000000', v_jean_paul, 'authenticated', 'authenticated', 'jeanpaul@demo.tradeflow.com', '+237650000001',  crypt('demo123', gen_salt('bf')), NOW(), '{"full_name":"Jean-Paul Mboumba","role":"pme","phone":"+237650000001"}'::jsonb,    NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', v_hawa,      'authenticated', 'authenticated', 'hawa@demo.tradeflow.com',     '+237650000002',  crypt('demo123', gen_salt('bf')), NOW(), '{"full_name":"Hawa Oumarou","role":"pme","phone":"+237650000002"}'::jsonb,         NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', v_albert,    'authenticated', 'authenticated', 'albert@demo.tradeflow.com',   '+237650000003',  crypt('demo123', gen_salt('bf')), NOW(), '{"full_name":"Albert Biya","role":"pme","phone":"+237650000003"}'::jsonb,          NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', v_kouadio,   'authenticated', 'authenticated', 'kouadio@demo.tradeflow.com',  '+2250700000001', crypt('demo123', gen_salt('bf')), NOW(), '{"full_name":"Kouadio Marc","role":"buyer","phone":"+2250700000001"}'::jsonb,      NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', v_fatou,     'authenticated', 'authenticated', 'fatou@demo.tradeflow.com',    '+2210700000002', crypt('demo123', gen_salt('bf')), NOW(), '{"full_name":"Fatou Diallo","role":"buyer","phone":"+2210700000002"}'::jsonb,      NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', v_pierre,    'authenticated', 'authenticated', 'pierre@demo.tradeflow.com',   '+2410700000003', crypt('demo123', gen_salt('bf')), NOW(), '{"full_name":"Pierre Ondo","role":"buyer","phone":"+2410700000003"}'::jsonb,       NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000000', v_admin,     'authenticated', 'authenticated', 'admin@demo.tradeflow.com',    '+237690000000',  crypt('demo123', gen_salt('bf')), NOW(), '{"full_name":"Admin LA RUCHE","role":"admin","phone":"+237690000000"}'::jsonb,     NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Profils utilisateurs : UPSERT pour compléter les champs non gérés par le trigger
-- (country, city, kyc_status, trust_score, escrow_limit, plan, plan_expires_at)
INSERT INTO profiles (id, role, full_name, phone, country, city, kyc_status, trust_score, escrow_limit, plan, plan_expires_at) VALUES
  (v_jean_paul, 'pme',   'Jean-Paul Mboumba',  '+237650000001', 'CM', 'Bafoussam',  'verified', 82, 2000000,  'pro', NOW() + INTERVAL '60 days'),
  (v_hawa,      'pme',   'Hawa Oumarou',        '+237650000002', 'CM', 'Ngaoundéré', 'verified', 91, 5000000,  'pro', NOW() + INTERVAL '45 days'),
  (v_albert,    'pme',   'Albert Biya',         '+237650000003', 'CM', 'Douala',     'verified', 76, 2000000,  'pro', NOW() + INTERVAL '30 days'),
  (v_kouadio,   'buyer', 'Kouadio Marc',        '+2250700000001','CI', 'Abidjan',    'verified', 94, 10000000, 'pro', NOW() + INTERVAL '90 days'),
  (v_fatou,     'buyer', 'Fatou Diallo',        '+2210700000002','SN', 'Dakar',      'verified', 87, 5000000,  'pro', NOW() + INTERVAL '60 days'),
  (v_pierre,    'buyer', 'Pierre Ondo',         '+2410700000003','GA', 'Libreville', 'verified', 76, 5000000,  'pro', NOW() + INTERVAL '30 days'),
  (v_admin,     'admin', 'Admin LA RUCHE',      '+237690000000', 'CM', 'Yaoundé',    'premium',  100, 999999999, 'enterprise', NOW() + INTERVAL '365 days')
ON CONFLICT (id) DO UPDATE SET
  role            = EXCLUDED.role,
  full_name       = EXCLUDED.full_name,
  phone           = EXCLUDED.phone,
  country         = EXCLUDED.country,
  city            = EXCLUDED.city,
  kyc_status      = EXCLUDED.kyc_status,
  trust_score     = EXCLUDED.trust_score,
  escrow_limit    = EXCLUDED.escrow_limit,
  plan            = EXCLUDED.plan,
  plan_expires_at = EXCLUDED.plan_expires_at;

-- Profils PME détaillés
INSERT INTO pme_profiles (id, user_id, business_name, rccm, sector, production_capacity, certifications, region, city) VALUES
  (v_pme1, v_jean_paul, 'GIC Agro-Bafoussam',       'RC/BFM/2020/B/1234', 'agro-alimentaire', '5 tonnes/mois', ARRAY['MINADER_certifié'], 'Ouest',  'Bafoussam'),
  (v_pme2, v_hawa,      'Coopérative Femmes Adamawa','RC/NGD/2019/C/5678', 'épices-bio',       '2 tonnes/mois', ARRAY['BIO_CMR'],           'Adamaoua','Ngaoundéré'),
  (v_pme3, v_albert,    'Neo Processing',            'RC/DLA/2021/B/9012', 'huiles-végétales', '10 000 L/mois', ARRAY['ISO22000'],          'Littoral','Douala')
ON CONFLICT (id) DO NOTHING;

-- Profils Acheteurs
INSERT INTO buyer_profiles (user_id, company_name, sector, city, country, annual_import_volume, products_wanted) VALUES
  (v_kouadio, 'Société Commerciale Abidjan', 'distribution-alimentaire', 'Abidjan',    'CI', 150000000, ARRAY['0803.10', '1511.10']),
  (v_fatou,   'Dakar Naturel SARL',          'épices-bio',               'Dakar',      'SN', 50000000,  ARRAY['0910.11']),
  (v_pierre,  'Distrib Gabon SA',            'distribution-alimentaire', 'Libreville', 'GA', 80000000,  ARRAY['1511.10'])
ON CONFLICT (user_id) DO NOTHING;

-- Produits
INSERT INTO products (id, pme_id, name, sh_code, sh_description, unit, price_fcfa, category, certifications) VALUES
  (v_prod1, v_pme1, 'Plantain séché sous vide',  '0803.10', 'Bananes plantain, séchées', 'kg',    3100, 'fruits-séchés',  ARRAY['MINADER']),
  (v_prod2, v_pme2, 'Gingembre séché bio',        '0910.11', 'Gingembre séché',          'kg',    4800, 'épices-bio',     ARRAY['BIO_CMR']),
  (v_prod3, v_pme3, 'Huile de palme raffinée',    '1511.10', 'Huile de palme brute',     'litre', 1200, 'huiles-végétales', ARRAY['ISO22000'])
ON CONFLICT (id) DO NOTHING;

-- Transactions démo (3 corridors)
INSERT INTO transactions (
  id, seller_id, buyer_id, product_id, corridor,
  product_name, product_emoji, sh_code,
  quantity, unit, unit_price_fcfa, total_fcfa, commission_fcfa,
  transport_cost, customs_duty, total_buyer_pays,
  status, risk_score,
  escrow_bank, escrow_account_ref, papss_reference,
  agl_tracking, agl_route, transport_days,
  escrowed_at, shipped_at
) VALUES
  (
    'cccccccc-0847-0847-0847-000000000847',
    v_jean_paul, v_kouadio, v_prod1, 'CMR-CIV',
    'Plantain séché sous vide', '🌿', '0803.10',
    500, 'kg', 3100, 1550000, 23250,
    85000, 0, 1658250,
    'in_transit', 32,
    'Ecobank_PAPSS', 'ESC-2024-0847', 'PAPSS-2024-CM-CI-0847',
    'AGL-CMR-0847', 'Douala → Abidjan via corridor Eséka', 8,
    NOW() - INTERVAL '5 days', NOW() - INTERVAL '3 days'
  ),
  (
    'cccccccc-0851-0851-0851-000000000851',
    v_hawa, v_fatou, v_prod2, 'CMR-SEN',
    'Gingembre séché bio', '🌱', '0910.11',
    200, 'kg', 4800, 960000, 14400,
    62000, 0, 1036400,
    'escrowed', 18,
    'Ecobank_PAPSS', 'ESC-2024-0851', 'PAPSS-2024-CM-SN-0851',
    NULL, 'Ngaoundéré → Dakar', 12,
    NOW() - INTERVAL '1 day', NULL
  ),
  (
    'cccccccc-0863-0863-0863-000000000863',
    v_albert, v_pierre, v_prod3, 'CMR-GAB',
    'Huile de palme raffinée', '🫙', '1511.10',
    1200, 'litre', 1200, 1440000, 21600,
    48000, 0, 1509600,
    'releasing', 12,
    'UBA_PAPSS', 'ESC-2024-0863', 'PAPSS-2024-CM-GA-0863',
    'AGL-CMR-0863', 'Douala → Libreville', 5,
    NOW() - INTERVAL '8 days', NOW() - INTERVAL '6 days'
  )
ON CONFLICT (id) DO NOTHING;

-- Données de prix corridors (historique 3 mois)
INSERT INTO price_data (sh_code, corridor, price_fcfa, unit, source, recorded_at) VALUES
  -- CMR→CIV Plantain
  ('0803.10', 'CMR-CIV', 2900, 'kg', 'itc_trademap', NOW() - INTERVAL '90 days'),
  ('0803.10', 'CMR-CIV', 3000, 'kg', 'itc_trademap', NOW() - INTERVAL '60 days'),
  ('0803.10', 'CMR-CIV', 3100, 'kg', 'transaction',  NOW() - INTERVAL '5 days'),
  -- CMR→SEN Gingembre
  ('0910.11', 'CMR-SEN', 4500, 'kg', 'itc_trademap', NOW() - INTERVAL '90 days'),
  ('0910.11', 'CMR-SEN', 4700, 'kg', 'itc_trademap', NOW() - INTERVAL '60 days'),
  ('0910.11', 'CMR-SEN', 4800, 'kg', 'transaction',  NOW() - INTERVAL '1 day'),
  -- CMR→GAB Huile de palme
  ('1511.10', 'CMR-GAB', 1100, 'litre', 'itc_trademap', NOW() - INTERVAL '90 days'),
  ('1511.10', 'CMR-GAB', 1150, 'litre', 'field_report', NOW() - INTERVAL '30 days'),
  ('1511.10', 'CMR-GAB', 1200, 'litre', 'transaction',  NOW() - INTERVAL '8 days');

-- Données trade ITC (acheteurs potentiels CIV pour plantain)
INSERT INTO trade_data (reporter_iso, partner_iso, sh_code, sh_description, trade_value_fcfa, quantity, unit, year, month, source) VALUES
  ('CM', 'CI', '0803.10', 'Plantain séché', 9550000,   3000, 'kg', 2024, 1, 'ITC_TradeMap'),
  ('MA', 'CI', '0803.10', 'Plantain séché', 3200000000, 890000, 'kg', 2024, 1, 'ITC_TradeMap'),
  ('CM', 'SN', '0910.11', 'Gingembre',       320000000, 66000, 'kg', 2024, 1, 'ITC_TradeMap'),
  ('CM', 'GA', '1511.10', 'Huile de palme',  580000000, 480000, 'litre', 2024, 1, 'ITC_TradeMap');

-- Abonnements actifs
INSERT INTO subscriptions (user_id, plan, status, price_fcfa, starts_at, ends_at) VALUES
  (v_jean_paul, 'pro', 'active', 25000, NOW() - INTERVAL '15 days', NOW() + INTERVAL '60 days'),
  (v_hawa,      'pro', 'active', 25000, NOW() - INTERVAL '30 days', NOW() + INTERVAL '45 days'),
  (v_albert,    'pro', 'active', 25000, NOW() - INTERVAL '5 days',  NOW() + INTERVAL '25 days')
ON CONFLICT (user_id) DO NOTHING;

-- Résultat matching démo (acheteurs CIV pour plantain)
INSERT INTO matches (pme_id, product_id, sh_code, target_country, corridor, opportunity_score, buyers_list, price_range, agl_quote) VALUES
  (v_pme1, v_prod1, '0803.10', 'CI', 'CMR-CIV', 87,
   '[
     {"rank":1,"name":"Société Commerciale Abidjan","contact":"Kouadio Marc","phone":"+2250701234567","score":94,"import_tons_year":45,"price_min":3200,"price_max":3500,"verified":true},
     {"rank":2,"name":"Cocody Food Distribution","contact":"Aminata Coulibaly","phone":"+2250707654321","score":87,"import_tons_year":28,"price_min":2900,"price_max":3300,"verified":true},
     {"rank":3,"name":"Grands Marchés CI","contact":"Jean-Baptiste Koné","phone":"+2250712345678","score":79,"import_tons_year":15,"price_min":2800,"price_max":3100,"verified":false},
     {"rank":4,"name":"Export Ivoire Group","contact":"Mariam Traoré","phone":"+2250787654321","score":71,"import_tons_year":8,"price_min":3000,"price_max":3400,"verified":false},
     {"rank":5,"name":"Sud Vivres SARL","contact":"Adjoua Brou","phone":"+2250798765432","score":65,"import_tons_year":5,"price_min":2700,"price_max":2900,"verified":false}
   ]'::jsonb,
   '{"min":2700,"max":3500,"avg":3100,"currency":"FCFA","unit":"kg","source":"ITC_TradeMap+transactions","date":"2026-05-01"}'::jsonb,
   '{"route":"Douala → Abidjan","days":8,"cost_fcfa":85000,"service":"route","provider":"AGL"}'::jsonb);

-- Taux de change BEAC (parité fixe XAF/XOF)
INSERT INTO exchange_rates (from_currency, to_currency, rate, source, recorded_date) VALUES
  ('XAF', 'XOF', 1.000000, 'BEAC', CURRENT_DATE),
  ('XAF', 'EUR', 0.001524, 'BEAC', CURRENT_DATE),
  ('XAF', 'USD', 0.001660, 'BEAC', CURRENT_DATE),
  ('XOF', 'XAF', 1.000000, 'BCEAO', CURRENT_DATE),
  ('EUR', 'XAF', 655.957, 'BEAC', CURRENT_DATE),
  ('USD', 'XAF', 602.400, 'BEAC', CURRENT_DATE)
ON CONFLICT (from_currency, to_currency, recorded_date) DO NOTHING;

END $$;

-- ============================================================
-- PARTIE 15 — VUES UTILES (Dashboard B2G & Admin)
-- ============================================================

-- Vue agrégée des corridors pour le Dashboard Institutionnel
CREATE OR REPLACE VIEW corridor_stats AS
SELECT
  corridor,
  COUNT(*) AS total_transactions,
  COUNT(*) FILTER (WHERE status = 'completed') AS completed_transactions,
  SUM(total_fcfa) AS total_volume_fcfa,
  AVG(total_fcfa) AS avg_transaction_fcfa,
  SUM(commission_fcfa) AS total_commission_fcfa,
  MAX(created_at) AS last_transaction_at,
  COUNT(DISTINCT seller_id) AS unique_sellers,
  COUNT(DISTINCT buyer_id) AS unique_buyers,
  AVG(risk_score) AS avg_risk_score
FROM transactions
WHERE status NOT IN ('cancelled', 'refunded')
GROUP BY corridor;

-- Vue des métriques plateforme pour le Dashboard Admin
CREATE OR REPLACE VIEW platform_metrics AS
SELECT
  (SELECT COUNT(*) FROM profiles WHERE role = 'pme' AND is_active = TRUE) AS active_pme,
  (SELECT COUNT(*) FROM profiles WHERE role = 'buyer' AND is_active = TRUE) AS active_buyers,
  (SELECT COUNT(*) FROM transactions WHERE status IN ('escrowed','shipped','in_transit','delivered','releasing')) AS active_transactions,
  (SELECT COALESCE(SUM(total_fcfa), 0) FROM transactions WHERE status IN ('escrowed','shipped','in_transit','delivered','releasing')) AS total_escrow_volume_fcfa,
  (SELECT COALESCE(SUM(commission_fcfa), 0) FROM transactions WHERE status = 'completed' AND DATE_TRUNC('month', completed_at) = DATE_TRUNC('month', NOW())) AS monthly_revenue_fcfa,
  (SELECT COUNT(*) FROM profiles WHERE kyc_status = 'pending') AS kyc_pending,
  (SELECT ROUND(AVG(trust_score)) FROM profiles WHERE role = 'pme') AS avg_trust_score,
  (SELECT COUNT(*) FROM fraud_alerts WHERE is_resolved = FALSE) AS active_fraud_alerts,
  (SELECT COUNT(*) FROM profiles WHERE plan = 'pro' AND role = 'pme') AS pro_subscribers,
  (SELECT COUNT(*) FROM rag_queries WHERE created_at > NOW() - INTERVAL '30 days') AS rag_queries_month;

-- Vue obstacles non tarifaires pour le Dashboard B2G
CREATE OR REPLACE VIEW nontariff_barriers AS
SELECT
  corridor,
  report_type AS obstacle_type,
  COUNT(*) AS occurrences,
  MAX(created_at) AS last_reported,
  AVG(severity) AS avg_severity
FROM field_reports
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY corridor, report_type
ORDER BY corridor, occurrences DESC;

-- ============================================================
-- FIN DU SCHÉMA
-- ============================================================
-- POUR APPLIQUER :
--   supabase db push
-- OU dans le SQL Editor Supabase :
--   Coller et exécuter ce fichier complet
--
-- VÉRIFICATION :
--   SELECT COUNT(*) FROM profiles;         -- doit retourner 7
--   SELECT COUNT(*) FROM transactions;     -- doit retourner 3
--   SELECT COUNT(*) FROM trade_data;       -- doit retourner 4
--   SELECT * FROM platform_metrics;        -- vue globale
--   SELECT * FROM corridor_stats;          -- stats par corridor
-- ============================================================

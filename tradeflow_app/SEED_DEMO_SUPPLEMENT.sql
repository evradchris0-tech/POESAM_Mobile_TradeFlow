-- ============================================================
-- TRADEFLOW AFRICA — SEED DÉMO COMPLET (SUPPLÉMENT)
-- À exécuter dans le SQL Editor Supabase (service role)
--
-- Pré-requis : TradeFlow_Supabase_Schema_Complet.sql déjà appliqué
--   → 7 profils, 3 produits, 3 transactions existent déjà
--
-- Ce fichier ajoute :
--   • 2 produits          (→ 5 total pour GIC Agro-Bafoussam)
--   • 4 transactions      (→ 5 pour Jean-Paul avec statuts variés)
--   • 5 événements audit  (journal des transitions de statut)
--   • 5 documents KYC     (Jean-Paul entièrement vérifié)
--   • 5 notifications     (feed actif pour le pitch)
--   • 5 offres marché     (écran Marché alimenté)
-- ============================================================

DO $$
DECLARE
  -- ── UUIDs EXISTANTS (déjà dans la base) ─────────────────────
  v_jean_paul  UUID := '11111111-0001-0001-0001-000000000001';
  v_kouadio    UUID := '22222222-0001-0001-0001-000000000001'; -- buyer CIV
  v_fatou      UUID := '22222222-0002-0002-0002-000000000002'; -- buyer SEN
  v_pierre     UUID := '22222222-0003-0003-0003-000000000003'; -- buyer GAB
  v_pme1       UUID := 'aaaaaaaa-0001-0001-0001-000000000001'; -- GIC Agro-Bafoussam
  v_prod1      UUID := 'bbbbbbbb-0001-0001-0001-000000000001'; -- Plantain séché (existant)
  v_tx1        UUID := 'cccccccc-0847-0847-0847-000000000847'; -- Plantain→Kouadio in_transit

  -- ── NOUVEAUX PRODUITS ────────────────────────────────────────
  v_prod4      UUID := 'bbbbbbbb-0004-0004-0004-000000000004'; -- Cacao brut fermenté
  v_prod5      UUID := 'bbbbbbbb-0005-0005-0005-000000000005'; -- Café Arabica Bafoussam

  -- ── NOUVELLES TRANSACTIONS ───────────────────────────────────
  v_tx2        UUID := 'cccccccc-0852-0852-0852-000000000852'; -- Cacao→Kouadio  escrowed
  v_tx3        UUID := 'cccccccc-0853-0853-0853-000000000853'; -- Café→Fatou     pending
  v_tx4        UUID := 'cccccccc-0854-0854-0854-000000000854'; -- Plantain→Pierre completed
  v_tx5        UUID := 'cccccccc-0855-0855-0855-000000000855'; -- Cacao→Fatou    shipped

  -- ── ÉVÉNEMENTS AUDIT ─────────────────────────────────────────
  v_ev1        UUID := 'dddddddd-0001-0001-0001-000000000001';
  v_ev2        UUID := 'dddddddd-0002-0002-0002-000000000002';
  v_ev3        UUID := 'dddddddd-0003-0003-0003-000000000003';
  v_ev4        UUID := 'dddddddd-0004-0004-0004-000000000004';
  v_ev5        UUID := 'dddddddd-0005-0005-0005-000000000005';

  -- ── DOCUMENTS KYC ────────────────────────────────────────────
  v_kyc1       UUID := 'eeeeeeee-0001-0001-0001-000000000001';
  v_kyc2       UUID := 'eeeeeeee-0002-0002-0002-000000000002';
  v_kyc3       UUID := 'eeeeeeee-0003-0003-0003-000000000003';
  v_kyc4       UUID := 'eeeeeeee-0004-0004-0004-000000000004';
  v_kyc5       UUID := 'eeeeeeee-0005-0005-0005-000000000005';

  -- ── NOTIFICATIONS ────────────────────────────────────────────
  v_notif1     UUID := 'ffffffff-0001-0001-0001-000000000001';
  v_notif2     UUID := 'ffffffff-0002-0002-0002-000000000002';
  v_notif3     UUID := 'ffffffff-0003-0003-0003-000000000003';
  v_notif4     UUID := 'ffffffff-0004-0004-0004-000000000004';
  v_notif5     UUID := 'ffffffff-0005-0005-0005-000000000005';

  -- ── OFFRES MARCHÉ ────────────────────────────────────────────
  v_offer1     UUID := '77777777-0001-0001-0001-000000000001';
  v_offer2     UUID := '77777777-0002-0002-0002-000000000002';
  v_offer3     UUID := '77777777-0003-0003-0003-000000000003';
  v_offer4     UUID := '77777777-0004-0004-0004-000000000004';
  v_offer5     UUID := '77777777-0005-0005-0005-000000000005';

BEGIN

-- ================================================================
-- 1. PRODUITS (2 nouveaux → 5 total pour GIC Agro-Bafoussam)
-- ================================================================

INSERT INTO products (
  id, pme_id,
  name, sh_code, sh_description, description,
  category, unit,
  min_quantity, max_quantity, price_fcfa, price_negotiable,
  certifications, origin_region, is_active, views_count
) VALUES
  -- Produit 4 : Cacao brut fermenté
  (v_prod4, v_pme1,
   'Cacao brut fermenté',
   '1801.00',
   'Cacao en fèves, brut ou torréfié',
   'Fèves de cacao fermentées 7 jours, séchées au soleil. Origine Bangangté, région Ouest Cameroun. Teneur en beurre 54 %. Lot minimum 100 kg.',
   'cacao',
   'kg',
   100, 5000, 1850, true,
   ARRAY['MINADER_certifié', 'FairTrade_candidat'],
   'Ouest', true, 0),

  -- Produit 5 : Café Arabica torréfié
  (v_prod5, v_pme1,
   'Café Arabica Bafoussam',
   '0901.21',
   'Café torréfié, non décaféiné',
   'Arabica 100 % torréfié artisanalement à Bafoussam. Altitude 1 500 m. Notes de caramel et fruits rouges. Conditionné en sachets kraft 1 kg sous vide.',
   'café',
   'kg',
   50, 2000, 5200, false,
   ARRAY['MINADER_certifié', 'UTZ_certifié'],
   'Ouest', true, 0)
ON CONFLICT (id) DO NOTHING;


-- ================================================================
-- 2. TRANSACTIONS (4 nouvelles — Jean-Paul vendeur, statuts variés)
-- ================================================================

INSERT INTO transactions (
  id, seller_id, buyer_id, product_id, corridor,
  product_name, sh_code,
  quantity, unit, unit_price_fcfa, total_fcfa, commission_fcfa,
  transport_cost, customs_duty, total_buyer_pays,
  status, risk_score,
  escrow_bank, escrow_account_ref, papss_reference,
  agl_tracking, agl_route, transport_days,
  escrowed_at, shipped_at, delivered_at, completed_at
) VALUES

  -- TX2 : Cacao brut → Kouadio (Abidjan) — Escrow confirmé, expédition imminente
  (v_tx2,
   v_jean_paul, v_kouadio, v_prod4, 'CMR-CIV',
   'Cacao brut fermenté', '1801.00',
   800, 'kg', 1850, 1480000, 22200,
   92000, 0, 1594200,
   'escrowed', 28,
   'Ecobank_PAPSS', 'ESC-2024-0852', 'PAPSS-2024-CM-CI-0852',
   NULL, 'Douala → Abidjan via Eséka', 8,
   NOW() - INTERVAL '2 days', NULL, NULL, NULL),

  -- TX3 : Café Arabica → Fatou (Dakar) — En attente de paiement
  (v_tx3,
   v_jean_paul, v_fatou, v_prod5, 'CMR-SEN',
   'Café Arabica Bafoussam', '0901.21',
   300, 'kg', 5200, 1560000, 23400,
   74000, 0, 1657400,
   'pending', 15,
   NULL, NULL, NULL,
   NULL, 'Bafoussam → Dakar', 14,
   NULL, NULL, NULL, NULL),

  -- TX4 : Plantain → Pierre (Libreville) — Livraison complétée (historique)
  (v_tx4,
   v_jean_paul, v_pierre, v_prod1, 'CMR-GAB',
   'Plantain séché sous vide', '0803.10',
   400, 'kg', 3100, 1240000, 18600,
   68000, 0, 1326600,
   'completed', 10,
   'UBA_PAPSS', 'ESC-2024-0854', 'PAPSS-2024-CM-GA-0854',
   'AGL-CMR-0854', 'Douala → Libreville', 5,
   NOW() - INTERVAL '25 days',
   NOW() - INTERVAL '22 days',
   NOW() - INTERVAL '17 days',
   NOW() - INTERVAL '16 days'),

  -- TX5 : Cacao → Fatou (Dakar) — Expédié, en transit
  (v_tx5,
   v_jean_paul, v_fatou, v_prod4, 'CMR-SEN',
   'Cacao brut fermenté', '1801.00',
   600, 'kg', 1850, 1110000, 16650,
   76000, 0, 1202650,
   'shipped', 22,
   'Ecobank_PAPSS', 'ESC-2024-0855', 'PAPSS-2024-CM-SN-0855',
   'AGL-CMR-0855', 'Douala → Dakar via Ngaoundéré', 12,
   NOW() - INTERVAL '6 days',
   NOW() - INTERVAL '3 days',
   NULL, NULL)
ON CONFLICT (id) DO NOTHING;


-- ================================================================
-- 3. ÉVÉNEMENTS D'AUDIT (journal des transitions — 5 entrées)
-- ================================================================

INSERT INTO transaction_events (
  id, transaction_id,
  from_status, to_status,
  triggered_by, is_automated, note
) VALUES
  -- TX1 (Plantain) : pending → escrowed
  (v_ev1, v_tx1,
   'pending', 'escrowed',
   v_kouadio, false,
   'Paiement Orange Money confirmé via PAPSS — réf. PAPSS-2024-CM-CI-0847'),

  -- TX1 (Plantain) : escrowed → shipped
  (v_ev2, v_tx1,
   'escrowed', 'shipped',
   v_jean_paul, false,
   'Remise des 500 kg au transporteur AGL Douala — BL AGL-CMR-0847'),

  -- TX1 (Plantain) : shipped → in_transit
  (v_ev3, v_tx1,
   'shipped', 'in_transit',
   NULL, true,
   'Tracking AGL : camion au poste frontière de Noépé (CM-CI)'),

  -- TX2 (Cacao) : pending → escrowed
  (v_ev4, v_tx2,
   'pending', 'escrowed',
   v_kouadio, false,
   'Virement PAPSS reçu — fonds bloqués sur compte escrow Ecobank'),

  -- TX4 (Plantain→Libreville) : delivered → completed
  (v_ev5, v_tx4,
   'delivered', 'completed',
   v_pierre, false,
   'Pierre Ondo confirme la réception à Libreville — libération des fonds')
ON CONFLICT (id) DO NOTHING;


-- ================================================================
-- 4. DOCUMENTS KYC (Jean-Paul — profil 100 % vérifié)
-- ================================================================

INSERT INTO kyc_documents (
  id, user_id,
  doc_type, is_verified,
  storage_path, file_name, mime_type, file_size,
  created_at
) VALUES
  (v_kyc1, v_jean_paul,
   'rccm', true,
   'kyc/11111111-0001-0001-0001-000000000001/RCCM_GIC_Agro_Bafoussam_RC_BFM_2020.pdf',
   'RCCM_GIC_Agro_Bafoussam_RC_BFM_2020.pdf', 'application/pdf', 245000,
   NOW() - INTERVAL '90 days'),

  (v_kyc2, v_jean_paul,
   'nif', true,
   'kyc/11111111-0001-0001-0001-000000000001/NIF_Mboumba_Jean_Paul_P_082_4512.pdf',
   'NIF_Mboumba_Jean_Paul_P_082_4512.pdf', 'application/pdf', 180000,
   NOW() - INTERVAL '89 days'),

  (v_kyc3, v_jean_paul,
   'national_id', true,
   'kyc/11111111-0001-0001-0001-000000000001/CNI_Mboumba_JP_recto_verso.jpg',
   'CNI_Mboumba_JP_recto_verso.jpg', 'image/jpeg', 310000,
   NOW() - INTERVAL '88 days'),

  (v_kyc4, v_jean_paul,
   'selfie', true,
   'kyc/11111111-0001-0001-0001-000000000001/selfie_liveness_check.jpg',
   'selfie_liveness_check.jpg', 'image/jpeg', 420000,
   NOW() - INTERVAL '87 days'),

  (v_kyc5, v_jean_paul,
   'phytosanitary', true,
   'kyc/11111111-0001-0001-0001-000000000001/Certificat_Phytosanitaire_MINADER_CMR_CIV_0847.pdf',
   'Certificat_Phytosanitaire_MINADER_CMR_CIV_0847.pdf', 'application/pdf', 198000,
   NOW() - INTERVAL '6 days')
ON CONFLICT (id) DO NOTHING;


-- ================================================================
-- 5. NOTIFICATIONS (Jean-Paul — feed vivant pour le pitch)
-- ================================================================

INSERT INTO notifications (
  id, user_id,
  kind, title, body,
  unread, created_at
) VALUES

  -- Escrow confirmé sur le Cacao
  (v_notif1, v_jean_paul,
   'escrow',
   'Escrow confirmé — Cacao brut fermenté',
   'Kouadio Marc a verrouillé 1 480 000 FCFA via PAPSS (réf. ESC-2024-0852). Vous pouvez maintenant préparer l''expédition.',
   true,  NOW() - INTERVAL '2 days'),

  -- Mise à jour tracking Plantain
  (v_notif2, v_jean_paul,
   'transit',
   'Plantain en transit — frontière CM-CI franchie',
   'AGL-CMR-0847 : votre chargement de 500 kg a passé le poste de Noépé. Arrivée estimée à Abidjan dans 3 jours.',
   false, NOW() - INTERVAL '1 day'),

  -- Opportunité IA détectée
  (v_notif3, v_jean_paul,
   'opportunity',
   'Opportunité IA : demande +18 % en Côte d''Ivoire',
   'Le Guide IA détecte une hausse de la demande en Cacao brut à Abidjan ce mois. Prix marché observé : 2 100 FCFA/kg. Votre stock de 1 200 kg peut générer 2,52 M FCFA.',
   true,  NOW() - INTERVAL '18 hours'),

  -- Document KYC accepté
  (v_notif4, v_jean_paul,
   'doc',
   'Certificat phytosanitaire accepté par la DGDDI',
   'Votre certificat phytosanitaire CMR-CIV-0847 a été validé par la Direction Générale des Douanes de Côte d''Ivoire. Transaction TF-2024-0847 débloquée.',
   false, NOW() - INTERVAL '4 days'),

  -- Trust Score boosté
  (v_notif5, v_jean_paul,
   'system',
   'Trust Score : 82 → 90 — Exportateur Confirmé',
   'La livraison complète à Pierre Ondo (TF-2024-0854, 400 kg, Libreville) a été confirmée. Votre Trust Score passe à 90/100. Plus que 10 points pour atteindre Exportateur Premium.',
   true,  NOW() - INTERVAL '16 days')
ON CONFLICT (id) DO NOTHING;


-- ================================================================
-- 6. OFFRES MARCHÉ (5 offres actives — écran Marché de l'app)
-- ================================================================

INSERT INTO market_offers (
  id, user_id,
  product, quantity, price_target,
  is_active, created_at
) VALUES
  (v_offer1, v_kouadio,
   'Plantain',    2500, 3300,
   true, NOW() - INTERVAL '10 days'),

  (v_offer2, v_kouadio,
   'Cacao',       1200, 2100,
   true, NOW() - INTERVAL '8 days'),

  (v_offer3, v_fatou,
   'Café',         400, 5500,
   true, NOW() - INTERVAL '5 days'),

  (v_offer4, v_fatou,
   'Plantain',     800, 3100,
   true, NOW() - INTERVAL '3 days'),

  (v_offer5, v_pierre,
   'Huile de palme', 15000, 1250,
   true, NOW() - INTERVAL '7 days')
ON CONFLICT (id) DO NOTHING;


END $$;


-- ================================================================
-- VÉRIFICATION FINALE
-- ================================================================
SELECT
  'produits'           AS table_name, COUNT(*) AS total FROM products
UNION ALL SELECT
  'transactions'       AS table_name, COUNT(*) AS total FROM transactions
UNION ALL SELECT
  'transaction_events' AS table_name, COUNT(*) AS total FROM transaction_events
UNION ALL SELECT
  'kyc_documents'      AS table_name, COUNT(*) AS total FROM kyc_documents
UNION ALL SELECT
  'notifications'      AS table_name, COUNT(*) AS total FROM notifications
UNION ALL SELECT
  'market_offers'      AS table_name, COUNT(*) AS total FROM market_offers;

-- Résultat attendu :
--   produits           | 5
--   transactions       | 7   (3 existantes + 4 nouvelles)
--   transaction_events | 5
--   kyc_documents      | 5
--   notifications      | 5
--   market_offers      | 5

-- ============================================================
-- RESET DEMO POESAM — TradeFlow Africa
-- Coller dans Supabase SQL Editor avant chaque répétition.
-- Durée : ~2 secondes.
-- ============================================================

-- 1. Remettre la transaction Plantain en "En transit"
--    (efface la confirmation de réception de la répétition précédente)
UPDATE transactions
SET
  status       = 'in_transit',
  delivered_at = NULL,
  completed_at = NULL,
  updated_at   = NOW()
WHERE id = 'cccccccc-0847-0847-0847-000000000847';

-- 2. Recalculer le Trust Score de Jean-Paul
--    (le trigger ne se déclenche que sur UPDATE de status,
--     donc on force le recalcul manuellement après le reset)
UPDATE profiles
SET
  trust_score = compute_trust_score('11111111-0001-0001-0001-000000000001'),
  updated_at  = NOW()
WHERE id = '11111111-0001-0001-0001-000000000001';

-- 3. Vérification visuelle (doit afficher in_transit + 90)
SELECT
  t.status        AS statut_transaction,
  p.trust_score   AS trust_score_jean_paul
FROM transactions t
JOIN profiles p ON p.id = '11111111-0001-0001-0001-000000000001'
WHERE t.id = 'cccccccc-0847-0847-0847-000000000847';

-- Résultat attendu :
--   statut_transaction | trust_score_jean_paul
--   in_transit         | 90
--
-- Après le reset, relance l'app (hot restart R majuscule)
-- et refais le flow : Home → Plantain → Confirmer réception → Profile = 98.
-- ============================================================

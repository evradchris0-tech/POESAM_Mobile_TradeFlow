-- ==========================================
-- 🚀 TRADEFLOW AFRICA - SCHEMA V2 (SANS MOCK)
-- A exécuter dans l'éditeur SQL de Supabase
-- ==========================================

-- 1. TABLE DES NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    kind VARCHAR(50) NOT NULL, -- 'transit', 'escrow', 'opportunity', 'doc', 'system'
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    unread BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour accélérer les requêtes de l'utilisateur actif
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);

-- 2. TABLE DU MARCHÉ (OFFRES & ACHETEURS)
CREATE TABLE IF NOT EXISTS public.market_offers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    product VARCHAR(100) NOT NULL, -- ex: 'Cacao', 'Plantain'
    quantity INTEGER NOT NULL, -- Quantité requise en Tonnes
    price_target INTEGER NOT NULL, -- Prix cible par Kg en FCFA
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Autoriser la lecture via RLS (Row Level Security)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

ALTER TABLE public.market_offers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read active market offers" ON public.market_offers FOR SELECT USING (is_active = true);

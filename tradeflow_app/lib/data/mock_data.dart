import 'package:flutter/material.dart';

import '../models/buyer.dart';
import '../models/corridor.dart';
import '../models/notification_item.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';

final List<Transaction> mockTransactions = [
  const Transaction(
    id: 'TF-2024-0847',
    product: 'Plantain séché sous vide',
    emoji: '🌿',
    shCode: '0803.10',
    sellerName: 'GIC Agro-Bafoussam',
    sellerCity: 'Bafoussam',
    buyerName: 'Soc. Commerciale Abidjan',
    buyerCity: 'Abidjan',
    corridor: 'CMR→CIV',
    quantity: 500,
    unit: 'kg',
    unitPrice: 3100,
    totalAmount: 1550000,
    commission: 23250,
    transportCost: 85000,
    customsDuty: 0,
    transportDays: 8,
    transportRoute: 'Douala → Abidjan via AGL',
    opportunityScore: 87,
    status: TransactionStatus.inTransit,
    progressPercent: 0.60,
    sellerTrustScore: 82,
  ),
  const Transaction(
    id: 'TF-2024-0851',
    product: 'Gingembre séché bio',
    emoji: '🌱',
    shCode: '0910.11',
    sellerName: 'Coop. Femmes Adamawa',
    sellerCity: 'Ngaoundéré',
    buyerName: 'Dakar Naturel SARL',
    buyerCity: 'Dakar',
    corridor: 'CMR→SEN',
    quantity: 200,
    unit: 'kg',
    unitPrice: 4800,
    totalAmount: 960000,
    commission: 14400,
    transportCost: 62000,
    customsDuty: 0,
    transportDays: 12,
    transportRoute: 'Ngaoundéré → Dakar via AGL',
    opportunityScore: 73,
    status: TransactionStatus.escrowConfirmed,
    progressPercent: 0.40,
    sellerTrustScore: 91,
    isTrustVerified: true,
  ),
  const Transaction(
    id: 'TF-2024-0863',
    product: 'Huile de palme raffinée',
    emoji: '🫙',
    shCode: '1511.10',
    sellerName: 'Neo Processing',
    sellerCity: 'Douala',
    buyerName: 'Distrib Gabon SA',
    buyerCity: 'Libreville',
    corridor: 'CMR→GAB',
    quantity: 1200,
    unit: 'L',
    unitPrice: 1200,
    totalAmount: 1440000,
    commission: 21600,
    transportCost: 48000,
    customsDuty: 0,
    transportDays: 5,
    transportRoute: 'Douala → Libreville via AGL',
    opportunityScore: 91,
    status: TransactionStatus.delivered,
    progressPercent: 0.90,
    sellerTrustScore: 76,
  ),
];

final List<Buyer> mockBuyers = [
  const Buyer(
    name: 'Société Commerciale Abidjan',
    contactName: 'Kouadio Marc',
    city: 'Abidjan',
    country: 'Côte d\'Ivoire',
    score: 94,
    annualImportTons: 45,
    priceRangeMin: 3200,
    priceRangeMax: 3500,
    isVerified: true,
    initials: 'SCA',
    avatarColor: Color(0xFF185FA5),
  ),
  const Buyer(
    name: 'Cocody Food Distribution',
    contactName: 'Aminata Coulibaly',
    city: 'Abidjan',
    country: 'Côte d\'Ivoire',
    score: 87,
    annualImportTons: 28,
    priceRangeMin: 2900,
    priceRangeMax: 3300,
    isVerified: true,
    initials: 'CFD',
    avatarColor: Color(0xFF0F6E56),
  ),
  const Buyer(
    name: 'Grands Marchés CI',
    contactName: 'Jean-Baptiste Koné',
    city: 'Abidjan',
    country: 'Côte d\'Ivoire',
    score: 79,
    annualImportTons: 15,
    priceRangeMin: 2800,
    priceRangeMax: 3100,
    isVerified: false,
    initials: 'GMC',
    avatarColor: Color(0xFF854F0B),
  ),
  const Buyer(
    name: 'Export Ivoire Group',
    contactName: 'Mariam Traoré',
    city: 'Abidjan',
    country: 'Côte d\'Ivoire',
    score: 71,
    annualImportTons: 8,
    priceRangeMin: 3000,
    priceRangeMax: 3400,
    isVerified: false,
    initials: 'EIG',
    avatarColor: Color(0xFF639922),
  ),
  const Buyer(
    name: 'Sud Vivres SARL',
    contactName: 'Adjoua Brou',
    city: 'Abidjan',
    country: 'Côte d\'Ivoire',
    score: 65,
    annualImportTons: 5,
    priceRangeMin: 2700,
    priceRangeMax: 2900,
    isVerified: false,
    initials: 'SVS',
    avatarColor: Color(0xFF534AB7),
  ),
];

const UserProfile mockUser = UserProfile(
  firstName: 'Jean-Paul',
  lastName: 'Ngassam',
  company: 'Agro Export Cameroun',
  initials: 'JN',
  role: 'pme',
  plan: 'Pro',
  planExpiry: '15 juin 2026',
  trustScore: 82,
  trustLevel: 'Exportateur Confirmé',
  nextLevel: 'Exportateur Vérifié',
  levelsToNext: 3,
  transactionsSuccess: 8,
  deliveryRate: 100.0,
  avgDeliveryDays: 6.2,
  disputes: 0,
  activeCorridors: ['CMR→CIV', 'CMR→SEN', 'CMR→GAB'],
  kycDocuments: [
    KYCDoc(name: 'RCCM', status: 'Vérifié'),
    KYCDoc(name: 'NIF', status: 'Vérifié'),
    KYCDoc(name: "Pièce d'identité", status: 'Vérifié'),
    KYCDoc(name: 'Certificats (2)', status: 'Vérifié'),
  ],
);

const List<Corridor> mockCorridors = [
  Corridor(
    code: 'CMR→CIV',
    fromCountry: 'Cameroun',
    toCountry: 'Côte d\'Ivoire',
    fromCity: 'Douala',
    toCity: 'Abidjan',
    avgTransportDays: 8,
    avgTransportCost: 85000,
    dutyRate: 0.0,
  ),
  Corridor(
    code: 'CMR→SEN',
    fromCountry: 'Cameroun',
    toCountry: 'Sénégal',
    fromCity: 'Ngaoundéré',
    toCity: 'Dakar',
    avgTransportDays: 12,
    avgTransportCost: 62000,
    dutyRate: 0.0,
  ),
  Corridor(
    code: 'CMR→GAB',
    fromCountry: 'Cameroun',
    toCountry: 'Gabon',
    fromCity: 'Douala',
    toCity: 'Libreville',
    avgTransportDays: 5,
    avgTransportCost: 48000,
    dutyRate: 0.0,
  ),
];

const List<String> mockProducts = [
  'Plantain',
  'Cacao',
  'Gingembre',
  'Huile de palme',
  'Café',
];

final Map<String, List<Buyer>> mockBuyersByProduct = {
  'Plantain': mockBuyers,
  'Cacao': const [
    Buyer(
      name: 'Cocoa Processing CI',
      contactName: 'Yao Konan Bertin',
      city: 'San Pedro',
      country: 'Côte d\'Ivoire',
      score: 96,
      annualImportTons: 1200,
      priceRangeMin: 2400,
      priceRangeMax: 2900,
      isVerified: true,
      initials: 'CPC',
      avatarColor: Color(0xFF6B3F1B),
    ),
    Buyer(
      name: 'CemoaCao SARL',
      contactName: 'Aïcha Diomandé',
      city: 'Abidjan',
      country: 'Côte d\'Ivoire',
      score: 88,
      annualImportTons: 540,
      priceRangeMin: 2300,
      priceRangeMax: 2700,
      isVerified: true,
      initials: 'CMC',
      avatarColor: Color(0xFF8B5A2B),
    ),
    Buyer(
      name: 'Choco Atelier Lagos',
      contactName: 'Tunde Adeyemi',
      city: 'Lagos',
      country: 'Nigeria',
      score: 81,
      annualImportTons: 220,
      priceRangeMin: 2500,
      priceRangeMax: 2800,
      isVerified: false,
      initials: 'CAL',
      avatarColor: Color(0xFF155E3D),
    ),
    Buyer(
      name: 'Ghana Cocoa Traders',
      contactName: 'Kwame Mensah',
      city: 'Accra',
      country: 'Ghana',
      score: 74,
      annualImportTons: 130,
      priceRangeMin: 2200,
      priceRangeMax: 2500,
      isVerified: false,
      initials: 'GCT',
      avatarColor: Color(0xFF1B4D8E),
    ),
    Buyer(
      name: 'Dakar Cacao Import',
      contactName: 'Mamadou Sow',
      city: 'Dakar',
      country: 'Sénégal',
      score: 68,
      annualImportTons: 60,
      priceRangeMin: 2100,
      priceRangeMax: 2400,
      isVerified: false,
      initials: 'DCI',
      avatarColor: Color(0xFF534AB7),
    ),
  ],
  'Gingembre': const [
    Buyer(
      name: 'Dakar Naturel SARL',
      contactName: 'Fatoumata Ndiaye',
      city: 'Dakar',
      country: 'Sénégal',
      score: 91,
      annualImportTons: 35,
      priceRangeMin: 4600,
      priceRangeMax: 5100,
      isVerified: true,
      initials: 'DNS',
      avatarColor: Color(0xFF0F6E56),
    ),
    Buyer(
      name: 'Bio Sahel Distribution',
      contactName: 'Awa Diallo',
      city: 'Bamako',
      country: 'Mali',
      score: 78,
      annualImportTons: 18,
      priceRangeMin: 4400,
      priceRangeMax: 4800,
      isVerified: false,
      initials: 'BSD',
      avatarColor: Color(0xFF854F0B),
    ),
    Buyer(
      name: 'Spice Lagos Co.',
      contactName: 'Chidi Okeke',
      city: 'Lagos',
      country: 'Nigeria',
      score: 72,
      annualImportTons: 22,
      priceRangeMin: 4500,
      priceRangeMax: 4900,
      isVerified: false,
      initials: 'SLC',
      avatarColor: Color(0xFF185FA5),
    ),
  ],
  'Huile de palme': const [
    Buyer(
      name: 'Distrib Gabon SA',
      contactName: 'Yvette Mba',
      city: 'Libreville',
      country: 'Gabon',
      score: 89,
      annualImportTons: 480,
      priceRangeMin: 1100,
      priceRangeMax: 1350,
      isVerified: true,
      initials: 'DGA',
      avatarColor: Color(0xFF1B4D8E),
    ),
    Buyer(
      name: 'Brazza Foods',
      contactName: 'Patrick Loemba',
      city: 'Brazzaville',
      country: 'Congo',
      score: 82,
      annualImportTons: 260,
      priceRangeMin: 1050,
      priceRangeMax: 1300,
      isVerified: true,
      initials: 'BZF',
      avatarColor: Color(0xFF639922),
    ),
    Buyer(
      name: 'N\'Djamena Trading',
      contactName: 'Hassan Ali',
      city: 'N\'Djamena',
      country: 'Tchad',
      score: 70,
      annualImportTons: 90,
      priceRangeMin: 1000,
      priceRangeMax: 1200,
      isVerified: false,
      initials: 'NDT',
      avatarColor: Color(0xFF534AB7),
    ),
  ],
  'Café': const [
    Buyer(
      name: 'Café d\'Abidjan',
      contactName: 'Mariam Bamba',
      city: 'Abidjan',
      country: 'Côte d\'Ivoire',
      score: 90,
      annualImportTons: 75,
      priceRangeMin: 3800,
      priceRangeMax: 4200,
      isVerified: true,
      initials: 'CAB',
      avatarColor: Color(0xFF6B3F1B),
    ),
    Buyer(
      name: 'Ethiopia Beans Hub',
      contactName: 'Selam Tesfaye',
      city: 'Addis-Abeba',
      country: 'Éthiopie',
      score: 84,
      annualImportTons: 40,
      priceRangeMin: 3900,
      priceRangeMax: 4400,
      isVerified: true,
      initials: 'EBH',
      avatarColor: Color(0xFF8B5A2B),
    ),
    Buyer(
      name: 'Lomé Espresso Co.',
      contactName: 'Komla Ayité',
      city: 'Lomé',
      country: 'Togo',
      score: 71,
      annualImportTons: 15,
      priceRangeMin: 3700,
      priceRangeMax: 4000,
      isVerified: false,
      initials: 'LEC',
      avatarColor: Color(0xFF155E3D),
    ),
  ],
};

final List<NotificationItem> mockNotifications = [
  const NotificationItem(
    id: 'n1',
    kind: NotificationKind.transit,
    title: 'Cargaison CMR→CIV arrive bientôt',
    body: 'Votre cargaison #TF-2024-0847 sera livrée dans 3 jours. Préparez la confirmation de réception.',
    timeAgo: 'Il y a 12 min',
  ),
  const NotificationItem(
    id: 'n2',
    kind: NotificationKind.escrow,
    title: 'Fonds sécurisés chez Ecobank PAPSS',
    body: 'L\'escrow #TF-2024-0851 (Gingembre 200kg) a été confirmé. 974 400 FCFA bloqués.',
    timeAgo: 'Il y a 2 h',
  ),
  const NotificationItem(
    id: 'n3',
    kind: NotificationKind.opportunity,
    title: 'Nouvelle opportunité — Cacao San Pedro',
    body: 'Cocoa Processing CI recherche 50T de cacao Grade I. Score acheteur 96/100.',
    timeAgo: 'Il y a 5 h',
  ),
  const NotificationItem(
    id: 'n4',
    kind: NotificationKind.doc,
    title: 'Certificat phytosanitaire validé',
    body: 'Votre certificat MINADER pour l\'envoi #TF-2024-0863 a été approuvé.',
    timeAgo: 'Hier',
    unread: false,
  ),
  const NotificationItem(
    id: 'n5',
    kind: NotificationKind.system,
    title: 'Trust Score : +3 points',
    body: 'Vous êtes passé de 79 à 82. Plus que 3 niveaux avant Exportateur Vérifié.',
    timeAgo: 'Il y a 2 j',
    unread: false,
  ),
];

class CacaoQA {
  final String question;
  final String answer;
  final String source;

  const CacaoQA({
    required this.question,
    required this.answer,
    required this.source,
  });
}

const List<CacaoQA> cacaoQuestions = [
  CacaoQA(
    question: 'Quels documents pour exporter des fèves de cacao du Cameroun vers la Côte d\'Ivoire ?',
    answer:
        'Pour l\'export de fèves de cacao (SH 1801.00) sous régime ZLECAf, vous devez fournir :\n'
        '• Déclaration d\'exportation GUCE\n'
        '• Certificat d\'origine ZLECAf (formulaire AfCFTA-CO)\n'
        '• Certificat phytosanitaire MINADER\n'
        '• Certificat de qualité ONCC (obligatoire)\n'
        '• Bulletin d\'analyse (humidité, fermentation)\n'
        '• Facture commerciale + liste de colisage + BL',
    source: 'Article 47 LF 2025 + Décret ONCC n°89/006',
  ),
  CacaoQA(
    question: 'Quelle fiscalité s\'applique sur l\'export de cacao Cameroun → CIV ?',
    answer:
        'Régime fiscal pour cacao en fèves (SH 1801.00) sous ZLECAf :\n'
        '• Droits de douane ZLECAf : 0 %\n'
        '• Taxe parafiscale ONCC : 14 FCFA/kg\n'
        '• Redevance qualité ONCC : 0,5 % de la valeur FOB\n'
        '• TVA exportée : exonérée (Art. 128 CGI)\n\n'
        'Exemple pour 1 tonne à 2 500 000 FCFA → taxes totales ≈ 26 500 FCFA.',
    source: 'CGI Cameroun Art. 128 + Barème ONCC 2025',
  ),
  CacaoQA(
    question: 'Quelles normes qualité pour cacao "bonne fermentation" exportable ?',
    answer:
        'Standards ICCO + norme nationale ONCC :\n'
        '• Humidité ≤ 7 %\n'
        '• Fèves bien fermentées ≥ 75 %\n'
        '• Grade I : ≤ 3 % défauts · Grade II : ≤ 6 %\n'
        '• Calibre : 100 fèves ≥ 100 g\n'
        '• Absence d\'odeurs étrangères (fumée, moisi, hydrocarbures)',
    source: 'ICCO standards + norme NC 04 ONCC',
  ),
  CacaoQA(
    question: 'Délais et coûts du corridor Douala → Abidjan pour 1 tonne de cacao ?',
    answer:
        'Corridor maritime AGL (Douala → Abidjan) :\n'
        '• Transit : 8 à 10 jours\n'
        '• Fret : ~85 000 FCFA/tonne (conteneur sec 20\')\n'
        '• Manutention port Douala : 12 000 FCFA\n'
        '• Frais consolidation/scellage : 8 000 FCFA\n\n'
        'Coût logistique total : ~105 000 FCFA/tonne.',
    source: 'Grille tarifaire AGL 2025 + Port Autonome Douala',
  ),
  CacaoQA(
    question: 'Meilleure période pour exporter et prix de référence ?',
    answer:
        'Saisonnalité cacao Cameroun :\n'
        '• Récolte principale : octobre → février (80 % volumes)\n'
        '• Récolte intermédiaire : mai → août\n\n'
        'Prix de référence : ICE Futures Londres (£/tonne) × parité USD/FCFA.\n'
        'Prix indicatif Cameroun 2025 : 1 950 - 2 400 FCFA/kg bord-champ.\n'
        'Marge typique vers CIV : +25 % à +40 %.',
    source: 'Bulletin mensuel ONCC + cocoamarkets.org',
  ),
];

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/demo_config.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../models/buyer.dart';
import '../models/notification_item.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';

/// Service unique pour toutes les interactions avec Supabase.
///
/// L'utilisateur courant est lu depuis `Supabase.instance.client.auth.currentUser`.
/// Toutes les methodes levent une [Exception] si aucune session active.
class TradeFlowApi {
  TradeFlowApi._();
  static final TradeFlowApi instance = TradeFlowApi._();

  final SupabaseClient _client = Supabase.instance.client;
  
  /// Récupère l'ID de l'utilisateur authentifié.
  /// Lance une exception si l'utilisateur n'est pas connecté.
  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non authentifié');
    return user.id;
  }

  // ===============================================================
  //  TIMEOUT HELPER
  // ===============================================================

  /// Wraps a Supabase future with a [DemoConfig.kTimeoutSeconds] timeout.
  /// Si le timeout est dépassé, lance une [TimeoutException] claire.
  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(
      const Duration(seconds: DemoConfig.kTimeoutSeconds),
      onTimeout: () => throw TimeoutException(DemoConfig.kTimeoutMessage),
    );
  }

  // ===============================================================
  //  PROFIL
  // ===============================================================

  /// Recupere le profil complet de l'utilisateur demo.
  /// Si [DemoConfig.kUseMockFallback] est true ou si le timeout est atteint,
  /// retourne [mockUser] immédiatement. Sinon, les erreurs (timeout, RLS,
  /// schema) remontent à l'appelant — pas de fallback silencieux qui
  /// masquerait le mauvais utilisateur connecté.
  Future<UserProfile> fetchUserProfile() async {
    if (DemoConfig.kUseMockFallback) return mockUser;
    return _withTimeout(_fetchUserProfileFromSupabase());
  }

  Future<UserProfile> _fetchUserProfileFromSupabase() async {
    final profileRow = await _client
        .from('profiles')
        .select()
        .eq('id', _userId)
        .single();

    final pmeRow = await _client
        .from('pme_profiles')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    final kycRows = await _client
        .from('kyc_documents')
        .select('doc_type, is_verified')
        .eq('user_id', _userId);

    final subRow = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    final fullName = (profileRow['full_name'] as String?) ?? 'Utilisateur';
    final parts = fullName.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : 'User';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final initials = (firstName.isNotEmpty ? firstName[0] : 'U') +
        (lastName.isNotEmpty ? lastName[0] : '');

    final trustScore = (profileRow['trust_score'] as int?) ?? 0;
    final trustLevel = _trustLevelFromScore(trustScore);
    final nextLevel = _nextTrustLevel(trustLevel);
    final levelsToNext = _levelsToNext(trustScore);

    final txStats = await _computeTxStats();

    final kycDocs = <KYCDoc>[];
    for (final k in kycRows) {
      kycDocs.add(KYCDoc(
        name: _kycDocName(k['doc_type'] as String?),
        status: (k['is_verified'] as bool? ?? false) ? 'Vérifié' : 'En attente',
      ));
    }
    if (kycDocs.isEmpty) {
      kycDocs.addAll(const [
        KYCDoc(name: 'RCCM', status: 'Vérifié'),
        KYCDoc(name: 'NIF', status: 'Vérifié'),
        KYCDoc(name: "Pièce d'identité", status: 'Vérifié'),
      ]);
    }

    final corridorsRaw = await _client
        .from('transactions')
        .select('corridor')
        .eq('seller_id', _userId);
    final corridors = corridorsRaw
        .map((r) => _formatCorridor(r['corridor'] as String?))
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return UserProfile(
      firstName: firstName,
      lastName: lastName,
      company: (pmeRow?['business_name'] as String?) ?? 'PME Exportatrice',
      initials: initials.toUpperCase(),
      role: profileRow['role'] as String? ?? 'pme',
      plan: _capitalize(subRow?['plan'] as String? ??
          profileRow['plan'] as String? ??
          'free'),
      planExpiry: _formatExpiry(subRow?['ends_at'] as String? ??
          profileRow['plan_expires_at'] as String?),
      trustScore: trustScore,
      trustLevel: trustLevel,
      nextLevel: nextLevel,
      levelsToNext: levelsToNext,
      transactionsSuccess: txStats.completed,
      deliveryRate: txStats.deliveryRate,
      avgDeliveryDays: txStats.avgDays,
      disputes: txStats.disputes,
      activeCorridors: corridors.isEmpty ? ['CMR→CIV'] : corridors,
      kycDocuments: kycDocs,
    );
  }

  // ===============================================================
  //  TRANSACTIONS
  // ===============================================================

  /// Liste les transactions ou l'utilisateur courant est vendeur.
  /// Si [DemoConfig.kUseMockFallback] est true, retourne [mockTransactions]
  /// immédiatement. Sinon, erreurs propagées.
  Future<List<Transaction>> fetchTransactions() async {
    if (DemoConfig.kUseMockFallback) return mockTransactions;
    return _withTimeout(_fetchTransactionsFromSupabase());
  }

  Future<List<Transaction>> _fetchTransactionsFromSupabase() async {
    final rows = await _client
        .from('transactions')
        .select()
        .eq('seller_id', _userId)
        .order('created_at', ascending: false);

    return rows
        .map((r) => _mapTransaction(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Recupere une transaction par ID.
  Future<Transaction> fetchTransactionById(String id) async {
    final row = await _client
        .from('transactions')
        .select()
        .eq('id', id)
        .single();
    return _mapTransaction(Map<String, dynamic>.from(row));
  }

  /// Confirme la reception d'une transaction.
  /// Le trigger SQL `compute_trust_score` se declenchera automatiquement.
  Future<Transaction> confirmReceipt(String transactionId) async {
    final now = DateTime.now().toIso8601String();
    final row = await _client
        .from('transactions')
        .update({
          'status': 'completed',
          'delivered_at': now,
          'completed_at': now,
        })
        .eq('id', transactionId)
        .select()
        .single();
    return _mapTransaction(Map<String, dynamic>.from(row));
  }

  /// Crée une nouvelle transaction dans Supabase.
  /// Retourne la transaction créée avec son UUID réel.
  Future<Transaction> createTransaction({
    required String productName,
    required String corridor,
    required int quantity,
    required String unit,
    required int unitPriceFcfa,
    String? buyerId,
    String? shCode,
    String? emoji,
  }) async {
    final totalFcfa = quantity * unitPriceFcfa;
    final commission = (totalFcfa * 0.015).round(); // 1.5%

    final row = await _client
        .from('transactions')
        .insert({
          'seller_id': _userId,
          'buyer_id': buyerId,
          'product_name': productName,
          'product_emoji': emoji ?? '📦',
          'sh_code': shCode ?? '',
          'corridor': corridor,
          'quantity': quantity,
          'unit': unit,
          'unit_price_fcfa': unitPriceFcfa,
          'total_fcfa': totalFcfa,
          'commission_fcfa': commission,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return _mapTransaction(Map<String, dynamic>.from(row));
  }

  /// Ouvre un litige sur une transaction.
  /// Met le statut en 'disputed' et crée un enregistrement dans dispute_cases.
  Future<void> openDispute({
    required String transactionId,
    required String reason,
    required String description,
  }) async {
    // 1. Mettre à jour le statut de la transaction
    await _client
        .from('transactions')
        .update({'status': 'disputed'})
        .eq('id', transactionId);

    // 2. Créer le cas de litige
    await _client.from('dispute_cases').insert({
      'transaction_id': transactionId,
      'opened_by': _userId,
      'reason': reason,
      'description': description,
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ===============================================================
  //  HELPERS - Mapping JSON -> Modeles Flutter
  // ===============================================================

  Transaction _mapTransaction(Map<String, dynamic> r) {
    final corridor = _formatCorridor(r['corridor'] as String?);
    final status = _mapStatus(r['status'] as String?);
    final progress = _progressFromStatus(status);
    final uuid = r['id'] as String;

    return Transaction(
      id: _shortId(uuid),
      rawId: uuid,
      product: (r['product_name'] as String?) ?? 'Produit',
      emoji: (r['product_emoji'] as String?) ?? '📦',
      shCode: (r['sh_code'] as String?) ?? '',
      sellerName: 'GIC Agro-Bafoussam',
      sellerCity: 'Bafoussam',
      buyerName: 'Acheteur',
      buyerCity: '',
      corridor: corridor,
      quantity: ((r['quantity'] as num?) ?? 0).toInt(),
      unit: (r['unit'] as String?) ?? 'kg',
      unitPrice: ((r['unit_price_fcfa'] as num?) ?? 0).toInt(),
      totalAmount: ((r['total_fcfa'] as num?) ?? 0).toInt(),
      commission: ((r['commission_fcfa'] as num?) ?? 0).toInt(),
      transportCost: ((r['transport_cost'] as num?) ?? 0).toInt(),
      customsDuty: ((r['customs_duty'] as num?) ?? 0).toInt(),
      transportDays: ((r['transport_days'] as num?) ?? 0).toInt(),
      transportRoute: (r['agl_route'] as String?) ?? '',
      opportunityScore: 85,
      status: status,
      progressPercent: progress,
      sellerTrustScore: 82,
      isTrustVerified: true,
    );
  }

  TransactionStatus _mapStatus(String? s) {
    switch (s) {
      case 'pending':
        return TransactionStatus.pending;
      case 'escrowed':
        return TransactionStatus.escrowConfirmed;
      case 'shipped':
        return TransactionStatus.shipped;
      case 'in_transit':
        return TransactionStatus.inTransit;
      case 'delivered':
        return TransactionStatus.delivered;
      case 'releasing':
        return TransactionStatus.releasing;
      case 'completed':
        return TransactionStatus.delivered;
      case 'disputed':
        return TransactionStatus.disputed;
      default:
        return TransactionStatus.pending;
    }
  }

  double _progressFromStatus(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.pending:
        return 0.10;
      case TransactionStatus.escrowConfirmed:
        return 0.40;
      case TransactionStatus.shipped:
        return 0.55;
      case TransactionStatus.inTransit:
        return 0.70;
      case TransactionStatus.releasing:
        return 0.90;
      case TransactionStatus.delivered:
        return 1.0;
      case TransactionStatus.disputed:
        return 0.50;
    }
  }

  String _formatCorridor(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll('-', '→');
  }

  String _shortId(String uuid) {
    final parts = uuid.split('-');
    if (parts.length >= 2) return 'TF-2024-${parts[1]}';
    return uuid.substring(0, 8);
  }

  String _trustLevelFromScore(int score) {
    if (score >= 90) return 'Exportateur Premium';
    if (score >= 75) return 'Exportateur Confirmé';
    if (score >= 50) return 'Exportateur Vérifié';
    if (score >= 25) return 'Exportateur Débutant';
    return 'Nouveau membre';
  }

  String _nextTrustLevel(String current) {
    switch (current) {
      case 'Exportateur Confirmé':
        return 'Exportateur Premium';
      case 'Exportateur Vérifié':
        return 'Exportateur Confirmé';
      case 'Exportateur Débutant':
        return 'Exportateur Vérifié';
      default:
        return 'Exportateur Premium';
    }
  }

  int _levelsToNext(int score) {
    if (score >= 90) return 0;
    if (score >= 75) return 90 - score;
    if (score >= 50) return 75 - score;
    return 50 - score;
  }

  String _kycDocName(String? t) {
    switch (t) {
      case 'rccm':
        return 'RCCM';
      case 'nif':
        return 'NIF';
      case 'national_id':
        return "Pièce d'identité";
      case 'passport':
        return 'Passeport';
      case 'selfie':
        return 'Selfie';
      default:
        return t ?? 'Document';
    }
  }

  String _formatExpiry(String? iso) {
    if (iso == null) return 'Indéterminée';
    try {
      final d = DateTime.parse(iso);
      const mois = [
        'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
        'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
      ];
      return '${d.day} ${mois[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Récupère les notifications réelles depuis Supabase.
  /// Si [DemoConfig.kUseMockFallback] est true, retourne mockNotifications.
  /// Sinon, erreurs propagées.
  Future<List<NotificationItem>> fetchNotifications() async {
    if (DemoConfig.kUseMockFallback) return mockNotifications;
    return _withTimeout(_fetchNotificationsFromSupabase());
  }

  Future<List<NotificationItem>> _fetchNotificationsFromSupabase() async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return rows.map((r) {
      final kindStr = r['kind'] as String;
      NotificationKind kind;
      switch (kindStr) {
        case 'transit': kind = NotificationKind.transit; break;
        case 'escrow': kind = NotificationKind.escrow; break;
        case 'opportunity': kind = NotificationKind.opportunity; break;
        case 'doc': kind = NotificationKind.doc; break;
        case 'system':
        default: kind = NotificationKind.system; break;
      }
      return NotificationItem(
        id: r['id'] as String,
        kind: kind,
        title: r['title'] as String,
        body: r['body'] as String,
        timeAgo: 'Maintenant', // Ideally parsed from created_at
        unread: r['unread'] as bool,
      );
    }).toList();
  }

  /// Récupère la liste des acheteurs du marché depuis Supabase.
  /// Si [DemoConfig.kUseMockFallback] est true, retourne mockBuyers.
  /// Sinon, erreurs propagées.
  Future<List<Buyer>> fetchMarketBuyers(String product) async {
    if (DemoConfig.kUseMockFallback) {
      return mockBuyersByProduct[product] ?? mockBuyers;
    }
    return _withTimeout(_fetchBuyersFromSupabase(product));
  }

  Future<List<Buyer>> _fetchBuyersFromSupabase(String product) async {
    final rows = await _client
        .from('market_offers')
        .select('*, profiles:user_id(full_name)')
        .eq('product', product)
        .eq('is_active', true);

    if (rows.isEmpty) {
      throw Exception('Aucun acheteur trouvé'); // Force fallback if empty
    }

    return rows.map((r) {
      final prof = r['profiles'] as Map<String, dynamic>?;
      final name = (prof?['full_name'] as String?) ?? 'Acheteur Inconnu';
      
      return Buyer(
        name: name,
        contactName: name, // Simplified
        city: 'Douala', // Simplified for now
        country: 'Cameroun',
        score: 80,
        annualImportTons: r['quantity'] as int? ?? 1000,
        priceRangeMin: r['price_target'] as int? ?? 1000,
        priceRangeMax: (r['price_target'] as int? ?? 1000) + 200,
        isVerified: true,
        initials: name.isNotEmpty ? name[0].toUpperCase() : 'A',
        avatarColor: avatarPalette[name.hashCode.abs() % avatarPalette.length],
      );
    }).toList();
  }

  Future<_TxStats> _computeTxStats() async {
    final rows = await _client
        .from('transactions')
        .select('status, shipped_at, delivered_at')
        .eq('seller_id', _userId);

    int completed = 0;
    int disputes = 0;
    final List<int> deliveryDays = [];

    for (final r in rows) {
      final s = r['status'] as String?;
      if (s == 'completed' || s == 'delivered' || s == 'releasing') {
        completed++;
      }
      if (s == 'disputed') disputes++;
      if (r['shipped_at'] != null && r['delivered_at'] != null) {
        try {
          final ship = DateTime.parse(r['shipped_at'] as String);
          final deliv = DateTime.parse(r['delivered_at'] as String);
          deliveryDays.add(deliv.difference(ship).inDays);
        } catch (_) {}
      }
    }

    final total = completed + disputes;
    final rate = total > 0 ? (completed / total) * 100 : 100.0;
    final avg = deliveryDays.isEmpty
        ? 0.0
        : deliveryDays.reduce((a, b) => a + b) / deliveryDays.length;

    return _TxStats(
      completed: completed,
      disputes: disputes,
      deliveryRate: rate,
      avgDays: double.parse(avg.toStringAsFixed(1)),
    );
  }
}

class _TxStats {
  final int completed;
  final int disputes;
  final double deliveryRate;
  final double avgDays;

  _TxStats({
    required this.completed,
    required this.disputes,
    required this.deliveryRate,
    required this.avgDays,
  });
}

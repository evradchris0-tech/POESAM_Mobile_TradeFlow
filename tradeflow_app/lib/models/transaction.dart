enum TransactionStatus {
  pending,
  escrowConfirmed,
  shipped,
  inTransit,
  delivered,
  releasing,
  disputed,
}

class Transaction {
  final String id;       // ID court affiché : 'TF-2024-0847'
  final String rawId;    // UUID Supabase complet : 'cccccccc-0847-...'
  final String product;
  final String emoji;
  final String shCode;
  final String sellerName;
  final String sellerCity;
  final String buyerName;
  final String buyerCity;
  final String corridor;
  final int quantity;
  final String unit;
  final int unitPrice;
  final int totalAmount;
  final int commission;
  final int transportCost;
  final int customsDuty;
  final int transportDays;
  final String transportRoute;
  final int opportunityScore;
  final TransactionStatus status;
  final double progressPercent;
  final int sellerTrustScore;
  final bool isTrustVerified;

  const Transaction({
    required this.id,
    this.rawId = '',
    required this.product,
    required this.emoji,
    required this.shCode,
    required this.sellerName,
    required this.sellerCity,
    required this.buyerName,
    required this.buyerCity,
    required this.corridor,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalAmount,
    required this.commission,
    required this.transportCost,
    required this.customsDuty,
    required this.transportDays,
    required this.transportRoute,
    required this.opportunityScore,
    required this.status,
    required this.progressPercent,
    required this.sellerTrustScore,
    this.isTrustVerified = false,
  });

  int get totalForBuyer => totalAmount + commission + transportCost + customsDuty;

  Transaction copyWith({
    String? id,
    String? rawId,
    String? product,
    String? emoji,
    String? shCode,
    String? sellerName,
    String? sellerCity,
    String? buyerName,
    String? buyerCity,
    String? corridor,
    int? quantity,
    String? unit,
    int? unitPrice,
    int? totalAmount,
    int? commission,
    int? transportCost,
    int? customsDuty,
    int? transportDays,
    String? transportRoute,
    int? opportunityScore,
    TransactionStatus? status,
    double? progressPercent,
    int? sellerTrustScore,
    bool? isTrustVerified,
  }) {
    return Transaction(
      id: id ?? this.id,
      rawId: rawId ?? this.rawId,
      product: product ?? this.product,
      emoji: emoji ?? this.emoji,
      shCode: shCode ?? this.shCode,
      sellerName: sellerName ?? this.sellerName,
      sellerCity: sellerCity ?? this.sellerCity,
      buyerName: buyerName ?? this.buyerName,
      buyerCity: buyerCity ?? this.buyerCity,
      corridor: corridor ?? this.corridor,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      commission: commission ?? this.commission,
      transportCost: transportCost ?? this.transportCost,
      customsDuty: customsDuty ?? this.customsDuty,
      transportDays: transportDays ?? this.transportDays,
      transportRoute: transportRoute ?? this.transportRoute,
      opportunityScore: opportunityScore ?? this.opportunityScore,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      sellerTrustScore: sellerTrustScore ?? this.sellerTrustScore,
      isTrustVerified: isTrustVerified ?? this.isTrustVerified,
    );
  }
}

extension TransactionStatusLabel on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.escrowConfirmed:
        return 'Escrow confirmé';
      case TransactionStatus.shipped:
        return 'Expédié';
      case TransactionStatus.inTransit:
        return 'En transit';
      case TransactionStatus.delivered:
        return 'Livré';
      case TransactionStatus.releasing:
        return 'Libération en cours';
      case TransactionStatus.disputed:
        return 'Litige';
    }
  }
}

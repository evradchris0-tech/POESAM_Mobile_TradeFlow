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
  final String id;
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

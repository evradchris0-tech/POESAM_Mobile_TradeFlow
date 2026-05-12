class KYCDoc {
  final String name;
  final String status;

  const KYCDoc({required this.name, required this.status});
}

class UserProfile {
  final String firstName;
  final String lastName;
  final String company;
  final String initials;
  final String plan;
  final String planExpiry;
  final int trustScore;
  final String trustLevel;
  final String nextLevel;
  final int levelsToNext;
  final int transactionsSuccess;
  final double deliveryRate;
  final double avgDeliveryDays;
  final int disputes;
  final List<String> activeCorridors;
  final List<KYCDoc> kycDocuments;

  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.initials,
    required this.plan,
    required this.planExpiry,
    required this.trustScore,
    required this.trustLevel,
    required this.nextLevel,
    required this.levelsToNext,
    required this.transactionsSuccess,
    required this.deliveryRate,
    required this.avgDeliveryDays,
    required this.disputes,
    required this.activeCorridors,
    required this.kycDocuments,
  });

  String get fullName => '$firstName $lastName';
}

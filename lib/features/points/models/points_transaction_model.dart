/// PointsTransaction model matching the `points_transactions` table in Supabase.
class PointsTransactionModel {
  final String id;
  final String userId;
  final int points;
  final String transactionType;
  final String? referenceId;
  final String? descriptionAr;
  final String? descriptionEn;
  final DateTime? createdAt;

  const PointsTransactionModel({
    required this.id,
    required this.userId,
    required this.points,
    required this.transactionType,
    this.referenceId,
    this.descriptionAr,
    this.descriptionEn,
    this.createdAt,
  });

  /// Whether this is a credit (positive) transaction
  bool get isCredit =>
      transactionType == 'earned' || transactionType == 'adjustment' && points > 0;

  /// Whether this is a debit (negative) transaction
  bool get isDebit =>
      transactionType == 'redeemed' || transactionType == 'expired';

  factory PointsTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointsTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      points: json['points'] as int? ?? 0,
      transactionType: json['transaction_type'] as String? ?? 'earned',
      referenceId: json['reference_id'] as String?,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'points': points,
      'transaction_type': transactionType,
      'reference_id': referenceId,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
    };
  }
}


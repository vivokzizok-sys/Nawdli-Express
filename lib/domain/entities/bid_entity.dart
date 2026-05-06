enum BidStatus { pending, accepted, rejected }

extension BidStatusX on BidStatus {
  String get value => switch (this) {
        BidStatus.pending => 'pending',
        BidStatus.accepted => 'accepted',
        BidStatus.rejected => 'rejected',
      };

  static BidStatus fromString(String value) => switch (value) {
        'accepted' => BidStatus.accepted,
        'rejected' => BidStatus.rejected,
        _ => BidStatus.pending,
      };
}

class BidEntity {
  final String bidId;
  final String orderId;
  final String driverId;
  final String driverName;
  final double driverRating;
  final double amount;
  final BidStatus status;
  final DateTime? createdAt;

  const BidEntity({
    required this.bidId,
    required this.orderId,
    required this.driverId,
    required this.driverName,
    required this.driverRating,
    required this.amount,
    required this.status,
    this.createdAt,
  });
}

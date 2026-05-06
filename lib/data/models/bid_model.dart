import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/bid_entity.dart';

class BidModel extends BidEntity {
  const BidModel({
    required super.bidId,
    required super.orderId,
    required super.driverId,
    required super.driverName,
    required super.driverRating,
    required super.amount,
    required super.status,
    super.createdAt,
  });

  factory BidModel.fromFirestore({
    required String orderId,
    required DocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    final data = doc.data() ?? {};
    return BidModel(
      bidId: doc.id,
      orderId: orderId,
      driverId: data['driverId'] as String? ?? '',
      driverName: data['driverName'] as String? ?? '',
      driverRating: (data['driverRating'] as num?)?.toDouble() ?? 0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      status: BidStatusX.fromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool creating = false}) {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverRating': driverRating,
      'amount': amount,
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
      if (creating) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

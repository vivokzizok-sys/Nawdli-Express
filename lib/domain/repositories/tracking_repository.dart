import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/order_entity.dart';

abstract class TrackingRepository {
  Future<Either<Failure, void>> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  });
  Stream<LocationPoint?> streamDriverLocation(String driverId);
  Future<Either<Failure, void>> startTrip(String orderId);
  Future<Either<Failure, void>> completeDelivery(String orderId);
  Future<Either<Failure, void>> rateDriver({
    required String orderId,
    required String driverId,
    required double rating,
    String? comment,
  });
}

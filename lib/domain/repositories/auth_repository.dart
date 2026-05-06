import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> authStateChanges();
  Future<UserEntity?> currentUser();
  Future<Either<Failure, UserEntity>> signIn(String email, String password);
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
    VehicleType? vehicleType,
    File? vehiclePhoto,
  });
  Future<Either<Failure, void>> resendEmailVerification();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserEntity>> reloadCurrentUser();
  Stream<UserEntity?> watchUser(String uid);
}

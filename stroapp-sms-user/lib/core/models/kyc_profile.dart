import 'package:freezed_annotation/freezed_annotation.dart';
part 'kyc_profile.freezed.dart';
part 'kyc_profile.g.dart';

@freezed
class KycProfile with _$KycProfile {
  const factory KycProfile({
    required String id,
    required String status,
    String? verificationLevel,
    String? fullName,
    String? dateOfBirth,
    String? nationality,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) = _KycProfile;

  factory KycProfile.fromJson(Map<String, dynamic> json) => _$KycProfileFromJson(json);
}

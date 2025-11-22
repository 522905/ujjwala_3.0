import 'package:hive/hive.dart';

part 'local_address.g.dart';

/// Local Address Model
///
/// Stores address data (Current or Permanent) for the application.

@HiveType(typeId: 1)
class LocalAddress extends HiveObject {
  @HiveField(0)
  String localId;

  @HiveField(1)
  String applicationLocalId; // Reference to parent application

  @HiveField(2)
  String addressType; // CURRENT or PERMANENT

  @HiveField(3)
  String? houseFlatNo;

  @HiveField(4)
  String? floorNumber;

  @HiveField(5)
  String? buildingColony;

  @HiveField(6)
  String? streetRoad;

  @HiveField(7)
  String? villagePanchayatArea;

  @HiveField(8)
  String? blockSubDistrict;

  @HiveField(9)
  String? district;

  @HiveField(10)
  String? cityTown;

  @HiveField(11)
  String? state; // State code (e.g., MH, DL, PB)

  @HiveField(12)
  String? pincode;

  @HiveField(13)
  String? landmark;

  @HiveField(14)
  String? poaCode; // Proof of Address code (e.g., POA01, POA05)

  @HiveField(15)
  DateTime createdAt;

  @HiveField(16)
  DateTime updatedAt;

  LocalAddress({
    required this.localId,
    required this.applicationLocalId,
    required this.addressType,
    this.houseFlatNo,
    this.floorNumber,
    this.buildingColony,
    this.streetRoad,
    this.villagePanchayatArea,
    this.blockSubDistrict,
    this.district,
    this.cityTown,
    this.state,
    this.pincode,
    this.landmark,
    this.poaCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert to JSON for server submission
  Map<String, dynamic> toServerJson() {
    return {
      'address_type': addressType,
      'house_flat_no': houseFlatNo,
      'floor_number': floorNumber,
      'building_colony': buildingColony,
      'street_road': streetRoad,
      'village_panchayat_area': villagePanchayatArea,
      'block_sub_district': blockSubDistrict,
      'district': district,
      'city_town': cityTown,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'poa_code': poaCode,
    };
  }

  /// Check if address is complete
  bool get isComplete {
    if (houseFlatNo == null || houseFlatNo!.isEmpty) return false;
    if (district == null || district!.isEmpty) return false;
    if (state == null || state!.isEmpty) return false;
    if (pincode == null || pincode!.length != 6) return false;
    if (poaCode == null) return false;

    return true;
  }

  /// Get formatted address string
  String get formattedAddress {
    final parts = <String>[];

    if (houseFlatNo != null && houseFlatNo!.isNotEmpty) {
      parts.add(houseFlatNo!);
    }

    if (buildingColony != null && buildingColony!.isNotEmpty) {
      parts.add(buildingColony!);
    }

    if (streetRoad != null && streetRoad!.isNotEmpty) {
      parts.add(streetRoad!);
    }

    if (villagePanchayatArea != null && villagePanchayatArea!.isNotEmpty) {
      parts.add(villagePanchayatArea!);
    }

    if (cityTown != null && cityTown!.isNotEmpty) {
      parts.add(cityTown!);
    }

    if (district != null && district!.isNotEmpty) {
      parts.add(district!);
    }

    if (state != null && state!.isNotEmpty) {
      parts.add(state!);
    }

    if (pincode != null && pincode!.isNotEmpty) {
      parts.add(pincode!);
    }

    return parts.join(', ');
  }

  /// Update timestamp
  void touch() {
    updatedAt = DateTime.now();
  }

  /// Copy address data
  LocalAddress copyWith({
    String? addressType,
  }) {
    return LocalAddress(
      localId: localId,
      applicationLocalId: applicationLocalId,
      addressType: addressType ?? this.addressType,
      houseFlatNo: houseFlatNo,
      floorNumber: floorNumber,
      buildingColony: buildingColony,
      streetRoad: streetRoad,
      villagePanchayatArea: villagePanchayatArea,
      blockSubDistrict: blockSubDistrict,
      district: district,
      cityTown: cityTown,
      state: state,
      pincode: pincode,
      landmark: landmark,
      poaCode: poaCode,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

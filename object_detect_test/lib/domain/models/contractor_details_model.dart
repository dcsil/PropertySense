import 'package:cloud_firestore/cloud_firestore.dart';

class ContractorDetails {
  final String idPhotoUrl;
  final String companyName;
  final String licenseNumber;
  final Timestamp? approvalDate;

  ContractorDetails({
    required this.idPhotoUrl,
    required this.companyName,
    required this.licenseNumber,
    this.approvalDate,
  });

  static ContractorDetails? fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }
    return ContractorDetails(
      idPhotoUrl: map['idPhotoUrl'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      licenseNumber: map['licenseNumber'] as String? ?? '',
      approvalDate: map['approvalDate'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'idPhotoUrl': idPhotoUrl,
      'companyName': companyName,
      'licenseNumber': licenseNumber,
      'approvalDate': approvalDate,
    };
  }
}
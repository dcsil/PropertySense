import 'package:cloud_firestore/cloud_firestore.dart';
enum OfferStatus {
  pending,
  accepted,
  finished,
  rejected,
}

class Offer {
  final String id;
  final String listingId;
  final String homeownerId;
  final String contractorId;
  final OfferStatus status;
  final String message;
  final double offerPrice;
  final Timestamp? offerDate;
  final Timestamp createdDate;

  Offer({
    required this.message,
    required this.offerPrice,
    required this.offerDate,
    required this.createdDate,
    this.id = '',
    this.listingId = '',
    this.contractorId = '',
    this.homeownerId = '',
    this.status = OfferStatus.pending,
  });

static Offer fromFirestore(
    DocumentSnapshot<Object?> snapshot,
    SnapshotOptions? options,
  ) {
    final map = snapshot.data() as Map<String, dynamic>?;
    return Offer(
      id: snapshot.id,
      listingId: map?['listingId'] as String? ?? '',
      contractorId: map?['contractorId'] as String? ?? '',
      homeownerId: map?['homeownerId'] as String? ?? '',
      status: statusFromInt((map?['status'] as int?) ?? 0),
      message: map?['message'] as String? ?? '',
      offerPrice: (map?['offerPrice'] as num?)?.toDouble() ?? 0.0,
      offerDate: map?['offerDate'] as Timestamp?,
      createdDate: map?['createdDate'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Convert from Listing to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'offerPrice': offerPrice,
      'offerDate': offerDate,
      'createdDate': createdDate,
      'listingId': listingId,
      'contractorId': contractorId,
      'homeownerId': homeownerId,
      'status': status.index,
    };
  }

  static OfferStatus statusFromInt(int status) {
    return OfferStatus.values.firstWhere(
      (e) => e.index == status,
      orElse: () => OfferStatus.pending,
    );
  }
}
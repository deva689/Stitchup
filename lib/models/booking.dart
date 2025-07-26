import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  active,
  completed,
  cancelled,
  refunded,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

class Booking {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemCategory;
  final List<String> itemImages;
  final String renterId;
  final String renterName;
  final String renterPhone;
  final String renterEmail;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final DateTime startDate;
  final DateTime endDate;
  final int quantity;
  final double pricePerDay;
  final double pricePerHour;
  final double totalAmount;
  final double platformFee;
  final double finalAmount;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? paymentId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  Booking({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemCategory,
    required this.itemImages,
    required this.renterId,
    required this.renterName,
    required this.renterPhone,
    required this.renterEmail,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.startDate,
    required this.endDate,
    required this.quantity,
    required this.pricePerDay,
    required this.pricePerHour,
    required this.totalAmount,
    required this.platformFee,
    required this.finalAmount,
    required this.status,
    required this.paymentStatus,
    this.paymentId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemTitle: data['itemTitle'] ?? '',
      itemCategory: data['itemCategory'] ?? '',
      itemImages: List<String>.from(data['itemImages'] ?? []),
      renterId: data['renterId'] ?? '',
      renterName: data['renterName'] ?? '',
      renterPhone: data['renterPhone'] ?? '',
      renterEmail: data['renterEmail'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerPhone: data['ownerPhone'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quantity: data['quantity'] ?? 1,
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      platformFee: (data['platformFee'] ?? 0).toDouble(),
      finalAmount: (data['finalAmount'] ?? 0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${data['status']}',
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${data['paymentStatus']}',
        orElse: () => PaymentStatus.pending,
      ),
      paymentId: data['paymentId'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'itemTitle': itemTitle,
      'itemCategory': itemCategory,
      'itemImages': itemImages,
      'renterId': renterId,
      'renterName': renterName,
      'renterPhone': renterPhone,
      'renterEmail': renterEmail,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'quantity': quantity,
      'pricePerDay': pricePerDay,
      'pricePerHour': pricePerHour,
      'totalAmount': totalAmount,
      'platformFee': platformFee,
      'finalAmount': finalAmount,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentId': paymentId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  Duration get duration => endDate.difference(startDate);
  int get durationInDays => duration.inDays == 0 ? 1 : duration.inDays;
  int get durationInHours => duration.inHours;

  String get statusDisplayName {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending Confirmation';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.refunded:
        return 'Refunded';
    }
  }

  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  bool get canCancel => 
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  bool get isActive => status == BookingStatus.active;
  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;

  Booking copyWith({
    String? id,
    String? itemId,
    String? itemTitle,
    String? itemCategory,
    List<String>? itemImages,
    String? renterId,
    String? renterName,
    String? renterPhone,
    String? renterEmail,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    DateTime? startDate,
    DateTime? endDate,
    int? quantity,
    double? pricePerDay,
    double? pricePerHour,
    double? totalAmount,
    double? platformFee,
    double? finalAmount,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? paymentId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Booking(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      itemCategory: itemCategory ?? this.itemCategory,
      itemImages: itemImages ?? this.itemImages,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      renterPhone: renterPhone ?? this.renterPhone,
      renterEmail: renterEmail ?? this.renterEmail,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      quantity: quantity ?? this.quantity,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      totalAmount: totalAmount ?? this.totalAmount,
      platformFee: platformFee ?? this.platformFee,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
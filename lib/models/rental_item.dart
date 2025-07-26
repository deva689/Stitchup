import 'package:cloud_firestore/cloud_firestore.dart';

enum RentalCategory {
  studio,
  manpower,
  equipment,
}

enum RentalStatus {
  available,
  rented,
  maintenance,
  unavailable,
}

class RentalItem {
  final String id;
  final String title;
  final String description;
  final double pricePerDay;
  final double pricePerHour;
  final RentalCategory category;
  final RentalStatus status;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String location;
  final double latitude;
  final double longitude;
  final List<String> features;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic> specifications;
  final bool isVerified;
  final List<String> availableDates;
  final int maxQuantity;
  final String? videoUrl;

  RentalItem({
    required this.id,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.pricePerHour,
    required this.category,
    required this.status,
    required this.images,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.features,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.specifications = const {},
    this.isVerified = false,
    this.availableDates = const [],
    this.maxQuantity = 1,
    this.videoUrl,
  });

  factory RentalItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
      category: RentalCategory.values.firstWhere(
        (e) => e.toString() == 'RentalCategory.${data['category']}',
        orElse: () => RentalCategory.equipment,
      ),
      status: RentalStatus.values.firstWhere(
        (e) => e.toString() == 'RentalStatus.${data['status']}',
        orElse: () => RentalStatus.available,
      ),
      images: List<String>.from(data['images'] ?? []),
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerPhone: data['ownerPhone'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      features: List<String>.from(data['features'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
      isVerified: data['isVerified'] ?? false,
      availableDates: List<String>.from(data['availableDates'] ?? []),
      maxQuantity: data['maxQuantity'] ?? 1,
      videoUrl: data['videoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'pricePerDay': pricePerDay,
      'pricePerHour': pricePerHour,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'images': images,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerEmail': ownerEmail,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'features': features,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rating': rating,
      'reviewCount': reviewCount,
      'specifications': specifications,
      'isVerified': isVerified,
      'availableDates': availableDates,
      'maxQuantity': maxQuantity,
      'videoUrl': videoUrl,
    };
  }

  String get categoryDisplayName {
    switch (category) {
      case RentalCategory.studio:
        return 'Studio';
      case RentalCategory.manpower:
        return 'Manpower';
      case RentalCategory.equipment:
        return 'Equipment';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case RentalStatus.available:
        return 'Available';
      case RentalStatus.rented:
        return 'Rented';
      case RentalStatus.maintenance:
        return 'Under Maintenance';
      case RentalStatus.unavailable:
        return 'Unavailable';
    }
  }

  bool get isAvailable => status == RentalStatus.available;

  String get priceDisplay {
    if (pricePerHour > 0 && pricePerDay > 0) {
      return '\$${pricePerHour.toStringAsFixed(0)}/hr • \$${pricePerDay.toStringAsFixed(0)}/day';
    } else if (pricePerHour > 0) {
      return '\$${pricePerHour.toStringAsFixed(0)}/hour';
    } else {
      return '\$${pricePerDay.toStringAsFixed(0)}/day';
    }
  }

  RentalItem copyWith({
    String? id,
    String? title,
    String? description,
    double? pricePerDay,
    double? pricePerHour,
    RentalCategory? category,
    RentalStatus? status,
    List<String>? images,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? features,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? specifications,
    bool? isVerified,
    List<String>? availableDates,
    int? maxQuantity,
    String? videoUrl,
  }) {
    return RentalItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      category: category ?? this.category,
      status: status ?? this.status,
      images: images ?? this.images,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      features: features ?? this.features,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      specifications: specifications ?? this.specifications,
      isVerified: isVerified ?? this.isVerified,
      availableDates: availableDates ?? this.availableDates,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}
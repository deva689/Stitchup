import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import '../models/rental_item.dart';
import '../models/booking.dart';
import '../models/app_user.dart';

class RentalService {
  static final RentalService _instance = RentalService._internal();
  factory RentalService() => _instance;
  RentalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  final String _usersCollection = 'users';
  final String _rentalItemsCollection = 'rental_items';
  final String _bookingsCollection = 'bookings';
  final String _reviewsCollection = 'reviews';

  // Current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // ========== USER OPERATIONS ==========

  Future<AppUser?> getCurrentUserProfile() async {
    if (currentUserId == null) return null;
    
    final doc = await _firestore
        .collection(_usersCollection)
        .doc(currentUserId)
        .get();
    
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  Future<AppUser> createOrUpdateUser({
    required String name,
    required String email,
    required String phone,
    String? profileImageUrl,
    UserRole role = UserRole.renter,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final userData = AppUser(
      id: currentUserId!,
      name: name,
      email: email,
      phone: phone,
      profileImageUrl: profileImageUrl,
      role: role,
      address: address,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    await _firestore
        .collection(_usersCollection)
        .doc(currentUserId)
        .set(userData.toFirestore(), SetOptions(merge: true));

    return userData;
  }

  Future<void> updateUserLocation(String address, double lat, double lng) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection(_usersCollection)
        .doc(currentUserId)
        .update({
      'address': address,
      'latitude': lat,
      'longitude': lng,
      'lastActiveAt': Timestamp.now(),
    });
  }

  // ========== RENTAL ITEM OPERATIONS ==========

  Stream<List<RentalItem>> getRentalItems({
    RentalCategory? category,
    String? searchQuery,
    double? userLat,
    double? userLng,
    double maxDistance = 50, // km
  }) {
    Query query = _firestore.collection(_rentalItemsCollection);

    if (category != null) {
      query = query.where('category', isEqualTo: category.toString().split('.').last);
    }

    query = query.where('status', isEqualTo: 'available');

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      var items = snapshot.docs
          .map((doc) => RentalItem.fromFirestore(doc))
          .toList();

      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        items = items.where((item) =>
            item.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            item.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
            item.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()))).toList();
      }

      // Filter by distance if user location is provided
      if (userLat != null && userLng != null) {
        items = items.where((item) {
          if (item.latitude == 0 || item.longitude == 0) return true;
          
          final distance = Geolocator.distanceBetween(
            userLat, userLng, item.latitude, item.longitude,
          ) / 1000; // Convert to km
          
          return distance <= maxDistance;
        }).toList();
      }

      return items;
    });
  }

  Future<RentalItem?> getRentalItem(String itemId) async {
    final doc = await _firestore
        .collection(_rentalItemsCollection)
        .doc(itemId)
        .get();
    
    if (doc.exists) {
      return RentalItem.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<RentalItem>> getUserRentalItems(String userId) {
    return _firestore
        .collection(_rentalItemsCollection)
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RentalItem.fromFirestore(doc))
            .toList());
  }

  Future<String> createRentalItem(RentalItem item) async {
    final docRef = await _firestore
        .collection(_rentalItemsCollection)
        .add(item.toFirestore());
    
    return docRef.id;
  }

  Future<void> updateRentalItem(String itemId, Map<String, dynamic> updates) async {
    await _firestore
        .collection(_rentalItemsCollection)
        .doc(itemId)
        .update({
      ...updates,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteRentalItem(String itemId) async {
    await _firestore
        .collection(_rentalItemsCollection)
        .doc(itemId)
        .delete();
  }

  // ========== BOOKING OPERATIONS ==========

  Stream<List<Booking>> getUserBookings(String userId, {bool asRenter = true}) {
    final field = asRenter ? 'renterId' : 'ownerId';
    
    return _firestore
        .collection(_bookingsCollection)
        .where(field, isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }

  Future<String> createBooking(Booking booking) async {
    final docRef = await _firestore
        .collection(_bookingsCollection)
        .add(booking.toFirestore());
    
    return docRef.id;
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await _firestore
        .collection(_bookingsCollection)
        .doc(bookingId)
        .update({
      'status': status.toString().split('.').last,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updatePaymentStatus(String bookingId, PaymentStatus status, {String? paymentId}) async {
    final updates = {
      'paymentStatus': status.toString().split('.').last,
      'updatedAt': Timestamp.now(),
    };
    
    if (paymentId != null) {
      updates['paymentId'] = paymentId;
    }
    
    await _firestore
        .collection(_bookingsCollection)
        .doc(bookingId)
        .update(updates);
  }

  // ========== IMAGE OPERATIONS ==========

  Future<List<String>> uploadImages(List<File> imageFiles, String itemId) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final ref = _storage
          .ref()
          .child('rental_items')
          .child(itemId)
          .child('image_$i.jpg');

      final uploadTask = await ref.putFile(imageFiles[i]);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    return downloadUrls;
  }

  Future<String> uploadProfileImage(File imageFile, String userId) async {
    final ref = _storage
        .ref()
        .child('profile_images')
        .child('$userId.jpg');

    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  // ========== LOCATION OPERATIONS ==========

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Unknown location';
  }

  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      print('Error getting coordinates: $e');
      return [];
    }
  }

  // ========== SEARCH AND FILTER ==========

  Future<List<RentalItem>> searchRentalItems({
    required String query,
    RentalCategory? category,
    double? minPrice,
    double? maxPrice,
    double? userLat,
    double? userLng,
    double maxDistance = 50,
  }) async {
    Query baseQuery = _firestore.collection(_rentalItemsCollection);
    
    if (category != null) {
      baseQuery = baseQuery.where('category', isEqualTo: category.toString().split('.').last);
    }
    
    baseQuery = baseQuery.where('status', isEqualTo: 'available');
    
    final snapshot = await baseQuery.get();
    var items = snapshot.docs
        .map((doc) => RentalItem.fromFirestore(doc))
        .toList();

    // Filter by text search
    if (query.isNotEmpty) {
      items = items.where((item) =>
          item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.description.toLowerCase().contains(query.toLowerCase()) ||
          item.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))).toList();
    }

    // Filter by price range
    if (minPrice != null) {
      items = items.where((item) => item.pricePerDay >= minPrice).toList();
    }
    if (maxPrice != null) {
      items = items.where((item) => item.pricePerDay <= maxPrice).toList();
    }

    // Filter by distance
    if (userLat != null && userLng != null) {
      items = items.where((item) {
        if (item.latitude == 0 || item.longitude == 0) return true;
        
        final distance = Geolocator.distanceBetween(
          userLat, userLng, item.latitude, item.longitude,
        ) / 1000;
        
        return distance <= maxDistance;
      }).toList();
    }

    return items;
  }

  // ========== FAVORITES ==========

  Future<void> toggleFavorite(String itemId) async {
    if (currentUserId == null) return;

    final userDoc = _firestore.collection(_usersCollection).doc(currentUserId);
    final user = await userDoc.get();
    
    if (user.exists) {
      final savedItems = List<String>.from(user.data()?['savedItems'] ?? []);
      
      if (savedItems.contains(itemId)) {
        savedItems.remove(itemId);
      } else {
        savedItems.add(itemId);
      }
      
      await userDoc.update({'savedItems': savedItems});
    }
  }

  Stream<List<String>> getUserFavorites() {
    if (currentUserId == null) return Stream.value([]);
    
    return _firestore
        .collection(_usersCollection)
        .doc(currentUserId)
        .snapshots()
        .map((doc) => List<String>.from(doc.data()?['savedItems'] ?? []));
  }

  // ========== ANALYTICS ==========

  Future<Map<String, dynamic>> getDashboardStats(String userId) async {
    final bookingsAsOwner = await _firestore
        .collection(_bookingsCollection)
        .where('ownerId', isEqualTo: userId)
        .get();

    final bookingsAsRenter = await _firestore
        .collection(_bookingsCollection)
        .where('renterId', isEqualTo: userId)
        .get();

    final userItems = await _firestore
        .collection(_rentalItemsCollection)
        .where('ownerId', isEqualTo: userId)
        .get();

    double totalEarnings = 0;
    double totalSpent = 0;

    for (var doc in bookingsAsOwner.docs) {
      final booking = Booking.fromFirestore(doc);
      if (booking.paymentStatus == PaymentStatus.paid) {
        totalEarnings += booking.finalAmount;
      }
    }

    for (var doc in bookingsAsRenter.docs) {
      final booking = Booking.fromFirestore(doc);
      if (booking.paymentStatus == PaymentStatus.paid) {
        totalSpent += booking.finalAmount;
      }
    }

    return {
      'totalListings': userItems.docs.length,
      'totalBookingsReceived': bookingsAsOwner.docs.length,
      'totalBookingsMade': bookingsAsRenter.docs.length,
      'totalEarnings': totalEarnings,
      'totalSpent': totalSpent,
    };
  }
}
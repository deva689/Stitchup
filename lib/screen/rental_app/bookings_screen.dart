import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../services/rental_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  final RentalService _rentalService = RentalService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Rentals'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyRentalsTab(),
          _buildMyListingsTab(),
        ],
      ),
    );
  }

  Widget _buildMyRentalsTab() {
    final userId = _rentalService.currentUserId;
    if (userId == null) {
      return const Center(
        child: Text('Please log in to view your bookings'),
      );
    }

    return StreamBuilder<List<Booking>>(
      stream: _rentalService.getUserBookings(userId, asRenter: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_online_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No bookings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start exploring and book your first rental!',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildBookingCard(booking, isRenter: true);
          },
        );
      },
    );
  }

  Widget _buildMyListingsTab() {
    final userId = _rentalService.currentUserId;
    if (userId == null) {
      return const Center(
        child: Text('Please log in to view your listings'),
      );
    }

    return StreamBuilder<List<Booking>>(
      stream: _rentalService.getUserBookings(userId, asRenter: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No bookings received yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'List your items to start receiving bookings!',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildBookingCard(booking, isRenter: false);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking, {required bool isRenter}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: booking.itemImages.isNotEmpty
                        ? booking.itemImages.first
                        : 'https://via.placeholder.com/60x60',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.itemTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRenter 
                            ? 'Owner: ${booking.ownerName}'
                            : 'Renter: ${booking.renterName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Booking Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'From: ${DateFormat('MMM dd, yyyy').format(booking.startDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'To: ${DateFormat('MMM dd, yyyy').format(booking.endDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Duration: ${booking.durationInDays} ${booking.durationInDays == 1 ? 'day' : 'days'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (booking.quantity > 1) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.numbers, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Quantity: ${booking.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Payment Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: \$${booking.finalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      booking.paymentStatusDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPaymentStatusColor(booking.paymentStatus),
                      ),
                    ),
                  ],
                ),
                if (!isRenter && booking.status == BookingStatus.pending)
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _updateBookingStatus(
                          booking.id,
                          BookingStatus.confirmed,
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 32),
                        ),
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _updateBookingStatus(
                          booking.id,
                          BookingStatus.cancelled,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(80, 32),
                        ),
                        child: const Text('Decline'),
                      ),
                    ],
                  ),
                if (booking.canCancel)
                  OutlinedButton(
                    onPressed: () => _showCancelDialog(booking),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
            
            if (booking.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      booking.notes!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        color = Colors.blue;
        break;
      case BookingStatus.active:
        color = Colors.green;
        break;
      case BookingStatus.completed:
        color = Colors.grey;
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        break;
      case BookingStatus.refunded:
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  Future<void> _updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _rentalService.updateBookingStatus(bookingId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking ${status.toString().split('.').last}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating booking: $e')),
        );
      }
    }
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text(
            'Are you sure you want to cancel this booking? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateBookingStatus(booking.id, BookingStatus.cancelled);
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
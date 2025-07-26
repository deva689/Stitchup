import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rental_item.dart';
import '../../models/booking.dart';
import '../../models/app_user.dart';
import '../../services/rental_service.dart';

class BookingScreen extends StatefulWidget {
  final RentalItem item;

  const BookingScreen({super.key, required this.item});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final RentalService _rentalService = RentalService();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  int _quantity = 1;
  bool _isLoading = false;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await _rentalService.getCurrentUserProfile();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Rental'),
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBookingForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBookingForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemSummary(),
            const SizedBox(height: 20),
            _buildDateSelection(),
            const SizedBox(height: 20),
            _buildQuantitySelection(),
            const SizedBox(height: 20),
            _buildNotesSection(),
            const SizedBox(height: 20),
            _buildPricingBreakdown(),
            const SizedBox(height: 20),
            _buildTermsAndConditions(),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
    );
  }

  Widget _buildItemSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rental Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.item.images.isNotEmpty
                      ? Image.network(
                          widget.item.images.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.categoryDisplayName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.item.location,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rental Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Start Date',
                    _startDate,
                    (date) {
                      setState(() {
                        _startDate = date;
                        if (_endDate.isBefore(_startDate)) {
                          _endDate = _startDate.add(const Duration(days: 1));
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'End Date',
                    _endDate,
                    (date) {
                      setState(() {
                        _endDate = date;
                      });
                    },
                    firstDate: _startDate.add(const Duration(days: 1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Duration: ${_durationInDays} ${_durationInDays == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime selectedDate,
    Function(DateTime) onDateSelected, {
    DateTime? firstDate,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Quantity:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _quantity.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _quantity < widget.item.maxQuantity
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Available quantity: ${widget.item.maxQuantity}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any special requirements or notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    final subtotal = _calculateSubtotal();
    final platformFee = _calculatePlatformFee(subtotal);
    final total = subtotal + platformFee;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPriceRow(
              'Rental fee',
              '${widget.item.priceDisplay} × $_quantity × $_durationInDays ${_durationInDays == 1 ? 'day' : 'days'}',
              '\$${subtotal.toStringAsFixed(2)}',
            ),
            _buildPriceRow(
              'Platform fee',
              '5% of rental fee',
              '\$${platformFee.toStringAsFixed(2)}',
            ),
            const Divider(),
            _buildPriceRow(
              'Total',
              '',
              '\$${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String description, String amount,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isTotal ? 16 : 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Payment is required to confirm booking\n'
              '• Cancellation must be made 24 hours before start date\n'
              '• Items must be returned in original condition\n'
              '• Late returns may incur additional charges\n'
              '• By booking, you agree to our Terms of Service',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = _calculateSubtotal() + _calculatePlatformFee(_calculateSubtotal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  'For $_durationInDays ${_durationInDays == 1 ? 'day' : 'days'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _confirmBooking,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }

  int get _durationInDays {
    final duration = _endDate.difference(_startDate).inDays;
    return duration == 0 ? 1 : duration;
  }

  double _calculateSubtotal() {
    return widget.item.pricePerDay * _quantity * _durationInDays;
  }

  double _calculatePlatformFee(double subtotal) {
    return subtotal * 0.05; // 5% platform fee
  }

  Future<void> _confirmBooking() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to make a booking')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final subtotal = _calculateSubtotal();
      final platformFee = _calculatePlatformFee(subtotal);
      final total = subtotal + platformFee;

      final booking = Booking(
        id: '',
        itemId: widget.item.id,
        itemTitle: widget.item.title,
        itemCategory: widget.item.categoryDisplayName,
        itemImages: widget.item.images,
        renterId: _currentUser!.id,
        renterName: _currentUser!.name,
        renterPhone: _currentUser!.phone,
        renterEmail: _currentUser!.email,
        ownerId: widget.item.ownerId,
        ownerName: widget.item.ownerName,
        ownerPhone: widget.item.ownerPhone,
        startDate: _startDate,
        endDate: _endDate,
        quantity: _quantity,
        pricePerDay: widget.item.pricePerDay,
        pricePerHour: widget.item.pricePerHour,
        totalAmount: subtotal,
        platformFee: platformFee,
        finalAmount: total,
        status: BookingStatus.pending,
        paymentStatus: PaymentStatus.pending,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _rentalService.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully! Owner will be notified.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating booking: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
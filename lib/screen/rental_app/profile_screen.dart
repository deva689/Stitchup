import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../services/rental_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final RentalService _rentalService = RentalService();
  AppUser? _currentUser;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _rentalService.getCurrentUserProfile();
      Map<String, dynamic>? stats;
      
      if (user != null) {
        stats = await _rentalService.getDashboardStats(user.id);
      }

      setState(() {
        _currentUser = user;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? _buildSignInPrompt()
              : _buildProfileContent(),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to RentEase',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to access your profile and manage your rentals',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showSignInDialog,
              child: const Text('Sign In / Sign Up'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserHeader(),
            const SizedBox(height: 20),
            _buildStatsSection(),
            const SizedBox(height: 20),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage: _currentUser?.profileImageUrl != null
                  ? NetworkImage(_currentUser!.profileImageUrl!)
                  : null,
              child: _currentUser?.profileImageUrl == null
                  ? Text(
                      _currentUser?.initials ?? 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _currentUser?.name ?? 'Unknown User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentUser?.email ?? '',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _currentUser?.roleDisplayName ?? '',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _editProfile,
                    child: const Text('Edit Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentUser?.role == UserRole.renter)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _upgradeToOwner,
                      child: const Text('Become Owner'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Listings',
                    _stats!['totalListings'].toString(),
                    Icons.inventory_2,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Bookings Made',
                    _stats!['totalBookingsMade'].toString(),
                    Icons.book_online,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Bookings Received',
                    _stats!['totalBookingsReceived'].toString(),
                    Icons.event_available,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Earned',
                    '\$${_stats!['totalEarnings'].toStringAsFixed(0)}',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(
          Icons.favorite,
          'Saved Items',
          () {
            // TODO: Navigate to saved items
          },
        ),
        _buildMenuItem(
          Icons.history,
          'Rental History',
          () {
            // TODO: Navigate to rental history
          },
        ),
        _buildMenuItem(
          Icons.payment,
          'Payment Methods',
          () {
            // TODO: Navigate to payment methods
          },
        ),
        _buildMenuItem(
          Icons.help_outline,
          'Help & Support',
          () {
            // TODO: Navigate to help
          },
        ),
        _buildMenuItem(
          Icons.privacy_tip,
          'Privacy Policy',
          () {
            // TODO: Navigate to privacy policy
          },
        ),
        _buildMenuItem(
          Icons.info_outline,
          'About',
          () {
            _showAboutDialog();
          },
        ),
        const Divider(),
        _buildMenuItem(
          Icons.logout,
          'Sign Out',
          _signOut,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showSignInDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final emailController = TextEditingController();
        final phoneController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Create Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  try {
                    await _rentalService.createOrUpdateUser(
                      name: nameController.text,
                      email: emailController.text,
                      phone: phoneController.text,
                    );
                    Navigator.pop(context);
                    _loadUserData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating profile: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _editProfile() {
    if (_currentUser == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: _currentUser!.name);
        final phoneController = TextEditingController(text: _currentUser!.phone);
        
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _rentalService.createOrUpdateUser(
                    name: nameController.text,
                    email: _currentUser!.email,
                    phone: phoneController.text,
                    role: _currentUser!.role,
                  );
                  Navigator.pop(context);
                  _loadUserData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating profile: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _upgradeToOwner() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Become an Owner'),
          content: const Text(
            'Upgrade your account to start listing your items for rent. You\'ll be able to receive bookings and earn money from your rentals.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _rentalService.createOrUpdateUser(
                    name: _currentUser!.name,
                    email: _currentUser!.email,
                    phone: _currentUser!.phone,
                    role: UserRole.both,
                  );
                  Navigator.pop(context);
                  _loadUserData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account upgraded! You can now list items.'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error upgrading account: $e')),
                  );
                }
              },
              child: const Text('Upgrade'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement notification settings
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location Services'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement location settings
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'RentEase',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.home_work_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text(
          'RentEase is your one-stop solution for renting studios, equipment, and professional services. Connect with verified owners and professionals in your area.',
        ),
      ],
    );
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
                setState(() {
                  _currentUser = null;
                  _stats = null;
                });
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
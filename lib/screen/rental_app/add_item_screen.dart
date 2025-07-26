import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/rental_item.dart';
import '../../models/app_user.dart';
import '../../services/rental_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final RentalService _rentalService = RentalService();
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxQuantityController = TextEditingController();
  
  RentalCategory _selectedCategory = RentalCategory.equipment;
  List<File> _selectedImages = [];
  List<String> _features = [];
  Map<String, dynamic> _specifications = {};
  bool _isLoading = false;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _maxQuantityController.text = '1';
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
        title: const Text('Add New Item'),
        automaticallyImplyLeading: false,
      ),
      body: _currentUser?.canListItems != true
          ? _buildUpgradePrompt()
          : _buildForm(),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Become an Owner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade your account to start listing your items for rent',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to upgrade/profile screen
              },
              child: const Text('Upgrade Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildBasicInfoSection(),
            const SizedBox(height: 20),
            _buildPricingSection(),
            const SizedBox(height: 20),
            _buildLocationSection(),
            const SizedBox(height: 20),
            _buildFeaturesSection(),
            const SizedBox(height: 20),
            _buildSpecificationsSection(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('List Item'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _buildAddImageButton();
              }
              return _buildImageItem(index);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add up to 5 photos. First photo will be the cover image.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: _selectedImages.length < 5 ? _pickImage : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 32,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(_selectedImages[index]),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          if (index == 0)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImages.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Category
        DropdownButtonFormField<RentalCategory>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: RentalCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(_getCategoryDisplayName(category)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Title
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Max Quantity
        TextFormField(
          controller: _maxQuantityController,
          decoration: const InputDecoration(
            labelText: 'Maximum Quantity Available',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter quantity';
            }
            final quantity = int.tryParse(value!);
            if (quantity == null || quantity < 1) {
              return 'Please enter a valid quantity';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pricePerHourController,
                decoration: const InputDecoration(
                  labelText: 'Price per Hour (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _pricePerDayController,
                decoration: const InputDecoration(
                  labelText: 'Price per Day (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if ((value?.isEmpty ?? true) && 
                      (_pricePerHourController.text.isEmpty)) {
                    return 'Set at least one price';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Feature'),
              onPressed: _addFeature,
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_features.isEmpty)
          Text(
            'No features added yet',
            style: TextStyle(color: Colors.grey[600]),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _features.map((feature) {
              return Chip(
                label: Text(feature),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _features.remove(feature);
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSpecificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Specifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Spec'),
              onPressed: _addSpecification,
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_specifications.isEmpty)
          Text(
            'No specifications added yet',
            style: TextStyle(color: Colors.grey[600]),
          )
        else
          Column(
            children: _specifications.entries.map((entry) {
              return Card(
                child: ListTile(
                  title: Text(entry.key),
                  subtitle: Text(entry.value.toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _specifications.remove(entry.key);
                      });
                    },
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _rentalService.getCurrentLocation();
      final address = await _rentalService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      _locationController.text = address;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _addFeature() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Feature'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Feature',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _features.add(controller.text);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addSpecification() {
    showDialog(
      context: context,
      builder: (context) {
        final keyController = TextEditingController();
        final valueController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Specification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Specification Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty && valueController.text.isNotEmpty) {
                  setState(() {
                    _specifications[keyController.text] = valueController.text;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get coordinates from address
      final locations = await _rentalService.getCoordinatesFromAddress(
        _locationController.text,
      );
      
      double latitude = 0;
      double longitude = 0;
      if (locations.isNotEmpty) {
        latitude = locations.first.latitude;
        longitude = locations.first.longitude;
      }

      // Create rental item
      final item = RentalItem(
        id: '',
        title: _titleController.text,
        description: _descriptionController.text,
        pricePerDay: double.tryParse(_pricePerDayController.text) ?? 0,
        pricePerHour: double.tryParse(_pricePerHourController.text) ?? 0,
        category: _selectedCategory,
        status: RentalStatus.available,
        images: [], // Will be updated after upload
        ownerId: _currentUser!.id,
        ownerName: _currentUser!.name,
        ownerPhone: _currentUser!.phone,
        ownerEmail: _currentUser!.email,
        location: _locationController.text,
        latitude: latitude,
        longitude: longitude,
        features: _features,
        tags: _features, // Using features as tags for now
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        specifications: _specifications,
        maxQuantity: int.parse(_maxQuantityController.text),
      );

      // Create item first to get ID
      final itemId = await _rentalService.createRentalItem(item);

      // Upload images
      final imageUrls = await _rentalService.uploadImages(_selectedImages, itemId);

      // Update item with image URLs
      await _rentalService.updateRentalItem(itemId, {
        'images': imageUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item listed successfully!')),
        );
        
        // Clear form
        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
        _pricePerDayController.clear();
        _pricePerHourController.clear();
        _locationController.clear();
        _maxQuantityController.text = '1';
        setState(() {
          _selectedImages.clear();
          _features.clear();
          _specifications.clear();
          _selectedCategory = RentalCategory.equipment;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error listing item: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getCategoryDisplayName(RentalCategory category) {
    switch (category) {
      case RentalCategory.studio:
        return 'Studio';
      case RentalCategory.manpower:
        return 'Manpower';
      case RentalCategory.equipment:
        return 'Equipment';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pricePerDayController.dispose();
    _pricePerHourController.dispose();
    _locationController.dispose();
    _maxQuantityController.dispose();
    super.dispose();
  }
}
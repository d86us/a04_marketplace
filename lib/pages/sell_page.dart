import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import '../services/database_helper.dart';
import '../widgets/menu_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'selling_page.dart';
import 'package:location/location.dart' as loc;

class SellPage extends StatefulWidget {
  final Map<String, dynamic>? goatData;

  const SellPage({super.key, this.goatData});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedGender;
  String? _selectedHealth;
  int? _selectedAge;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  List<String> _existingImages = [];

  // Declare a local geolocation variable
  Map<String, double>? _geolocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Automatically gets the location
    if (widget.goatData != null) {
      _nameController.text = widget.goatData!['name'] ?? '';
      _priceController.text = widget.goatData!['price']?.toString() ?? '';
      _locationController.text = widget.goatData!['location'] ?? '';
      _descriptionController.text = widget.goatData!['description'] ?? '';
      _selectedGender = widget.goatData!['gender'];
      _selectedHealth = widget.goatData!['health'];
      _selectedAge = widget.goatData!['age'];
      _existingImages = List<String>.from(widget.goatData!['images'] ?? []);
    }
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<File> _resizeImage(XFile image) async {
    final img.Image originalImage = img.decodeImage(await image.readAsBytes())!;
    final img.Image resizedImage = img.copyResize(originalImage, width: 800);
    final resizedFile = File(image.path)
      ..writeAsBytesSync(img.encodeJpg(resizedImage));
    return resizedFile;
  }

  Future<void> _pickImageFromGallery() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(picked);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final cameraImage = await _picker.pickImage(source: ImageSource.camera);
    if (cameraImage != null) {
      setState(() {
        _selectedImages.add(cameraImage);
      });
    }
  }

  Future<List<String>> _uploadImages(List<XFile> images) async {
    var uri = Uri.parse('https://d86.us/a04_marketplace/upload.php');
    var request = http.MultipartRequest('POST', uri);

    for (var image in images) {
      final fileExtension = image.path.split('.').last.toLowerCase();
      if (fileExtension == 'jpg' ||
          fileExtension == 'jpeg' ||
          fileExtension == 'png') {
        var resizedImage = await _resizeImage(image);
        final mimeType = lookupMimeType(resizedImage.path);
        final mimeParts =
            mimeType?.split('/') ?? ['application', 'octet-stream'];
        final mediaType = MediaType(mimeParts[0], mimeParts[1]);

        var multipartFile = await http.MultipartFile.fromPath(
            'images[]', resizedImage.path,
            contentType: mediaType);
        request.files.add(multipartFile);
      } else {
        continue;
      }
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      try {
        final List<dynamic> urls = jsonDecode(responseBody);
        List<String> imageUrls =
            urls.map<String>((item) => item['url']).toList();
        return imageUrls;
      } catch (e) {
        throw Exception('Failed to decode response body');
      }
    } else {
      throw Exception('Failed to upload images');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      loc.Location location = loc.Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return;
      }

      final locationData = await location.getLocation();

      // Update the local geolocation variable with the fetched location
      setState(() {
        _geolocation = {
          'latitude': locationData.latitude ?? 0.0,
          'longitude': locationData.longitude ?? 0.0,
        };
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true); // Start spinner

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User not logged in.')));
        return;
      }

      final userId = user.uid;
      final price = int.tryParse(_priceController.text);

      if (price == null || _selectedAge == null) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please enter valid numbers for price and age.')));
        return;
      }

      if (_selectedImages.isEmpty && _existingImages.isEmpty) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one image.')));
        return;
      }

      final location = _locationController.text;
      final description = _descriptionController.text;
      final gender = _selectedGender;
      final health = _selectedHealth;
      final name = _nameController.text;

      if (_geolocation == null) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geolocation is not available.')));
        return;
      }

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(_selectedImages);
      }

      imageUrls.addAll(_existingImages);

      if (imageUrls.isEmpty) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload images')));
        }
        return;
      }

      try {
        if (widget.goatData != null) {
          await _dbHelper.updateGoat(
            goatId: widget.goatData!['id'],
            name: name,
            price: price,
            location: location,
            description: description,
            gender: gender!,
            health: health!,
            age: _selectedAge!,
            images: imageUrls,
            geolocation: _geolocation,
          );
        } else {
          await _dbHelper.addGoat(
            name: name,
            price: price,
            location: location,
            description: description,
            gender: gender!,
            health: health!,
            age: _selectedAge!,
            images: imageUrls,
            userId: userId,
            geolocation: _geolocation,
          );
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SellingPage()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false); // Stop spinner
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuWidget(
      title: 'Sell Goat',
      selectedIndex: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Goat Name',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Enter goat name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Images',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2)),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ..._selectedImages.map((image) => Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Stack(
                                  children: [
                                    Image.file(File(image.path),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.remove(image);
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          ..._existingImages.map((url) => Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Stack(
                                  children: [
                                    Image.network(url,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _existingImages.remove(url);
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: ElevatedButton.icon(
                              onPressed: _pickImageFromCamera,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Photo'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: ElevatedButton.icon(
                              onPressed: _pickImageFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Price',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration:
                          const InputDecoration(hintText: 'Enter price'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        final parsedValue = int.tryParse(value);
                        if (parsedValue == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Location',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(hintText: 'Enter location'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a location'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(hintText: 'Enter description'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Age', style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedAge,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedAge = newValue;
                        });
                      },
                      items: List.generate(15, (index) {
                        final age = index + 1;
                        return DropdownMenuItem<int>(
                          value: age,
                          child: Text('$age years'),
                        );
                      }),
                      decoration: const InputDecoration(hintText: 'Select age'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Gender',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                      items: ['Male', 'Female']
                          .map((gender) => DropdownMenuItem<String>(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      decoration:
                          const InputDecoration(hintText: 'Select gender'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Health',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedHealth,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedHealth = newValue;
                        });
                      },
                      items: ['Excellent', 'Good', 'Fair', 'Poor', 'Sick']
                          .map((health) => DropdownMenuItem<String>(
                                value: health,
                                child: Text(health),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                          hintText: 'Select health status'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Submit'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

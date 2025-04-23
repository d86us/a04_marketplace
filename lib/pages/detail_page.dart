import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/menu_widget.dart';
import 'sell_page.dart'; // Import SellPage
import '../widgets/image_preview.dart'; // Import ImagePreview

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> goat;

  const DetailPage({super.key, required this.goat});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  User? currentUser;
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        currentUser = user;
        isOwner = widget.goat['userId'] == user.uid; // ✅ Fixed field name
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final goat = widget.goat;

    return MenuWidget(
      title: goat['name'] ?? 'Unnamed Goat',
      selectedIndex: 0,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              goat['images'] != null && goat['images'].isNotEmpty
                  ? Container(
                      color: Colors.grey[300], // light gray background
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: goat['images'].length,
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImagePreview(
                                  imageUrl: goat['images'][index],
                                  goatName: goat['name'],
                                ),
                              ),
                            );
                          },
                          child: Image.network(
                            goat['images'][index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  : const Center(child: Icon(Icons.pets, size: 150)),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${goat['price']} KSh',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_pin,
                            size: 16, color: Colors.black),
                        const SizedBox(width: 5),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Location: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: goat['location'] ?? 'Unknown',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          goat['gender'] == 'Male' ? Icons.male : Icons.female,
                          size: 16,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 5),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Gender: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: goat['gender'] ?? 'Unknown',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.cake, size: 16, color: Colors.black),
                        const SizedBox(width: 5),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Age: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: goat['age'] != null
                                    ? '${goat['age']} years'
                                    : 'Unknown',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.medical_information,
                            size: 16, color: Colors.black),
                        const SizedBox(width: 5),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Health: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: goat['health'] ?? 'Unknown',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Description:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(goat['description'] ?? 'No description provided.'),
                    if (isOwner)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellPage(goatData: goat),
                              ),
                            );
                          },
                          child: const Text('Edit Listing'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

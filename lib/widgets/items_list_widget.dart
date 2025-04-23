import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../pages/detail_page.dart';

class ItemsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> goats;
  final List<String> favoriteGoatIds;
  final bool showFavorites;
  final Widget? header;
  final Function(String)? onFavoriteToggle; // Make this nullable

  const ItemsListWidget({
    super.key,
    required this.goats,
    this.favoriteGoatIds = const [],
    this.showFavorites = true,
    this.header,
    this.onFavoriteToggle, // No need to require it now
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = header != null;
    final itemCount = goats.length + (hasHeader ? 1 : 0);

    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (hasHeader && index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header!,
            ],
          );
        }

        final goatIndex = hasHeader ? index - 1 : index;
        final goat = goats[goatIndex];
        final goatId = goat['id']?.toString();

        if (goatId == null) {
          if (kDebugMode) {
            print('⚠️ Skipping goat with missing ID: $goat');
          }
          return const SizedBox();
        }

        final isFavorite = favoriteGoatIds.contains(goatId);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(goat: goat),
              ),
            );
          },
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 2, color: Colors.black),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                top: 20.0,
                right: 0.0,
                bottom: 20.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  goat['images'] is List && goat['images'].isNotEmpty
                      ? Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[
                                300], // Grey background before image is loaded
                            image: DecorationImage(
                              image: NetworkImage(goat['images'][0]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : const Icon(Icons.pets, size: 50),

                  const SizedBox(width: 20),

                  Expanded(
                    child: SizedBox(
                      height: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goat['name'] ?? 'Unnamed Goat',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_pin,
                                      size: 16, color: Colors.black),
                                  const SizedBox(width: 5),
                                  Text(goat['location'] ?? 'Unknown'),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    goat['gender'] == 'Male'
                                        ? Icons.male
                                        : Icons.female,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(goat['gender'] ?? 'Unknown'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.cake,
                                      size: 16, color: Colors.black),
                                  const SizedBox(width: 5),
                                  Text('${goat['age']} years'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.medical_information,
                                      size: 16, color: Colors.black),
                                  const SizedBox(width: 5),
                                  Text('${goat['health']}'),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '${goat['price']} KSh',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Heart icon for favorites
                  if (showFavorites)
                    Transform.translate(
                      offset: Offset(0, -10), // Move icon up by 10px
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? const Color.fromARGB(255, 255, 0, 0) : Colors.black,
                        ),
                        onPressed: () {
                          onFavoriteToggle?.call(goatId);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

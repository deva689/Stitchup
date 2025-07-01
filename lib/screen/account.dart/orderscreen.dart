import 'package:flutter/material.dart';
import 'package:stitchup/screen/account.dart/accountscreen.dart';
import 'package:stitchup/screen/account.dart/home.dart/homepage.dart';

class Orderpage extends StatelessWidget {
  final List<Map<String, dynamic>> orders = [
    {
      "name": "Suri",
      "description": "Bridal Embroidery Blouse",
      "quantity": 2,
      "delivery": "Today 9 PM",
      "image": "assets/images/order1.jpg"
    },
    {
      "name": "Linko",
      "description": "Half sleeve shirt",
      "quantity": 1,
      "delivery": "Today 2 PM",
      "image": "assets/images/order2.jpg"
    },
    {
      "name": "Rangi",
      "description": "Regular fit jean pant",
      "quantity": 1,
      "delivery": "Tomorrow 11 AM",
      "image": "assets/images/order3.jpg"
    },
  ];

  Orderpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fix for black screen
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Search & Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search your order here",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.filter_list, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Orders List
            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Text("No Orders Found",
                          style: TextStyle(fontSize: 18, color: Colors.black)))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Image.asset(
                                      order["image"],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image,
                                            size: 80, color: Colors.red);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Order Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(order["name"],
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      Text(order["description"],
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700])),
                                      const SizedBox(height: 4),
                                      Text("Quantity: ${order['quantity']}",
                                          style: TextStyle(
                                              color: Colors.grey[600])),
                                      const SizedBox(height: 4),
                                      Text("Delivery: ${order['delivery']}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),

                                // Change Date Button
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                    side: const BorderSide(color: Colors.blue),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text("Change Date",
                                      style: TextStyle(color: Colors.blue)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        iconSize: 24,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'TRNDx'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Order'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Homepage()));
              break;
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Placeholder()));
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Placeholder()));
              break;
            case 3:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Orderpage()));
              break;
            case 4:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccountScreen()));
              break;
          }
        },
      ),
    );
  }
}

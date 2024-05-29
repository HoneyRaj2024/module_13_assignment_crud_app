import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'addproduct.dart';
import 'updateProduct.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final response = await http.get(
      Uri.parse('https://crudapp.alsaaditsolution.com/rest-api/api/read.php'),
    );
    if (response.statusCode == 200) {
      setState(() {
        products = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load products data');
    }
  }

  void deleteProduct(String id) async {
    final response = await http.delete(
      Uri.parse('https://crudapp.alsaaditsolution.com/rest-api/api/delete.php'),
      body: jsonEncode({'id': id}),
    );
    if (response.statusCode == 200) {
      setState(() {
        products.removeWhere((product) => product['id'] == id);
      });
    } else {
      throw Exception('Failed to delete product');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: const Text(
          'Product List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: Colors.grey[200], // Set the background color to gray
        child: products.isEmpty
            ? Center(
                child: Lottie.asset(
                  'assets/animation.json', // Replace with your Lottie animation file path
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            : RefreshIndicator(
                onRefresh: fetchProducts,
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Image.network(
                            products[index]['img'],
                            height: 100,
                            width: 100,
                          ),
                          Expanded(
                            child: ListTile(
                              title: Text(products[index]['productname']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Code: ${products[index]['productcode']}'),
                                  Text(
                                      'Price: \$${products[index]['unitprice']}'),
                                  Text(
                                      'Quantity: ${products[index]['quantity']}'),
                                  Text(
                                      'Total Price: \$${products[index]['totalprice']}'),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                onSelected: (value) {
                                  if (value == 'update') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UpdateProductPage(
                                          productId:
                                              int.parse(products[index]['id']),
                                        ),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    deleteProduct(products[index]['id']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'update',
                                    child: Text('Update'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateProductPage(),
            ),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.purpleAccent,
          size: 50,
        ),
      ),
    );
  }
}

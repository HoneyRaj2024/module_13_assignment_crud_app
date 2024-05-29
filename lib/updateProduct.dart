import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UpdateProductPage extends StatefulWidget {
  final int productId;

  const UpdateProductPage({Key? key, required this.productId}) : super(key: key);

  @override
  _UpdateProductPageState createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _unitPriceController.addListener(_calculateTotalPrice);
    _quantityController.addListener(_calculateTotalPrice);
    _fetchProductData();
  }

  @override
  void dispose() {
    _unitPriceController.removeListener(_calculateTotalPrice);
    _quantityController.removeListener(_calculateTotalPrice);
    super.dispose();
  }

  void _calculateTotalPrice() {
    setState(() {
      final double unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
      final int quantity = int.tryParse(_quantityController.text) ?? 0;
      final double totalPrice = unitPrice * quantity;
      _totalPriceController.text = totalPrice.toStringAsFixed(2);
    });
  }

  Future<void> _fetchProductData() async {
    try {
      final url = Uri.parse('https://crudapp.alsaaditsolution.com/rest-api/api/get_product.php?id=${widget.productId}');
      final response = await http.get(url);

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final product = jsonDecode(response.body);

        final double unitPrice = double.parse(product['unitprice']);
        final int quantity = int.parse(product['quantity'].toString());

        setState(() {
          _productNameController.text = product['productname'];
          _productCodeController.text = product['productcode'];
          _unitPriceController.text = unitPrice.toString();
          _quantityController.text = quantity.toString();
          _totalPriceController.text = (unitPrice * quantity).toStringAsFixed(2);
          _imageUrl = product['img'];
          _isLoading = false;
        });
      } else {
        _showErrorDialog('Failed to fetch product data. Please try again.');
      }
    } catch (e) {
      print("Error fetching product data: $e");
      _showErrorDialog('Failed to fetch product data. Please try again.');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: const Text(
          'Update Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        color: Colors.grey[200],
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _productNameController,
                    decoration: const InputDecoration(labelText: 'Product Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _productCodeController,
                    decoration: const InputDecoration(labelText: 'Product Code'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _unitPriceController,
                    decoration: const InputDecoration(labelText: 'Unit Price'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter unit price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _totalPriceController,
                    decoration: const InputDecoration(labelText: 'Total Price'),
                    keyboardType: TextInputType.number,
                    enabled: false,
                  ),
                  const SizedBox(height: 20.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Pick Image'),
                    ),
                  ),
                  if (_imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Image.file(
                        _imageFile!,
                        height: 150,
                      ),
                    )
                  else if (_imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Image.network(
                        _imageUrl!,
                        height: 150,
                      ),
                    ),
                  const SizedBox(height: 20.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: _updateProduct,
                      child: const Text('Update Product'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    print("Pick image button clicked");
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          print("Image picked: ${_imageFile!.path}");
        });
      } else {
        print("User cancelled the image picker");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final url = Uri.parse('https://crudapp.alsaaditsolution.com/rest-api/api/update.php');
        final request = http.MultipartRequest('POST', url);

        if (_imageFile != null) {
          request.files.add(await http.MultipartFile.fromPath('img', _imageFile!.path));
        }

        request.fields['productname'] = _productNameController.text;
        request.fields['productcode'] = _productCodeController.text;
        request.fields['unitprice'] = _unitPriceController.text;
        request.fields['quantity'] = _quantityController.text;
        request.fields['product_id'] = widget.productId.toString();

        print("Sending request...");
        final response = await request.send();

        final result = await http.Response.fromStream(response);
        print("Response received: ${result.statusCode}");
        print("Response body: ${result.body}");
        if (response.statusCode == 200) {
          final responseData = jsonDecode(result.body);
          if (responseData['error'] != null) {
            _showErrorDialog(responseData['error']);
          } else {
            _showSuccessDialog();
          }
        } else {
          _showErrorDialog('Failed to update product. Please try again.');
          print('Error: ${result.body}');
        }
      } catch (e) {
        print("Error updating product: $e");
        _showErrorDialog('Failed to update product. Please try again.');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Product updated successfully'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Pop update page
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

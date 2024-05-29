import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CreateProductPage extends StatefulWidget {
  @override
  _CreateProductPageState createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _unitPriceController.addListener(_calculateTotalPrice);
    _quantityController.addListener(_calculateTotalPrice);
  }

  @override
  void dispose() {
    _unitPriceController.removeListener(_calculateTotalPrice);
    _quantityController.removeListener(_calculateTotalPrice);
    super.dispose();
  }

  void _calculateTotalPrice() {
    setState(() {
      final double unitPrice =
          double.tryParse(_unitPriceController.text) ?? 0.0;
      final int quantity = int.tryParse(_quantityController.text) ?? 0;
      final double totalPrice = unitPrice * quantity;
      _totalPriceController.text = totalPrice.toStringAsFixed(2);
    });
  }

  Future<void> _pickImage() async {
    print("Pick image button clicked");
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
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

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile != null) {
        try {
          final url = Uri.parse(
              'https://crudapp.alsaaditsolution.com/rest-api/api/create.php');
          final request = http.MultipartRequest('POST', url);
          request.files
              .add(await http.MultipartFile.fromPath('img', _imageFile!.path));
          request.fields['productname'] = _productNameController.text;
          request.fields['productcode'] = _productCodeController.text;
          request.fields['unitprice'] = _unitPriceController.text;
          request.fields['quantity'] = _quantityController.text;
          request.fields['totalprice'] = _totalPriceController.text;

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
              _resetForm();
            }
          } else {
            _showErrorDialog('Failed to create product. Please try again.');
            print('Error: ${result.body}');
          }
        } catch (e) {
          print("Error uploading product: $e");
          _showErrorDialog('Failed to upload product. Please try again.');
        }
      } else {
        _showErrorDialog('Please pick an image');
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
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Success'),
          content: Text('Product created successfully'),
        );
      },
    );

    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  void _resetForm() {
    _productNameController.clear();
    _productCodeController.clear();
    _unitPriceController.clear();
    _quantityController.clear();
    _totalPriceController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: const Text(
          'Add Product',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: Colors.grey[200], // Set the background color to gray
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
                    decoration:
                        const InputDecoration(labelText: 'Product Name'),
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
                    decoration:
                        const InputDecoration(labelText: 'Product Code'),
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
                    ),
                  const SizedBox(height: 20.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: _addProduct,
                      child: const Text('Add Product'),
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
}

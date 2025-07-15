import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../utils/auth.dart';

class AddPropertyScreen extends StatefulWidget {
  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _rentController = TextEditingController();
  final _descController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final headers = await getAuthHeaders();
      var request = http.MultipartRequest('POST', Uri.parse('http://localhost:5000/api/properties'));
      request.headers.addAll(headers);
      request.fields['name'] = _nameController.text.trim();
      request.fields['unit_type'] = _typeController.text.trim();
      request.fields['rent'] = _rentController.text.trim();
      request.fields['description'] = _descController.text.trim();
      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _imageFile!.path));
      }
      final response = await request.send();
      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 201) {
        Navigator.pop(context);
      } else {
        final respStr = await response.stream.bytesToString();
        setState(() {
          _errorMessage = json.decode(respStr)['message'] ?? 'Failed to add property.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _rentController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Property', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.red)),
                  ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'Property Name', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Enter property name' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _typeController,
                        decoration: InputDecoration(labelText: 'Unit Type', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Enter unit type' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _rentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Rent', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Enter rent' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          _imageFile != null
                              ? Image.file(_imageFile!, width: 80, height: 80, fit: BoxFit.cover)
                              : Container(width: 80, height: 80, color: Colors.grey[200], child: Icon(Icons.image, size: 40)),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.upload),
                            label: Text('Upload Photo', style: GoogleFonts.poppins()),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text('Add Property', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
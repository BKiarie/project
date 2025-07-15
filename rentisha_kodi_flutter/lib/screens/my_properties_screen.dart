import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_property_screen.dart';
import '../utils/auth.dart';

class MyPropertiesScreen extends StatefulWidget {
  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  List<dynamic> _properties = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/properties'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        setState(() {
          _properties = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch properties.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Properties', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPropertyScreen()),
          ).then((_) => _fetchProperties());
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
        tooltip: 'Add Property',
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: GoogleFonts.poppins(color: Colors.red)))
              : _properties.isEmpty
                  ? Center(child: Text('No properties found.', style: GoogleFonts.poppins()))
                  : ListView.builder(
                      itemCount: _properties.length,
                      itemBuilder: (context, index) {
                        final property = _properties[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: property['photo_url'] != null
                                ? Image.network(
                                    property['photo_url'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(Icons.home, size: 40, color: Colors.green),
                            title: Text(property['name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            subtitle: Text('Rent: ${property['rent'] ?? ''}', style: GoogleFonts.poppins()),
                            trailing: Icon(Icons.chevron_right),
                            onTap: () {
                              // Optionally show property details or edit
                            },
                          ),
                        );
                      },
                    ),
    );
  }
} 
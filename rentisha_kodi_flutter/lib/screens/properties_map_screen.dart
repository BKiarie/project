import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'property_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';
// Modern green palette (should match main.dart)
const Color kPrimaryGreen = Color(0xFF2ecc71); // Emerald
const Color kAccentGold = Color(0xFFF9CA24); // Soft Gold
const Color kSecondaryGreen = Color(0xFF145A32); // Deep Green
const Color kBackground = Color(0xFFF8F9FA); // Off-white
const Color kTextDark = Color(0xFF222222);

class PropertiesMapScreen extends StatefulWidget {
  @override
  _PropertiesMapScreenState createState() => _PropertiesMapScreenState();
}

class _PropertiesMapScreenState extends State<PropertiesMapScreen> {
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;

  // Default to Nairobi coordinates
  static const LatLng _center = LatLng(-1.2921, 36.8219);

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/properties/map'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _properties = data.cast<Map<String, dynamic>>();
          _createMarkers();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load properties')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _createMarkers() {
    _markers.clear();
    for (var property in _properties) {
      if (property['latitude'] != null && property['longitude'] != null) {
        final marker = Marker(
          markerId: MarkerId(property['id'].toString()),
          position: LatLng(
            double.parse(property['latitude'].toString()),
            double.parse(property['longitude'].toString()),
          ),
          infoWindow: InfoWindow(
            title: property['name'] ?? 'Property',
            snippet: 'KES ${property['rent']} - ${property['status']}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PropertyDetailsScreen(
                    propertyId: property['id'],
                  ),
                ),
              );
            },
          ),
        );
        _markers.add(marker);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Properties Map', style: GoogleFonts.poppins(color: kTextDark, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryGreen,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: kTextDark),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadProperties();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_center, 11.0),
            );
          }
        },
        child: Icon(Icons.center_focus_strong, color: kTextDark),
        backgroundColor: kPrimaryGreen,
      ),
    );
  }
} 
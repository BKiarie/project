import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

// Modern green palette (should match main.dart)
const Color kPrimaryGreen = Color(0xFF2ecc71); // Emerald
const Color kAccentGold = Color(0xFFF9CA24); // Soft Gold
const Color kSecondaryGreen = Color(0xFF145A32); // Deep Green
const Color kBackground = Color(0xFFF8F9FA); // Off-white
const Color kTextDark = Color(0xFF222222);

class PropertyDetailsScreen extends StatefulWidget {
  final int propertyId;

  PropertyDetailsScreen({required this.propertyId});

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  Map<String, dynamic>? _property;
  bool _isLoading = true;
  bool _isRequestingViewing = false;
  bool _isPayingDeposit = false;

  @override
  void initState() {
    super.initState();
    _loadPropertyDetails();
  }

  Future<void> _loadPropertyDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/properties/${widget.propertyId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _property = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load property details')),
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

  Future<void> _requestViewing() async {
    setState(() {
      _isRequestingViewing = true;
    });

    try {
      // Show a dialog to get viewing date/time
      final DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 30)),
      );

      if (selectedDate != null) {
        final TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (selectedTime != null) {
          final response = await http.post(
            Uri.parse('http://localhost:5000/api/properties/${widget.propertyId}/request-viewing'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'viewing_date': '${selectedDate.toIso8601String().split('T')[0]} ${selectedTime.format(context)}',
              'message': 'I would like to view this property.',
            }),
          );

          if (response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Viewing request sent successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send viewing request')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isRequestingViewing = false;
      });
    }
  }

  Future<void> _payDeposit() async {
    setState(() {
      _isPayingDeposit = true;
    });

    try {
      // Show a dialog to get phone number
      final TextEditingController phoneController = TextEditingController();
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter Phone Number'),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '254710913737',
              labelText: 'Safaricom Phone Number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Pay'),
            ),
          ],
        ),
      );

      if (confirmed == true && phoneController.text.isNotEmpty) {
        final response = await http.post(
          Uri.parse('http://localhost:5000/api/properties/${widget.propertyId}/pay-deposit'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'amount': 1, // For testing, use 1 KES
            'phone': phoneController.text,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment initiated! Check your phone for STK Push.')),
          );
        } else {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorData['message'] ?? 'Payment failed')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isPayingDeposit = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Property Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_property == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Property Details')),
        body: Center(child: Text('Property not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_property!['name'] ?? 'Property Details', style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: kTextDark,
        )),
        backgroundColor: kPrimaryGreen,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home,
                size: 80,
                color: kSecondaryGreen,
              ),
            ),
            SizedBox(height: 16),

            // Property Name and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _property!['name'] ?? 'Property',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                ),
                Text(
                  'KES ${_property!['rent']}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Status Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _property!['status'] == 'available' 
                    ? kSecondaryGreen 
                    : kAccentGold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _property!['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Description
            Text(
              'Description',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _property!['description'] ?? 'No description available',
              style: GoogleFonts.poppins(fontSize: 16, color: kSecondaryGreen),
            ),
            SizedBox(height: 16),

            // Property Details
            _buildDetailRow('Unit Type', _property!['unit_type'] ?? 'N/A'),
            _buildDetailRow('Bathrooms', _property!['bathrooms']?.toString() ?? 'N/A'),
            
            // Amenities
            if (_property!['amenities'] != null) ...[
              SizedBox(height: 16),
              Text(
                'Amenities',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (_property!['amenities'] as List<dynamic>?)
                    ?.map((amenity) => Chip(
                          label: Text(amenity.toString()),
                          backgroundColor: kBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: kSecondaryGreen, width: 1),
                          ),
                        ))
                    .toList() ?? [],
              ),
            ],

            SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRequestingViewing ? null : _requestViewing,
                    icon: _isRequestingViewing 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.visibility, color: Colors.white),
                    label: Text('Request Viewing', style: GoogleFonts.poppins(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentGold,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPayingDeposit ? null : _payDeposit,
                    icon: _isPayingDeposit 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.payment, color: Colors.white),
                    label: Text('Pay Deposit', style: GoogleFonts.poppins(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSecondaryGreen,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kTextDark,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 16, color: kSecondaryGreen),
          ),
        ],
      ),
    );
  }
} 
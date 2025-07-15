import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Modern green palette (should match main.dart)
const Color kPrimaryGreen = Color(0xFF2ecc71); // Emerald
const Color kAccentGold = Color(0xFFF9CA24); // Soft Gold
const Color kSecondaryGreen = Color(0xFF145A32); // Deep Green
const Color kBackground = Color(0xFFF8F9FA); // Off-white
const Color kTextDark = Color(0xFF222222);

class PropertyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? property;
  final bool isLoading;

  const PropertyDetailsScreen({Key? key, this.property, this.isLoading = false}) : super(key: key);

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  bool _isLoading = false;
  bool _isRequestingViewing = false;
  bool _isPayingDeposit = false;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
  }

  void _requestViewing() {
    setState(() {
      _isRequestingViewing = true;
    });
    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isRequestingViewing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Viewing request sent!')),
      );
    });
  }

  void _payDeposit() {
    setState(() {
      _isPayingDeposit = true;
    });
    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isPayingDeposit = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deposit paid!')),
      );
    });
  }

  // Add an image carousel placeholder at the top
  Widget _buildImageCarousel() {
    return Container(
      height: 220,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kPrimaryGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(Icons.image, size: 80, color: kPrimaryGreen.withOpacity(0.4)),
      ),
    );
  }

  // Helper to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: kTextDark,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: kSecondaryGreen,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Property Details', style: GoogleFonts.poppins(color: kTextDark))),
        body: Center(child: CircularProgressIndicator(color: kPrimaryGreen)),
        backgroundColor: kBackground,
      );
    }

    if (widget.property == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Property Details', style: GoogleFonts.poppins(color: kTextDark))),
        body: Center(child: Text('Property not found', style: GoogleFonts.poppins(color: kSecondaryGreen))),
        backgroundColor: kBackground,
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(widget.property!['name'] ?? 'Property Details', style: GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            // Property Name and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.property!['name'] ?? 'Property',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                ),
                Text(
                  'KES ${widget.property!['rent']}',
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
                color: widget.property!['status'] == 'available' ? kPrimaryGreen : kAccentGold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.property!['status']?.toString().toUpperCase() ?? 'UNKNOWN',
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
              widget.property!['description'] ?? 'No description available',
              style: GoogleFonts.poppins(fontSize: 16, color: kSecondaryGreen),
            ),
            SizedBox(height: 16),
            // Property Details
            _buildDetailRow('Unit Type', widget.property!['unit_type'] ?? 'N/A'),
            _buildDetailRow('Bathrooms', widget.property!['bathrooms']?.toString() ?? 'N/A'),
            // Amenities
            if (widget.property!['amenities'] != null) ...[
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
                children: (widget.property!['amenities'] as List<dynamic>?)
                    ?.map((amenity) => Chip(
                          label: Text(amenity.toString(), style: GoogleFonts.poppins(color: kPrimaryGreen)),
                          backgroundColor: kBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: kPrimaryGreen, width: 1),
                          ),
                          avatar: Icon(Icons.check_circle, color: kPrimaryGreen, size: 18),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.visibility, color: Colors.white),
                    label: Text('Request Viewing', style: GoogleFonts.poppins(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
} 
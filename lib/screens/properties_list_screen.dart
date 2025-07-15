import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Modern green palette (should match main.dart)
const Color kPrimaryGreen = Color(0xFF2ecc71); // Emerald
const Color kAccentGold = Color(0xFFF9CA24); // Soft Gold
const Color kSecondaryGreen = Color(0xFF145A32); // Deep Green
const Color kBackground = Color(0xFFF8F9FA); // Off-white
const Color kTextDark = Color(0xFF222222);

class PropertiesListScreen extends StatefulWidget {
  const PropertiesListScreen({Key? key}) : super(key: key);

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _filteredProperties = [];
  String _searchQuery = '';
  String? _selectedUnitType;
  String? _selectedStatus;
  int? _minBathrooms;
  int? _maxRent;
  List<String> _selectedAmenities = [];
  bool _isLoading = true;
  int _featuredIndex = 0; // For carousel

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        _properties = [
          {
            'id': '1',
            'name': 'Luxury Apartment',
            'description': 'Spacious 2-bedroom apartment in a prime location.',
            'rent': 25000,
            'status': 'available',
            'unit_type': 'Apartment',
            'bathrooms': 2,
            'amenities': ['WiFi', 'Parking', 'Gym'],
          },
          {
            'id': '2',
            'name': 'Cozy Studio',
            'description': 'Perfect for a single person or couple.',
            'rent': 12000,
            'status': 'rented',
            'unit_type': 'Studio',
            'bathrooms': 1,
            'amenities': ['WiFi'],
          },
          {
            'id': '3',
            'name': 'Modern Townhouse',
            'description': 'Large 3-bedroom townhouse with a garden.',
            'rent': 35000,
            'status': 'available',
            'unit_type': 'Townhouse',
            'bathrooms': 3,
            'amenities': ['WiFi', 'Pool', 'Gym'],
          },
        ];
        _filteredProperties = _properties;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading properties: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProperties = _properties.where((property) {
        final matchesSearch = property['name']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        final matchesUnitType = _selectedUnitType == null || property['unit_type'] == _selectedUnitType;
        final matchesStatus = _selectedStatus == null || property['status'] == _selectedStatus;
        final matchesBathrooms = _minBathrooms == null || property['bathrooms'] >= _minBathrooms!;
        final matchesRent = _maxRent == null || property['rent'] <= _maxRent!;
        final matchesAmenities = _selectedAmenities.isEmpty ||
            _selectedAmenities.every((amenity) => property['amenities']?.contains(amenity) ?? false);

        return matchesSearch &&
            matchesUnitType &&
            matchesStatus &&
            matchesBathrooms &&
            matchesRent &&
            matchesAmenities;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Properties', style: GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search properties...',
                  prefixIcon: Icon(Icons.search, color: kSecondaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.poppins(color: kTextDark),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _applyFilters();
                },
              ),
              SizedBox(height: 16),
              Text('Unit Type', style: GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedUnitType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['All', 'Apartment', 'Studio', 'Townhouse'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUnitType = newValue;
                  });
                  _applyFilters();
                },
              ),
              SizedBox(height: 16),
              Text('Status', style: GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['All', 'Available', 'Renting', 'Sold'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                  _applyFilters();
                },
              ),
              SizedBox(height: 16),
              Text('Bathrooms (Min)', style: GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 1',
                  prefixIcon: Icon(Icons.bathtub, color: kSecondaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.poppins(color: kTextDark),
                onChanged: (value) {
                  setState(() {
                    _minBathrooms = int.tryParse(value);
                  });
                  _applyFilters();
                },
              ),
              SizedBox(height: 16),
              Text('Max Rent (KES)', style: GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 30000',
                  prefixIcon: Icon(Icons.attach_money, color: kSecondaryGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: GoogleFonts.poppins(color: kTextDark),
                onChanged: (value) {
                  setState(() {
                    _maxRent = int.tryParse(value);
                  });
                  _applyFilters();
                },
              ),
              SizedBox(height: 16),
              Text('Amenities', style: GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ..._properties.expand((property) => property['amenities'] ?? []).toSet().map((amenity) {
                    return FilterChip(
                      label: Text(amenity),
                      selected: _selectedAmenities.contains(amenity),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                        _applyFilters();
                      },
                      backgroundColor: kPrimaryGreen.withOpacity(0.1),
                      selectedColor: kPrimaryGreen.withOpacity(0.2),
                      labelStyle: GoogleFonts.poppins(color: kPrimaryGreen),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: kPrimaryGreen.withOpacity(0.3)),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Clear All', style: GoogleFonts.poppins(color: kPrimaryGreen)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
              child: Text('Apply Filters', style: GoogleFonts.poppins(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Add a featured carousel at the top (placeholder for now)
  Widget _buildFeaturedCarousel() {
    return Container(
      height: 180,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(3, (index) => Container(
          width: 320,
          margin: EdgeInsets.only(left: index == 0 ? 16 : 8, right: 8),
          decoration: BoxDecoration(
            color: kPrimaryGreen.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Featured Property ${index + 1}',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kPrimaryGreen,
              ),
            ),
          ),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text('Properties', style: GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: kAccentGold),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimaryGreen))
          : Column(
              children: [
                // Featured Properties Carousel
                if (_filteredProperties.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: _filteredProperties.length > 3 ? 3 : _filteredProperties.length,
                      controller: PageController(viewportFraction: 0.85),
                      onPageChanged: (index) {
                        setState(() {
                          _featuredIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final property = _filteredProperties[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: _featuredIndex == index ? 8 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: _featuredIndex == index ? kPrimaryGreen : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              // Navigate to property details (implement as needed)
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    property['name'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: kPrimaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    property['description'] ?? '',
                                    style: GoogleFonts.poppins(color: kTextDark, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_money, color: kAccentGold, size: 20),
                                      SizedBox(width: 4),
                                      Text(
                                        property['rent'] != null ? property['rent'].toString() : '',
                                        style: GoogleFonts.poppins(color: kTextDark, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 16),
                                      Icon(Icons.bathtub, color: kSecondaryGreen, size: 20),
                                      SizedBox(width: 4),
                                      Text(
                                        property['bathrooms'] != null ? property['bathrooms'].toString() : '',
                                        style: GoogleFonts.poppins(color: kTextDark),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: (property['amenities'] as List<dynamic>? ?? [])
                                        .map((amenity) => Chip(
                                              label: Text(amenity.toString(), style: GoogleFonts.poppins(fontSize: 12)),
                                              backgroundColor: kPrimaryGreen.withOpacity(0.1),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // Search Bar
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search properties...',
                      prefixIcon: Icon(Icons.search, color: kSecondaryGreen),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: GoogleFonts.poppins(color: kTextDark),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                // Results Count
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredProperties.length} properties found',
                        style: GoogleFonts.poppins(
                          color: kSecondaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedUnitType != null || _selectedStatus != null || 
                          _minBathrooms != null || _maxRent != null || _selectedAmenities.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedUnitType = null;
                              _selectedStatus = null;
                              _minBathrooms = null;
                              _maxRent = null;
                              _selectedAmenities.clear();
                              _searchQuery = '';
                            });
                            _applyFilters();
                          },
                          child: Text('Clear Filters', style: GoogleFonts.poppins(color: kPrimaryGreen)),
                        ),
                    ],
                  ),
                ),
                // Properties List
                Expanded(
                  child: _filteredProperties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_outlined, size: 64, color: kSecondaryGreen),
                              SizedBox(height: 16),
                              Text(
                                'No properties found',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: kSecondaryGreen,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProperties,
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _filteredProperties.length,
                            itemBuilder: (context, index) {
                              final property = _filteredProperties[index];
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  margin: EdgeInsets.only(bottom: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Property Image Placeholder
                                        ClipRRect(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                          child: Container(
                                            height: 160,
                                            width: double.infinity,
                                            color: kPrimaryGreen.withOpacity(0.15),
                                            child: Icon(
                                              Icons.home,
                                              size: 60,
                                              color: kPrimaryGreen.withOpacity(0.4),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(18),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      property['name'] ?? 'Property',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: kTextDark,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.favorite_border, color: kPrimaryGreen),
                                                    onPressed: () {},
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: property['status'] == 'available' ? kPrimaryGreen : kAccentGold,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      property['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'KES ${property['rent']}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: kPrimaryGreen,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                property['description'] ?? 'No description available',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(color: kTextDark.withOpacity(0.7)),
                                              ),
                                              SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Icon(Icons.home, size: 16, color: kSecondaryGreen),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    property['unit_type'] ?? 'N/A',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: kTextDark,
                                                    ),
                                                  ),
                                                  SizedBox(width: 16),
                                                  Icon(Icons.bathtub, size: 16, color: kSecondaryGreen),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '${property['bathrooms'] ?? 0}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: kTextDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 14),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: kPrimaryGreen,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => PropertyDetailsScreen(
                                                          propertyId: property['id'],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Text('View Details', style: GoogleFonts.poppins()),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
} 
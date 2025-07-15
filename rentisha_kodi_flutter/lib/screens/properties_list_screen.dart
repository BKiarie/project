import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'property_details_screen.dart';
import 'properties_map_screen.dart';
import 'package:google_fonts/google_fonts.dart';
// Modern green palette (should match main.dart)
const Color kPrimaryGreen = Color(0xFF2ecc71); // Emerald
const Color kAccentGold = Color(0xFFF9CA24); // Soft Gold
const Color kSecondaryGreen = Color(0xFF145A32); // Deep Green
const Color kBackground = Color(0xFFF8F9FA); // Off-white
const Color kTextDark = Color(0xFF222222);

class PropertiesListScreen extends StatefulWidget {
  @override
  _PropertiesListScreenState createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _filteredProperties = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Filter variables
  String? _selectedUnitType;
  String? _selectedStatus;
  int? _minBathrooms;
  double? _maxRent;
  List<String> _selectedAmenities = [];

  final List<String> _unitTypes = ['apartment', 'house', 'studio', 'bedsitter'];
  final List<String> _statuses = ['available', 'rented', 'pending'];
  final List<String> _amenities = ['parking', 'balcony', 'garden', 'security', 'water', 'electricity'];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/properties'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _properties = data.cast<Map<String, dynamic>>();
          _filteredProperties = List.from(_properties);
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

  void _applyFilters() {
    setState(() {
      _filteredProperties = _properties.where((property) {
        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final name = property['name']?.toString().toLowerCase() ?? '';
          final description = property['description']?.toString().toLowerCase() ?? '';
          if (!name.contains(_searchQuery.toLowerCase()) && 
              !description.contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }

        // Unit type filter
        if (_selectedUnitType != null && 
            property['unit_type'] != _selectedUnitType) {
          return false;
        }

        // Status filter
        if (_selectedStatus != null && 
            property['status'] != _selectedStatus) {
          return false;
        }

        // Bathrooms filter
        if (_minBathrooms != null && 
            (property['bathrooms'] ?? 0) < _minBathrooms!) {
          return false;
        }

        // Rent filter
        if (_maxRent != null && 
            (property['rent'] ?? 0) > _maxRent!) {
          return false;
        }

        // Amenities filter
        if (_selectedAmenities.isNotEmpty) {
          final propertyAmenities = List<String>.from(property['amenities'] ?? []);
          if (!_selectedAmenities.every((amenity) => propertyAmenities.contains(amenity))) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Filter Properties'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit Type
                Text('Unit Type', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: _selectedUnitType,
                  decoration: InputDecoration(hintText: 'All Types'),
                  items: [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    ..._unitTypes.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.toUpperCase()),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedUnitType = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Status
                Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(hintText: 'All Statuses'),
                  items: [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ..._statuses.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Min Bathrooms
                Text('Minimum Bathrooms', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<int>(
                  value: _minBathrooms,
                  decoration: InputDecoration(hintText: 'Any'),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Any')),
                    ...List.generate(5, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}+'),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _minBathrooms = value;
                    });
                  },
                ),
                SizedBox(height: 16),

                // Max Rent
                Text('Maximum Rent (KES)', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'No limit',
                    suffixText: 'KES',
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      _maxRent = value.isEmpty ? null : double.tryParse(value);
                    });
                  },
                ),
                SizedBox(height: 16),

                // Amenities
                Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _amenities.map((amenity) => FilterChip(
                    label: Text(amenity),
                    selected: _selectedAmenities.contains(amenity),
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedUnitType = null;
                  _selectedStatus = null;
                  _minBathrooms = null;
                  _maxRent = null;
                  _selectedAmenities.clear();
                });
              },
              child: Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Properties'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PropertiesMapScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search properties...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
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
                  style: TextStyle(
                    color: Colors.grey[600],
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
                    child: Text('Clear Filters'),
                  ),
              ],
            ),
          ),

          // Properties List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredProperties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No properties found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
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
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                color: kBackground,
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
                                        color: kSecondaryGreen.withOpacity(0.15),
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
                                                  color: property['status'] == 'available' ? Colors.green : Colors.orange,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  property['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                                                  style: TextStyle(
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
                                            style: TextStyle(color: kTextDark.withOpacity(0.7)),
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
                                              child: Text('View Details'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
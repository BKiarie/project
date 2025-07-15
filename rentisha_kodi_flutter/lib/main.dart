import 'package:flutter/material.dart';
import 'screens/properties_list_screen.dart';
import 'screens/properties_map_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/notifications_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'screens/reset_password_screen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/my_properties_screen.dart';
import 'screens/profile_screen.dart';

// Modern green palette
const Color kPrimaryGreen = Color(0xFF2ecc71); // Emerald
const Color kAccentGold = Color(0xFFF9CA24); // Soft Gold
const Color kSecondaryGreen = Color(0xFF145A32); // Deep Green
const Color kBackground = Color(0xFFF8F9FA); // Off-white
const Color kTextDark = Color(0xFF222222);

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    await Future.delayed(Duration(milliseconds: 800)); // For splash effect
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(token: token)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryGreen,
      body: Center(
        child: CircularProgressIndicator(color: kAccentGold),
      ),
    );
  }
}

void main() {
  // Handle password reset link on web
  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.path == '/reset-password' && uri.queryParameters['token'] != null) {
      runApp(MaterialApp(
        home: ResetPasswordScreen(token: uri.queryParameters['token']!),
      ));
      return;
    }
  }
  runApp(RentishaKodiApp());
}

class RentishaKodiApp extends StatefulWidget {
  @override
  State<RentishaKodiApp> createState() => _RentishaKodiAppState();
}

class _RentishaKodiAppState extends State<RentishaKodiApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleInitialUri();
    if (!kIsWeb) {
      _sub = uriLinkStream.listen((Uri? uri) {
        _handleUri(uri);
      }, onError: (err) {});
    }
  }

  Future<void> _handleInitialUri() async {
    final uri = await getInitialUri();
    _handleUri(uri);
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme == 'rentisha' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'] ?? '';
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(token: token),
      ));
    }
    // For web: if (uri.host == 'yourdomain.com' && uri.path == '/reset-password')
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentisha Kodi',
      theme: ThemeData(
        primaryColor: kPrimaryGreen,
        scaffoldBackgroundColor: kBackground,
        colorScheme: ColorScheme.light(
          primary: kPrimaryGreen,
          secondary: kAccentGold,
          background: kBackground,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white.withOpacity(0.85),
          elevation: 6,
          iconTheme: IconThemeData(color: kPrimaryGreen),
          titleTextStyle: GoogleFonts.poppins(
            color: kSecondaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.1,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: kPrimaryGreen,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: kPrimaryGreen,
          unselectedItemColor: kSecondaryGreen.withOpacity(0.5),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kPrimaryGreen, width: 2),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: kPrimaryGreen,
          contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        ),
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: kTextDark,
          displayColor: kTextDark,
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/main': (context) => MainScreen(token: 'YOUR_JWT_TOKEN_HERE'),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final String token;
  MainScreen({Key? key, required this.token}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _unreadNotifications = 2; // Example badge count

  final List<Widget> _screens = [
    PropertiesListScreen(),
    PropertiesMapScreen(),
  ];

  final List<String> _titles = [
    'Properties',
    'Map',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: () {
                    Navigator.pop(context);
                    _showSearchDialog();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.filter_list,
                  label: 'Filters',
                  onTap: () {
                    Navigator.pop(context);
                    _showFilterDialog();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.home_work,
                  label: 'My Properties',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyPropertiesScreen()),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    _showFavorites();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.notifications,
                  label: 'Alerts',
                  onTap: () {
                    Navigator.pop(context);
                    _showNotifications();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: Colors.blue[800],
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Properties'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter property name, location, or price...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to properties with search
              setState(() {
                _currentIndex = 1;
              });
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Properties'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Property Type'),
              subtitle: Text('All Types'),
              onTap: () {
                // Show property type options
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Price Range'),
              subtitle: Text('Any Price'),
              onTap: () {
                // Show price range options
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Location'),
              subtitle: Text('All Locations'),
              onTap: () {
                // Show location options
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 1;
              });
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Favorites feature coming soon!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications_active, color: Colors.blue),
              title: Text('New Property Alert'),
              subtitle: Text('2-bedroom apartment in Westlands'),
              trailing: Text('2m ago'),
            ),
            ListTile(
              leading: Icon(Icons.price_change, color: Colors.green),
              title: Text('Price Drop Alert'),
              subtitle: Text('Studio apartment price reduced'),
              trailing: Text('1h ago'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex], style: GoogleFonts.poppins()),
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 6,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.green),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Animated quick actions bar
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildQuickActionCard(
                  icon: Icons.add_home,
                  label: 'Add Property',
                  color: kAccentGold,
                  onTap: () {},
                ),
                _buildQuickActionCard(
                  icon: Icons.search,
                  label: 'Search',
                  color: kSecondaryGreen,
                  onTap: _showSearchDialog,
                ),
                _buildQuickActionCard(
                  icon: Icons.filter_list,
                  label: 'Filters',
                  color: kAccentGold,
                  onTap: _showFilterDialog,
                ),
                _buildQuickActionCard(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  color: kSecondaryGreen,
                  onTap: _showFavorites,
                ),
                _buildQuickActionCard(
                  icon: Icons.map,
                  label: 'Map',
                  color: kAccentGold,
                  onTap: () => _onTabTapped(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: EdgeInsets.all(16),
                child: _screens[_currentIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: kBackground,
          selectedItemColor: kPrimaryGreen,
          unselectedItemColor: kSecondaryGreen,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Properties',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: 1.0,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: kAccentGold,
          child: Icon(Icons.add, color: kTextDark),
          tooltip: 'Quick Add',
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 110,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kTextDark, size: 28),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: kTextDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('Language'),
              subtitle: Text('English'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Dark Mode'),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('How to use the app'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.contact_support),
              title: Text('Contact Support'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Send Feedback'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Rentisha Kodi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_work, size: 64, color: Colors.blue[800]),
            SizedBox(height: 16),
            Text(
              'Rentisha Kodi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('Your ultimate property rental platform'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
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

class NotificationsScreen extends StatefulWidget {
  final String token; // Auth token for API requests
  const NotificationsScreen({Key? key, required this.token}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() { isLoading = true; });
    final response = await http.get(
      Uri.parse('http://localhost:5000/api/properties/notifications'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        notifications = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notifications')),
      );
    }
  }

  Future<void> markAsRead(int id) async {
    final response = await http.patch(
      Uri.parse('http://localhost:5000/api/properties/notifications/$id/read'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      fetchNotifications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return ListTile(
                      leading: Icon(
                        notif['is_read'] ? Icons.notifications_none : Icons.notifications_active,
                        color: notif['is_read'] ? Colors.grey : Colors.blue,
                      ),
                      title: Text(notif['message'] ?? ''),
                      subtitle: Text(notif['created_at'] ?? ''),
                      trailing: notif['is_read']
                          ? null
                          : TextButton(
                              child: Text('Mark as read'),
                              onPressed: () => markAsRead(notif['id']),
                            ),
                    );
                  },
                ),
    );
  }
} 
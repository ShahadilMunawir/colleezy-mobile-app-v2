import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // TODO: Update this with your backend URL
  // For Android emulator, use: http://10.0.2.2:8000/api/v1
  // For iOS simulator, use: http://localhost:8000/api/v1
  // For physical devices, use your computer's IP address: http://YOUR_IP:8000/api/v1
  static const String baseUrl = 'http://192.168.1.14:8000/api/v1';
  
  /// Create or update a user in the backend after Firebase authentication
  Future<Map<String, dynamic>?> createUserFromFirebase(User firebaseUser) async {
    try {
      final url = Uri.parse('$baseUrl/auth/firebase-signup');
      
      // Extract email and phone from Firebase user
      final email = firebaseUser.email;
      final phone = firebaseUser.phoneNumber;
      final firebaseUid = firebaseUser.uid;
      
      // Prepare request body
      final body = <String, dynamic>{
        'firebase_uid': firebaseUid,
      };
      
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      
      if (phone != null && phone.isNotEmpty) {
        body['phone'] = phone;
      }
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        print('User created successfully: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 200) {
        // User was updated (not created)
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to create user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating user in backend: $e');
      return null;
    }
  }
  
  /// Get user information from backend
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/users/$userId');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
}


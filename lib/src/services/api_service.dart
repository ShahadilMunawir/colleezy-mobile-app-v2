import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // TODO: Update this with your backend URL
  // For Android emulator, use: http://10.0.2.2:8000/api/v1
  // For iOS simulator, use: http://localhost:8000/api/v1
  // For physical devices, use your computer's IP address: http://YOUR_IP:8000/api/v1
  static const String baseUrl = 'http://192.168.1.14:8000/api/v1';
  static const String _tokenKey = 'backend_jwt_token';
  
  // Cache SharedPreferences instance to avoid multiple initializations
  SharedPreferences? _prefs;
  
  /// Get or initialize SharedPreferences instance with retry logic
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) {
      return _prefs!;
    }
    
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs!;
    } catch (e) {
      // If channel error occurs, wait a bit and retry
      print('SharedPreferences initialization failed, retrying: $e');
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        _prefs = await SharedPreferences.getInstance();
        return _prefs!;
      } catch (e2) {
        print('SharedPreferences retry failed: $e2');
        // If still failing, try to get a fresh instance
        _prefs = null;
        _prefs = await SharedPreferences.getInstance();
        return _prefs!;
      }
    }
  }
  
  /// Get stored JWT token
  Future<String?> getToken() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token from SharedPreferences: $e');
      return null;
    }
  }
  
  /// Store JWT token
  Future<void> setToken(String token) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error setting token in SharedPreferences: $e');
      // Try to reinitialize and retry once
      _prefs = null;
      try {
        final prefs = await _getPrefs();
        await prefs.setString(_tokenKey, token);
      } catch (e2) {
        print('Error setting token after retry: $e2');
        rethrow;
      }
    }
  }
  
  /// Clear stored token
  Future<void> clearToken() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_tokenKey);
    } catch (e) {
      print('Error clearing token from SharedPreferences: $e');
      // Try to reinitialize and retry once
      _prefs = null;
      try {
        final prefs = await _getPrefs();
        await prefs.remove(_tokenKey);
      } catch (e2) {
        print('Error clearing token after retry: $e2');
      }
    }
  }
  
  /// Get headers with authentication token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (includeAuth) {
      try {
        final token = await getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        print('Error getting token for headers: $e');
        // Continue without auth token if SharedPreferences fails
      }
    }
    
    return headers;
  }
  
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
        headers: await _getHeaders(includeAuth: false),
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
  
  /// Login with Firebase UID and get JWT token
  Future<String?> loginWithFirebase(String firebaseUid) async {
    try {
      final url = Uri.parse('$baseUrl/auth/firebase-login');
      final response = await http.post(
        url,
        headers: await _getHeaders(includeAuth: false),
        body: jsonEncode({'firebase_uid': firebaseUid}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        await setToken(token);
        print('Token set: $token');
        return token;
      } else {
        print('Failed to login: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error logging in with Firebase: $e');
      return null;
    }
  }
  
  /// Get current user information from backend
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final url = Uri.parse('$baseUrl/auth/me');
      final response = await http.get(url, headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  /// Check if user profile is complete (has phone number)
  Future<bool> isProfileComplete() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;
      
      final phone = user['phone'] as String?;
      return phone != null && phone.trim().isNotEmpty;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }
  
  /// Upload profile photo
  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      final url = Uri.parse('$baseUrl/upload/profile-photo');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      
      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      
      // Add file
      final fileName = imageFile.path.split('/').last;
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: fileName,
      );
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final photoUrl = data['photo_url'] as String?;
        print('Profile photo uploaded successfully: $photoUrl');
        return photoUrl;
      } else {
        print('Failed to upload profile photo: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }
  
  /// Update current user information
  Future<Map<String, dynamic>?> updateCurrentUser({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/me');
      
      final body = <String, dynamic>{};
      if (name != null) {
        body['name'] = name;
      }
      if (email != null) {
        body['email'] = email;
      }
      if (phone != null) {
        body['phone'] = phone;
      }
      if (photoUrl != null) {
        body['photo_url'] = photoUrl;
      }
      
      final headers = await _getHeaders();
      final token = await getToken();
      
      if (token == null || token.isEmpty) {
        print('No authentication token available for updateCurrentUser');
        return null;
      }
      
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        print('User updated successfully: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        print('Authentication failed (401). Token may be invalid or expired.');
        print('Response: ${response.body}');
        return null;
      } else {
        print('Failed to update user: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating user: $e');
      return null;
    }
  }
  
  /// Get user information from backend
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final url = Uri.parse('$baseUrl/users/$userId');
      final response = await http.get(url, headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
  
  /// Create a new kuri group
  Future<Map<String, dynamic>?> createGroup({
    required String name,
    required DateTime startingDate,
    required double totalAmount,
    required int duration,
    required double amountPerPeriod,
    required String collectionPeriod, // 'weekly' or 'monthly'
  }) async {
    try {
      final url = Uri.parse('$baseUrl/kuri-groups');
      
      // Format date as YYYY-MM-DD
      final dateStr = '${startingDate.year}-${startingDate.month.toString().padLeft(2, '0')}-${startingDate.day.toString().padLeft(2, '0')}';
      
      final body = <String, dynamic>{
        'name': name,
        'starting_date': dateStr,
        'total_amount': totalAmount,
        'duration': duration,
        'amount_per_period': amountPerPeriod,
        'collection_period': collectionPeriod.toLowerCase(),
      };
      
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        print('Group created successfully: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to create group: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }
  
  /// Get all groups for the current user
  Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      final url = Uri.parse('$baseUrl/kuri-groups');
      final response = await http.get(url, headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting groups: $e');
      return [];
    }
  }
  
  /// Get a specific group by ID
  Future<Map<String, dynamic>?> getGroup(int groupId) async {
    try {
      final url = Uri.parse('$baseUrl/kuri-groups/$groupId');
      final response = await http.get(url, headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }
  
  /// Get all members of a specific group
  Future<List<Map<String, dynamic>>> getGroupMembers(int groupId) async {
    try {
      final url = Uri.parse('$baseUrl/kuri-groups/$groupId/members');
      final response = await http.get(url, headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting group members: $e');
      return [];
    }
  }
  
  /// Add a member directly to a group by phone number or email
  Future<Map<String, dynamic>?> addMemberToGroup({
    required int groupId,
    String? email,
    String? phone,
    String? name,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/kuri-groups/$groupId/members');
      
      final body = <String, dynamic>{};
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        body['phone'] = phone;
      }
      if (name != null && name.isNotEmpty) {
        body['name'] = name;
      }
      
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        print('Member added successfully: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to add member: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error adding member: $e');
      return null;
    }
  }
  
  /// Make a member an agent of a group
  Future<Map<String, dynamic>?> makeMemberAgent({
    required int groupId,
    required int userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/kuri-groups/$groupId/members/$userId/make-agent');
      
      final response = await http.post(
        url,
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        print('Member made agent successfully: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to make member agent: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error making member agent: $e');
      return null;
    }
  }
  
  /// Get transactions for a member in a group
  Future<List<Map<String, dynamic>>> getMemberTransactions({
    required int groupId,
    required int memberUserId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/kuri-groups/$groupId/members/$memberUserId/transactions');
      final response = await http.get(url, headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting member transactions: $e');
      return [];
    }
  }
  
  /// Create a new transaction (collect money from a member)
  Future<Map<String, dynamic>?> createTransaction({
    required int groupId,
    required int memberUserId,
    required double amount,
    double? dueAmount,
    required String status, // 'collected', 'partially_collected', 'pending'
    int? periodNumber,
    String? notes,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/kuri-groups/$groupId/members/$memberUserId/transactions');
      
      final body = <String, dynamic>{
        'amount': amount,
        'status': status,
      };
      
      if (dueAmount != null) {
        body['due_amount'] = dueAmount;
      }
      if (periodNumber != null) {
        body['period_number'] = periodNumber;
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }
      
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        print('Transaction created successfully: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to create transaction: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating transaction: $e');
      return null;
    }
  }
  
  /// Get all transactions for the current user with optional filters
  Future<List<Map<String, dynamic>>> getAllTransactions({
    int? groupId,
    String? startDate, // YYYY-MM-DD format
    String? endDate, // YYYY-MM-DD format
    String? status, // 'collected', 'partially_collected'
  }) async {
    try {
      final queryParams = <String, String>{};
      if (groupId != null) {
        queryParams['kuri_group_id'] = groupId.toString();
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      
      final url = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.get(url, headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting all transactions: $e');
      return [];
    }
  }
  
  /// Create a draw/winner record
  Future<Map<String, dynamic>?> createDraw({
    required int groupId,
    required int winnerUserId,
    required String drawType, // 'spin_wheel' or 'manual_draw'
    int? periodNumber,
    String? notes,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/kuri-groups/$groupId/draws');
      
      final body = <String, dynamic>{
        'winner_user_id': winnerUserId,
        'draw_type': drawType,
      };
      
      if (periodNumber != null) {
        body['period_number'] = periodNumber;
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }
      
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        print('Draw created successfully: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to create draw: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating draw: $e');
      return null;
    }
  }
  
  /// Get all draws/winners for groups where the current user is a member
  Future<List<Map<String, dynamic>>> getAllDraws() async {
    try {
      final url = Uri.parse('$baseUrl/draws');
      final response = await http.get(url, headers: await _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
      print('Failed to get all draws: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Error getting all draws: $e');
      return [];
    }
  }
}


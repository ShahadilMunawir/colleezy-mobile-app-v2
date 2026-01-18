import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;
  
  const ProfileScreen({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  bool _isLoggingOut = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _userPhotoUrl;
  String? _initial;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    // Get Firebase user info as fallback
    final firebaseUser = _authService.currentUser;
    String? photoUrl = firebaseUser?.photoURL;
    String? displayName = firebaseUser?.displayName;
    String? email = firebaseUser?.email;
    String? phone = firebaseUser?.phoneNumber;

    // Get backend user info - prioritize backend data as source of truth
    try {
      final backendUser = await _apiService.getCurrentUser();
      if (backendUser != null) {
        // Always use backend data if available, only fall back to Firebase if backend data is null/empty
        final backendName = backendUser['name'] as String?;
        final backendEmail = backendUser['email'] as String?;
        final backendPhone = backendUser['phone'] as String?;
        final backendPhotoUrl = backendUser['photo_url'] as String?;
        
        // Use backend data if available, otherwise keep Firebase data
        displayName = (backendName != null && backendName.isNotEmpty) ? backendName : displayName;
        email = (backendEmail != null && backendEmail.isNotEmpty) ? backendEmail : email;
        phone = (backendPhone != null && backendPhone.isNotEmpty) ? backendPhone : phone;
        
        if (backendPhotoUrl != null && backendPhotoUrl.isNotEmpty) {
          // Convert relative URL to full URL if needed
          if (backendPhotoUrl.startsWith('/')) {
            photoUrl = '${ApiService.baseUrl.replaceAll('/api/v1', '')}$backendPhotoUrl';
          } else {
            photoUrl = backendPhotoUrl;
          }
        }
      }
    } catch (e) {
      print('Error loading backend user info: $e');
      // Continue with Firebase data if backend fails
    }

    // Set initial for avatar
    String initial = '?';
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        initial = (parts[0][0] + parts[1][0]).toUpperCase();
      } else {
        initial = displayName[0].toUpperCase();
      }
    } else if (email != null && email.isNotEmpty) {
      initial = email[0].toUpperCase();
    }

    if (mounted) {
      setState(() {
        _nameController.text = displayName ?? '';
        _emailController.text = email ?? '';
        _phoneController.text = phone ?? '';
        _userPhotoUrl = photoUrl;
        _initial = initial;
        _isLoading = false;
      });
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFA5A5A5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF2D7A4F)),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white, fontFamily: 'DM Sans'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2D7A4F)),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(color: Colors.white, fontFamily: 'DM Sans'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red, fontFamily: 'DM Sans'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Check if token exists, if not, try to get it
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        // Token not available, try to get it by logging in again
        final firebaseUser = _authService.currentUser;
        if (firebaseUser != null) {
          print('Token not found, attempting to refresh token...');
          await _apiService.loginWithFirebase(firebaseUser.uid);
          
          // Check again after refresh
          final newToken = await _apiService.getToken();
          if (newToken == null || newToken.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Authentication failed. Please try logging in again.'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() {
                _isSaving = false;
              });
            }
            return;
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Not authenticated. Please log in again.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isSaving = false;
            });
          }
          return;
        }
      }

      String? photoUrl;
      
      // Upload image first if one is selected
      if (_selectedImage != null) {
        photoUrl = await _apiService.uploadProfilePhoto(_selectedImage!);
        if (photoUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload profile photo'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isSaving = false;
            });
          }
          return;
        }
        // Convert relative URL to full URL
        if (photoUrl.startsWith('/')) {
          final baseUrlWithoutApi = ApiService.baseUrl.replaceAll('/api/v1', '');
          photoUrl = '$baseUrlWithoutApi$photoUrl';
        }
      }

      // Update user profile
      final result = await _apiService.updateCurrentUser(
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        photoUrl: photoUrl,
      );

      if (result != null && mounted) {
        // Reload user data from backend to ensure we have the latest saved data
        await _loadUserData();
        
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF2D7A4F),
          ),
        );
        
        // Check if profile is now complete (has phone number)
        final phone = _phoneController.text.trim();
        if (phone.isNotEmpty) {
          // Profile is complete, check if we should navigate to home
          // Only navigate if we came from login (not from home screen)
          final canPop = Navigator.canPop(context);
          if (!canPop) {
            // We came from login, navigate to home
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile. Please check your connection and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B3A2E), // Lighter dark green at top
              Color(0xFF0A1A14), // Darker black-green at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button (only shown when navigated from home screen)
              if (widget.showBackButton) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 40),
              // Avatar Section
              Stack(
                alignment: Alignment.center,
                children: [
                  // Large Avatar Circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D7A4F),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2D7A4F),
                        width: 2,
                      ),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_userPhotoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: _selectedImage == null && (_userPhotoUrl == null || _userPhotoUrl!.isEmpty)
                        ? Center(
                            child: Text(
                              _initial ?? '?',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Plus Button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D7A4F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // Form Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A1A14),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Scrollable Form Fields
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: Column(
                            children: [
                              // Name Field
                              _buildInputField(
                                icon: Icons.person,
                                label: 'Name',
                                controller: _nameController,
                              ),
                              const SizedBox(height: 20),
                              // Email Field
                              _buildInputField(
                                icon: Icons.email,
                                label: 'Email (optional)',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              // Phone Field
                              _buildInputField(
                                icon: Icons.phone,
                                label: 'Phone',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Fixed Bottom Buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          children: [
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isSaving || _isLoading ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D7A4F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: const Color(0xFF6B7280),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'DM Sans',
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoggingOut ? null : _handleLogout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoggingOut
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                        ),
                                      )
                                    : const Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'DM Sans',
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'DM Sans',
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF2D7A4F),
            size: 24,
          ),
          hintText: label,
          hintStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'DM Sans',
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF2D7A4F),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFF141414),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}


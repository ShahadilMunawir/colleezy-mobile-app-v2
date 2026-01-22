import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../../utils/responsive.dart';

/// Minimal country data for the country code picker
class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final int phoneLength; // Expected phone number length (without country code)

  const Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.phoneLength,
  });
}

const List<Country> _countries = [
  Country(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸', phoneLength: 10),
  Country(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧', phoneLength: 10),
  Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳', phoneLength: 10),
  Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦', phoneLength: 10),
  Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺', phoneLength: 9),
  Country(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪', phoneLength: 11),
  Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷', phoneLength: 9),
  Country(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵', phoneLength: 10),
  Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳', phoneLength: 11),
  Country(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷', phoneLength: 11),
  Country(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽', phoneLength: 10),
  Country(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷', phoneLength: 10),
  Country(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹', phoneLength: 10),
  Country(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸', phoneLength: 9),
  Country(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱', phoneLength: 9),
  Country(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬', phoneLength: 8),
  Country(name: 'UAE', code: 'AE', dialCode: '+971', flag: '🇦🇪', phoneLength: 9),
  Country(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦', phoneLength: 9),
  Country(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦', phoneLength: 9),
  Country(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬', phoneLength: 10),
  Country(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰', phoneLength: 10),
  Country(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩', phoneLength: 10),
  Country(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩', phoneLength: 11),
  Country(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭', phoneLength: 10),
  Country(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳', phoneLength: 9),
  Country(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭', phoneLength: 9),
  Country(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾', phoneLength: 10),
  Country(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺', phoneLength: 10),
  Country(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷', phoneLength: 10),
  Country(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬', phoneLength: 10),
];

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
  Country _selectedCountry = _countries[2]; // Default to India

  void _parsePhoneNumber(String phoneNumber) {
    // Try to match country code from phone number
    for (var country in _countries) {
      if (phoneNumber.startsWith(country.dialCode)) {
        setState(() {
          _selectedCountry = country;
        });
        break;
      }
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CountryPickerSheet(
        countries: _countries,
        selectedCountry: _selectedCountry,
        onSelect: (country) {
          setState(() {
            _selectedCountry = country;
            // Update maxLength when country changes
          });
          Navigator.pop(context);
        },
      ),
    );
  }

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
        
        // Parse phone number to extract country code and set selected country
        if (phone != null && phone.isNotEmpty) {
          _parsePhoneNumber(phone);
        }
        
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

    // Parse phone number to extract country code and phone number separately
    String phoneWithoutCode = '';
    if (phone != null && phone.isNotEmpty) {
      // Try to find matching country code
      bool foundMatch = false;
      for (var country in _countries) {
        if (phone.startsWith(country.dialCode)) {
          phoneWithoutCode = phone.substring(country.dialCode.length).trim();
          if (mounted) {
            setState(() {
              _selectedCountry = country;
            });
          }
          foundMatch = true;
          break;
        }
      }
      // If no country code match found, use the full phone number
      if (!foundMatch) {
        phoneWithoutCode = phone;
      }
    }

    if (mounted) {
      setState(() {
        _nameController.text = displayName ?? '';
        _emailController.text = email ?? '';
        _phoneController.text = phoneWithoutCode;
        _userPhotoUrl = photoUrl;
        _initial = initial;
        _isLoading = false;
      });
    }
  }

  Future<void> _showImagePickerOptions() async {
    final responsive = Responsive(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(responsive.radius(20))),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: responsive.spacing(12)),
              Container(
                width: responsive.width(40),
                height: responsive.height(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFA5A5A5),
                  borderRadius: BorderRadius.circular(responsive.radius(2)),
                ),
              ),
              SizedBox(height: responsive.spacing(20)),
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF2D7A4F), size: responsive.width(24)),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white, fontFamily: 'DM Sans', fontSize: responsive.fontSize(16)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF2D7A4F), size: responsive.width(24)),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: Colors.white, fontFamily: 'DM Sans', fontSize: responsive.fontSize(16)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red, size: responsive.width(24)),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red, fontFamily: 'DM Sans', fontSize: responsive.fontSize(16)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
              SizedBox(height: responsive.spacing(20)),
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

      // Validate phone number is required
      final phoneNumber = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (phoneNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number is required. Please enter your phone number.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
        }
        return;
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

      // Prepare phone number with country code (phoneNumber already validated above)
      final phoneWithCountryCode = '${_selectedCountry.dialCode}$phoneNumber';

      // Update user profile
      final result = await _apiService.updateCurrentUser(
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        phone: phoneWithCountryCode,
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
        final phoneNumber = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
        final phone = phoneNumber.isNotEmpty ? '${_selectedCountry.dialCode}$phoneNumber' : '';
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
    final responsive = Responsive(context);
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
                  padding: responsive.paddingFromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: responsive.width(40),
                          height: responsive.height(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: responsive.width(24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(20)),
              ] else
                SizedBox(height: responsive.spacing(40)),
              // Avatar Section
              Stack(
                alignment: Alignment.center,
                children: [
                  // Large Avatar Circle
                  Container(
                    width: responsive.width(120),
                    height: responsive.height(120),
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
                              style: TextStyle(
                                fontSize: responsive.fontSize(48),
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
                        width: responsive.width(36),
                        height: responsive.height(36),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D7A4F),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: responsive.width(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(60)),
              // Form Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFF0A1A14),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(responsive.radius(30)),
                      topRight: Radius.circular(responsive.radius(30)),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Scrollable Form Fields
                      Expanded(
                        child: SingleChildScrollView(
                          padding: responsive.paddingFromLTRB(24, 24, 24, 0),
                          child: Column(
                            children: [
                              // Name Field
                              _buildInputField(
                                context: context,
                                icon: Icons.person,
                                label: 'Name',
                                controller: _nameController,
                              ),
                              SizedBox(height: responsive.spacing(20)),
                              // Email Field
                              _buildInputField(
                                context: context,
                                icon: Icons.email,
                                label: 'Email (optional)',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: responsive.spacing(20)),
                              // Phone Field with Country Picker
                              _buildPhoneField(context),
                            ],
                          ),
                        ),
                      ),
                      // Fixed Bottom Buttons
                      Padding(
                        padding: responsive.paddingFromLTRB(24, 16, 24, 24),
                        child: Column(
                          children: [
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: responsive.height(56),
                              child: ElevatedButton(
                                onPressed: _isSaving || _isLoading ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D7A4F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(responsive.radius(12)),
                                  ),
                                  disabledBackgroundColor: const Color(0xFF6B7280),
                                ),
                                child: _isSaving
                                    ? SizedBox(
                                        width: responsive.width(24),
                                        height: responsive.height(24),
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(18),
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'DM Sans',
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: responsive.spacing(12)),
                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              height: responsive.height(56),
                              child: ElevatedButton(
                                onPressed: _isLoggingOut ? null : _handleLogout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(responsive.radius(12)),
                                  ),
                                ),
                                child: _isLoggingOut
                                    ? SizedBox(
                                        width: responsive.width(24),
                                        height: responsive.height(24),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                        ),
                                      )
                                    : Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(18),
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

  Widget _buildPhoneField(BuildContext context) {
    final responsive = Responsive(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(responsive.radius(12)),
      ),
      child: Row(
        children: [
          // Country Code Picker
          GestureDetector(
            onTap: _showCountryPicker,
            child: Container(
              padding: responsive.paddingSymmetric(horizontal: 10, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Color(0xFF2A2A2A),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountry.flag,
                    style: TextStyle(fontSize: responsive.fontSize(18)),
                  ),
                  SizedBox(width: responsive.spacing(4)),
                  Text(
                    _selectedCountry.dialCode,
                    style: TextStyle(
                      color: Color(0xFFEFEEEC),
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  SizedBox(width: responsive.spacing(2)),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6B7280),
                    size: responsive.width(18),
                  ),
                ],
              ),
            ),
          ),
          // Phone Number Input
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: _selectedCountry.phoneLength,
              style: TextStyle(
                color: Color(0xFFEFEEEC),
                fontSize: responsive.fontSize(15),
                fontWeight: FontWeight.w400,
                fontFamily: 'DM Sans',
              ),
              decoration: InputDecoration(
                hintText: 'Phone Number (${_selectedCountry.phoneLength} digits)',
                hintStyle: TextStyle(
                  color: Color(0xFFD0CDC6),
                  fontSize: responsive.fontSize(15),
                  fontWeight: FontWeight.w400,
                ),
                counterText: '', // Hide the character counter
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.radius(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.radius(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(responsive.radius(12)),
                  borderSide: BorderSide(
                    color: Color(0xFF2D7A4F),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: responsive.paddingSymmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    final responsive = Responsive(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(responsive.radius(12)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: Colors.white,
          fontSize: responsive.fontSize(16),
          fontFamily: 'DM Sans',
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF2D7A4F),
            size: responsive.width(24),
          ),
          hintText: label,
          hintStyle: TextStyle(
            color: Colors.white,
            fontSize: responsive.fontSize(16),
            fontFamily: 'DM Sans',
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(responsive.radius(12)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(responsive.radius(12)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(responsive.radius(12)),
            borderSide: BorderSide(
              color: Color(0xFF2D7A4F),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFF141414),
          contentPadding: responsive.paddingSymmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final List<Country> countries;
  final Country selectedCountry;
  final Function(Country) onSelect;

  const _CountryPickerSheet({
    required this.countries,
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late TextEditingController _searchController;
  late List<Country> _filteredCountries;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCountries = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = widget.countries;
      } else {
        _filteredCountries = widget.countries
            .where((c) =>
                c.name.toLowerCase().contains(query.toLowerCase()) ||
                c.dialCode.contains(query) ||
                c.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.radius(24)),
          topRight: Radius.circular(responsive.radius(24)),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: responsive.spacing(12)),
            width: responsive.width(40),
            height: responsive.height(4),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(responsive.radius(2)),
            ),
          ),
          // Title
          Padding(
            padding: responsive.paddingAll(20),
            child: Text(
              'Select Country',
              style: TextStyle(
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.w600,
                color: Color(0xFFEFEEEC),
                fontFamily: 'DM Sans',
              ),
            ),
          ),
          // Search field
          Padding(
            padding: responsive.paddingSymmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(responsive.radius(12)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCountries,
                style: TextStyle(
                  color: Color(0xFFEFEEEC),
                  fontSize: responsive.fontSize(15),
                  fontFamily: 'DM Sans',
                ),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: TextStyle(
                    color: Color(0xFFD0CDC6),
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6B7280),
                    size: responsive.width(22),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(responsive.radius(12)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: responsive.paddingSymmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: responsive.spacing(12)),
          // Country list
          Expanded(
            child: ListView.builder(
              padding: responsive.paddingSymmetric(horizontal: 12),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;
                
                return GestureDetector(
                  onTap: () => widget.onSelect(country),
                  child: Container(
                    margin: responsive.paddingSymmetric(vertical: 2),
                    padding: responsive.paddingSymmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF2D7A4F).withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(responsive.radius(10)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          country.flag,
                          style: TextStyle(fontSize: responsive.fontSize(24)),
                        ),
                        SizedBox(width: responsive.spacing(14)),
                        Expanded(
                          child: Text(
                            country.name,
                            style: TextStyle(
                              color: isSelected 
                                  ? const Color(0xFF2D7A4F) 
                                  : const Color(0xFFEFEEEC),
                              fontSize: responsive.fontSize(15),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ),
                        Text(
                          country.dialCode,
                          style: TextStyle(
                            color: isSelected 
                                ? const Color(0xFF2D7A4F) 
                                : const Color(0xFFD0CDC6),
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: responsive.spacing(10)),
                          Icon(
                            Icons.check_rounded,
                            color: Color(0xFF2D7A4F),
                            size: responsive.width(20),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../profile/profile_screen.dart';
import 'otp_verification_screen.dart';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _verificationId;
  Country _selectedCountry = _countries[2]; // Default to India

  void _showErrorToast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Check if user is already signed in
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = _authService.currentUser;
    if (user != null && mounted) {
      // User is already signed in, check profile completion
      await _navigateAfterAuth();
    }
  }
  
  Future<void> _navigateAfterAuth() async {
    // Wait a bit for backend to sync
    await Future.delayed(const Duration(milliseconds: 500));
    
    final isComplete = await _apiService.isProfileComplete();
    if (mounted) {
      if (!isComplete) {
        // Profile incomplete, navigate to profile screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
      } else {
        // Profile complete, navigate to home
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null && mounted) {
        await _navigateAfterAuth();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Failed to sign in with Google: ${e.toString()}');
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
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _handlePhoneSignIn() async {
    final phoneNumber = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');

    if (phoneNumber.isEmpty) {
      _showErrorToast('Please enter your phone number');
      return;
    }

    // Validate phone number length based on selected country
    if (phoneNumber.length != _selectedCountry.phoneLength) {
      _showErrorToast(
        'Phone number must be ${_selectedCountry.phoneLength} digits for ${_selectedCountry.name}',
      );
      return;
    }

    // Combine country code with phone number
    String formattedPhone = '${_selectedCountry.dialCode}$phoneNumber';

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.sendOTP(
        formattedPhone,
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPVerificationScreen(
                  phoneNumber: formattedPhone,
                  verificationId: verificationId,
                  onVerified: _verifyOTP,
                ),
              ),
            );
          }
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
          });
          _showErrorToast(error);
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Failed to send OTP: ${e.toString()}');
    }
  }

  Future<void> _verifyOTP(String smsCode) async {
    if (_verificationId == null) return;

    try {
      final userCredential =
          await _authService.verifyOTP(_verificationId!, smsCode);
      if (userCredential.user != null && mounted) {
        await _navigateAfterAuth();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: isKeyboardVisible 
                  ? const AlwaysScrollableScrollPhysics() 
                  : const NeverScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: SvgPicture.asset('assets/svg/card.svg', width: 200, height: 200),
                            ),
                          ],
                        ),
                      ),
                      SvgPicture.asset('assets/svg/logo.svg'),
                      const SizedBox(height: 50),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 250 - 100 - 50,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                  children: [
                    const SizedBox(height: 40),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Welcome To\n',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'DM Sans',
                              color: Color(0XFFEFEEEC),
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Colleezy',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'DM Sans',
                              color: Color(0xFF2D7A4F),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign in with your Colleezy account to Manage money',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD0CDC6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Country Code Picker
                          GestureDetector(
                            onTap: _showCountryPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                              decoration: const BoxDecoration(
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
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedCountry.dialCode,
                                    style: const TextStyle(
                                      color: Color(0xFFEFEEEC),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF6B7280),
                                    size: 18,
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
                              style: const TextStyle(
                                color: Color(0xFFEFEEEC),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'DM Sans',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Phone Number (${_selectedCountry.phoneLength} digits)',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFD0CDC6),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                counterText: '', // Hide the character counter
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePhoneSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D7A4F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: const Color(0xFF9CA3AF),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Sign In with Phone',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or Continue With',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFD0CDC6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _isLoading ? null : _handleGoogleSignIn,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            width: 64,
                            child: SvgPicture.asset(
                              'assets/svg/google.svg',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/svg/apple.svg',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
                            ),
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
    );
  }
}

/// Bottom sheet for selecting a country code
class _CountryPickerSheet extends StatefulWidget {
  final List<Country> countries;
  final Country selectedCountry;
  final ValueChanged<Country> onSelect;

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
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Select Country',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEFEEEC),
                fontFamily: 'DM Sans',
              ),
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCountries,
                style: const TextStyle(
                  color: Color(0xFFEFEEEC),
                  fontSize: 15,
                  fontFamily: 'DM Sans',
                ),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFD0CDC6),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6B7280),
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Country list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;
                
                return GestureDetector(
                  onTap: () => widget.onSelect(country),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF2D7A4F).withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          country.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            country.name,
                            style: TextStyle(
                              color: isSelected 
                                  ? const Color(0xFF2D7A4F) 
                                  : const Color(0xFFEFEEEC),
                              fontSize: 15,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF2D7A4F),
                            size: 20,
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
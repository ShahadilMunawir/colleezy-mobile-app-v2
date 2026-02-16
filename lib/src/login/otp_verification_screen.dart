import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final Future<void> Function(String smsCode) onVerified;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.onVerified,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 5) return phoneNumber;
    final countryCode = phoneNumber.substring(0, 3);
    final lastTwo = phoneNumber.substring(phoneNumber.length - 2);
    final masked = '*' * (phoneNumber.length - 5);
    return '$countryCode$masked$lastTwo';
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    setState(() {});
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getOTPCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
    final code = _getOTPCode();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onVerified(code);
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid code. Please try again.';
        _isLoading = false;
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _maskPhoneNumber(widget.phoneNumber);

    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          final topGap = math.min(maxH * 0.06, 40.0);
          final midGap = math.min(maxH * 0.03, 24.0);
          final logoWidth = math.min(maxW * 0.4, 140.0);
          final otpBoxWidth = (maxW * 0.12).clamp(40.0, 70.0);
          final otpBoxHeight = otpBoxWidth * 1.12;
          final otpSpacing = math.max(6.0, maxW * 0.02);
          final horizontalPadding = math.max(16.0, maxW * 0.07);
          final buttonH = math.max(48.0, maxH * 0.07);

          return Column(
            children: [
              SizedBox(height: topGap),
              SizedBox(width: logoWidth, child: SvgPicture.asset('assets/svg/logo.svg')),
              SizedBox(height: midGap),

              AutoSizeText(
                '6-digit Code',
                maxLines: 1,
                minFontSize: 18,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: math.max(12.0, maxH * 0.015)),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: AutoSizeText(
                  'To confirm your phone number, please enter the 6-digit code we sent to $maskedPhone',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  minFontSize: 11,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
              ),

              TextButton(
                onPressed: () {},
                child: AutoSizeText(
                  'Re-send Code',
                  maxLines: 1,
                  minFontSize: 12,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: midGap),

              // OTP inputs
              Padding(
                padding: EdgeInsets.symmetric(horizontal: math.max(8.0, horizontalPadding - 8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (index) {
                    return Padding(
                      padding: EdgeInsets.only(right: index == 5 ? 0 : otpSpacing),
                      child: SizedBox(
                        width: otpBoxWidth,
                        height: otpBoxHeight,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: math.max(12.0, otpBoxWidth * 0.28),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'DM Sans',
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFF2A2A2A),
                            contentPadding: EdgeInsets.symmetric(vertical: otpBoxHeight * 0.12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(math.max(8.0, otpBoxWidth * 0.18)),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(math.max(8.0, otpBoxWidth * 0.18)),
                              borderSide: const BorderSide(
                                color: Color(0xFF3A3A3A),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(math.max(8.0, otpBoxWidth * 0.18)),
                              borderSide: const BorderSide(
                                color: Color(0xFF2D7A4F),
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _onChanged(index, value),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              if (_errorMessage != null) ...[
                SizedBox(height: math.max(12.0, maxH * 0.015)),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ],

              const Spacer(),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: math.max(12.0, horizontalPadding - 4), vertical: math.max(12.0, maxH * 0.02)),
                child: SizedBox(
                  width: double.infinity,
                  height: buttonH,
                  child: ElevatedButton(
                    onPressed: _isLoading || _getOTPCode().length != 6 ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A4F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(math.max(10.0, buttonH * 0.18)),
                      ),
                      disabledBackgroundColor: const Color(0xFF9CA3AF),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: math.max(20.0, buttonH * 0.4),
                            height: math.max(20.0, buttonH * 0.4),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : AutoSizeText(
                            'Continue',
                            maxLines: 1,
                            minFontSize: 12,
                            style: TextStyle(
                              fontSize: math.max(14.0, buttonH * 0.28),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

